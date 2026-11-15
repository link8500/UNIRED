import 'package:unired/core/utils/app_navigator.dart';

/// Mapa funcional del backoffice. Cada pestaña tiene URL y datos propios.
class AdminModuleTab {
  const AdminModuleTab(this.label, this.route);
  final String label;
  final String route;
}

class AdminModules {
  static const tutors = [
    AdminModuleTab('Solicitudes de tutor', AppRoutes.adminApplications),
    AdminModuleTab('Tutores autorizados', AppRoutes.adminTutors),
    AdminModuleTab('Próximos vencimientos', AppRoutes.adminExpiringTutors),
    AdminModuleTab('Historial de solicitudes', AppRoutes.adminTutorHistory),
  ];
  static const training = [
    AdminModuleTab('Catálogo de cursos', AppRoutes.adminTutorials),
    AdminModuleTab('Sesiones en vivo', AppRoutes.adminSessions),
    AdminModuleTab('Participación', AppRoutes.adminParticipation),
    AdminModuleTab('Reseñas', AppRoutes.adminReviews),
    AdminModuleTab('Áreas de enseñanza', AppRoutes.adminTrainingAreas),
    AdminModuleTab('Conversaciones', AppRoutes.adminCourseConversations),
  ];
  static const marketplace = [
    AdminModuleTab('Anuncios', AppRoutes.adminMarket),
    AdminModuleTab('Actualizaciones', AppRoutes.adminMarketUpdates),
    AdminModuleTab('Categorías', AppRoutes.adminMarketCategories),
    AdminModuleTab('Conversaciones', AppRoutes.adminMarketConversations),
  ];
  static const support = [
    AdminModuleTab('Casos abiertos', AppRoutes.adminSupport),
    AdminModuleTab(
      'En revisión',
      '${AppRoutes.adminSupport}?state=en_revision',
    ),
    AdminModuleTab(
      'Historial de casos',
      '${AppRoutes.adminSupport}?state=resuelta',
    ),
  ];
  static const users = [
    AdminModuleTab('Directorio', AppRoutes.user),
    AdminModuleTab('Roles y acceso', '${AppRoutes.user}?view=access'),
  ];
  static const configuration = [
    AdminModuleTab('Catálogos', AppRoutes.adminCatalogs),
    AdminModuleTab('Auditoría', AppRoutes.adminAudit),
    AdminModuleTab('Preferencias', AppRoutes.settings),
  ];
  static List<AdminModuleTab> tabs(String current) {
    const groups = [
      tutors,
      training,
      marketplace,
      support,
      users,
      configuration,
    ];
    for (final group in groups) {
      if (group.any((tab) => tab.route == current)) return group;
    }
    final path = Uri.tryParse(current)?.path;
    for (final group in groups) {
      if (group.any((tab) => tab.route == path)) return group;
    }
    return const [];
  }
}
