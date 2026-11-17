import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/tutorias/widgets/aula_curso.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'support/test_adapter.dart';

void main() {
  late AplicacionController service;
  setUp(() {
    service = AplicacionController(
      client: ClienteApi(
        enableLiveEvents: false,
        dio: Dio()
          ..httpClientAdapter = TestAdapter((r) async {
            if (r.path == '/courses/9/lessons/1') {
              return TestReply({
                'id': '1',
                'titulo': 'Lección de prueba',
                'tipo': 'texto',
                'contenidoTexto': List.filled(
                  60,
                  'Apuntes del curso para practicar lo aprendido.',
                ).join('\n'),
                'recursos': [
                  {'archivoId': '10', 'titulo': 'Apuntes descargables'},
                ],
              });
            }
            return TestReply({'items': [], 'page': 1, 'limit': 20, 'total': 0});
          }),
      ),
    );
    AplicacionController.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());

  for (final size in [
    const Size(1530, 668),
    const Size(1100, 500),
    const Size(390, 700),
  ]) {
    testWidgets(
      'la rueda permite llegar a los recursos y el temario es independiente $size',
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          MaterialApp(
            theme: TemaAplicacion.light,
            home: AulaCurso(
              owner: true,
              course: {
                'id': '9',
                'titulo': 'Universidad Angular',
                'secciones': [
                  {
                    'id': '1',
                    'titulo': 'Introducción',
                    'lecciones': [
                      for (var i = 1; i <= 45; i++)
                        {'id': '$i', 'titulo': 'Lección $i', 'tipo': 'texto'},
                    ],
                  },
                ],
              },
            ),
          ),
        );
        await t.pumpAndSettle();
        final bars = t
            .widgetList<Scrollbar>(find.byType(Scrollbar, skipOffstage: false))
            .toList();
        expect(bars.every((bar) => bar.thumbVisibility == true), isTrue);
        final main = bars.first.controller!;
        final mainBounds = t.getRect(find.byType(Scrollbar).first);
        expect(mainBounds.right, size.width);
        expect(find.text('Apuntes descargables').hitTestable(), findsNothing);
        for (var i = 0; i < 3; i++) {
          await t.sendEventToBinding(
            PointerScrollEvent(
              position: mainBounds.center,
              scrollDelta: const Offset(0, 1200),
            ),
          );
          await t.pumpAndSettle();
        }
        expect(main.offset, greaterThan(0));
        expect(find.text('Apuntes descargables').hitTestable(), findsOneWidget);
        if (size.width >= 900) {
          final outline = bars.last.controller!;
          expect(outline.offset, 0);
          expect(find.text('Universidad Angular').hitTestable(), findsNothing);
          expect(
            find.text('Contenido del curso').hitTestable(),
            findsOneWidget,
          );
          final mainOffset = main.offset;
          final listBounds = t.getRect(find.byType(ListView));
          await t.sendEventToBinding(
            PointerScrollEvent(
              position: listBounds.center,
              scrollDelta: const Offset(0, 10000),
            ),
          );
          await t.pumpAndSettle();
          expect(outline.offset, greaterThan(0));
          expect(main.offset, mainOffset);
          expect(find.text('45. Lección 45').hitTestable(), findsOneWidget);
        }
        expect(t.takeException(), isNull);
      },
    );
  }
}
