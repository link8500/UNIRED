// Archivo: lib/core/aplicacion/publicaciones_use_cases.dart
// Coordina la consulta y el guardado de anuncios o cursos y la solicitud de acceso a una tutoría.

import 'package:unired/core/dominio/contratos/repositorio_api.dart';
import 'package:unired/core/dominio/datos_api.dart';

/// Coordina publicaciones y solicitudes de acceso sin depender de la interfaz.
/// NestJS conserva la validación, los permisos y la decisión de aceptar alumnos.
class PublicacionesUseCases {
  const PublicacionesUseCases(this.repositorio);
  final RepositorioApi repositorio;

  Future<Json> consultar(bool tutoria, String id, {bool propia = false}) =>
      repositorio.object(
        '${propia ? '/me' : ''}/${tutoria ? 'courses' : 'listings'}/$id',
      );

  Future<Json> guardar(bool tutoria, Json datos, {String? id}) {
    final ruta = '/me/${tutoria ? 'courses' : 'listings'}';
    return repositorio.object(
      '$ruta${id == null ? '' : '/$id'}',
      method: id == null ? 'POST' : 'PATCH',
      data: datos,
    );
  }

  Future<Json> solicitarAcceso(String cursoId) =>
      repositorio.object('/courses/$cursoId/enrollments', method: 'POST');
}
