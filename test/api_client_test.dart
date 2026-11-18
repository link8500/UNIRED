import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/core/constantes/limites_archivos.dart';
import 'package:unired/shared/controllers/progreso_navegacion_controller.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'support/test_adapter.dart';

ClienteApi client(TestAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ClienteApi(
    enableLiveEvents: false,
    dio: dio,
    baseUrl: 'http://127.0.0.1:3000/api/v1',
    progreso: ProgresoNavegacionController.instance,
    retryDelay: Duration.zero,
  );
}

Json page() => {'items': <Object>[], 'total': 0, 'page': 1, 'limit': 50};

void main() {
  test(
    'una consulta se recupera de un arranque temporal sin recargar',
    () async {
      var calls = 0;
      final recovering = TestAdapter((_) async {
        if (++calls == 1) {
          return TestReply({'message': 'Starting'}, status: 503);
        }
        return TestReply({'id': 1});
      });
      expect((await client(recovering).object('/courses'))['id'], 1);
      expect(recovering.requests.length, 2);
    },
  );
  test(
    'un error transitorio no repite una publicación ni un multipart',
    () async {
      for (final data in [
        <String, Object>{'titulo': 'Libro'},
        FormData.fromMap({'proposito': 'avatar'}),
      ]) {
        final adapter = TestAdapter(
          (_) async => TestReply({'message': 'Starting'}, status: 503),
        );
        await expectLater(
          client(adapter).request('/files', method: 'POST', data: data),
          throwsA(isA<ErrorApi>()),
        );
        expect(adapter.requests.length, 1);
      }
    },
  );
  test('los errores de validación y permisos no se reintentan', () async {
    for (final status in [400, 403, 404, 409, 422, 429]) {
      final adapter = TestAdapter(
        (_) async => TestReply({'message': 'Rechazado'}, status: status),
      );
      await expectLater(
        client(adapter).object('/courses'),
        throwsA(isA<ErrorApi>()),
      );
      expect(adapter.requests.length, 1);
    }
  });
  test(
    'una API que continúa caída termina el reintento y conserva el error',
    () async {
      final adapter = TestAdapter(
        (_) async => TestReply({'message': 'No disponible'}, status: 503),
      );
      await expectLater(
        client(adapter).object('/courses'),
        throwsA(
          isA<ErrorApi>().having((e) => e.message, 'message', 'No disponible'),
        ),
      );
      expect(adapter.requests.length, 2);
    },
  );
  test('los límites evitan videos enormes en el multipart del navegador', () {
    expect(
      LimitesArchivos.forSelection('video_leccion', 'video.mp4', web: true),
      128 * 1048576,
    );
    expect(
      LimitesArchivos.forSelection('video_leccion', 'video.mp4', web: false),
      1073741824,
    );
    expect(
      LimitesArchivos.forSelection('evidencia_tutor', 'documento.PDF'),
      20 * 1048576,
    );
    expect(LimitesArchivos.forSelection('avatar', 'foto.png'), 10 * 1048576);
  });
  test(
    'una respuesta anterior al cierre de sesión no entra en otra cuenta',
    () async {
      final response = Completer<TestReply>();
      final api = client(TestAdapter((_) => response.future))
        ..acceptTokens({
          'accessToken': 'primera',
          'refreshToken': 'primera',
          'expiresIn': 900,
        });
      final request = api.object('/me');
      final rejected = expectLater(
        request,
        throwsA(isA<ErrorApi>().having((e) => e.status, 'status', 401)),
      );
      await Future<void>.delayed(Duration.zero);
      api.clearSession();
      api.acceptTokens({
        'accessToken': 'segunda',
        'refreshToken': 'segunda',
        'expiresIn': 900,
      });
      response.complete(TestReply({'nombre': 'Cuenta anterior'}));
      await rejected;
      expect(api.hasSession, isTrue);
    },
  );
  test(
    'la barra cubre una acción de varias consultas sin reiniciarse',
    () async {
      final gate = Completer<void>(), middle = Completer<void>();
      final api = client(TestAdapter((_) async => TestReply({})));
      final action = api.withProgress(() async {
        await api.object('/first');
        middle.complete();
        await gate.future;
        await api.object('/second');
      });
      await middle.future;
      expect(ProgresoNavegacionController.instance.value < 1, isTrue);
      gate.complete();
      await action;
      expect(ProgresoNavegacionController.instance.value, 1);
    },
  );
  test('actualizar el catálogo conserva la búsqueda y la categoría', () async {
    final adapter = TestAdapter(
      (options) async => TestReply(
        ['/categories', '/areas'].contains(options.path) ? <Object>[] : page(),
      ),
    );
    final service = AplicacionController(client: client(adapter));
    await service.initialize();
    await service.searchMarket(query: {'q': 'cuaderno', 'categoriaId': 1});
    await service.initialize(force: true);
    final request = adapter.requests.where((o) => o.path == '/listings').last;
    expect(request.queryParameters['q'], 'cuaderno');
    expect(request.queryParameters['categoriaId'], 1);
    service.dispose();
  });
  test(
    'HTTP utiliza el prefijo de la API y el JWT únicamente en el header',
    () async {
      final adapter = TestAdapter((options) async => TestReply({'id': 1}));
      final api = client(adapter)
        ..acceptTokens({
          'accessToken': 'access-test',
          'refreshToken': 'refresh-test',
          'expiresIn': 900,
        });
      await api.object('/me');
      expect(adapter.requests.single.uri.path, '/api/v1/me');
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer access-test',
      );
      expect(
        adapter.requests.single.uri.query.contains('access-test'),
        isFalse,
      );
    },
  );
  test('dos 401 concurrentes comparten una sola renovación', () async {
    int renewals = 0;
    final adapter = TestAdapter((options) async {
      if (options.path == '/auth/refresh') {
        renewals++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return TestReply({
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
          'expiresIn': 900,
        });
      }
      if (options.headers['Authorization'] == 'Bearer old-access') {
        return TestReply({'message': 'Token vencido'}, status: 401);
      }
      return TestReply({'id': 1});
    });
    final api = client(adapter)
      ..acceptTokens({
        'accessToken': 'old-access',
        'refreshToken': 'old-refresh',
        'expiresIn': 900,
      });
    await Future.wait([api.object('/me'), api.object('/me')]);
    expect(renewals, 1);
    expect(
      adapter.requests
          .where((r) => r.path == '/me')
          .last
          .headers['Authorization'],
      'Bearer new-access',
    );
  });
  test(
    'renovación revocada elimina la sesión y no entra en un bucle',
    () async {
      var expired = false;
      final adapter = TestAdapter(
        (_) async => TestReply({'message': 'Sesión revocada'}, status: 401),
      );
      final api = client(adapter)
        ..acceptTokens({
          'accessToken': 'test',
          'refreshToken': 'test',
          'expiresIn': 900,
        })
        ..onSessionExpired = () => expired = true;
      await expectLater(api.object('/me'), throwsA(isA<ErrorApi>()));
      expect(api.hasSession, isFalse);
      expect(expired, isTrue);
      expect(adapter.requests.length, 2);
    },
  );
  test('un 409 conserva el error y no repite la mutación', () async {
    final adapter = TestAdapter(
      (_) async => TestReply({
        'message': 'La publicación cambió',
        'code': 'CONFLICT',
      }, status: 409),
    );
    final api = client(adapter);
    await expectLater(
      api.object('/me/listings/1', method: 'PATCH', data: {'versionLock': 1}),
      throwsA(isA<ErrorApi>().having((e) => e.status, 'status', 409)),
    );
    expect(adapter.requests.length, 1);
  });
  test(
    'los endpoints que devuelven arrays también se pueden paginar',
    () async {
      final api = client(
        TestAdapter(
          (_) async => TestReply([
            {'id': 'sesion'},
          ]),
        ),
      );
      final result = await api.page('/me/sessions');
      expect(result.total, 1);
      expect(result.items.single['id'], 'sesion');
      expect(result.hasMore, isFalse);
    },
  );
  test('un catálogo vacío no se sustituye por datos de demostración', () async {
    final api = client(
      TestAdapter(
        (options) async => TestReply(
          ['/categories', '/areas'].contains(options.path)
              ? <Object>[]
              : page(),
        ),
      ),
    );
    final service = AplicacionController(client: api);
    await service.initialize();
    expect(service.initialized, isTrue);
    expect(service.products, isEmpty);
    expect(service.tutorials, isEmpty);
    service.dispose();
  });
  test('una API caída muestra error sin inventar productos', () async {
    final service = AplicacionController(
      client: client(
        TestAdapter(
          (_) async =>
              TestReply({'message': 'Servidor no disponible'}, status: 503),
        ),
      ),
    );
    await service.initialize();
    expect(service.initialized, isFalse);
    expect(service.lastError, 'Servidor no disponible');
    expect(service.publishedProducts, isEmpty);
    service.dispose();
  });
  test(
    'el catálogo público y la carga secundaria no bloquean el inicio de sesión',
    () async {
      final catalogStarted = Completer<void>();
      final catalog = Completer<TestReply>();
      final privateData = Completer<TestReply>();
      final finished = Completer<void>();
      final adapter = TestAdapter((request) async {
        switch (request.path) {
          case '/listings':
            if (!catalogStarted.isCompleted) catalogStarted.complete();
            return catalog.future;
          case '/auth/login':
            return TestReply({
              'accessToken': 'access',
              'refreshToken': 'refresh',
              'expiresIn': 900,
            });
          case '/me':
            return TestReply({
              'id': 1,
              'nombre': 'Ana',
              'email': 'ana@example.test',
              'estado': 'activo',
              'roles': ['usuario'],
            });
          case '/me/listings':
            return privateData.future;
          default:
            return TestReply(page());
        }
      });
      final store = AplicacionController(client: client(adapter));
      addTearDown(store.dispose);
      store.addListener(() {
        if (store.accountDataError != null && !finished.isCompleted) {
          finished.complete();
        }
      });
      final initialized = store.initialize();
      await catalogStarted.future;
      await store.signIn(email: 'ana@example.test', password: 'prueba');
      expect(store.currentUser?.name, 'Ana');
      expect(store.loadingAccountData, isTrue);
      catalog.complete(TestReply(page()));
      await initialized;
      expect(store.initialized, isTrue);
      expect(store.lastError, isNull);
      privateData.complete(
        TestReply({'message': 'No disponible'}, status: 403),
      );
      await finished.future;
      expect(store.accountDataError, isNotNull);
      expect(store.currentUser?.name, 'Ana');
      expect(store.api.hasSession, isTrue);
    },
  );
  test(
    'la cuenta pendiente no consulta recursos que requieren verificación',
    () async {
      final adapter = TestAdapter((options) async {
        if (options.path == '/auth/login') {
          return TestReply({
            'accessToken': 'test',
            'refreshToken': 'test',
            'expiresIn': 900,
          });
        }
        if (options.path == '/me') {
          return TestReply({
            'id': 1,
            'nombre': 'Ana',
            'email': 'ana@example.test',
            'estado': 'pendiente_email',
            'roles': ['usuario'],
            'perfil': {},
          });
        }
        return TestReply(page());
      });
      final service = AplicacionController(client: client(adapter));
      await service.signIn(
        email: 'ana@example.test',
        password: 'Clave-de-prueba-2026',
      );
      expect(service.currentUser!.verified, isFalse);
      expect(adapter.requests.any((r) => r.path == '/me/listings'), isFalse);
      service.dispose();
    },
  );
  test('los roles se obtienen de /me y no de una elección local', () async {
    final adapter = TestAdapter((options) async {
      if (options.path == '/auth/login') {
        return TestReply({
          'accessToken': 'test',
          'refreshToken': 'test',
          'expiresIn': 900,
          'roles': ['administrador'],
        });
      }
      if (options.path == '/me') {
        return TestReply({
          'id': 1,
          'nombre': 'Ana',
          'email': 'ana@example.test',
          'estado': 'activo',
          'roles': ['usuario'],
          'perfil': {},
        });
      }
      if (options.path == '/me/tutor-grants') return TestReply(<Object>[]);
      return TestReply(page());
    });
    final service = AplicacionController(client: client(adapter));
    await service.signIn(
      email: 'ana@example.test',
      password: 'Clave-de-prueba-2026',
    );
    expect(service.isAdmin, isFalse);
    expect(service.currentUser!.roles, ['usuario']);
    service.dispose();
  });
  test(
    'editar el perfil traduce ciudad y solo envía campos permitidos',
    () async {
      final adapter = TestAdapter(
        (options) async => TestReply({
          'id': 1,
          'nombre': 'Ana',
          'email': 'a@example.test',
          'estado': 'pendiente_email',
          'roles': ['usuario'],
          'perfil': {'ciudad': 'Managua'},
        }),
      );
      final service = AplicacionController(client: client(adapter));
      await service.saveProfileData({
        'nombre': 'Ana',
        'ciudad': 'Managua',
        'areaProfesional': 'Arte',
      });
      final data = adapter.requests.single.data as Map;
      expect(data['ciudad'], 'Managua');
      expect(data.containsKey('universidad'), isFalse);
      expect(data.containsKey('year'), isFalse);
      expect(data.containsKey('roles'), isFalse);
      service.dispose();
    },
  );
  test(
    'el servidor rechazando un favorito no cambia el estado local',
    () async {
      final service = AplicacionController(
        client: client(
          TestAdapter(
            (_) async => TestReply({'message': 'No permitido'}, status: 403),
          ),
        ),
      );
      service.currentUser = const UsuarioAplicacion(
        id: '1',
        name: 'Ana',
        email: 'a@example.test',
        university: 'Managua',
      );
      final item = service.productFromJson({
        'id': '123',
        'titulo': 'Artículo',
        'tipoPrecio': 'gratis',
        'precioBase': '0.00',
      });
      await expectLater(service.toggleFavorite(item), throwsA(isA<ErrorApi>()));
      expect(service.isFavorite(item), isFalse);
      expect(item.displayPrice, 'Gratis');
      service.dispose();
    },
  );
  test(
    'las imágenes se descargan una sola vez dentro de la misma sesión',
    () async {
      final adapter = TestAdapter((_) async => TestReply([1, 2, 3]));
      final service = AplicacionController(client: client(adapter));
      await Future.wait([service.imageBytes('5'), service.imageBytes('5')]);
      expect(adapter.requests.length, 1);
      service.dispose();
    },
  );
  test(
    'la barra no completa mientras queda otra solicitud pendiente',
    () async {
      final first = Completer<TestReply>(), second = Completer<TestReply>();
      final api = client(
        TestAdapter((o) => o.path == '/first' ? first.future : second.future),
      );
      final a = api.object('/first');
      final b = api.object('/second');
      await Future<void>.delayed(Duration.zero);
      expect(ProgresoNavegacionController.instance.visible, isTrue);
      first.complete(TestReply({}));
      await a;
      expect(ProgresoNavegacionController.instance.value < 1, isTrue);
      second.complete(TestReply({}));
      await b;
      expect(ProgresoNavegacionController.instance.value, 1);
    },
  );
}
