import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/acreditaciones/views/acreditacion_view.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/market/widgets/contacto_vendedor.dart';
import 'package:unired/models/mensajeria/views/mensajes_view.dart';
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
    service = DraftService(
      ClienteApi(
        enableLiveEvents: false,
        dio: Dio()..httpClientAdapter = adapter,
      ),
    )..currentUser = user;
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
    'la acreditación solicita el área y permite enviar los documentos requeridos',
    (t) async {
      var documents = <Json>[];
      var submitted = false;
      adapter = TestAdapter((r) async {
        switch (r.path) {
          case '/areas':
            return TestReply([
              {
                'id': 1,
                'nombre': 'Matemática',
                'requisitosDocumentales': ['certificado'],
              },
            ]);
          case '/me/tutor-applications':
            if (r.method == 'POST') return TestReply({'id': '5'}, status: 201);
            return TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 50});
          case '/me/tutor-applications/5':
            return TestReply({
              'id': '5',
              'areaId': 1,
              'versionLock': documents.isEmpty ? 1 : 2,
              'estado': submitted ? 'enviada' : 'borrador',
              'documentos': documents,
            });
          case '/me/tutor-applications/5/documents':
            documents = [
              {
                ...jsonObject(r.data),
                'grupoDocumento': 'grupo-prueba',
                'version': 1,
              },
            ];
            return TestReply(documents.single, status: 201);
          case '/me/tutor-applications/5/submit':
            submitted = true;
            return TestReply({'estado': 'enviada'});
          default:
            return TestReply({});
        }
      });
      service.api.dio.httpClientAdapter = adapter;
      t.view.physicalSize = const Size(1100, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          theme: TemaAplicacion.light,
          home: const AcreditacionView(),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Formación y experiencia'), findsNothing);
      await t.tap(find.text('Área'));
      await t.pumpAndSettle();
      await t.tap(find.text('Matemática').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Continuar a documentos'));
      await t.pumpAndSettle();
      expect(adapter.requests.singleWhere((r) => r.method == 'POST').data, {
        'areaId': 1,
      });
      final submit = find.widgetWithText(
        FilledButton,
        'Enviar documentos a revisión',
      );
      expect(t.widget<FilledButton>(submit).onPressed, isNull);
      await t.tap(find.text('Adjuntar'));
      await t.pumpAndSettle();
      expect(documents.single['tipo'], 'certificado');
      await t.tap(submit);
      await t.pumpAndSettle();
      expect(submitted, isTrue);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'abrir el artículo no contacta; enviar el primer mensaje abre el chat',
    (t) async {
      var sent = false;
      adapter = TestAdapter((r) async {
        if (r.path.endsWith('/contact')) {
          return TestReply({'conversacionId': sent ? '7' : null});
        }
        if (r.path.endsWith('/inquiry')) {
          sent = true;
          return TestReply({'conversacionId': '7'}, status: 201);
        }
        return TestReply({});
      });
      service.api.dio.httpClientAdapter = adapter;
      await open(t, const ContactoVendedor(listingId: '4'));
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      await t.enterText(
        find.byType(TextFormField).last,
        'Hola, ¿incluye el cargador?',
      );
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      await t.tap(find.text('Enviar mensaje'));
      await t.pumpAndSettle();
      final request = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect(request.path, '/listings/4/inquiry');
      expect(
        request.data,
        containsPair('contenido', 'Hola, ¿incluye el cargador?'),
      );
      expect(find.byType(MensajesView), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await open(t, const ContactoVendedor(listingId: '4'));
      expect(find.text('Abrir conversación'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
    },
  );
}
