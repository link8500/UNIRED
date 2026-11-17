import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/evento_servidor.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'support/test_adapter.dart';

void main() {
  test(
    'reconstruye eventos divididos por paquetes y separa heartbeat de notificaciones',
    () async {
      final events = await interpretarEventos(
        Stream.fromIterable([
          ': comentario\r\nevent: notifi',
          'cations\r\nid: 7\r\ndata: {"items":',
          '[{"titulo":"Tutoría aceptada"}]}\r\n\r\nevent: heartbeat\nid: 7\ndata: {"items":[]}\n\n',
        ]),
      ).toList();
      expect(events.length, 2);
      expect(events[0].type, 'notifications');
      expect(events[0].id, '7');
      expect(
        (events[0].data['items'] as List).single['titulo'],
        'Tutoría aceptada',
      );
      expect(events[1].type, 'heartbeat');
    },
  );
  test(
    'envía el JWT solo en la cabecera y recupera el cursor al conectar',
    () async {
      Uri? sentUrl;
      Map<String, String>? sentHeaders;
      final api =
          ClienteApi(
            baseUrl: 'https://api.example/api/v1',
            eventTransport: (url, headers) {
              sentUrl = url;
              sentHeaders = headers;
              return Stream.value(
                'event: notifications\nid: 9\ndata: {"items":[]}\n\n',
              );
            },
          )..acceptTokens({
            'accessToken': 'jwt-privado',
            'refreshToken': 'refresh',
            'expiresIn': 900,
          });
      expect((await api.events(afterId: '8').first).id, '9');
      expect(sentUrl!.path, '/api/v1/me/events');
      expect(sentUrl!.queryParameters['afterId'], '8');
      expect(sentUrl.toString().contains('jwt-privado'), false);
      expect(sentHeaders!['Authorization'], 'Bearer jwt-privado');
      api.dio.close();
    },
  );
  test(
    'una notificación SSE actualiza la cuenta sin esperar los veinte segundos del sondeo',
    () async {
      final source = StreamController<String>();
      var reads = 0;
      final adapter = TestAdapter((r) async {
        if (r.path == '/auth/login') {
          return TestReply({
            'accessToken': 'test',
            'refreshToken': 'refresh',
            'expiresIn': 900,
          });
        }
        if (r.path == '/me') {
          return TestReply({
            'id': 1,
            'nombre': 'Persona de prueba',
            'email': 'persona@example.test',
            'estado': 'activo',
            'roles': ['usuario'],
            'perfil': {},
          });
        }
        if (r.path == '/me/tutor-grants') return TestReply([]);
        if (r.path == '/me/notifications') reads++;
        return TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 50});
      });
      final api = ClienteApi(
        dio: Dio()..httpClientAdapter = adapter,
        eventTransport: (_, _) => source.stream,
      );
      final service = AplicacionController(client: api);
      await service.signIn(
        email: 'persona@example.test',
        password: 'Solo-prueba-2026!',
      );
      final initial = reads;
      source.add(
        'event: notifications\nid: 1\ndata: {"items":[{"id":"1"}]}\n\n',
      );
      for (var i = 0; i < 20 && reads == initial; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(reads, greaterThan(initial));
      service.dispose();
      await source.close();
    },
  );
}
