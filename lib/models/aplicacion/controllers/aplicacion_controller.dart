// Archivo: lib/models/aplicacion/controllers/aplicacion_controller.dart
// Mantiene la cuenta y los catálogos de esta sesión, coordina consultas y notifica a la interfaz cuando hay cambios.

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:unired/core/constantes/estado_publicacion.dart';
import 'package:unired/core/constantes/limites_archivos.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/administracion/models/usuario_comunidad.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/market/models/articulo_market.dart';
import 'package:unired/models/tutorias/models/tutoria.dart';
import 'package:unired/models/notificaciones/models/aviso_usuario.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/controllers/progreso_navegacion_controller.dart';
import 'package:unired/core/aplicacion/publicaciones_use_cases.dart';
import 'package:unired/core/dominio/evento_servidor.dart';
import 'package:unired/core/dominio/contratos/navegador_social.dart';
import 'package:unired/core/datos/remoto/navegador_social.dart';

/// Estado de presentación respaldado exclusivamente por la API NestJS.
/// Se mantienen separados catálogo público, publicaciones propias y moderación.
/// Ninguna mutación se confirma en pantalla antes de la respuesta del servidor.
class AplicacionController extends ChangeNotifier {
  AplicacionController({ClienteApi? client, NavegadorSocial? socialBrowser})
    : navegadorSocial = socialBrowser ?? crearNavegadorSocial(),
      api =
          client ??
          ClienteApi(progreso: ProgresoNavegacionController.instance) {
    api.onSessionExpired = () => _clearAccount(clearTokens: false);
  }
  static AplicacionController _instance = AplicacionController();
  static AplicacionController get instance => _instance;
  @visibleForTesting
  static void replaceInstanceForTesting(AplicacionController service) =>
      _instance = service;
  final ClienteApi api;
  final NavegadorSocial navegadorSocial;
  late final publicaciones = PublicacionesUseCases(api);
  UsuarioAplicacion? currentUser;
  bool get isAdmin => currentUser?.isStaff ?? false;
  bool get isAdministrator => currentUser?.isAdministrator ?? false;
  bool get canModerate => currentUser?.canModerate ?? false;
  bool get canReview => currentUser?.canReview ?? false;
  bool get notificationsEnabled => currentUser?.notificationsEnabled ?? true;
  bool compactAdminCards = false;
  bool loading = false;
  bool initialized = false;
  String? lastError;
  String? accountDataError;
  bool loadingAccountData = false;
  int sessionEpoch = 0;
  int notificationsRevision = 0;
  int promotionsRevision = 0;
  void refreshPublicPromotions() {
    promotionsRevision++;
    notifyListeners();
  }

  Future<void>? _initializing;
  Timer? _noticesTimer;
  StreamSubscription<EventoServidor>? _noticeEvents;
  Timer? _eventsReconnect;
  String _noticeCursor = '0';
  bool _disposed = false;

  List<ArticuloMarket> _publicProducts = [];
  List<ArticuloMarket> _popularProducts = [];
  List<ArticuloMarket> _ownProducts = [];
  List<ArticuloMarket> _adminProducts = [];
  List<Tutoria> _publicTutorials = [];
  List<Tutoria> _popularTutorials = [];
  List<Tutoria> _ownTutorials = [];
  List<Tutoria> _adminTutorials = [];
  List<UsuarioComunidad> _users = [];
  List<AvisoUsuario> _notices = [];
  int _unread = 0;
  List<ArticuloMarket> _favorites = [];
  List<Json> categories = [];
  List<Json> areas = [];
  List<Json> enrollments = [];
  List<Json> tutorGrants = [];
  Json dashboard = {};
  Json analytics = {};
  PaginaApi? marketPage;
  PaginaApi? coursesPage;
  PaginaApi? adminUsersPage;
  PaginaApi? adminMarketPage;
  PaginaApi? adminCoursesPage;
  Json _marketQuery = {};
  Json _coursesQuery = {};
  int _marketRequest = 0;
  int _coursesRequest = 0;
  int _adminUsersRequest = 0;
  int _dashboardRequest = 0;
  final _adminPublicationRequests = <bool, int>{};
  final _imageCache = <String, Future<Uint8List>>{};

  List<ArticuloMarket> get products => _unique([
    ..._publicProducts,
    ..._ownProducts,
    ..._adminProducts,
  ], (x) => x.id);
  List<Tutoria> get tutorials => _unique([
    ..._publicTutorials,
    ..._ownTutorials,
    ..._adminTutorials,
  ], (x) => x.id);
  List<UsuarioComunidad> get users => List.unmodifiable(_users);
  List<ArticuloMarket> get publishedProducts =>
      List.unmodifiable(_publicProducts);
  List<Tutoria> get publishedTutorials => List.unmodifiable(_publicTutorials);
  List<ArticuloMarket> get bestSellingProducts =>
      List.unmodifiable(_popularProducts);
  List<ArticuloMarket> get featuredProducts => bestSellingProducts;
  List<Tutoria> get topTutorials => List.unmodifiable(_popularTutorials);
  List<ArticuloMarket> get myProducts => List.unmodifiable(_ownProducts);
  List<Tutoria> get myTutorials => List.unmodifiable(_ownTutorials);
  List<ArticuloMarket> get moderatedProducts =>
      List.unmodifiable(_adminProducts);
  List<Tutoria> get moderatedTutorials => List.unmodifiable(_adminTutorials);
  List<ArticuloMarket> get favoriteProducts => List.unmodifiable(_favorites);
  List<AvisoUsuario> get notifications => List.unmodifiable(_notices);
  int get unreadNotifications => _unread;
  bool isNoticeRead(AvisoUsuario notice) => notice.read;
  bool isFavorite(ArticuloMarket item) =>
      _favorites.any((p) => p.id == item.id);
  bool hasStartedTutorial(String id) => enrollments.any(
    (e) =>
        textValue(e['tutoriaId']) == id &&
        ['activa', 'completada'].contains(e['estado']),
  );
  List<ArticuloMarket> productsForUser(String id) => products
      .where((p) => p.sellerId == id && p.status == EstadoPublicacion.published)
      .toList();
  List<Tutoria> tutorialsForUser(String id) => tutorials
      .where((p) => p.mentorId == id && p.status == EstadoPublicacion.published)
      .toList();
  List<T> _unique<T>(List<T> items, String Function(T) id) =>
      {for (final item in items) id(item): item}.values.toList(growable: false);
  String _catalogName(List<Json> values, Object? id) => textValue(
    values
        .where((v) => textValue(v['id']) == textValue(id))
        .firstOrNull?['nombre'],
  );
  String _ownerName(Object? id) => textValue(id) == currentUser?.id
      ? currentUser!.name
      : _users.where((u) => u.id == textValue(id)).firstOrNull?.name ??
            'Usuario UniRed';

  ArticuloMarket productFromJson(Json row) => ArticuloMarket(
    publicationType: textValue(row['tipoPublicacion'], 'venta'),
    id: textValue(row['id']),
    title: textValue(row['titulo']),
    description: textValue(row['descripcion']),
    amount: numberValue(row['precioBase']),
    price: textValue(row['precioBase']),
    discountPercent: numberValue(row['descuentoPorcentaje']),
    category: textValue(
      row['categoriaNombre'],
      _catalogName(categories, row['categoriaId']),
    ),
    categoryId: intValue(row['categoriaId']),
    sellerId: textValue(row['vendedorId']),
    seller: textValue(row['vendedorNombre'], _ownerName(row['vendedorId'])),
    status: EstadoPublicacion.fromApi(row['estado'] ?? 'publicado'),
    condition: switch (row['condicion']) {
      'nuevo' => 'Nuevo',
      'como_nuevo' => 'Como nuevo',
      _ => 'Usado',
    },
    versionLock: intValue(row['versionLock'] ?? 1),
    imageId:
        row['portadaArchivoId']?.toString() ??
        jsonRows(row['imagenes']).firstOrNull?['archivoId']?.toString(),
    city: textValue(row['ciudad']),
    priceType: textValue(row['tipoPrecio'], 'fijo'),
    currency: textValue(row['moneda'], 'NIO'),
    badge: '',
    icon: Icons.inventory_2_outlined,
    accent: ColoresAplicacion.surfaceBlue,
  );
  Tutoria tutorialFromJson(Json row) => Tutoria(
    lessonCount: intValue(row['leccionesTotal']),
    sectionCount: intValue(row['seccionesTotal']),
    resourceCount: intValue(row['recursosTotal']),
    durationMinutes: intValue(row['duracionEstimadaMinutos']),
    id: textValue(row['id']),
    title: textValue(row['titulo']),
    body: textValue(row['descripcion']),
    meta:
        '${textValue(row['modalidad'], 'grabada').replaceAll('_', ' ')} · ${textValue(row['nivel'], 'todos')}',
    category: textValue(row['areaNombre'], _catalogName(areas, row['areaId'])),
    areaId: intValue(row['areaId']),
    mentorId: textValue(row['tutorId']),
    mentor: textValue(row['tutorNombre'], _ownerName(row['tutorId'])),
    amount: numberValue(row['precioBase']),
    discountPercent: numberValue(row['descuentoPorcentaje']),
    rating: numberValue(row['puntuacion']),
    students: intValue(row['alumnos']),
    level: textValue(row['nivel'], 'todos'),
    modality: textValue(row['modalidad'], 'grabada'),
    currency: textValue(row['moneda'], 'NIO'),
    versionLock: intValue(row['versionLock'] ?? 1),
    imageId: row['portadaArchivoId']?.toString(),
    status: EstadoPublicacion.fromApi(row['estado'] ?? 'publicada'),
    icon: Icons.school_outlined,
    accent: ColoresAplicacion.navy,
  );
  UsuarioAplicacion _account(Json row) => UsuarioAplicacion.fromJson(row);

  Future<void> initialize({bool force = false}) {
    if (_initializing != null) return _initializing!;
    if (initialized && !force) return Future.value();
    loading = true;
    lastError = null;
    notifyListeners();
    _initializing = api
        .withProgress(() async {
          try {
            final catalog = await Future.wait([
              api.request('/categories', authenticated: false),
              api.request('/areas', authenticated: false),
            ]);
            categories = jsonRows(catalog[0]);
            areas = jsonRows(catalog[1]);
            final popular = await Future.wait([
              api.page(
                '/listings',
                query: {'sort': 'popular'},
                authenticated: false,
              ),
              api.page(
                '/courses',
                query: {'sort': 'popular'},
                authenticated: false,
              ),
            ]);
            _popularProducts = popular[0].items
                .take(4)
                .map(productFromJson)
                .toList();
            _popularTutorials = popular[1].items
                .take(6)
                .map(tutorialFromJson)
                .toList();
            await Future.wait([
              searchMarket(query: _marketQuery),
              searchCourses(query: _coursesQuery),
            ]);
            initialized = true;
          } catch (error) {
            lastError = error.toString();
          } finally {
            loading = false;
            notifyListeners();
          }
        })
        .whenComplete(() => _initializing = null);
    return _initializing!;
  }

  Future<void> searchMarket({Json? query, bool more = false}) async {
    final request = ++_marketRequest;
    if (!more) _marketQuery = query ?? {};
    final page = await api.page(
      '/listings',
      page: more ? (marketPage?.page ?? 0) + 1 : 1,
      query: _marketQuery,
      authenticated: false,
    );
    if (request != _marketRequest) return;
    marketPage = page;
    _publicProducts = _unique([
      if (more) ..._publicProducts,
      ...page.items.map(productFromJson),
    ], (p) => p.id);
    notifyListeners();
  }

  Future<void> searchCourses({Json? query, bool more = false}) async {
    final request = ++_coursesRequest;
    if (!more) _coursesQuery = query ?? {};
    final page = await api.page(
      '/courses',
      page: more ? (coursesPage?.page ?? 0) + 1 : 1,
      query: _coursesQuery,
      authenticated: false,
    );
    if (request != _coursesRequest) return;
    coursesPage = page;
    _publicTutorials = _unique([
      if (more) ..._publicTutorials,
      ...page.items.map(tutorialFromJson),
    ], (p) => p.id);
    notifyListeners();
  }

  Future<UsuarioAplicacion> signIn({
    required String email,
    required String password,
    String? name,
  }) => _signInWithPassword(email, password);

  Future<UsuarioAplicacion> _signInWithPassword(
    String email,
    String password, {
    bool admin = false,
  }) async {
    final result = await api.object(
      '/auth/login',
      method: 'POST',
      authenticated: false,
      data: {'email': email.trim(), 'password': password},
    );
    return _openSession(result, admin: admin);
  }

  Future<bool> signInAdmin({
    required String username,
    required String password,
  }) async {
    await _signInWithPassword(username, password, admin: true);
    return true;
  }

  Future<void> iniciarAccesoSocial(
    String provider, {
    bool vincular = false,
    bool admin = false,
  }) async {
    if (!navegadorSocial.disponible) {
      throw const ErrorApi('Este acceso está disponible en la versión web.');
    }
    if (!['google', 'facebook'].contains(provider)) {
      throw const ErrorApi('Proveedor de acceso no válido.');
    }
    final random = Random.secure();
    final verifier = base64UrlEncode(
      List<int>.generate(64, (_) => random.nextInt(256)),
    ).replaceAll('=', '');
    final challenge = base64UrlEncode(
      sha256.convert(utf8.encode(verifier)).bytes,
    ).replaceAll('=', '');
    navegadorSocial.guardar({
      'verificador': verifier,
      'proveedor': provider,
      'admin': admin,
      'vincular': vincular,
      'creadoEn': DateTime.now().millisecondsSinceEpoch,
    });
    try {
      final result = await api.object(
        '${vincular ? '/me' : '/auth'}/social/$provider/start',
        method: 'POST',
        authenticated: vincular,
        data: {'origen': navegadorSocial.origen, 'reto': challenge},
      );
      final target = Uri.parse(textValue(result['url']));
      if (target.scheme != 'https' ||
          !['accounts.google.com', 'www.facebook.com'].contains(target.host)) {
        throw const ErrorApi(
          'El proveedor devolvió un destino de acceso no válido.',
        );
      }
      navegadorSocial.redirigir(target);
    } catch (_) {
      navegadorSocial.limpiar();
      rethrow;
    }
  }

  Future<Json> completarAccesoSocial(String code, {String? password}) async {
    final pending = navegadorSocial.leer();
    if (pending == null ||
        DateTime.now().millisecondsSinceEpoch - intValue(pending['creadoEn']) >
            10 * 60 * 1000) {
      throw const ErrorApi(
        'El intento caducó. Vuelve al acceso y selecciona Google o Facebook.',
      );
    }
    final result = await api.object(
      '/auth/social/exchange',
      method: 'POST',
      authenticated: false,
      data: {
        'codigo': code,
        'verificador': pending['verificador'],
        'passwordActual': ?password,
      },
    );
    if (result['requierePassword'] == true ||
        result['requiereAccesoPrevio'] == true) {
      return result;
    }
    navegadorSocial.limpiar();
    await _openSession(result, admin: pending['admin'] == true);
    return {
      ...result,
      'volverAdmin': pending['admin'] == true,
      'vincular': pending['vincular'] == true,
    };
  }

  Future<UsuarioAplicacion> _openSession(
    Json tokens, {
    required bool admin,
  }) async {
    _clearAccount();
    final epoch = sessionEpoch;
    api.acceptTokens(tokens);
    try {
      final row = await api.object('/me');
      if (epoch != sessionEpoch) {
        throw const ErrorApi('Vuelve a iniciar sesión para continuar.', 401);
      }
      final user = _account(row);
      if (admin && !user.isStaff) {
        await logout();
        throw const ErrorApi('Esta cuenta no tiene acceso al panel.', 403);
      }
      currentUser = user;
      notifyListeners();
      if (user.verified) {
        _startNotices();
        unawaited(refreshSignedInData());
      }
      return user;
    } catch (_) {
      if (epoch == sessionEpoch) _clearAccount();
      rethrow;
    }
  }

  Future<Json> register({
    required String name,
    required String email,
    required String password,
    String? university,
    Json profile = const {},
  }) => api.object(
    '/auth/register',
    method: 'POST',
    authenticated: false,
    data: {
      ...profile,
      'nombre': name.trim(),
      'email': email.trim(),
      'password': password,
    },
  );
  Future<void> refreshMe() async {
    final epoch = sessionEpoch;
    final row = await api.object('/me');
    if (epoch != sessionEpoch) return;
    currentUser = _account(row);
    notifyListeners();
  }

  Future<void> refreshAccountData() async {
    if (currentUser?.verified != true) return;
    final epoch = sessionEpoch;
    Future<void> load(
      Future<List<Json>> rows,
      void Function(List<Json>) update,
    ) async {
      final result = await rows;
      if (!_disposed && epoch == sessionEpoch) {
        update(result);
        notifyListeners();
      }
    }

    await Future.wait([
      load(
        _all('/me/listings'),
        (rows) => _ownProducts = rows.map(productFromJson).toList(),
      ),
      load(
        _all('/me/courses'),
        (rows) => _ownTutorials = rows.map(tutorialFromJson).toList(),
      ),
      load(
        _all('/me/favorites'),
        (rows) => _favorites = rows.map(productFromJson).toList(),
      ),
      load(_all('/me/enrollments'), (rows) => enrollments = rows),
      load(
        api.request('/me/tutor-grants').then(jsonRows),
        (rows) => tutorGrants = rows,
      ),
      refreshNotifications(),
    ]);
  }

  Future<void> refreshSignedInData() async {
    if (loadingAccountData || currentUser?.verified != true) return;
    final epoch = sessionEpoch;
    loadingAccountData = true;
    accountDataError = null;
    notifyListeners();
    try {
      await refreshAccountData();
    } catch (_) {
      if (!_disposed && epoch == sessionEpoch) {
        accountDataError = 'Faltan algunos datos de tu cuenta por cargar.';
      }
    } finally {
      if (!_disposed && epoch == sessionEpoch) {
        loadingAccountData = false;
        notifyListeners();
      }
    }
  }

  Future<List<Json>> _all(String path, {bool foreground = true}) async {
    final rows = <Json>[];
    var page = await api.page(path, foreground: foreground);
    rows.addAll(page.items);
    while (page.hasMore) {
      page = await api.page(path, page: page.page + 1, foreground: foreground);
      rows.addAll(page.items);
    }
    return rows;
  }

  Future<void> logout() async {
    _noticesTimer?.cancel();
    String? warning;
    try {
      if (api.hasSession) await api.object('/auth/logout', method: 'POST');
    } on ErrorApi catch (error) {
      if (error.status != 401) {
        warning =
            'Sesión local cerrada. No se pudo confirmar su revocación en el servidor.';
      }
    } finally {
      _clearAccount();
      if (warning != null) {
        lastError = warning;
        notifyListeners();
      }
    }
  }

  void _clearAccount({bool clearTokens = true}) {
    sessionEpoch++;
    _noticesTimer?.cancel();
    _eventsReconnect?.cancel();
    unawaited(_noticeEvents?.cancel());
    _noticeEvents = null;
    _noticeCursor = '0';
    if (clearTokens) api.clearSession();
    currentUser = null;
    accountDataError = null;
    loadingAccountData = false;
    _ownProducts = [];
    _ownTutorials = [];
    _adminProducts = [];
    _adminTutorials = [];
    _users = [];
    adminUsersPage = null;
    adminMarketPage = null;
    adminCoursesPage = null;
    _favorites = [];
    _notices = [];
    _unread = 0;
    enrollments = [];
    tutorGrants = [];
    dashboard = {};
    analytics = {};
    _imageCache.clear();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) =>
      saveProfileData({'notificacionesActivas': value});

  /// PATCH exacto: permite vaciar opcionales sin recargar todos los catálogos.
  Future<void> saveProfileData(Json fields) async {
    final epoch = sessionEpoch;
    final row = await api.object('/me', method: 'PATCH', data: fields);
    if (epoch != sessionEpoch) return;
    currentUser = _account(row);
    notifyListeners();
  }

  void setCompactAdminCards(bool value) {
    compactAdminCards = value;
    notifyListeners();
  }

  Future<void> refreshNotifications({bool foreground = true}) async {
    if (currentUser?.verified != true) return;
    final epoch = sessionEpoch;
    final result = await Future.wait([
      api.page('/me/notifications', foreground: foreground),
      api.page(
        '/me/notifications',
        query: {'sinLeer': 'true', 'limit': 1},
        foreground: foreground,
      ),
    ]);
    if (epoch != sessionEpoch) return;
    final page = result[0];
    _unread = result[1].total;
    notificationsRevision++;
    _notices = page.items
        .map(
          (n) => AvisoUsuario(
            id: textValue(n['id']),
            title: textValue(n['titulo']),
            message: textValue(
              jsonObject(n['datos'])['motivo'],
              textValue(n['tipo']).replaceAll('_', ' '),
            ),
            ownerId: currentUser!.id,
            read: n['leidaEn'] != null,
            type: textValue(n['tipo']),
            data: jsonObject(n['datos']),
          ),
        )
        .toList();
    notifyListeners();
  }

  void _startNotices() {
    _noticesTimer?.cancel();
    _eventsReconnect?.cancel();
    unawaited(_noticeEvents?.cancel());
    _connectNoticeEvents();
    _noticesTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (currentUser?.verified == true && notificationsEnabled) {
        unawaited(
          refreshNotifications(foreground: false).catchError((Object _) {}),
        );
      }
    });
  }

  void _connectNoticeEvents() {
    if (_disposed ||
        !api.enableLiveEvents ||
        currentUser?.verified != true ||
        !notificationsEnabled) {
      return;
    }
    final epoch = sessionEpoch;
    void reconnect() {
      if (_disposed || epoch != sessionEpoch || currentUser == null) return;
      _eventsReconnect?.cancel();
      _eventsReconnect = Timer(
        const Duration(seconds: 3),
        _connectNoticeEvents,
      );
    }

    _noticeEvents = api
        .events(afterId: _noticeCursor)
        .listen(
          (event) {
            if (_disposed || epoch != sessionEpoch) return;
            if (RegExp(r'^\d+$').hasMatch(event.id)) _noticeCursor = event.id;
            if (event.type == 'notifications' &&
                jsonRows(event.data['items']).isNotEmpty &&
                notificationsEnabled) {
              unawaited(
                refreshNotifications(
                  foreground: false,
                ).catchError((Object _) {}),
              );
            }
          },
          onError: (Object _) => reconnect(),
          onDone: reconnect,
          cancelOnError: true,
        );
  }

  Future<void> markNotificationsRead() async {
    await api.object('/me/notifications/read-all', method: 'PATCH');
    await refreshNotifications();
  }

  Future<void> toggleFavorite(ArticuloMarket item) async {
    requireActive();
    await api.object(
      '/me/favorites/${item.id}',
      method: isFavorite(item) ? 'DELETE' : 'PUT',
    );
    _favorites = (await _all('/me/favorites')).map(productFromJson).toList();
    notifyListeners();
  }

  void requireActive() {
    if (currentUser == null) {
      throw const ErrorApi('Inicia sesión para continuar.', 401);
    }
    if (!currentUser!.verified) {
      throw const ErrorApi(
        'Verifica tu correo antes de realizar esta acción.',
        403,
      );
    }
  }

  Future<Json> startTutorial(Tutoria item) async {
    requireActive();
    final result = await publicaciones.solicitarAcceso(item.id);
    enrollments = await _all('/me/enrollments');
    notifyListeners();
    return result;
  }

  Future<void> refreshEnrollments() async {
    requireActive();
    final epoch = sessionEpoch;
    final rows = await _all('/me/enrollments', foreground: false);
    if (epoch != sessionEpoch) return;
    enrollments = rows;
    notifyListeners();
  }

  Future<void> cancelEnrollment(String id) async {
    requireActive();
    final epoch = sessionEpoch;
    final result = await api.object('/me/enrollments/$id', method: 'DELETE');
    if (epoch != sessionEpoch) return;
    enrollments = [
      for (final enrollment in enrollments)
        if (textValue(enrollment['id']) == id)
          {...enrollment, ...result}
        else
          enrollment,
    ];
    notifyListeners();
  }

  Future<Json> publicationDetails(
    bool tutorial,
    String id, {
    bool own = false,
  }) => publicaciones.consultar(tutorial, id, propia: own);
  Future<Json> savePublication(bool tutorial, Json fields, {String? id}) async {
    requireActive();
    final row = await publicaciones.guardar(tutorial, fields, id: id);
    await initialize(force: true);
    return row;
  }

  Future<void> setProductStatus(
    ArticuloMarket item,
    EstadoPublicacion status,
  ) async {
    final row = await publicationDetails(false, item.id, own: true);
    final state = switch (status) {
      EstadoPublicacion.published => 'publicado',
      EstadoPublicacion.reserved => 'reservado',
      EstadoPublicacion.sold => 'vendido',
      EstadoPublicacion.archived => 'archivado',
      _ => throw const ErrorApi('Estado no permitido para un anuncio.'),
    };
    await api.object(
      '/me/listings/${item.id}/state',
      method: 'PATCH',
      data: {'estado': state, 'versionLock': row['versionLock']},
    );
    await initialize(force: true);
  }

  Future<void> setTutorialStatus(Tutoria item, EstadoPublicacion status) async {
    final row = await publicationDetails(true, item.id, own: true);
    await api.object(
      '/me/courses/${item.id}/${status == EstadoPublicacion.published ? 'publish' : 'state'}',
      method: status == EstadoPublicacion.published ? 'POST' : 'PATCH',
      data: {
        'versionLock': row['versionLock'],
        if (status != EstadoPublicacion.published)
          'estado': status == EstadoPublicacion.archived
              ? 'archivada'
              : 'pausada',
      },
    );
    await initialize(force: true);
  }

  Future<void> loadAdminUsers({int page = 1, Json? query}) async {
    if (!isAdministrator) return;
    final request = ++_adminUsersRequest;
    final epoch = sessionEpoch;
    final result = await api.page('/admin/users', page: page, query: query);
    if (epoch != sessionEpoch || request != _adminUsersRequest) return;
    adminUsersPage = result;
    _users = result.items
        .map(
          (row) => UsuarioComunidad(
            id: textValue(row['id']),
            name: textValue(row['nombre']),
            major: textValue(row['carrera']),
            year: textValue(row['anioEstudio']),
            email: textValue(row['email']),
            status: switch (row['estado']) {
              'activo' => 'Activo',
              'suspendido' => 'Suspendido',
              'pendiente_email' => 'Pendiente',
              _ => 'Inactivo',
            },
            accent: ColoresAplicacion.blue,
            location: textValue(row['ciudad']),
            university: textValue(row['universidad']),
            avatarId: row['avatarArchivoId']?.toString(),
            publicationCount: intValue(row['publicaciones']),
            tutorialCount: intValue(row['tutorias']),
            accredited: row['tutorVerificado'] == true,
            roles: (row['roles'] is List ? row['roles'] as List : [])
                .map((x) => x.toString())
                .toList(),
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> setUserStatus(
    UsuarioComunidad user,
    String status, {
    String motivo = 'Cambio desde el panel administrativo',
  }) async {
    await api.object(
      '/admin/users/${user.id}/state',
      method: 'PATCH',
      data: {
        'estado': status == 'Activo'
            ? 'activo'
            : status == 'Inactivo'
            ? 'desactivado'
            : 'suspendido',
        'motivo': motivo,
      },
    );
    await loadAdminUsers(page: adminUsersPage?.page ?? 1);
  }

  Future<void> loadAdminPublications(
    bool tutorial, {
    int page = 1,
    Json? query,
  }) async {
    if (!canModerate) return;
    final request = (_adminPublicationRequests[tutorial] ?? 0) + 1;
    _adminPublicationRequests[tutorial] = request;
    final epoch = sessionEpoch;
    final result = await api.page(
      '/admin/${tutorial ? 'courses' : 'listings'}',
      page: page,
      query: query,
    );
    if (epoch != sessionEpoch ||
        request != _adminPublicationRequests[tutorial]) {
      return;
    }
    if (tutorial) {
      adminCoursesPage = result;
      _adminTutorials = result.items.map(tutorialFromJson).toList();
    } else {
      adminMarketPage = result;
      _adminProducts = result.items.map(productFromJson).toList();
    }
    notifyListeners();
  }

  Future<void> moderatePublication(
    bool tutorial,
    String id,
    String reason, {
    bool restore = false,
  }) async {
    await api.object(
      '/admin/${tutorial ? 'courses' : 'listings'}/$id/${restore ? 'restore' : 'block'}',
      method: 'POST',
      data: {'motivo': reason},
    );
    await loadAdminPublications(tutorial);
    await initialize(force: true);
  }

  Future<void> loadDashboard({int days = 30}) async {
    if (!isAdministrator) return;
    final request = ++_dashboardRequest;
    final epoch = sessionEpoch;
    final result = await Future.wait([
      api.object('/admin/dashboard'),
      api.object('/admin/analytics', query: {'days': days}),
    ]);
    if (epoch != sessionEpoch || request != _dashboardRequest) return;
    dashboard = result[0];
    analytics = result[1];
    notifyListeners();
  }

  /// Selección con flujo de bytes y límites específicos del cliente Web.
  /// El servidor vuelve a comprobar tamaño, formato y antivirus.
  Future<Json?> pickAndUpload(
    String purpose, {
    void Function(int, int)? progress,
    bool demonstrationVideo = false,
    Future<Uint8List?> Function(Uint8List)? editImage,
  }) async {
    requireActive();
    final epoch = sessionEpoch;
    final video =
        purpose == 'video_leccion' ||
        (purpose == 'galeria_curso' && demonstrationVideo);
    final document =
        purpose == 'evidencia_tutor' ||
        purpose == 'recurso_curso' ||
        purpose == 'adjunto_chat';
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: video
          ? ['mp4', 'webm']
          : document
          ? [
              'pdf',
              if (purpose == 'recurso_curso') 'zip',
              'jpg',
              'jpeg',
              'png',
              'webp',
            ]
          : ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null) return null;
    final size = await file.length();
    if (epoch != sessionEpoch) {
      throw const ErrorApi(
        'La sesión cambió. Selecciona el archivo nuevamente.',
        401,
      );
    }
    if (size == null || size == 0) {
      throw const ErrorApi('No se pudo leer el archivo seleccionado.');
    }
    final limit = LimitesArchivos.forSelection(purpose, file.name);
    if (size > limit) {
      throw ErrorApi('El archivo supera el límite de ${limit ~/ 1048576} MiB.');
    }
    Uint8List? adjusted;
    if (editImage != null && !video && !document) {
      adjusted = await editImage(await file.readAsBytes());
      if (adjusted == null) return null;
      if (adjusted.length > LimitesArchivos.image) {
        throw const ErrorApi('La imagen ajustada supera 10 MiB.');
      }
      if (epoch != sessionEpoch) {
        throw const ErrorApi(
          'La sesión cambió. Selecciona la imagen de nuevo.',
          401,
        );
      }
    }
    final result = jsonObject(
      await api.request(
        '/files',
        method: 'POST',
        data: FormData.fromMap({
          'proposito': purpose,
          'file': adjusted != null
              ? MultipartFile.fromBytes(adjusted, filename: 'publicacion.png')
              : MultipartFile.fromStream(
                  () => file.readAsByteStream(),
                  size,
                  filename: file.name,
                ),
        }),
        onSendProgress: progress,
      ),
    );
    if (result['estado'] != 'listo' || result['escaneo'] != 'limpio') {
      throw ErrorApi(
        'Archivo recibido, pero no está listo para vincular. Revisa el archivo ${result['id']} y el antivirus del servidor.',
      );
    }
    return result;
  }

  Future<Json> uploadPublicationImage(String purpose, Uint8List bytes) async {
    requireActive();
    if (![
          'portada_curso',
          'imagen_anuncio',
          'galeria_curso',
        ].contains(purpose) ||
        bytes.length > LimitesArchivos.image) {
      throw const ErrorApi('Imagen o propósito no válido.');
    }
    final epoch = sessionEpoch;
    final result = jsonObject(
      await api.request(
        '/files',
        method: 'POST',
        data: FormData.fromMap({
          'proposito': purpose,
          'file': MultipartFile.fromBytes(bytes, filename: 'publicacion.png'),
        }),
      ),
    );
    if (epoch != sessionEpoch) throw const ErrorApi('La sesión cambió.', 401);
    if (result['estado'] != 'listo' || result['escaneo'] != 'limpio') {
      throw const ErrorApi('La imagen todavía no está lista para vincular.');
    }
    return result;
  }

  Future<Uint8List> imageBytes(String id, {bool thumbnail = true}) {
    final key = '$sessionEpoch:$id:$thumbnail';
    return _imageCache.putIfAbsent(
      key,
      () => (() async {
        try {
          final data = await api.request(
            '/files/$id/${thumbnail ? 'thumbnail' : 'content'}',
            bytes: true,
            foreground: false,
          );
          return Uint8List.fromList((data as List).cast<int>());
        } catch (_) {
          _imageCache.remove(key);
          rethrow;
        }
      })(),
    );
  }

  Future<Uri> fileAccess(String id) async {
    final ticket = await api.object('/files/$id/access', method: 'POST');
    return api.resolve(textValue(ticket['url']));
  }

  @override
  void dispose() {
    _disposed = true;
    _noticesTimer?.cancel();
    _eventsReconnect?.cancel();
    unawaited(_noticeEvents?.cancel());
    api.dio.close();
    super.dispose();
  }
}
