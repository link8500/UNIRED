// Archivo: lib/models/administracion/models/modulos_administracion.dart
// Centraliza la definición y agrupación de los apartados del panel administrativo.

import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';

/// Mapa funcional del backoffice. Cada pestaña tiene URL y datos propios.
class PestanaModuloAdmin {
  const PestanaModuloAdmin(this.label, this.route);
  final String label;
  final String route;
}

class ModulosAdministracion {
  static const tutors = [
    PestanaModuloAdmin(
      'Solicitudes de tutor',
      RutasAplicacion.adminApplications,
    ),
    PestanaModuloAdmin('Tutores autorizados', RutasAplicacion.adminTutors),
    PestanaModuloAdmin(
      'Próximos vencimientos',
      RutasAplicacion.adminExpiringTutors,
    ),
    PestanaModuloAdmin(
      'Historial de solicitudes',
      RutasAplicacion.adminTutorHistory,
    ),
  ];
  static const training = [
    PestanaModuloAdmin('Catálogo de cursos', RutasAplicacion.adminTutorials),
    PestanaModuloAdmin('Sesiones en vivo', RutasAplicacion.adminSessions),
    PestanaModuloAdmin('Participación', RutasAplicacion.adminParticipation),
    PestanaModuloAdmin('Reseñas', RutasAplicacion.adminReviews),
    PestanaModuloAdmin(
      'Áreas de enseñanza',
      RutasAplicacion.adminTrainingAreas,
    ),
    PestanaModuloAdmin(
      'Conversaciones',
      RutasAplicacion.adminCourseConversations,
    ),
  ];
  static const marketplace = [
    PestanaModuloAdmin('Anuncios', RutasAplicacion.adminMarket),
    PestanaModuloAdmin('Actualizaciones', RutasAplicacion.adminMarketUpdates),
    PestanaModuloAdmin('Categorías', RutasAplicacion.adminMarketCategories),
    PestanaModuloAdmin(
      'Conversaciones',
      RutasAplicacion.adminMarketConversations,
    ),
  ];
  static const support = [
    PestanaModuloAdmin('Casos abiertos', RutasAplicacion.adminSupport),
    PestanaModuloAdmin(
      'Valoraciones entre usuarios',
      RutasAplicacion.adminPeerReviews,
    ),
    PestanaModuloAdmin(
      'En revisión',
      '${RutasAplicacion.adminSupport}?state=en_revision',
    ),
    PestanaModuloAdmin(
      'Historial de casos',
      '${RutasAplicacion.adminSupport}?state=resuelta',
    ),
  ];
  static const users = [
    PestanaModuloAdmin('Directorio', RutasAplicacion.user),
    PestanaModuloAdmin('Roles y acceso', '${RutasAplicacion.user}?view=access'),
  ];
  static const configuration = [
    PestanaModuloAdmin('Catálogos', RutasAplicacion.adminCatalogs),
    PestanaModuloAdmin('Auditoría', RutasAplicacion.adminAudit),
    PestanaModuloAdmin('Preferencias', RutasAplicacion.settings),
  ];
  static List<PestanaModuloAdmin> tabs(String current) {
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
