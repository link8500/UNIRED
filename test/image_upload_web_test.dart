import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/network/api_client.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/shared/themes/app_theme.dart';
import 'package:unired/shared/widgets/publication_image_editor.dart';
import 'support/test_adapter.dart';

/// Ejecutable en VM y Chrome. --web añade NestJS y PostgreSQL reales con
/// credenciales efímeras. La red real usa runAsync, fuera del reloj simulado.
void main() {
  const live = bool.fromEnvironment('UNIRED_LIVE_UPLOAD');
  late AppService service;
  late TestAdapter adapter;
  late Uint8List photo;
  Future<Uint8List?>? editing;
  setUp(() async {
    editing = null;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 800, 400),
      Paint()..color = Colors.blue,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(800, 400);
    photo = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
    adapter = TestAdapter(
      (_) async => TestReply({
        'id': '31',
        'estado': 'listo',
        'escaneo': 'limpio',
      }, status: 201),
    );
    service =
        AppService(client: ApiClient(dio: Dio()..httpClientAdapter = adapter))
          ..currentUser = const AppUser(
            id: '1',
            name: 'Prueba',
            email: 'test@example.test',
            university: '',
            roles: ['usuario'],
          );
    AppService.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());

  Future<void> open(WidgetTester t, {bool realApi = false}) async {
    t.view.physicalSize = const Size(1000, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    if (realApi) {
      service.dispose();
      service = AppService(
        client: ApiClient(baseUrl: const String.fromEnvironment('baseUrl')),
      );
      AppService.replaceInstanceForTesting(service);
      await t.runAsync(
        () => service.signInAdmin(
          username: const String.fromEnvironment('adminEmail'),
          password: const String.fromEnvironment('adminPassword'),
        ),
      );
    }
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                editing = editPublicationImage(context, photo);
              },
              child: const Text('Subir fotografía'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Subir fotografía'));
    for (
      var i = 0;
      i < 100 && find.text('Ajustar fotografía').evaluate().isEmpty;
      i++
    ) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pumpAndSettle();
    expect(find.text('Ajustar fotografía'), findsOneWidget);
  }

  Future<Json> exportAndUpload(WidgetTester t) async {
    await t.tap(find.text('Usar este encuadre'));
    for (
      var i = 0;
      i < 100 && find.text('Ajustar fotografía').evaluate().isNotEmpty;
      i++
    ) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pumpAndSettle();
    final png = await editing!;
    expect(png, isNotNull);
    final result = await t.runAsync(() async {
      final file = await service.uploadPublicationImage('imagen_anuncio', png!);
      expect(file['estado'], 'listo');
      expect(file['escaneo'], 'limpio');
      return file;
    });
    await t.pumpAndSettle();
    return result!;
  }

  testWidgets(
    'web: ajustar, exportar y enviar el PNG al servicio de archivos',
    (t) async {
      await open(t);
      await t.tap(find.byTooltip('Girar 90°'));
      await t.pumpAndSettle();
      await exportAndUpload(t);
      final data = adapter.requests.single.data as FormData;
      expect(data.fields.single.key, 'proposito');
      expect(data.fields.single.value, 'imagen_anuncio');
      expect(data.files.single.value.filename, 'publicacion.png');
      expect(data.files.single.value.length, greaterThan(0));
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('cancelar el editor no sube archivos', (t) async {
    await open(t);
    await t.tap(find.byTooltip('Cancelar edición'));
    await t.pumpAndSettle();
    expect(await editing, isNull);
    expect(adapter.requests, isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Chrome + NestJS + PostgreSQL: PNG ajustado, escaneado y vinculado',
    (t) async {
      await open(t, realApi: true);
      final file = await exportAndUpload(t);
      await t.runAsync(() async {
        final categories = jsonRows(
          await service.api.request(
            '/categories',
            authenticated: false,
            foreground: false,
          ),
        );
        final listing = await service.api.object(
          '/me/listings',
          method: 'POST',
          data: {
            'titulo': 'Prueba de imagen desde Chrome',
            'descripcion':
                'Fotografía ajustada y enviada desde el navegador de pruebas.',
            'categoriaId': intValue(categories.first['id']),
            'tipoPrecio': 'fijo',
            'precioBase': '100.00',
            'moneda': 'NIO',
          },
        );
        final id = textValue(listing['id']);
        await service.api.object(
          '/me/listings/$id/images',
          method: 'POST',
          data: {'archivoId': file['id'], 'orden': 1},
        );
        final fetched = await service.api.object('/me/listings/$id');
        expect(
          jsonRows(
            fetched['imagenes'],
          ).any((i) => textValue(i['archivoId']) == textValue(file['id'])),
          isTrue,
        );
        final content = await service.imageBytes(
          textValue(file['id']),
          thumbnail: false,
        );
        expect(content.length, greaterThan(8));
      });
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
    skip: !live,
  );
}
