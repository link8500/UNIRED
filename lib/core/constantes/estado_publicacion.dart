// Archivo: lib/core/constantes/estado_publicacion.dart
// Representa los estados de un anuncio o curso y sus etiquetas de presentación.

/// Ciclo de vida compartido por productos y tutorías locales.
enum EstadoPublicacion {
  published('Publicado'),
  draft('Borrador'),
  archived('Archivado'),
  paused('Pausado'),
  reserved('Reservado'),
  sold('Vendido'),
  blocked('Bloqueado');

  const EstadoPublicacion(this.label);
  final String label;

  static EstadoPublicacion fromApi(Object? value) => switch (value) {
    'publicado' || 'publicada' => published,
    'archivado' || 'archivada' => archived,
    'pausada' => paused,
    'reservado' => reserved,
    'vendido' => sold,
    'bloqueado' || 'bloqueada' => blocked,
    _ => draft,
  };
}
