import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/mensajeria/views/mensajes_view.dart';
import 'package:unired/models/mensajeria/widgets/asunto_conversacion.dart';
import 'package:unired/models/tutorias/views/curso_view.dart';
import 'package:unired/models/tutorias/widgets/gestion_curso.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'package:unired/shared/widgets/boton_notificaciones.dart';
import 'support/test_adapter.dart';

void main() {
  late AplicacionController service;
  late TestAdapter adapter;
  String? state;
  late bool paid;
  String? approvedAt;
  final course = <String, Object?>{
    'id': '9',
    'tutorId': 2,
    'titulo': 'Angular para empezar',
    'descripcion': 'Videos y recursos prácticos',
    'tutorNombre': 'Daniela Rivas',
    'precioBase': '0.00',
    'moneda': 'NIO',
    'modalidad': 'grabada',
    'nivel': 'inicial',
    'estado': 'publicada',
    'secciones': [],
    'lecciones': [],
  };
  final conversation = <String, Object?>{
    'id': '10',
    'tipo': 'market',
    'anuncioId': '17',
    'interlocutorId': '2',
    'interlocutorNombre': 'Daniela Rivas',
    'interlocutorRol': 'administrador',
    'recursoTitulo': 'Omeprazol 20 mg',
    'recursoDescripcion':
        'Caja de 10 cápsulas. Artículo de muestra de Farmacia JAE.',
    'recursoPrecioBase': '110.00',
    'recursoMoneda': 'NIO',
    'recursoTipoPrecio': 'fijo',
    'recursoImagenId': '71',
    'ultimoMensaje': '¿Todavía está disponible?',
    'noLeidos': 0,
  };
  setUp(() {
    state = null;
    paid = false;
    approvedAt = null;
    adapter = TestAdapter((r) async {
      if (r.responseType == ResponseType.bytes) {
        return TestReply(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
          ),
        );
      }
      if (r.path == '/courses/9') return TestReply(course);
      if (r.path == '/me/courses/9') return TestReply(course);
      if (r.path == '/me/courses') {
        return TestReply({
          'items': [course],
          'total': 1,
          'page': 1,
          'limit': 20,
        });
      }
      if (r.path == '/me/notifications') {
        final notices = [
          {
            'id': '5',
            'tipo': 'inscripcion',
            'titulo': 'Nueva solicitud de acceso a tu tutoría',
            'datos': {'cursoId': '9', 'inscripcionId': '90'},
          },
          {
            'id': '4',
            'tipo': 'mensaje',
            'titulo': 'Tienes un nuevo mensaje',
            'datos': {'conversacionId': '10'},
          },
          {'id': '3', 'tipo': 'sistema', 'titulo': 'Aviso general'},
        ];
        return TestReply({
          'items': notices,
          'total': notices.length,
          'page': 1,
          'limit': 20,
        });
      }
      if (r.path == '/courses/9/enrollments') {
        state = 'solicitada';
        return TestReply({
          'id': '90',
          'tutoriaId': '9',
          'estado': state,
        }, status: 201);
      }
      if (r.path == '/me/enrollments') {
        return TestReply({
          'items': [
            if (state != null) {'id': '90', 'tutoriaId': '9', 'estado': state},
          ],
          'total': state == null ? 0 : 1,
          'limit': 20,
          'page': 1,
        });
      }
      if (r.path == '/me/courses/9/students') {
        return TestReply({
          'items': [
            if (state == 'solicitada')
              {
                'id': '90',
                'alumnoId': 3,
                'nombre': 'Sofía Martínez',
                'estado': state,
                'aprobadaParaPagoEn': approvedAt,
                'completadas': 0,
              },
          ],
          'total': state == 'solicitada' ? 1 : 0,
          'page': 1,
          'limit': 20,
        });
      }
      if (r.path == '/me/courses/9/enrollments/90') {
        if (paid) {
          approvedAt = '2026-11-18T17:00:00Z';
        } else {
          state = textValue(jsonObject(r.data)['estado']);
        }
        return TestReply({
          'id': '90',
          'estado': state,
          'aprobadaParaPagoEn': approvedAt,
        });
      }
      if (r.path == '/me/conversations') {
        return TestReply({
          'items': [conversation],
          'total': 1,
          'page': 1,
          'limit': 20,
        });
      }
      if (r.path == '/conversations/10') return TestReply(conversation);
      if (r.path == '/conversations/10/messages') {
        return TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 20});
      }
      return TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 20});
    });
    service =
        AplicacionController(
            client: ClienteApi(
              enableLiveEvents: false,
              dio: Dio()..httpClientAdapter = adapter,
            ),
          )
          ..currentUser = const UsuarioAplicacion(
            id: '3',
            name: 'Sofía Martínez',
            email: 'sofia@example.test',
            university: '',
            roles: ['usuario'],
          );
    AplicacionController.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());

  Future<void> open(WidgetTester t, Widget child, double width) async {
    t.view.physicalSize = Size(width, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(theme: TemaAplicacion.light, home: child));
    await t.pumpAndSettle();
  }

  testWidgets(
    'una tutoría gratuita requiere solicitud y la aceptación habilita el aula',
    (t) async {
      await open(t, const CursoView(id: '9'), 1100);
      await t.tap(find.text('Solicitar acceso'));
      await t.pumpAndSettle();
      expect(find.text('Solicitud enviada'), findsOneWidget);
      expect(find.text('Abrir aula'), findsNothing);
      expect(find.text('Conversar con el tutor'), findsNothing);
      state = 'activa';
      await t.pump(const Duration(seconds: 8));
      await t.pumpAndSettle();
      expect(find.text('Abrir aula'), findsOneWidget);
      expect(find.text('Conversar con el tutor'), findsOneWidget);
      expect(
        adapter.requests
            .where(
              (r) => r.method == 'POST' && r.path == '/courses/9/enrollments',
            )
            .length,
        1,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(milliseconds: 300));
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'el tutor acepta la solicitud sin salir de la gestión de alumnos',
    (t) async {
      state = 'solicitada';
      var externalReloads = 0;
      await open(
        t,
        Scaffold(
          body: SingleChildScrollView(
            child: GestionCurso(
              course: course,
              reload: () => externalReloads++,
              initialTab: PestanaGestionCurso.students,
            ),
          ),
        ),
        1100,
      );
      await t.ensureVisible(find.text('Aceptar solicitud'));
      await t.tap(find.text('Aceptar solicitud'));
      await t.pumpAndSettle();
      final approval = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(approval.path, '/me/courses/9/enrollments/90');
      expect(jsonObject(approval.data)['estado'], 'activa');
      expect(externalReloads, 0);
      expect(find.text('No hay solicitudes pendientes.'), findsOneWidget);
      expect(
        find.text('Solicitud aceptada. El estudiante ya tiene acceso al aula.'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'la campana abre las solicitudes del tutor y distingue los avisos de texto',
    (t) async {
      state = 'solicitada';
      paid = true;
      service.currentUser = const UsuarioAplicacion(
        id: '2',
        name: 'Daniela Rivas',
        email: 'daniela@example.test',
        university: '',
        roles: ['tutor'],
      );
      await t.runAsync(service.refreshAccountData);
      await open(
        t,
        Scaffold(appBar: AppBar(actions: const [BotonNotificaciones()])),
        1440,
      );
      await t.tap(find.byTooltip('Notificaciones'));
      await t.pumpAndSettle();
      expect(find.text('Aviso general'), findsOneWidget);
      expect(find.text('Ver detalles'), findsNWidgets(2));
      await t.tap(find.text('Ver detalles').last);
      await t.pumpAndSettle();
      expect(find.byType(MensajesView), findsOneWidget);
      expect(
        adapter.requests.any((r) => r.path == '/conversations/10'),
        isTrue,
      );

      Navigator.of(t.element(find.byType(MensajesView))).pop();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Notificaciones'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ver detalles').first);
      await t.pumpAndSettle();
      expect(
        ModalRoute.of(t.element(find.byType(GestionCurso)))?.settings.name,
        RutasAplicacion.courseRequests(id: '9', admin: false),
      );
      await t.ensureVisible(find.text('Aceptar solicitud'));
      await t.tap(find.text('Aceptar solicitud'));
      await t.pumpAndSettle();
      expect(
        find.text('Esperando el pago demo del estudiante'),
        findsOneWidget,
      );
      expect(find.text('Aceptar solicitud'), findsNothing);
      expect(
        find.text('Solicitud aceptada. Queda pendiente el pago de prueba.'),
        findsOneWidget,
      );
      final approval = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(approval.path, '/me/courses/9/enrollments/90');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(milliseconds: 300));
    },
  );

  for (final width in [1440.0, 390.0]) {
    testWidgets(
      'el chat identifica el artículo y muestra su descripción a $width',
      (t) async {
        await open(t, const MensajesView(id: '10'), width);
        expect(find.text('Omeprazol 20 mg'), findsAtLeastNWidgets(1));
        expect(
          find.text(
            'Caja de 10 cápsulas. Artículo de muestra de Farmacia JAE.',
          ),
          findsAtLeastNWidgets(1),
        );
        expect(find.text('administrador'), findsNothing);
        final images = t.widgetList<ImagenAsuntoChat>(
          find.byType(ImagenAsuntoChat),
        );
        expect(
          images.any((image) => image.row?['recursoImagenId'] == '71'),
          isTrue,
        );
        expect(find.byTooltip('Enviar mensaje'), findsOneWidget);
        await t.tap(find.byTooltip('Detalles de la conversación'));
        await t.pumpAndSettle();
        if (width < 1220) {
          expect(find.text('Acerca de esta conversación'), findsOneWidget);
          expect(find.byTooltip('Enviar mensaje'), findsNothing);
          expect(find.text('Saluda y comienza la conversación.'), findsNothing);
          final details = find.byWidgetPredicate(
            (w) => w is VistaPreviaAsuntoChat && w.detailed,
          );
          expect(t.getSize(details).height, greaterThan(300));
        } else {
          expect(find.text('Acerca de esta conversación'), findsNothing);
          expect(find.byTooltip('Enviar mensaje'), findsOneWidget);
        }
        await t.tap(find.byTooltip('Detalles de la conversación'));
        await t.pumpAndSettle();
        expect(find.byTooltip('Enviar mensaje'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
        await t.pump(const Duration(milliseconds: 200));
      },
    );
  }

  testWidgets('la bandeja sin selección no muestra información vacía', (
    t,
  ) async {
    await open(t, const MensajesView(), 1440);
    expect(find.text('Tus conversaciones'), findsOneWidget);
    expect(find.text('Acerca de esta conversación'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    await t.pump(const Duration(milliseconds: 200));
  });
}
