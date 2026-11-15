import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/network/api_client.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/messaging/views/messages_page.dart';
import 'package:unired/models/messaging/widgets/conversation_subject.dart';
import 'package:unired/models/tutorials/views/course_page.dart';
import 'package:unired/models/tutorials/widgets/course_management.dart';
import 'package:unired/shared/themes/app_theme.dart';
import 'support/test_adapter.dart';

void main() {
  late AppService service;
  late TestAdapter adapter;
  String? state;
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
    adapter = TestAdapter((r) async {
      if (r.responseType == ResponseType.bytes) {
        return TestReply(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
          ),
        );
      }
      if (r.path == '/courses/9') return TestReply(course);
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
                'completadas': 0,
              },
          ],
          'total': state == 'solicitada' ? 1 : 0,
          'page': 1,
          'limit': 20,
        });
      }
      if (r.path == '/me/courses/9/enrollments/90') {
        state = textValue(jsonObject(r.data)['estado']);
        return TestReply({'id': '90', 'estado': state});
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
        AppService(client: ApiClient(dio: Dio()..httpClientAdapter = adapter))
          ..currentUser = const AppUser(
            id: '3',
            name: 'Sofía Martínez',
            email: 'sofia@example.test',
            university: '',
            roles: ['usuario'],
          );
    AppService.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());

  Future<void> open(WidgetTester t, Widget child, double width) async {
    t.view.physicalSize = Size(width, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
    await t.pumpAndSettle();
  }

  testWidgets(
    'una tutoría gratuita requiere solicitud y la aceptación habilita el aula',
    (t) async {
      await open(t, const CoursePage(id: '9'), 1100);
      await t.tap(find.text('Solicitar acceso'));
      await t.pumpAndSettle();
      expect(find.text('Solicitud enviada'), findsOneWidget);
      expect(find.text('Abrir aula'), findsNothing);
      expect(find.text('Conversar con el tutor'), findsOneWidget);
      state = 'activa';
      await t.pump(const Duration(seconds: 8));
      await t.pumpAndSettle();
      expect(find.text('Abrir aula'), findsOneWidget);
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
            child: CourseManagement(
              course: course,
              reload: () => externalReloads++,
              initialTab: CourseManagementTab.students,
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
      if (find.text('Entendido').evaluate().isNotEmpty) {
        await t.tap(find.text('Entendido'));
        await t.pumpAndSettle();
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  for (final width in [1440.0, 390.0]) {
    testWidgets(
      'el chat identifica el artículo y muestra su descripción a $width',
      (t) async {
        await open(t, const MessagesPage(id: '10'), width);
        expect(find.text('Omeprazol 20 mg'), findsAtLeastNWidgets(1));
        expect(
          find.text(
            'Caja de 10 cápsulas. Artículo de muestra de Farmacia JAE.',
          ),
          findsAtLeastNWidgets(1),
        );
        expect(find.text('administrador'), findsNothing);
        final images = t.widgetList<ChatSubjectImage>(
          find.byType(ChatSubjectImage),
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
            (w) => w is ChatSubjectPreview && w.detailed,
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
    await open(t, const MessagesPage(), 1440);
    expect(find.text('Tus conversaciones'), findsOneWidget);
    expect(find.text('Acerca de esta conversación'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    await t.pump(const Duration(milliseconds: 200));
  });
}
