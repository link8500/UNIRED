import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/comunidad/views/busqueda_view.dart';
import 'package:unired/models/interacciones/views/interacciones_view.dart';
import 'package:unired/models/interacciones/widgets/solicitar_tutoria.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'support/test_adapter.dart';

void main() {
  late AplicacionController store;
  late TestAdapter adapter;
  var state = 'pendiente';
  Json page(List<Json> rows) => {
    'items': rows,
    'total': rows.length,
    'page': 1,
    'limit': 20,
  };
  setUpAll(() async {
    if (Platform.environment['UNIRED_PREVIEW_DIR'] != null) {
      await (FontLoader('Arial')..addFont(
            File(
              'C:/Windows/Fonts/arial.ttf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  setUp(() {
    state = 'pendiente';
    adapter = TestAdapter((r) async {
      if (r.path == '/areas') {
        return TestReply([
          {'id': 1, 'nombre': 'Programación'},
        ]);
      }
      if (r.path == '/tutorial-quote') {
        return TestReply({'total': '180.00', 'comision': '18.00'}, status: 201);
      }
      if (r.path == '/me/tutoring-requests' && r.method == 'POST') {
        return TestReply({'id': '9', 'estado': 'publicada'}, status: 201);
      }
      if (r.path == '/me/tutoring-requests') {
        return TestReply(
          page([
            {
              'id': '9',
              'alumnoId': 2,
              'tutorId': 1,
              'alumnoNombre': 'Sofía Martínez',
              'tema': 'Entender los componentes de Angular',
              'materia': 'Desarrollo web',
              'descripcion':
                  'Necesito organizar los componentes y comunicar sus datos.',
              'duracionMinutos': 60,
              'modalidad': 'online',
              'precio': '180.00',
              'comision': '18.00',
              'estado': 'aceptada',
              'conversacionId': '8',
              'areaId': 1,
            },
          ]),
        );
      }
      if (r.path == '/me/offers/7' && r.method == 'PATCH') {
        state = textValue(jsonObject(r.data)['estado']);
        return TestReply({'id': '7', 'estado': state});
      }
      if (r.path == '/me/offers') {
        return TestReply(
          page([
            {
              'id': '7',
              'vendedorId': 1,
              'compradorId': 2,
              'compradorNombre': 'Sofía Martínez',
              'anuncioTitulo': 'Atlas de anatomía para estudiantes',
              'tipo': 'compra',
              'importe': '450.00',
              'moneda': 'NIO',
              'mensaje':
                  'Me interesa para mis clases. ¿Podemos acordar la entrega?',
              'estado': state,
              if (state == 'aceptada') 'conversacionId': '8',
            },
          ]),
        );
      }
      if (r.path == '/search') {
        return TestReply({'courses': page([]), 'listings': page([])});
      }
      return TestReply(page([]));
    });
    store =
        AplicacionController(
            client: ClienteApi(
              enableLiveEvents: false,
              retryDelay: Duration.zero,
              dio: Dio()..httpClientAdapter = adapter,
            ),
          )
          ..currentUser = const UsuarioAplicacion(
            id: '1',
            name: 'Daniela Rivas',
            email: 'daniela@example.test',
            university: 'UNAN',
            roles: ['usuario', 'administrador'],
          );
    AplicacionController.replaceInstanceForTesting(store);
  });
  tearDown(() => store.dispose());
  Future<GlobalKey> open(WidgetTester t, Widget child, double width) async {
    t.view.physicalSize = Size(width, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(theme: TemaAplicacion.light, home: child),
      ),
    );
    await t.pumpAndSettle();
    return key;
  }

  Future<void> preview(WidgetTester t, GlobalKey key, String name) async {
    final directory = Platform.environment['UNIRED_PREVIEW_DIR'];
    if (directory == null) return;
    await t.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      image.dispose();
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes.buffer.asUint8List());
    });
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'oferta a $width: aceptación abre el chat y el cierre permite valorar',
      (t) async {
        final key = await open(t, const InteraccionesView(), width);
        expect(find.text('En espera'), findsOneWidget);
        expect(find.text('Abrir chat'), findsNothing);
        await preview(t, key, 'ofertas-$width');
        await t.ensureVisible(find.text('Aceptar oferta'));
        await t.tap(find.text('Aceptar oferta'));
        await t.pumpAndSettle();
        expect(find.text('En curso'), findsOneWidget);
        expect(find.text('Abrir chat'), findsOneWidget);
        await t.ensureVisible(find.text('Finalizar'));
        await t.tap(find.text('Finalizar'));
        await t.pumpAndSettle();
        expect(state, 'aceptada');
        await t.tap(find.text('Confirmar'));
        await t.pumpAndSettle();
        expect(state, 'finalizada');
        expect(find.text('Abrir chat'), findsNothing);
        expect(find.text('Valorar experiencia'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
    testWidgets(
      'solicitud a $width: conserva datos al editar y solo publica tras confirmar',
      (t) async {
        var completed = 0;
        final key = await open(
          t,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SolicitarTutoria(finished: () => completed++),
            ),
          ),
          width,
        );
        await t.tap(find.text('Área de enseñanza'));
        await t.pumpAndSettle();
        await t.tap(find.text('Programación').last);
        await t.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await t.enterText(fields.at(0), 'Desarrollo web');
        await t.enterText(fields.at(1), 'Entender los componentes de Angular');
        await t.enterText(
          fields.at(2),
          'Necesito organizar los componentes y comunicar sus datos.',
        );
        await t.ensureVisible(find.text('Revisar cotización'));
        await t.tap(find.text('Revisar cotización'));
        await t.pumpAndSettle();
        expect(find.text('Cotización: C\$ 180.00'), findsOneWidget);
        expect(
          adapter.requests.where(
            (r) => r.path == '/me/tutoring-requests' && r.method == 'POST',
          ),
          isEmpty,
        );
        await preview(t, key, 'solicitud-confirmacion-$width');
        await t.ensureVisible(find.text('Editar solicitud'));
        await t.tap(find.text('Editar solicitud'));
        await t.pumpAndSettle();
        expect(
          t
              .widget<TextFormField>(find.byType(TextFormField).at(1))
              .controller!
              .text,
          'Entender los componentes de Angular',
        );
        await t.ensureVisible(find.text('Revisar cotización'));
        await t.tap(find.text('Revisar cotización'));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Publicar solicitud'));
        await t.tap(find.text('Publicar solicitud'));
        await t.pumpAndSettle();
        expect(completed, 1);
        expect(
          adapter.requests
              .singleWhere(
                (r) => r.path == '/me/tutoring-requests' && r.method == 'POST',
              )
              .data,
          containsPair('precioConfirmado', '180.00'),
        );
        expect(t.takeException(), isNull);
      },
    );
    testWidgets(
      'tutoría a $width: compartir material explica cómo preparar un curso',
      (t) async {
        await open(t, const InteraccionesView(tutorials: true), width);
        expect(find.text('Abrir chat'), findsOneWidget);
        await t.ensureVisible(find.text('Compartir material'));
        await t.tap(find.text('Compartir material'));
        await t.pumpAndSettle();
        expect(find.text('Preparar un curso'), findsOneWidget);
        expect(find.text('Compartir curso'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );
    testWidgets('búsqueda a $width: filtros académicos se envían al buscar', (
      t,
    ) async {
      await open(t, const BusquedaView(), width);
      await t.enterText(find.byType(TextField).first, 'anatomía');
      await t.tap(find.text('Filtros académicos'));
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, 'Universidad'), 'UNAN');
      await t.enterText(find.widgetWithText(TextField, 'Carrera'), 'Medicina');
      await t.ensureVisible(find.text('Aplicar filtros'));
      await t.tap(find.text('Aplicar filtros'));
      await t.pumpAndSettle();
      expect(
        adapter.requests.last.queryParameters,
        containsPair('universidad', 'UNAN'),
      );
      expect(
        adapter.requests.last.queryParameters,
        containsPair('carrera', 'Medicina'),
      );
      expect(
        adapter.requests.last.queryParameters,
        containsPair('q', 'anatomía'),
      );
      expect(find.textContaining('No hay coincidencias'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
