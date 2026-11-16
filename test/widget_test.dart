import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:unired/main.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'support/test_adapter.dart';

void main() {
  late AplicacionController service;
  setUp(() {
    final dio = Dio()
      ..httpClientAdapter = TestAdapter(
        (_) async =>
            TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 50}),
      );
    service = AplicacionController(client: ClienteApi(dio: dio));
    AplicacionController.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());
  for (final required in [false, true]) {
    testWidgets(
      'el registro respeta la verificación configurada por la API: $required',
      (tester) async {
        final adapter = TestAdapter(
          (_) async => TestReply({
            'verificacionEmailRequerida': required,
            'mensaje': 'Cuenta creada.',
          }, status: 201),
        );
        service.dispose();
        service = AplicacionController(
          client: ClienteApi(dio: Dio()..httpClientAdapter = adapter),
        );
        AplicacionController.replaceInstanceForTesting(service);
        await tester.pumpWidget(
          MaterialApp(
            theme: TemaAplicacion.light,
            initialRoute: RutasAplicacion.register,
            navigatorObservers: [NavegadorAplicacion.observer],
            onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Usuario de prueba');
        await tester.enterText(fields.at(1), 'registro@example.test');
        await tester.enterText(fields.at(2), 'Prueba-registro-2026!');
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Crear cuenta'),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Cuenta creada'), findsOneWidget);
        await tester.tap(find.text('Entendido'));
        await tester.pumpAndSettle();
        expect(
          find.text(required ? 'Verifica tu correo' : 'Bienvenido de nuevo'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'seleccionar un usuario carga una sola ficha y conserva su panel',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = TestAdapter(
        (options) async => TestReply(
          options.path == '/admin/users/2'
              ? {
                  'id': 2,
                  'nombre': 'Tutor de prueba',
                  'email': 'tutor@example.test',
                  'roles': ['usuario'],
                  'perfil': {'ciudad': 'Managua'},
                }
              : {
                  'items': [
                    {
                      'id': 2,
                      'nombre': 'Tutor de prueba',
                      'email': 'tutor@example.test',
                      'estado': 'activo',
                      'roles': ['usuario'],
                    },
                  ],
                  'total': 1,
                  'page': 1,
                  'limit': 50,
                },
        ),
      );
      service.dispose();
      service = AplicacionController(
        client: ClienteApi(dio: Dio()..httpClientAdapter = adapter),
      );
      service.currentUser = const UsuarioAplicacion(
        id: '1',
        name: 'Administrador',
        email: 'admin@example.test',
        university: '',
        roles: ['usuario', 'administrador'],
      );
      AplicacionController.replaceInstanceForTesting(service);
      await tester.runAsync(service.loadAdminUsers);
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaAplicacion.light,
          initialRoute: RutasAplicacion.user,
          navigatorObservers: [NavegadorAplicacion.observer],
          onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tutor de prueba'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Datos del usuario'), findsOneWidget);
      expect(find.text('Managua'), findsOneWidget);
      service.setCompactAdminCards(true);
      await tester.pumpAndSettle();
      expect(
        adapter.requests.where((r) => r.path == '/admin/users/2').length,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('la navegación no utiliza animaciones', () {
    final route =
        NavegadorAplicacion.onGenerateRoute(
              const RouteSettings(name: RutasAplicacion.market),
            )
            as PageRoute;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
  });
  testWidgets('el inicio conserva el diseño sin inventar publicaciones', (
    tester,
  ) async {
    await tester.pumpWidget(const AplicacionUniRed());
    await tester.pumpAndSettle();
    expect(find.text('Artículos más populares'), findsOneWidget);
    expect(find.text('Apuntes de cálculo II'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('el panel no se abre para una sesión anónima', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        initialRoute: RutasAplicacion.dashboard,
        navigatorObservers: [NavegadorAplicacion.observer],
        onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Inicia sesión con una cuenta autorizada.'),
      findsOneWidget,
    );
    expect(find.text('Usuarios'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('el acceso no ofrece Google ni credenciales simuladas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        initialRoute: RutasAplicacion.login,
        navigatorObservers: [NavegadorAplicacion.observer],
        onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CORREO ELECTRÓNICO'), findsOneWidget);
    expect(find.text('Recordarme'), findsNothing);
    expect(find.text('Google'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('seleccionar la misma ruta no agrega otra pantalla', (
    tester,
  ) async {
    final observer = _Observer();
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        initialRoute: RutasAplicacion.home,
        navigatorObservers: [NavegadorAplicacion.observer, observer],
        onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    final count = observer.pushes;
    NavegadorAplicacion.go(
      tester.element(find.text('Artículos más populares')),
      RutasAplicacion.home,
    );
    await tester.pumpAndSettle();
    expect(observer.pushes, count);
  });
}

class _Observer extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}
