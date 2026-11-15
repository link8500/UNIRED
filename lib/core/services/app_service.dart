import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:unired/core/constants/publication_status.dart';
import 'package:unired/core/constants/upload_limits.dart';
import 'package:unired/core/network/api_client.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/models/admin/models/community_user.dart';
import 'package:unired/models/auth/models/app_user.dart';
import 'package:unired/models/market/models/market_item.dart';
import 'package:unired/models/tutorials/models/tutorial_item.dart';
import 'package:unired/models/notifications/models/local_notice.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// Estado de presentación respaldado exclusivamente por la API NestJS.
/// Se mantienen separados catálogo público, publicaciones propias y moderación.
/// Ninguna mutación se confirma en pantalla antes de la respuesta del servidor.
class AppService extends ChangeNotifier {
  AppService({ApiClient? client}) : api = client ?? ApiClient() {
    api.onSessionExpired = () => _clearAccount(clearTokens: false);
  }
  static AppService _instance = AppService();
  static AppService get instance => _instance;
  @visibleForTesting
  static void replaceInstanceForTesting(AppService service) =>
      _instance = service;
  final ApiClient api;
  AppUser? currentUser;
  bool get isAdmin => currentUser?.isStaff ?? false;
  bool get isAdministrator => currentUser?.isAdministrator ?? false;
  bool get canModerate => currentUser?.canModerate ?? false;
  bool get canReview => currentUser?.canReview ?? false;
  bool get notificationsEnabled => currentUser?.notificationsEnabled ?? true;
  bool compactAdminCards = false;
  bool loading = false;
  bool initialized = false;
  String? lastError;
  int sessionEpoch = 0;
  Future<void>? _initializing;
  Timer? _noticesTimer;

  List<MarketItem> _publicProducts = [];
  List<MarketItem> _popularProducts = [];
  List<MarketItem> _ownProducts = [];
  List<MarketItem> _adminProducts = [];
  List<TutorialItem> _publicTutorials = [];
  List<TutorialItem> _popularTutorials = [];
  List<TutorialItem> _ownTutorials = [];
  List<TutorialItem> _adminTutorials = [];
  List<CommunityUser> _users = [];
  List<LocalNotice> _notices = [];
  int _unread = 0;
  List<MarketItem> _favorites = [];
  List<Json> categories = [];
  List<Json> areas = [];
  List<Json> enrollments = [];
  List<Json> tutorGrants = [];
  Json dashboard = {};
  Json analytics = {};
  ApiPage? marketPage;
  ApiPage? coursesPage;
  ApiPage? adminUsersPage;
  ApiPage? adminMarketPage;
  ApiPage? adminCoursesPage;
  Json _marketQuery = {};
  Json _coursesQuery = {};
  int _marketRequest = 0;
  int _coursesRequest = 0;
  int _adminUsersRequest = 0;
  int _dashboardRequest = 0;
  final _adminPublicationRequests = <bool, int>{};
  final _imageCache = <String, Future<Uint8List>>{};

  List<MarketItem> get products => _unique([
    ..._publicProducts,
    ..._ownProducts,
    ..._adminProducts,
  ], (x) => x.id);
  List<TutorialItem> get tutorials => _unique([
    ..._publicTutorials,
    ..._ownTutorials,
    ..._adminTutorials,
  ], (x) => x.id);
  List<CommunityUser> get users => List.unmodifiable(_users);
  List<MarketItem> get publishedProducts => List.unmodifiable(_publicProducts);
  List<TutorialItem> get publishedTutorials =>
      List.unmodifiable(_publicTutorials);
  List<MarketItem> get bestSellingProducts =>
      List.unmodifiable(_popularProducts);
  List<MarketItem> get featuredProducts => bestSellingProducts;
  List<TutorialItem> get topTutorials => List.unmodifiable(_popularTutorials);
  List<MarketItem> get myProducts => List.unmodifiable(_ownProducts);
  List<TutorialItem> get myTutorials => List.unmodifiable(_ownTutorials);
  List<MarketItem> get moderatedProducts => List.unmodifiable(_adminProducts);
  List<TutorialItem> get moderatedTutorials =>
      List.unmodifiable(_adminTutorials);
  List<MarketItem> get favoriteProducts => List.unmodifiable(_favorites);
  List<LocalNotice> get notifications => List.unmodifiable(_notices);
  int get unreadNotifications => _unread;
  bool isNoticeRead(LocalNotice notice) => notice.read;
  bool isFavorite(MarketItem item) => _favorites.any((p) => p.id == item.id);
  bool hasStartedTutorial(String id) => enrollments.any(
    (e) =>
        textValue(e['tutoriaId']) == id &&
        ['activa', 'completada'].contains(e['estado']),
  );
  List<MarketItem> productsForUser(String id) => products
      .where((p) => p.sellerId == id && p.status == PublicationStatus.published)
      .toList();
  List<TutorialItem> tutorialsForUser(String id) => tutorials
      .where((p) => p.mentorId == id && p.status == PublicationStatus.published)
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

  MarketItem productFromJson(Json row) => MarketItem(
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
    status: PublicationStatus.fromApi(row['estado'] ?? 'publicado'),
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
    accent: AppColors.surfaceBlue,
  );
  TutorialItem tutorialFromJson(Json row) => TutorialItem(
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
    status: PublicationStatus.fromApi(row['estado'] ?? 'publicada'),
    icon: Icons.school_outlined,
    accent: AppColors.navy,
  );
  AppUser _account(Json row) => AppUser.fromJson(row);

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
              api.page('/listings', query: {'sort': 'popular'}),
              api.page('/courses', query: {'sort': 'popular'}),
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
            if (currentUser != null) await refreshAccountData();
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
    );
    if (request != _coursesRequest) return;
    coursesPage = page;
    _publicTutorials = _unique([
      if (more) ..._publicTutorials,
      ...page.items.map(tutorialFromJson),
    ], (p) => p.id);
    notifyListeners();
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
    String? name,
  }) async {
    final result = await api.object(
      '/auth/login',
      method: 'POST',
      authenticated: false,
      data: {'email': email.trim(), 'password': password},
    );
    _clearAccount(clearTokens: true);
    api.acceptTokens(result);
    try {
      await refreshMe();
    } catch (_) {
      _clearAccount();
      rethrow;
    }
    await refreshAccountData();
    _startNotices();
    return currentUser!;
  }

  Future<bool> signInAdmin({
    required String username,
    required String password,
  }) async {
    final account = await signIn(email: username, password: password);
    if (!account.isStaff) {
      await logout();
      throw const ApiError('Esta cuenta no tiene acceso al panel.', 403);
    }
    return true;
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
    final values = await Future.wait([
      _all('/me/listings'),
      _all('/me/courses'),
      _all('/me/favorites'),
      _all('/me/enrollments'),
      api.request('/me/tutor-grants'),
    ]);
    if (epoch != sessionEpoch) return;
    _ownProducts = jsonRows(values[0]).map(productFromJson).toList();
    _ownTutorials = jsonRows(values[1]).map(tutorialFromJson).toList();
    _favorites = jsonRows(values[2]).map(productFromJson).toList();
    enrollments = jsonRows(values[3]);
    tutorGrants = jsonRows(values[4]);
    await Future.wait([
      refreshNotifications(),
      if (isAdministrator) ...[loadAdminUsers(), loadDashboard()],
      if (canModerate) ...[
        loadAdminPublications(false),
        loadAdminPublications(true),
      ],
    ]);
    notifyListeners();
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
    } on ApiError catch (error) {
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
    if (clearTokens) api.clearSession();
    currentUser = null;
    _ownProducts = [];
    _ownTutorials = [];
    _adminProducts = [];
    _adminTutorials = [];
    _users = [];
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
    _notices = page.items
        .map(
          (n) => LocalNotice(
            id: textValue(n['id']),
            title: textValue(n['titulo']),
            message: textValue(
              jsonObject(n['datos'])['motivo'],
              textValue(n['tipo']).replaceAll('_', ' '),
            ),
            ownerId: currentUser!.id,
            read: n['leidaEn'] != null,
          ),
        )
        .toList();
    notifyListeners();
  }

  void _startNotices() {
    _noticesTimer?.cancel();
    _noticesTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (currentUser?.verified == true && notificationsEnabled) {
        unawaited(
          refreshNotifications(foreground: false).catchError((Object _) {}),
        );
      }
    });
  }

  Future<void> markNotificationsRead() async {
    await api.object('/me/notifications/read-all', method: 'PATCH');
    await refreshNotifications();
  }

  Future<void> toggleFavorite(MarketItem item) async {
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
      throw const ApiError('Inicia sesión para continuar.', 401);
    }
    if (!currentUser!.verified) {
      throw const ApiError(
        'Verifica tu correo antes de realizar esta acción.',
        403,
      );
    }
  }

  Future<Json> startTutorial(TutorialItem item) async {
    requireActive();
    final result = await api.object(
      '/courses/${item.id}/enrollments',
      method: 'POST',
    );
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
  }) => api.object(
    '${own ? '/me' : ''}/${tutorial ? 'courses' : 'listings'}/$id',
  );
  Future<Json> savePublication(bool tutorial, Json fields, {String? id}) async {
    requireActive();
    final path = '/me/${tutorial ? 'courses' : 'listings'}';
    final row = await api.object(
      '$path${id == null ? '' : '/$id'}',
      method: id == null ? 'POST' : 'PATCH',
      data: fields,
    );
    await initialize(force: true);
    return row;
  }

  Future<void> setProductStatus(
    MarketItem item,
    PublicationStatus status,
  ) async {
    final row = await publicationDetails(false, item.id, own: true);
    final state = switch (status) {
      PublicationStatus.published => 'publicado',
      PublicationStatus.reserved => 'reservado',
      PublicationStatus.sold => 'vendido',
      PublicationStatus.archived => 'archivado',
      _ => throw const ApiError('Estado no permitido para un anuncio.'),
    };
    await api.object(
      '/me/listings/${item.id}/state',
      method: 'PATCH',
      data: {'estado': state, 'versionLock': row['versionLock']},
    );
    await initialize(force: true);
  }

  Future<void> setTutorialStatus(
    TutorialItem item,
    PublicationStatus status,
  ) async {
    final row = await publicationDetails(true, item.id, own: true);
    await api.object(
      '/me/courses/${item.id}/${status == PublicationStatus.published ? 'publish' : 'state'}',
      method: status == PublicationStatus.published ? 'POST' : 'PATCH',
      data: {
        'versionLock': row['versionLock'],
        if (status != PublicationStatus.published)
          'estado': status == PublicationStatus.archived
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
          (row) => CommunityUser(
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
            accent: AppColors.blue,
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
    CommunityUser user,
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
      throw const ApiError(
        'La sesión cambió. Selecciona el archivo nuevamente.',
        401,
      );
    }
    if (size == null || size == 0) {
      throw const ApiError('No se pudo leer el archivo seleccionado.');
    }
    final limit = UploadLimits.forSelection(purpose, file.name);
    if (size > limit) {
      throw ApiError('El archivo supera el límite de ${limit ~/ 1048576} MiB.');
    }
    Uint8List? adjusted;
    if (editImage != null && !video && !document) {
      adjusted = await editImage(await file.readAsBytes());
      if (adjusted == null) return null;
      if (adjusted.length > UploadLimits.image) {
        throw const ApiError('La imagen ajustada supera 10 MiB.');
      }
      if (epoch != sessionEpoch) {
        throw const ApiError(
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
      throw ApiError(
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
        bytes.length > UploadLimits.image) {
      throw const ApiError('Imagen o propósito no válido.');
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
    if (epoch != sessionEpoch) throw const ApiError('La sesión cambió.', 401);
    if (result['estado'] != 'listo' || result['escaneo'] != 'limpio') {
      throw const ApiError('La imagen todavía no está lista para vincular.');
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
    _noticesTimer?.cancel();
    api.dio.close();
    super.dispose();
  }
}
