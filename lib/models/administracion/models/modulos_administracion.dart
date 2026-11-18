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
      'Expedientes de acreditación',
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
  static const profile = [
    PestanaModuloAdmin('Mi perfil', RutasAplicacion.adminProfile),
    PestanaModuloAdmin(
      'Editar perfil',
      '${RutasAplicacion.adminProfile}?tab=edit',
    ),
    PestanaModuloAdmin(
      'Seguridad y sesiones',
      '${RutasAplicacion.adminProfile}?tab=security',
    ),
    PestanaModuloAdmin(
      'Preferencias',
      '${RutasAplicacion.adminProfile}?tab=preferences',
    ),
  ];
  static List<PestanaModuloAdmin> tabs(String current) {
    final path = Uri.tryParse(current)?.path ?? current;
    if (path == RutasAplicacion.adminAccreditation) return tutors;
    for (final group in [
      tutors,
      training,
      marketplace,
      support,
      users,
      configuration,
      profile,
    ]) {
      if (group.any((tab) => tab.route == current || tab.route == path)) {
        return group;
      }
    }
    return const [];
  }
}
