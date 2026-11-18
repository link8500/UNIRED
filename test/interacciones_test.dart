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
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/tutorias/views/tutorias_view.dart';
import 'package:unired/shared/widgets/formulario_resena.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'support/test_adapter.dart';

void main() {
  late AplicacionController store;
  late TestAdapter adapter;
  var state = 'pendiente';
  var demoPayment = false;
  var paymentConfirmed = false;
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
    demoPayment = false;
    paymentConfirmed = false;
    adapter = TestAdapter((r) async {
      if (r.path == '/areas') {
        return TestReply([
          {'id': 1, 'nombre': 'Programación'},
        ]);
      }
      if (r.path == '/courses' && r.queryParameters['q'] == 'Angular') {
        return TestReply(
          page([
            {
              'id': '42',
              'titulo': 'Componentes de Angular',
              'areaNombre': 'Programación',
              'precioBase': '0.00',
            },
          ]),
        );
      }
      if (r.path == '/demo/checkout' && r.method == 'POST') {
        paymentConfirmed = true;
        return TestReply({
          'pago': {'id': '41', 'importe': '180.00'},
          'simulado': true,
        }, status: 201);
      }
      if (r.path == '/me/tutoring-requests') {
        return TestReply(
          page([
            {
              'id': '9',
              'alumnoId': demoPayment ? 1 : 2,
              'tutorId': demoPayment ? 2 : 1,
              'alumnoNombre': 'Sofía Martínez',
              'tema': 'Entender los componentes de Angular',
              'materia': 'Desarrollo web',
              'descripcion':
                  'Necesito organizar los componentes y comunicar sus datos.',
              'duracionMinutos': 60,
              'modalidad': 'online',
              'precio': demoPayment ? '180.00' : '0.00',
              'comision': demoPayment ? '18.00' : '0.00',
              'requierePagoDemo': demoPayment,
              'pagoDemoConfirmado': paymentConfirmed,
              if (paymentConfirmed) 'pagoDemoId': '41',
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
        child: MaterialApp(
          theme: TemaAplicacion.light,
          home: child,
          onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
        ),
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

  testWidgets(
    'la tarjeta de prueba confirma la tutoría y deja un comprobante',
    (t) async {
      demoPayment = true;
      await open(t, const InteraccionesView(tutorials: true), 390);
      expect(find.text('Pago demo pendiente'), findsOneWidget);
      expect(find.text('Finalizar'), findsNothing);
      final pay = find.text('Pagar con tarjeta de prueba');
      await t.ensureVisible(pay);
      await t.tap(pay);
      await t.pumpAndSettle();
      final testCard = find.text('Usar tarjeta de prueba');
      await t.ensureVisible(testCard);
      await t.tap(testCard);
      await t.pumpAndSettle();
      final confirm = find.text('Confirmar pago demo');
      await t.ensureVisible(confirm);
      await t.tap(confirm);
      await t.pumpAndSettle();
      expect(find.text('Comprobante de demostración'), findsOneWidget);
      expect(find.text('Referencia: DEMO-41'), findsOneWidget);
      final payload = jsonObject(
        adapter.requests.singleWhere((r) => r.path == '/demo/checkout').data,
      );
      expect(
        payload.keys,
        unorderedEquals(['concepto', 'recursoId', 'importe', 'clienteId']),
      );
      expect(payload['concepto'], 'tutoria_solicitud');
      expect(payload['recursoId'], '9');
      await t.tap(find.text('Cerrar'));
      await t.pumpAndSettle();
      expect(find.text('Ver comprobante'), findsOneWidget);
      expect(find.text('Finalizar'), findsOneWidget);
    },
  );

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
      'a $width se busca una tutoría publicada sin crear solicitudes',
      (t) async {
        await open(t, const InteraccionesView(tutorials: true), width);
        expect(find.text('Historial de solicitudes'), findsOneWidget);
        await t.tap(find.text('Buscar tutorías'));
        await t.pumpAndSettle();
        expect(find.byType(TutoriasView), findsOneWidget);
        final search = find.widgetWithText(TextField, 'Buscar tutorías');
        await t.enterText(search, 'Angular');
        await t.testTextInput.receiveAction(TextInputAction.search);
        await t.pumpAndSettle();
        expect(find.text('Componentes de Angular'), findsOneWidget);
        expect(
          adapter.requests.where(
            (r) => r.path == '/courses' && r.queryParameters['q'] == 'Angular',
          ),
          hasLength(1),
        );
        expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      },
    );

    testWidgets(
      'reseña a $width requiere elegir estrellas y envía la puntuación',
      (t) async {
        Json? review;
        await open(
          t,
          Scaffold(
            body: FormularioResena(
              title: 'Mi reseña',
              submit: (value) async {
                review = value;
              },
            ),
          ),
          width,
        );
        await t.tap(find.text('Guardar reseña'));
        expect(review, isNull);
        await t.tap(find.byTooltip('4 estrellas'));
        await t.pumpAndSettle();
        expect(find.text('4 de 5 · Muy buena'), findsOneWidget);
        await t.enterText(find.byType(TextFormField), 'Material práctico');
        await t.tap(find.text('Guardar reseña'));
        await t.pumpAndSettle();
        expect(review, {'puntuacion': 4, 'comentario': 'Material práctico'});
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
