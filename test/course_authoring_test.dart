import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/network/api_client.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/admin/widgets/publication_editor.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/tutorials/widgets/course_curriculum_editor.dart';
import 'package:unired/models/tutorials/widgets/course_lesson_editor.dart';
import 'package:unired/shared/themes/app_theme.dart';
import 'support/test_adapter.dart';

void main() {
  late AppService service;
  late TestAdapter adapter;
  late Json course;
  setUp(() {
    course = {
      'id': '9',
      'areaId': 1,
      'titulo': 'Angular desde cero',
      'descripcion': 'Un curso con proyectos y ejercicios.',
      'estado': 'borrador',
      'precioBase': '0.00',
      'moneda': 'NIO',
      'nivel': 'inicial',
      'modalidad': 'grabada',
      'versionLock': 1,
      'secciones': <Json>[],
      'lecciones': <Json>[],
      'preparacion': {
        'acreditacionVigente': true,
        'leccionesPublicadas': 0,
        'tieneSesionFutura': false,
      },
    };
    adapter = TestAdapter((r) async {
      if (r.path == '/me/courses' && r.method == 'POST') {
        course = {...course, ...jsonObject(r.data)};
        return TestReply(course, status: 201);
      }
      if (r.path == '/me/courses/9') return TestReply(course);
      if (r.path == '/me/courses/9/sections' && r.method == 'POST') {
        final section = {'id': '31', ...jsonObject(r.data)};
        course['secciones'] = [...jsonRows(course['secciones']), section];
        return TestReply(section, status: 201);
      }
      if (r.path == '/me/courses/9/lessons' && r.method == 'POST') {
        final lesson = {'id': '41', ...jsonObject(r.data)};
        course['lecciones'] = [...jsonRows(course['lecciones']), lesson];
        course['preparacion'] = {
          'acreditacionVigente': true,
          'leccionesPublicadas': 1,
        };
        return TestReply(lesson, status: 201);
      }
      if (r.path.startsWith('/me/courses/9/lessons/')) {
        return TestReply({'id': '41', ...jsonObject(r.data)});
      }
      return TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 20});
    });
    service =
        AppService(client: ApiClient(dio: Dio()..httpClientAdapter = adapter))
          ..currentUser = const AppUser(
            id: '2',
            name: 'Daniela Rivas',
            email: 'daniela@example.test',
            university: '',
            roles: ['usuario'],
          )
          ..areas = [
            {'id': 1, 'nombre': 'Programación'},
          ];
    AppService.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());

  Future<void> open(WidgetTester t, Widget child, double width) async {
    t.view.physicalSize = Size(width, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> click(WidgetTester t, String text) async {
    await t.ensureVisible(find.text(text).last);
    await t.tap(find.text(text).last);
    await t.pumpAndSettle();
  }

  Future<void> type(WidgetTester t, String key, String text) async {
    final field = find.byKey(ValueKey(key));
    await t.ensureVisible(field);
    await t.enterText(field, text);
    await t.pumpAndSettle();
  }

  for (final width in [1440.0, 390.0]) {
    testWidgets(
      'creación guiada, sección y lectura con datos reales a $width',
      (t) async {
        await open(t, const PublicationEditor(isTutorial: true), width);
        await click(t, 'Siguiente');
        expect(find.text('Completa este campo.'), findsAtLeastNWidgets(1));
        expect(
          find.byKey(const ValueKey('publication-objetivos')),
          findsNothing,
        );
        await type(t, 'publication-titulo', 'Angular desde cero');
        await type(
          t,
          'publication-descripcion',
          'Un curso con proyectos y ejercicios.',
        );
        final area = find.byKey(
          const ValueKey('publication-select-Área de enseñanza'),
        );
        await t.ensureVisible(area);
        await t.tap(area);
        await t.pumpAndSettle();
        await t.tap(find.text('Programación').last);
        await t.pumpAndSettle();
        await click(t, 'Siguiente');
        await type(
          t,
          'publication-objetivos',
          'Crear componentes\nConfigurar rutas',
        );
        await type(
          t,
          'publication-dirigidoA',
          'Estudiantes que quieren aprender desarrollo web.',
        );
        await click(t, 'Siguiente');
        expect(find.text('Seleccionar portada del curso'), findsOneWidget);
        await click(t, 'Guardar y crear contenido');
        expect(
          adapter.requests
              .where((r) => r.path == '/me/courses' && r.method == 'POST')
              .length,
          1,
        );
        await click(t, 'Crear primera sección');
        await type(t, 'section-title', 'Introducción y entorno de trabajo');
        await click(t, 'Guardar sección');
        expect(find.text('Introducción y entorno de trabajo'), findsOneWidget);
        await click(t, 'Añadir lección');
        expect(find.text('Seleccionar video'), findsOneWidget);
        await click(t, 'Lectura');
        expect(find.text('Seleccionar video'), findsNothing);
        await type(t, 'lesson-title', 'Preparar las herramientas');
        await type(
          t,
          'lesson-body',
          'Instala las herramientas y crea tu primer proyecto.',
        );
        await click(t, 'Guardar lección');
        expect(find.text('1. Preparar las herramientas'), findsOneWidget);
        expect(find.byType(CourseLessonEditor), findsNothing);
        final request = adapter.requests.singleWhere(
          (r) => r.method == 'POST' && r.path == '/me/courses/9/lessons',
        );
        expect(jsonObject(request.data), containsPair('seccionId', 31));
        expect(jsonObject(request.data), containsPair('vistaPrevia', false));
        expect(jsonObject(request.data), containsPair('publicada', true));
        expect(jsonObject(request.data), containsPair('videoArchivoId', null));
        await t.tap(find.byTooltip('Vista previa'));
        await t.pumpAndSettle();
        expect(
          find.text('Sección 1: Introducción y entorno de trabajo'),
          findsOneWidget,
        );
        expect(find.text('Preparar las herramientas'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'no abre formularios de las 80 lecciones ni pierde archivos existentes',
    (t) async {
      course['secciones'] = [
        {'id': '31', 'titulo': 'Componentes', 'orden': 1},
      ];
      course['lecciones'] = [
        for (var i = 0; i < 80; i++)
          {
            'id': '${41 + i}',
            'seccionId': '31',
            'titulo': 'Tema ${i + 1}',
            'tipo': 'video',
            'videoArchivoId': '71',
            'videoNombre': 'componentes.mp4',
            'orden': i + 1,
            'publicada': true,
            'recursos': [
              {
                'id': '91',
                'archivoId': '81',
                'titulo': 'Apuntes de componentes.pdf',
              },
            ],
          },
      ];
      await open(
        t,
        SingleChildScrollView(
          child: CourseCurriculumEditor(course: course, reload: () {}),
        ),
        1100,
      );
      expect(find.byType(CourseLessonEditor), findsNothing);
      await t.tap(find.byTooltip('Editar lección').first);
      await t.pumpAndSettle();
      expect(find.byType(CourseLessonEditor), findsOneWidget);
      expect(find.text('componentes.mp4'), findsOneWidget);
      expect(find.text('Apuntes de componentes.pdf'), findsOneWidget);
      await click(t, 'Guardar lección');
      final edit = adapter.requests.singleWhere((r) => r.method == 'PUT');
      expect(jsonObject(edit.data), containsPair('videoArchivoId', '71'));
      expect(
        adapter.requests.where(
          (r) => r.method == 'POST' && r.path.endsWith('/resources'),
        ),
        isEmpty,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
