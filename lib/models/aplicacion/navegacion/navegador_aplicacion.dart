// Archivo: lib/models/aplicacion/navegacion/navegador_aplicacion.dart
// Declara rutas, crea vistas, comprueba accesos y administra la navegación y la conservación de pantallas.

import 'package:flutter/material.dart';
import 'package:unired/models/autenticacion/views/retorno_social_view.dart';
import 'package:unired/models/comercial/views/cartera_view.dart';
import 'package:unired/models/comercial/views/empresas_view.dart';
import 'package:unired/models/comercial/views/comercial_admin_view.dart';
import 'package:unired/models/interacciones/views/interacciones_view.dart';
import 'package:unired/models/comunidad/views/busqueda_view.dart';
import 'package:unired/models/autenticacion/views/acceso_cuenta_view.dart';
import 'package:unired/models/market/views/detalle_anuncio_view.dart';
import 'package:unired/models/mensajeria/views/mensajes_view.dart';
import 'package:unired/models/acreditaciones/views/acreditacion_view.dart';
import 'package:unired/models/tutorias/views/curso_view.dart';
import 'package:unired/models/administracion/views/catalogos_view.dart';
import 'package:unired/models/administracion/views/operaciones_view.dart';
import 'package:unired/models/administracion/views/espacio_gestion_view.dart';
import 'package:unired/models/administracion/views/revision_curso_view.dart';
import 'package:unired/models/administracion/views/revision_conversacion_view.dart';
import 'package:unired/models/perfil/views/archivos_view.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

import 'package:unired/models/nosotros/views/nosotros_view.dart';
import 'package:unired/models/administracion/views/acceso_admin_view.dart';
import 'package:unired/models/administracion/views/panel_view.dart';
import 'package:unired/models/administracion/views/market_admin_view.dart';
import 'package:unired/models/administracion/views/tutorias_admin_view.dart';
import 'package:unired/models/administracion/views/publicacion_view.dart';
import 'package:unired/models/autenticacion/views/acceso_view.dart';
import 'package:unired/models/autenticacion/views/registro_view.dart';
import 'package:unired/models/inicio/views/inicio_view.dart';
import 'package:unired/models/market/views/market_view.dart';
import 'package:unired/models/perfil/views/perfil_view.dart';
import 'package:unired/models/perfil/views/perfil_publico_view.dart';
import 'package:unired/models/configuracion/views/configuracion_view.dart';
import 'package:unired/models/tutorias/views/tutorias_view.dart';
import 'package:unired/models/usuarios/views/usuarios_view.dart';

/// Rutas declaradas en un solo sitio para evitar strings repetidos.
class RutasAplicacion {
  static const socialCallback = '/auth/social';
  static const search = '/search';
  static const adminPeerReviews = '/admin/support/peer-reviews';
  static const adminOffers = '/admin/profile/offers';
  static const adminTutoringRequests = '/admin/profile/tutoring-requests';
  static const adminWallet = '/admin/profile/wallet';
  static const adminBusiness = '/admin/profile/business';
  static const offers = '/profile/offers';
  static const tutoringRequests = '/profile/tutoring-requests';
  static const wallet = '/profile/wallet';
  static const business = '/profile/business';
  static const adminCommerce = '/admin/commerce';
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const market = '/market';
  static const tutorials = '/tutorials';
  static const about = '/about';
  static const adminLogin = '/admin-login';
  static const dashboard = '/dashboard';
  static const adminMarket = '/admin/marketplace';
  static const adminTutorials = '/admin/tutorials';
  static const user = '/user';
  static const profile = '/profile';
  static const member = '/community/profile';
  static String memberProfile(String id) =>
      Uri(path: member, queryParameters: {'id': id}).toString();
  static const adminProfile = '/admin/profile';
  static const adminProduct = '/admin/marketplace/item';
  static const adminTutorial = '/admin/tutorials/item';
  static const myProduct = '/profile/products/item';
  static const myTutorial = '/profile/tutorials/item';
  static const settings = '/settings';
  static const verifyEmail = '/verify-email';
  static const recover = '/recover';
  static const listing = '/market/item';
  static const course = '/tutorials/course';
  static const messages = '/messages';
  static const adminMessages = '/admin/messages';
  static const adminConversations = '/admin/conversations';
  static const adminCourseConversations = '/admin/training/conversations';
  static const adminMarketConversations = '/admin/marketplace/conversations';
  static const adminOwnMarket = '/admin/my-listings';
  static const adminOwnCourses = '/admin/my-courses';
  static const accreditation = '/profile/accreditation';
  static const adminAccreditation = '/admin/accreditation';
  static const adminCatalogs = '/admin/catalogs';
  static const adminReports = '/admin/reports';
  static const adminAudit = '/admin/audit';
  static const adminApplications = '/admin/tutors/applications';
  static const adminTutors = '/admin/tutors/authorized';
  static const adminExpiringTutors = '/admin/tutors/expiring';
  static const adminTutorHistory = '/admin/tutors/history';
  static const adminSessions = '/admin/training/sessions';
  static const adminParticipation = '/admin/training/participation';
  static const adminReviews = '/admin/training/reviews';
  static const adminTrainingAreas = '/admin/training/areas';
  static const adminMarketUpdates = '/admin/marketplace/updates';
  static const adminMarketCategories = '/admin/marketplace/categories';
  static const adminSupport = '/admin/support';
  static const files = '/profile/files';
  static const adminFiles = '/admin/profile/files';
  static const adminOwnAccreditation = '/admin/profile/accreditation';
  static const courseRequestsSection = 'solicitudes';

  /// URLs distintas conservan el entorno y permiten volver desde el editor.
  static String publication({
    required bool tutorial,
    required bool admin,
    String? id,
    bool editing = false,
    String? section,
  }) => Uri(
    path: admin
        ? (tutorial ? adminTutorial : adminProduct)
        : (tutorial ? myTutorial : myProduct),
    queryParameters: {'id': ?id, if (editing) 'edit': '1', 'section': ?section},
  ).toString();
  static String courseRequests({required String id, required bool admin}) =>
      publication(
        tutorial: true,
        admin: admin,
        id: id,
        section: courseRequestsSection,
      );

  static String myPublications(bool tutorial) =>
      '$profile?tab=${tutorial ? 'tutorials' : 'products'}';
}

/// Observa las rutas para saber cuáles ya fueron abiertas y siguen en el
/// stack. Así, al volver a una pantalla existente, Flutter conserva su
/// instancia y su estado en memoria.
class ObservadorNavegacion extends NavigatorObserver {
  NavigatorState? _trackedNavigator;
  final _routes = <Route<dynamic>>[];

  void _syncNavigator() {
    final currentNavigator = navigator;
    if (currentNavigator == null || currentNavigator == _trackedNavigator) {
      return;
    }
    _trackedNavigator = currentNavigator;
    _routes.clear();
  }

  bool contains(NavigatorState targetNavigator, String routeName) {
    if (_trackedNavigator != targetNavigator) return false;
    return _routes.any((route) => route.settings.name == routeName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncNavigator();
    _routes.remove(route);
    _routes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncNavigator();
    _routes.remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncNavigator();
    _routes.remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _syncNavigator();
    if (oldRoute != null) _routes.remove(oldRoute);
    if (newRoute != null) _routes.add(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

/// Crea las pantallas y navega sin animaciones.
///
/// El comportamiento busca sentirse como una página web: los enlaces cambian
/// el contenido de inmediato, no agregan rutas repetidas y reutilizan las
/// vistas que ya fueron abiertas.
class NavegadorAplicacion {
  /// Observador que mantiene localizadas las rutas que siguen en memoria.
  static final observer = ObservadorNavegacion();
  static final visibilityObserver = RouteObserver<PageRoute<dynamic>>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? RutasAplicacion.home);
    final page = switch (uri?.path) {
      RutasAplicacion.socialCallback => RetornoSocialView(
        code: uri?.queryParameters['codigo'] ?? '',
        error: uri?.queryParameters['error'] ?? '',
      ),
      RutasAplicacion.search => const BusquedaView(),
      RutasAplicacion.adminOffers => const InteraccionesView(asAdmin: true),
      RutasAplicacion.adminTutoringRequests
          when uri?.queryParameters['new'] == '1' =>
        const TutoriasView(),
      RutasAplicacion.adminTutoringRequests => InteraccionesView(
        asAdmin: true,
        tutorials: true,
        initialTab:
            {'disponibles': 1, 'impartidas': 2}[uri?.queryParameters['view']] ??
            0,
      ),
      RutasAplicacion.adminWallet => const CarteraView(asAdmin: true),
      RutasAplicacion.adminBusiness => EmpresasView(
        asAdmin: true,
        companyId: uri?.queryParameters['id'],
      ),
      RutasAplicacion.offers => const InteraccionesView(),
      RutasAplicacion.tutoringRequests
          when uri?.queryParameters['new'] == '1' =>
        const TutoriasView(),
      RutasAplicacion.tutoringRequests => InteraccionesView(
        tutorials: true,
        initialTab:
            {'disponibles': 1, 'impartidas': 2}[uri?.queryParameters['view']] ??
            0,
      ),
      RutasAplicacion.wallet => const CarteraView(),
      RutasAplicacion.business => EmpresasView(
        companyId: uri?.queryParameters['id'],
      ),
      RutasAplicacion.adminCommerce => const ComercialAdminView(),
      RutasAplicacion.login => const AccesoView(),
      RutasAplicacion.register => const RegistroView(),
      RutasAplicacion.verifyEmail => AccesoCuentaView(
        token: uri?.queryParameters['token'] ?? '',
      ),
      RutasAplicacion.recover => AccesoCuentaView(
        recovery: true,
        token: uri?.queryParameters['token'] ?? '',
      ),
      RutasAplicacion.listing => DetalleAnuncioView(
        id: uri?.queryParameters['id'] ?? '',
      ),
      RutasAplicacion.messages || RutasAplicacion.adminMessages => MensajesView(
        id: uri?.queryParameters['id'],
        asAdmin: uri?.path == RutasAplicacion.adminMessages,
      ),
      RutasAplicacion.adminConversations ||
      RutasAplicacion.adminCourseConversations ||
      RutasAplicacion.adminMarketConversations => RevisionConversacionView(
        kind: uri?.path == RutasAplicacion.adminCourseConversations
            ? 'tutoria'
            : uri?.path == RutasAplicacion.adminMarketConversations
            ? 'market'
            : '',
        userId: uri?.queryParameters['user'],
      ),
      RutasAplicacion.adminOwnMarket ||
      RutasAplicacion.adminOwnCourses => PerfilView(
        asAdmin: true,
        initialTab: uri?.path == RutasAplicacion.adminOwnCourses
            ? 'tutorials'
            : 'products',
      ),
      RutasAplicacion.accreditation => const AcreditacionView(),
      RutasAplicacion.adminOwnAccreditation => const AcreditacionView(
        asAdmin: true,
      ),
      RutasAplicacion.adminAccreditation || RutasAplicacion.adminApplications =>
        const EspacioGestionView(section: 'applications'),
      RutasAplicacion.adminTutors => const EspacioGestionView(
        section: 'tutors',
      ),
      RutasAplicacion.adminExpiringTutors => const EspacioGestionView(
        section: 'tutors',
        view: 'expiring',
      ),
      RutasAplicacion.adminTutorHistory => const EspacioGestionView(
        section: 'applications',
        view: 'history',
      ),
      RutasAplicacion.adminSessions => const EspacioGestionView(
        section: 'sessions',
      ),
      RutasAplicacion.adminParticipation => const EspacioGestionView(
        section: 'participation',
      ),
      RutasAplicacion.adminReviews => const EspacioGestionView(
        section: 'reviews',
      ),
      RutasAplicacion.adminPeerReviews => const EspacioGestionView(
        section: 'peer-reviews',
      ),
      RutasAplicacion.adminMarketUpdates => const EspacioGestionView(
        section: 'market-updates',
      ),
      RutasAplicacion.adminTrainingAreas => const CatalogosView(
        initialAreas: true,
        route: RutasAplicacion.adminTrainingAreas,
      ),
      RutasAplicacion.adminMarketCategories => const CatalogosView(
        initialAreas: false,
        route: RutasAplicacion.adminMarketCategories,
      ),
      RutasAplicacion.adminCatalogs => const CatalogosView(),
      RutasAplicacion.adminReports => const OperacionesView(),
      RutasAplicacion.adminSupport => OperacionesView(
        initialState: uri?.queryParameters['state'] ?? 'pendiente',
      ),
      RutasAplicacion.adminAudit => const OperacionesView(audit: true),
      RutasAplicacion.files || RutasAplicacion.adminFiles => ArchivosView(
        asAdmin: uri?.path == RutasAplicacion.adminFiles,
      ),
      RutasAplicacion.course => CursoView(
        id: uri?.queryParameters['id'] ?? '',
        manage: uri?.queryParameters['manage'] == '1',
        classroom: uri?.queryParameters['aula'] == '1',
        initialLesson: uri?.queryParameters['lesson'],
      ),
      RutasAplicacion.market => const MarketView(),
      RutasAplicacion.tutorials => const TutoriasView(),
      RutasAplicacion.about => const NosotrosView(),
      RutasAplicacion.adminLogin => const AccesoAdminView(),
      RutasAplicacion.dashboard => const PanelView(),
      RutasAplicacion.adminMarket => MarketAdminView(
        ownerId: uri?.queryParameters['owner'],
      ),
      RutasAplicacion.adminTutorials =>
        uri?.queryParameters['inspect'] != null
            ? RevisionCursoView(id: uri!.queryParameters['inspect']!)
            : TutoriasAdminView(ownerId: uri?.queryParameters['owner']),
      RutasAplicacion.user => UsuariosView(
        accessView: uri?.queryParameters['view'] == 'access',
      ),
      RutasAplicacion.profile => PerfilView(
        initialTab: uri?.queryParameters['tab'] ?? 'data',
      ),
      RutasAplicacion.member => PerfilPublicoView(
        id: uri?.queryParameters['id'] ?? '',
      ),
      RutasAplicacion.adminProfile => PerfilView(
        asAdmin: true,
        initialTab: uri?.queryParameters['tab'] ?? 'data',
      ),
      RutasAplicacion.adminProduct ||
      RutasAplicacion.adminTutorial ||
      RutasAplicacion.myProduct ||
      RutasAplicacion.myTutorial => PublicacionView(
        isTutorial:
            uri!.path == RutasAplicacion.adminTutorial ||
            uri.path == RutasAplicacion.myTutorial,
        asAdmin: uri.path.startsWith('/admin/'),
        id: uri.queryParameters['id'],
        initiallyEditing: uri.queryParameters['edit'] == '1',
        initialSection: uri.queryParameters['section'],
      ),
      RutasAplicacion.settings => const ConfiguracionView(),
      _ => const InicioView(),
    };

    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, animation, _) =>
          _RouteAccess(path: uri?.path ?? '', child: page),
      transitionsBuilder: (_, _, _, child) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  /// Cambia de página sin hacer nada si la ruta ya está seleccionada.
  static void go(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;

    final navigator = Navigator.of(context);

    // Si ya existe en el stack, se vuelve a esa instancia conservando su
    // estado local y sin mostrar una nueva carga.
    if (observer.contains(navigator, route)) {
      navigator.popUntil((candidate) => candidate.settings.name == route);
      return;
    }

    final nextRoute = onGenerateRoute(RouteSettings(name: route));

    // Las vistas nuevas se agregan al stack para que permanezcan disponibles
    // en memoria. Como la ruta no tiene duración de transición, el cambio es
    // inmediato y no produce el efecto de una animación entre páginas.
    navigator.push(nextRoute);
  }
}

/// También protege vistas conservadas en memoria después de cerrar sesión.
class _RouteAccess extends StatelessWidget {
  const _RouteAccess({required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AplicacionController.instance,
    builder: (_, _) {
      final store = AplicacionController.instance;
      final admin =
          path.startsWith('/admin/') ||
          [
            RutasAplicacion.dashboard,
            RutasAplicacion.user,
            RutasAplicacion.settings,
          ].contains(path);
      final private =
          admin ||
          path.startsWith('/profile') ||
          path == RutasAplicacion.messages;
      if (!private) {
        return path == RutasAplicacion.course
            ? KeyedSubtree(key: ValueKey(store.sessionEpoch), child: child)
            : child;
      }
      var allowed = store.currentUser != null;
      if (admin) allowed = allowed && store.isAdmin;
      if ([
        RutasAplicacion.user,
        RutasAplicacion.adminCatalogs,
        RutasAplicacion.adminAudit,
        RutasAplicacion.adminCommerce,
        RutasAplicacion.adminConversations,
        RutasAplicacion.adminCourseConversations,
        RutasAplicacion.adminMarketConversations,
      ].contains(path)) {
        allowed = allowed && store.isAdministrator;
      }
      if (path == RutasAplicacion.adminAccreditation) {
        allowed = allowed && store.canReview;
      }
      if (path.startsWith('/admin/tutors/')) {
        allowed = allowed && store.canReview;
      }
      if (path.startsWith('/admin/training/') ||
          path == RutasAplicacion.adminMarketUpdates ||
          path == RutasAplicacion.adminPeerReviews ||
          path == RutasAplicacion.adminSupport) {
        allowed = allowed && store.canModerate;
      }
      if ([
        RutasAplicacion.adminTrainingAreas,
        RutasAplicacion.adminMarketCategories,
      ].contains(path)) {
        allowed = allowed && store.isAdministrator;
      }
      if ([
        RutasAplicacion.adminMarket,
        RutasAplicacion.adminTutorials,
        RutasAplicacion.adminReports,
      ].contains(path)) {
        allowed = allowed && store.canModerate;
      }
      final pending =
          store.currentUser != null &&
          !store.currentUser!.verified &&
          ![
            RutasAplicacion.profile,
            RutasAplicacion.adminProfile,
          ].contains(path);
      if (allowed && !pending) {
        return KeyedSubtree(key: ValueKey(store.sessionEpoch), child: child);
      }
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: TarjetaSuave(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 36),
                  const SizedBox(height: 16),
                  Text(
                    pending
                        ? 'Verifica tu correo para continuar.'
                        : 'Inicia sesión con una cuenta autorizada.',
                  ),
                  TextButton(
                    onPressed: () => NavegadorAplicacion.go(
                      context,
                      pending
                          ? RutasAplicacion.verifyEmail
                          : admin
                          ? RutasAplicacion.adminLogin
                          : RutasAplicacion.login,
                    ),
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
