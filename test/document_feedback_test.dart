import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/market/widgets/contacto_vendedor.dart';
import 'package:unired/models/perfil/widgets/editor_perfil.dart';
import 'package:unired/models/perfil/widgets/tarjeta_identidad_perfil.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'support/test_adapter.dart';

class DraftService extends AplicacionController {
  DraftService(ClienteApi client) : super(client: client);
  @override
  Future<Json?> pickAndUpload(
    String purpose, {
    void Function(int, int)? progress,
    bool demonstrationVideo = false,
    Future<Uint8List?> Function(Uint8List)? editImage,
  }) async => {'id': purpose == 'avatar' ? '90' : '91'};
}

void main() {
  late AplicacionController service;
  late TestAdapter adapter;
  const user = UsuarioAplicacion(
    id: '1',
    name: 'Sofía Martínez',
    email: 'sofia@example.test',
    university: 'Universidad de muestra',
    roles: ['usuario'],
  );
  setUp(() {
    adapter = TestAdapter((_) async => TestReply({}));
    service = DraftService(ClienteApi(dio: Dio()..httpClientAdapter = adapter))
      ..currentUser = user;
    AplicacionController.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());

  Future<void> open(WidgetTester t, Widget child) async {
    t.view.physicalSize = const Size(1100, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'el avatar y la portada se previsualizan y solo se vinculan al guardar',
    (t) async {
      adapter = TestAdapter((r) async {
        if (r.path == '/me' && r.method == 'PATCH') {
          return TestReply({
            'id': 1,
            'nombre': 'Sofía Martínez',
            'email': user.email,
            'estado': 'activo',
            'roles': ['usuario'],
            'perfil': jsonObject(r.data),
          });
        }
        return TestReply({});
      });
      service.api.dio.httpClientAdapter = adapter;
      var saved = 0;
      await open(t, EditorPerfil(user: user, onSaved: () => saved++));
      await t.tap(find.byTooltip('Cambiar avatar'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cambiar portada'));
      await t.pumpAndSettle();
      final preview = t.widget<TarjetaIdentidadPerfil>(
        find.byType(TarjetaIdentidadPerfil),
      );
      expect(preview.avatarPreviewId, '90');
      expect(preview.coverPreviewId, '91');
      expect(service.currentUser?.avatarId, isNull);
      expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
      await t.ensureVisible(find.text('Guardar perfil'));
      await t.tap(find.text('Guardar perfil'));
      await t.pumpAndSettle();
      final save = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(save.data, containsPair('avatarArchivoId', '90'));
      expect(save.data, containsPair('bannerArchivoId', '91'));
      expect(service.currentUser?.avatarId, '90');
      expect(saved, 1);
    },
  );

  testWidgets(
    'descartar restaura el formulario y las imágenes sin cambiar el perfil',
    (t) async {
      await open(t, EditorPerfil(user: user, onSaved: () {}));
      await t.tap(find.byTooltip('Cambiar avatar'));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('profile-nombre')),
        'Nombre pendiente',
      );
      await t.ensureVisible(find.text('Descartar cambios'));
      await t.tap(find.text('Descartar cambios'));
      await t.pumpAndSettle();
      final preview = t.widget<TarjetaIdentidadPerfil>(
        find.byType(TarjetaIdentidadPerfil),
      );
      expect(preview.avatarPreviewId, isNull);
      expect(
        t
            .widget<TextFormField>(find.byKey(const ValueKey('profile-nombre')))
            .controller
            ?.text,
        user.name,
      );
      expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
      expect(service.currentUser?.name, user.name);
    },
  );

  testWidgets(
    'abrir el artículo no contacta; Enviar usa el texto confirmado una sola vez',
    (t) async {
      var sent = false;
      adapter = TestAdapter((r) async {
        if (r.path.endsWith('/contact')) {
          return TestReply({
            'conversacionId': sent ? '8' : null,
            'mensajeEnviado': sent,
          });
        }
        if (r.path.endsWith('/inquiry')) {
          sent = true;
          return TestReply({'conversacionId': '8', 'mensajeEnviado': true});
        }
        return TestReply({});
      });
      service.api.dio.httpClientAdapter = adapter;
      await open(t, const ContactoVendedor(listingId: '4'));
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      await t.enterText(find.byType(TextField), 'Hola, ¿incluye el cargador?');
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      await t.tap(find.text('Enviar consulta'));
      await t.pumpAndSettle();
      final request = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect(request.path, '/listings/4/inquiry');
      expect(
        request.data,
        containsPair('contenido', 'Hola, ¿incluye el cargador?'),
      );
      expect(find.text('Ir a la conversación'), findsOneWidget);
      expect(find.text('Enviar consulta'), findsNothing);
      await t.pumpWidget(const SizedBox());
      await open(t, const ContactoVendedor(listingId: '4'));
      expect(find.text('Ir a la conversación'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
    },
  );
}
