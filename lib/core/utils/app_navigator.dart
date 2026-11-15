import 'package:flutter/material.dart';
import 'package:unired/models/auth/views/account_access_page.dart';
import 'package:unired/models/market/views/listing_details_page.dart';
import 'package:unired/models/messaging/views/messages_page.dart';
import 'package:unired/models/accreditation/views/accreditation_page.dart';
import 'package:unired/models/tutorials/views/course_page.dart';
import 'package:unired/models/admin/views/catalogs_page.dart';
import 'package:unired/models/admin/views/operations_page.dart';
import 'package:unired/models/admin/views/workspace_page.dart';
import 'package:unired/models/admin/views/course_inspection_page.dart';
import 'package:unired/models/admin/views/conversation_review_page.dart';
import 'package:unired/models/profile/views/files_page.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/shared/widgets/page_frame.dart';

import 'package:unired/models/about/views/about_page.dart';
import 'package:unired/models/admin/views/admin_login_page.dart';
import 'package:unired/models/admin/views/dashboard_page.dart';
import 'package:unired/models/admin/views/admin_market_page.dart';
import 'package:unired/models/admin/views/admin_tutorials_page.dart';
import 'package:unired/models/admin/views/publication_page.dart';
import 'package:unired/models/auth/views/login_page.dart';
import 'package:unired/models/auth/views/register_page.dart';
import 'package:unired/models/home/views/home_page.dart';
import 'package:unired/models/market/views/market_page.dart';
import 'package:unired/models/profile/views/profile_page.dart';
import 'package:unired/models/profile/views/public_member_page.dart';
import 'package:unired/models/settings/views/settings_page.dart';
import 'package:unired/models/tutorials/views/tutorials_page.dart';
import 'package:unired/models/user/views/user_page.dart';

/// Rutas declaradas en un solo sitio para evitar strings repetidos.
class AppRoutes {
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
  static String myPublications(bool tutorial) =>
      '$profile?tab=${tutorial ? 'tutorials' : 'products'}';
}

/// Observa las rutas para saber cuáles ya fueron abiertas y siguen en el
/// stack. Así, al volver a una pantalla existente, Flutter conserva su
/// instancia y su estado en memoria.
class AppNavigationObserver extends NavigatorObserver {
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
class AppNavigator {
  /// Observador que mantiene localizadas las rutas que siguen en memoria.
  static final observer = AppNavigationObserver();
  static final visibilityObserver = RouteObserver<PageRoute<dynamic>>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? AppRoutes.home);
    final page = switch (uri?.path) {
      AppRoutes.login => const LoginPage(),
      AppRoutes.register => const RegisterPage(),
      AppRoutes.verifyEmail => AccountAccessPage(
        token: uri?.queryParameters['token'] ?? '',
      ),
      AppRoutes.recover => AccountAccessPage(
        recovery: true,
        token: uri?.queryParameters['token'] ?? '',
      ),
      AppRoutes.listing => ListingDetailsPage(
        id: uri?.queryParameters['id'] ?? '',
      ),
      AppRoutes.messages || AppRoutes.adminMessages => MessagesPage(
        id: uri?.queryParameters['id'],
        asAdmin: uri?.path == AppRoutes.adminMessages,
      ),
      AppRoutes.adminConversations || AppRoutes.adminCourseConversations || AppRoutes.adminMarketConversations => ConversationReviewPage(kind: uri?.path==AppRoutes.adminCourseConversations?'tutoria':uri?.path==AppRoutes.adminMarketConversations?'market':'',userId:uri?.queryParameters['user']),
      AppRoutes.adminOwnMarket || AppRoutes.adminOwnCourses => ProfilePage(
        asAdmin: true,
        initialTab: uri?.path == AppRoutes.adminOwnCourses
            ? 'tutorials'
            : 'products',
      ),
      AppRoutes.accreditation => const AccreditationPage(),
      AppRoutes.adminOwnAccreditation => const AccreditationPage(asAdmin: true),
      AppRoutes.adminAccreditation || AppRoutes.adminApplications =>
        const WorkspacePage(section: 'applications'),
      AppRoutes.adminTutors => const WorkspacePage(section: 'tutors'),
      AppRoutes.adminExpiringTutors => const WorkspacePage(
        section: 'tutors',
        view: 'expiring',
      ),
      AppRoutes.adminTutorHistory => const WorkspacePage(
        section: 'applications',
        view: 'history',
      ),
      AppRoutes.adminSessions => const WorkspacePage(section: 'sessions'),
      AppRoutes.adminParticipation => const WorkspacePage(
        section: 'participation',
      ),
      AppRoutes.adminReviews => const WorkspacePage(section: 'reviews'),
      AppRoutes.adminMarketUpdates => const WorkspacePage(
        section: 'market-updates',
      ),
      AppRoutes.adminTrainingAreas => const CatalogsPage(
        initialAreas: true,
        route: AppRoutes.adminTrainingAreas,
      ),
      AppRoutes.adminMarketCategories => const CatalogsPage(
        initialAreas: false,
        route: AppRoutes.adminMarketCategories,
      ),
      AppRoutes.adminCatalogs => const CatalogsPage(),
      AppRoutes.adminReports => const OperationsPage(),
      AppRoutes.adminSupport => OperationsPage(
        initialState: uri?.queryParameters['state'] ?? 'pendiente',
      ),
      AppRoutes.adminAudit => const OperationsPage(audit: true),
      AppRoutes.files || AppRoutes.adminFiles => FilesPage(
        asAdmin: uri?.path == AppRoutes.adminFiles,
      ),
      AppRoutes.course => CoursePage(
        id: uri?.queryParameters['id'] ?? '',
        manage: uri?.queryParameters['manage'] == '1',
        classroom: uri?.queryParameters['aula'] == '1',
        initialLesson: uri?.queryParameters['lesson'],
      ),
      AppRoutes.market => const MarketPage(),
      AppRoutes.tutorials => const TutorialsPage(),
      AppRoutes.about => const AboutPage(),
      AppRoutes.adminLogin => const AdminLoginPage(),
      AppRoutes.dashboard => const DashboardPage(),
      AppRoutes.adminMarket => AdminMarketPage(
        ownerId: uri?.queryParameters['owner'],
      ),
      AppRoutes.adminTutorials =>
        uri?.queryParameters['inspect'] != null
            ? CourseInspectionPage(id: uri!.queryParameters['inspect']!)
            : AdminTutorialsPage(ownerId: uri?.queryParameters['owner']),
      AppRoutes.user => UserPage(
        accessView: uri?.queryParameters['view'] == 'access',
      ),
      AppRoutes.profile => ProfilePage(
        initialTab: uri?.queryParameters['tab'] ?? 'data',
      ),
      AppRoutes.member => PublicMemberPage(
        id: uri?.queryParameters['id'] ?? '',
      ),
      AppRoutes.adminProfile => ProfilePage(
        asAdmin: true,
        initialTab: uri?.queryParameters['tab'] ?? 'data',
      ),
      AppRoutes.adminProduct ||
      AppRoutes.adminTutorial ||
      AppRoutes.myProduct ||
      AppRoutes.myTutorial => PublicationPage(
        isTutorial:
            uri!.path == AppRoutes.adminTutorial ||
            uri.path == AppRoutes.myTutorial,
        asAdmin: uri.path.startsWith('/admin/'),
        id: uri.queryParameters['id'],
        initiallyEditing: uri.queryParameters['edit'] == '1',
        initialSection: uri.queryParameters['section'],
      ),
      AppRoutes.settings => const SettingsPage(),
      _ => const HomePage(),
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
    animation: AppService.instance,
    builder: (_, _) {
      final store = AppService.instance;
      final admin =
          path.startsWith('/admin/') ||
          [
            AppRoutes.dashboard,
            AppRoutes.user,
            AppRoutes.settings,
          ].contains(path);
      final private =
          admin || path.startsWith('/profile') || path == AppRoutes.messages;
      if (!private) {
        return path == AppRoutes.course
            ? KeyedSubtree(key: ValueKey(store.sessionEpoch), child: child)
            : child;
      }
      var allowed = store.currentUser != null;
      if (admin) allowed = allowed && store.isAdmin;
      if ([
        AppRoutes.user,
        AppRoutes.adminCatalogs,
        AppRoutes.adminAudit,
        AppRoutes.adminConversations,
        AppRoutes.adminCourseConversations,
        AppRoutes.adminMarketConversations,
      ].contains(path)) {
        allowed = allowed && store.isAdministrator;
      }
      if (path == AppRoutes.adminAccreditation) {
        allowed = allowed && store.canReview;
      }
      if (path.startsWith('/admin/tutors/')) {
        allowed = allowed && store.canReview;
      }
      if (path.startsWith('/admin/training/') ||
          path == AppRoutes.adminMarketUpdates ||
          path == AppRoutes.adminSupport) {
        allowed = allowed && store.canModerate;
      }
      if ([
        AppRoutes.adminTrainingAreas,
        AppRoutes.adminMarketCategories,
      ].contains(path)) {
        allowed = allowed && store.isAdministrator;
      }
      if ([
        AppRoutes.adminMarket,
        AppRoutes.adminTutorials,
        AppRoutes.adminReports,
      ].contains(path)) {
        allowed = allowed && store.canModerate;
      }
      final pending =
          store.currentUser != null &&
          !store.currentUser!.verified &&
          ![AppRoutes.profile, AppRoutes.adminProfile].contains(path);
      if (allowed && !pending) {
        return KeyedSubtree(key: ValueKey(store.sessionEpoch), child: child);
      }
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SoftCard(
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
                    onPressed: () => AppNavigator.go(
                      context,
                      pending
                          ? AppRoutes.verifyEmail
                          : admin
                          ? AppRoutes.adminLogin
                          : AppRoutes.login,
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
