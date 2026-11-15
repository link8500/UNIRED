import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/network/api_client.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/admin/views/conversation_review_page.dart';
import 'package:unired/models/tutorials/widgets/course_classroom.dart';
import 'package:unired/models/tutorials/widgets/lesson_resources_button.dart';
import 'package:unired/shared/themes/app_theme.dart';
import 'support/test_adapter.dart';

void main() {
  late AppService service;
  late TestAdapter adapter;
  final chat = {
    'id': '10',
    'tipo': 'tutoria',
    'consultanteId': '1',
    'propietarioId': '2',
    'consultanteNombre': 'Sofía',
    'propietarioNombre': 'Daniela',
    'recursoTitulo': 'Universidad Angular',
    'mensajes': 1,
  };
  setUp(() {
    adapter = TestAdapter((r) async {
      if (r.path == '/admin/conversations') {
        return TestReply({
          'items': [chat],
          'total': 1,
          'page': 1,
          'limit': 20,
        });
      }
      if (r.path == '/admin/conversations/10') return TestReply(chat);
      if (r.path == '/admin/conversations/10/messages') {
        return TestReply({
          'items': [
            {
              'id': '1',
              'autorId': '1',
              'contenido': '¿Dónde están los apuntes?',
            },
          ],
          'total': 1,
          'page': 1,
          'limit': 50,
        });
      }
      if (r.path.startsWith('/courses/9/lessons/')) {
        return TestReply({
          'id': r.path.split('/').last,
          'titulo': 'Apuntes del curso',
          'tipo': 'texto',
          'contenidoTexto': 'Material de estudio',
          'recursos': [
            {'archivoId': '77', 'titulo': 'Guía de la lección · PDF'},
          ],
        });
      }
      return TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 20});
    });
    service =
        AppService(client: ApiClient(dio: Dio()..httpClientAdapter = adapter))
          ..currentUser = const AppUser(
            id: '3',
            name: 'Administrador',
            email: 'admin@example.test',
            university: '',
            roles: ['administrador'],
          );
    AppService.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());
  Future<void> open(WidgetTester t, Widget child, double width) async {
    t.view.physicalSize = Size(width, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
    await t.pumpAndSettle();
  }

  testWidgets(
    'el menú de recursos consulta una vez y conserva la lección abierta',
    (t) async {
      await open(
        t,
        const Scaffold(
          body: Center(
            child: LessonResourcesButton(courseId: '9', lessonId: '2'),
          ),
        ),
        1100,
      );
      await t.tap(find.text('Recursos'));
      await t.pumpAndSettle();
      expect(find.text('Guía de la lección · PDF'), findsOneWidget);
      expect(
        adapter.requests.where((r) => r.path == '/courses/9/lessons/2').length,
        1,
      );
      await t.tapAt(const Offset(20, 20));
      await t.pumpAndSettle();
      await t.tap(find.text('Recursos'));
      await t.pumpAndSettle();
      expect(find.text('Guía de la lección · PDF'), findsOneWidget);
      expect(
        adapter.requests.where((r) => r.path == '/courses/9/lessons/2').length,
        1,
      );
      expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
      await t.tapAt(const Offset(20, 20));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );

  for (final width in [1440.0, 390.0]) {
    testWidgets('revisión administrativa solo consulta y cabe a $width', (
      t,
    ) async {
      await open(t, const ConversationReviewPage(kind: 'tutoria'), width);
      await t.tap(find.text('Universidad Angular'));
      await t.pumpAndSettle();
      expect(find.text('¿Dónde están los apuntes?'), findsOneWidget);
      expect(
        find.text('Revisión administrativa · solo lectura'),
        findsOneWidget,
      );
      expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
      expect(adapter.requests.where((r) => r.path.endsWith('/read')), isEmpty);
      expect(find.byTooltip('Enviar mensaje'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'el aula permite elegir lección sin salir del espacio a $width',
      (t) async {
        await open(
          t,
          CourseClassroom(
            owner: true,
            course: {
              'id': '9',
              'titulo': 'Universidad Angular',
              'secciones': [
                {
                  'id': '1',
                  'titulo': 'Introducción',
                  'lecciones': [
                    {'id': '1', 'titulo': 'Primera lectura', 'tipo': 'texto'},
                    {'id': '2', 'titulo': 'Segunda lectura', 'tipo': 'texto'},
                  ],
                },
              ],
            },
          ),
          width,
        );
        if (width < 900) {
          await t.tap(find.text('Contenido'));
          await t.pumpAndSettle();
          await t.tap(find.byTooltip('Ocultar contenido del curso'));
          await t.pumpAndSettle();
          expect(
            adapter.requests
                .where((r) => r.path == '/courses/9/lessons/1')
                .length,
            1,
          );
          await t.tap(find.text('Contenido'));
          await t.pumpAndSettle();
        }
        await t.tap(find.text('2. Segunda lectura'));
        await t.pumpAndSettle();
        expect(
          adapter.requests.any((r) => r.path == '/courses/9/lessons/2'),
          isTrue,
        );
        expect(find.text('Material de estudio'), findsOneWidget);
        t.view.physicalSize = Size(width >= 900 ? 842 : 1440, 900);
        await t.pumpAndSettle();
        expect(
          adapter.requests
              .where((r) => r.path == '/courses/9/lessons/2')
              .length,
          1,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
