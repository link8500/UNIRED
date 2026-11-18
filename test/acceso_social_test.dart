// Prueba el contrato de Flutter sin cuentas externas ni credenciales reales.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/contratos/navegador_social.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/inicio/views/inicio_view.dart';
import 'package:unired/models/administracion/views/panel_view.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/autenticacion/views/retorno_social_view.dart';
import 'package:unired/models/autenticacion/widgets/botones_acceso_social.dart';
import 'package:unired/models/perfil/widgets/seguridad_cuenta.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'support/test_adapter.dart';

class NavegadorPrueba implements NavegadorSocial {
  Json? intento;
  Uri? destino;
  bool retornoLimpio = false;
  @override
  bool get disponible => true;
  @override
  String get origen => 'http://localhost:62604';
  @override
  void guardar(Json valor) => intento = valor;
  @override
  Json? leer() => intento;
  @override
  void limpiar() => intento = null;
  @override
  void redirigir(Uri uri) => destino = uri;
  @override
  void limpiarRetorno() => retornoLimpio = true;
}

// En Chrome, Dio termina sus transformaciones en la cola de eventos del
// navegador. Avanza ambos relojes antes de comprobar la interfaz.
Future<void> flushRequests(WidgetTester t) async {
  for (var i = 0; i < 40; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await t.pump(const Duration(milliseconds: 40));
    if (i >= 3 &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        find.byType(LinearProgressIndicator).evaluate().isEmpty) {
      break;
    }
  }
}

void main() {
  const browserId = '1c2511ff-911b-4acb-9046-7dd3b11034a5';
  late AplicacionController store;
  late NavegadorPrueba browser;
  late TestAdapter adapter;
  Json providers = {}, exchange = {}, account = {}, linked = {};
  List<Json> sessions = [];
  setUp(() {
    sessions = [];
    providers = {'google': true, 'facebook': true};
    exchange = {
      'accessToken': 'jwt-ficticio',
      'refreshToken': 'refresh-ficticio',
      'expiresIn': 900,
    };
    account = {
      'id': 8,
      'nombre': 'Sofía',
      'email': 'social@example.test',
      'estado': 'activo',
      'roles': ['usuario'],
      'tienePassword': false,
      'perfil': {'universidad': 'Universidad', 'carrera': 'Ingeniería'},
    };
    linked = {
      'tienePassword': false,
      'proveedores': providers,
      'identidades': [
        {'proveedor': 'google', 'correo': 'social@example.test'},
      ],
    };
    browser = NavegadorPrueba();
    adapter = TestAdapter((r) async {
      if (r.path == '/auth/social/providers') return TestReply(providers);
      if (r.path.endsWith('/start')) {
        return TestReply({
          'url': 'https://accounts.google.com/o/oauth2/v2/auth?state=ficticio',
        });
      }
      if (['/auth/social/exchange', '/auth/login'].contains(r.path)) {
        return TestReply(exchange);
      }
      if (r.path == '/me') return TestReply(account);
      if (r.path == '/me/social') return TestReply(linked);
      if (r.path == '/me/sessions') return TestReply(sessions);
      if (r.path == '/me/sessions/revoke-others') {
        sessions = sessions
            .where((session) => session['actual'] == true)
            .toList();
        return TestReply({'cerradas': 2});
      }
      return TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 50});
    });
    store = AplicacionController(
      socialBrowser: browser,
      browserId: () => browserId,
      client: ClienteApi(
        enableLiveEvents: false,
        dio: Dio()..httpClientAdapter = adapter,
      ),
    );
    AplicacionController.replaceInstanceForTesting(store);
  });
  tearDown(() => store.dispose());
  Future<void> screen(WidgetTester t, Widget child, double width) async {
    t.view.physicalSize = Size(width, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
        home: child is RetornoSocialView
            ? child
            : Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ),
      ),
    );
    await flushRequests(t);
    await t.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 4),
    );
  }

  test(
    'el inicio envía solo origen y reto; el verificador queda en la pestaña',
    () async {
      await store.iniciarAccesoSocial('google');
      final pending = browser.intento!;
      final body = adapter.requests.single.data as Map;
      final challenge = base64UrlEncode(
        sha256.convert(utf8.encode(pending['verificador'] as String)).bytes,
      ).replaceAll('=', '');
      expect(body, {'origen': browser.origen, 'reto': challenge});
      expect(
        (pending['verificador'] as String).length,
        greaterThanOrEqualTo(43),
      );
      expect(browser.destino?.host, 'accounts.google.com');
      expect(jsonEncode(pending), isNot(contains('jwt')));
      expect(adapter.requests.single.headers['Authorization'], isNull);
    },
  );
  test('el canje establece JWT y elimina el intento temporal', () async {
    await store.iniciarAccesoSocial('google');
    await store.completarAccesoSocial('codigo-efimero');
    expect(store.api.hasSession, true);
    expect(store.currentUser?.email, 'social@example.test');
    expect(store.currentUser?.hasPassword, false);
    expect(browser.intento, isNull);
    final sent = adapter.requests.singleWhere(
      (r) => r.path == '/auth/social/exchange',
    );
    expect((sent.data as Map).containsKey('passwordActual'), false);
    expect((sent.data as Map)['navegadorId'], browserId);
  });
  test(
    'el acceso con contraseña también envía el identificador del navegador',
    () async {
      await store.signIn(email: 'social@example.test', password: 'ficticia');
      final sent = adapter.requests.singleWhere((r) => r.path == '/auth/login');
      expect((sent.data as Map)['navegadorId'], browserId);
      await store.logout();
    },
  );
  test(
    'confirmar una cuenta conserva el intento sin aceptar JWT prematuramente',
    () async {
      exchange = {'requierePassword': true};
      await store.iniciarAccesoSocial('google');
      expect(
        (await store.completarAccesoSocial('codigo'))['requierePassword'],
        true,
      );
      expect(browser.intento, isNotNull);
      expect(store.api.hasSession, false);
      expect(store.currentUser, isNull);
    },
  );
  test('rechaza el intento vencido sin enviar una solicitud', () async {
    browser.guardar({'verificador': 'v', 'creadoEn': 0});
    await expectLater(
      store.completarAccesoSocial('codigo'),
      throwsA(isA<ErrorApi>()),
    );
    expect(adapter.requests, isEmpty);
  });
  testWidgets(
    'Seguridad identifica los dispositivos y conserva la sesión actual al cerrar las demás',
    (t) async {
      sessions = [
        {
          'id': '1',
          'dispositivo': 'Chrome en Windows',
          'actual': true,
          'creadoEn': '2026-11-18T20:00:00Z',
          'expiraEn': '2026-12-18T20:00:00Z',
        },
        {
          'id': '2',
          'dispositivo': 'Safari en iPhone',
          'creadoEn': '2026-11-18T20:00:00Z',
          'expiraEn': '2026-12-18T20:00:00Z',
        },
        {
          'id': '3',
          'creadoEn': '2026-11-17T20:00:00Z',
          'expiraEn': '2026-12-17T20:00:00Z',
        },
      ];
      await screen(t, const SeguridadCuenta(), 390);
      expect(find.text('Chrome en Windows'), findsOneWidget);
      expect(find.textContaining('Sesión actual'), findsOneWidget);
      expect(find.text('Safari en iPhone'), findsOneWidget);
      expect(find.text('Dispositivo no identificado'), findsOneWidget);
      final close = find.text('Cerrar las demás sesiones');
      await t.ensureVisible(close);
      await t.tap(close);
      await t.pumpAndSettle();
      expect(
        adapter.requests.where((r) => r.path.endsWith('revoke-others')),
        isEmpty,
      );
      await t.tap(find.text('Cerrar las demás'));
      await t.pumpAndSettle();
      expect(find.text('Safari en iPhone'), findsNothing);
      expect(find.text('Chrome en Windows'), findsOneWidget);
    },
  );
  test('entrar por el acceso administrativo no eleva los roles', () async {
    await store.iniciarAccesoSocial('google', admin: true);
    await expectLater(
      store.completarAccesoSocial('codigo'),
      throwsA(isA<ErrorApi>()),
    );
    expect(store.currentUser, isNull);
    expect(store.api.hasSession, false);
    expect(adapter.requests.any((r) => r.path == '/auth/logout'), true);
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets('botones y PKCE adaptables a $width', (t) async {
      await screen(t, const BotonesAccesoSocial(), width);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con Facebook'), findsOneWidget);
      await t.tap(find.text('Continuar con Google'));
      await flushRequests(t);
      await t.pumpAndSettle();
      expect(browser.destino, isNotNull);
      expect(t.takeException(), isNull);
    });
    testWidgets(
      'sin configuración explica y deshabilita los botones a $width',
      (t) async {
        providers = {'google': false, 'facebook': false};
        await screen(t, const BotonesAccesoSocial(), width);
        expect(
          t
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Continuar con Google'),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.textContaining('todavía no está habilitado'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
    testWidgets(
      'Seguridad protege el último acceso y permite crear contraseña a $width',
      (t) async {
        store.currentUser = UsuarioAplicacion.fromJson(account);
        await screen(t, const SeguridadCuenta(), width);
        expect(find.text('Cuentas vinculadas'), findsOneWidget);
        expect(find.text('Mis sesiones'), findsOneWidget);
        expect(find.text('Contraseña actual'), findsNothing);
        expect(find.text('Crear una contraseña'), findsOneWidget);
        expect(
          t
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Desvincular'),
              )
              .onPressed,
          isNull,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'el retorno solicita la contraseña de UniRed y la envía solo al confirmar',
    (t) async {
      exchange = {'requierePassword': true};
      await t.runAsync(() => store.iniciarAccesoSocial('google'));
      await screen(t, const RetornoSocialView(code: 'codigo'), 1440);
      expect(browser.retornoLimpio, true);
      expect(find.text('Contraseña de UniRed'), findsOneWidget);
      await t.enterText(find.byType(TextFormField), 'Contraseña-ficticia');
      await t.ensureVisible(find.text('Confirmar y continuar'));
      await t.tap(find.text('Confirmar y continuar'));
      await flushRequests(t);
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 4),
      );
      final sent = adapter.requests
          .where((r) => r.path == '/auth/social/exchange')
          .toList();
      expect((sent.first.data as Map).containsKey('passwordActual'), false);
      expect((sent.last.data as Map)['passwordActual'], 'Contraseña-ficticia');
      expect(browser.intento!.containsKey('passwordActual'), false);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('una cancelación no intenta canjear un código', (t) async {
    browser.guardar({'verificador': 'temporal'});
    await screen(t, const RetornoSocialView(error: 'SOCIAL_CANCELLED'), 390);
    expect(find.textContaining('Cancelaste el acceso'), findsOneWidget);
    expect(browser.intento, isNull);
    expect(adapter.requests, isEmpty);
    expect(t.takeException(), isNull);
  });
  testWidgets('una cuenta nueva llega al inicio', (t) async {
    account['perfil'] = {};
    await t.runAsync(() => store.iniciarAccesoSocial('google'));
    await screen(t, const RetornoSocialView(code: 'codigo'), 390);
    expect(find.byType(InicioView), findsOneWidget);
    expect(t.takeException(), isNull);
    // Cancela la consulta periódica de notificaciones antes del cierre del test.
    await t.runAsync(store.logout);
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'el retorno del equipo abre el resumen administrativo a $width',
      (t) async {
        account['roles'] = ['usuario', 'administrador'];
        await t.runAsync(
          () => store.iniciarAccesoSocial('google', admin: true),
        );
        await screen(t, const RetornoSocialView(code: 'codigo'), width);
        expect(find.byType(PanelView), findsOneWidget);
        expect(
          find.byTooltip('Abrir navegación'),
          width < 960 ? findsOneWidget : findsNothing,
        );
        expect(find.text('Sin cuentas registradas'), findsOneWidget);
        if (width < 960) {
          await t.tap(find.byTooltip('Abrir navegación'));
          await t.pumpAndSettle();
          expect(find.byType(Drawer), findsOneWidget);
        }
        expect(find.text('Mi perfil'), findsOneWidget);
        await t.runAsync(store.logout);
      },
    );
  }
}
