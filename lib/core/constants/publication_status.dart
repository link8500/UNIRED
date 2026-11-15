/// Ciclo de vida compartido por productos y tutorías locales.
enum PublicationStatus {
  published('Publicado'),
  draft('Borrador'),
  archived('Archivado'),
  paused('Pausado'),
  reserved('Reservado'),
  sold('Vendido'),
  blocked('Bloqueado');

  const PublicationStatus(this.label);
  final String label;

  static PublicationStatus fromApi(Object? value) => switch (value) {
    'publicado' || 'publicada' => published,
    'archivado' || 'archivada' => archived,
    'pausada' => paused,
    'reservado' => reserved,
    'vendido' => sold,
    'bloqueado' || 'bloqueada' => blocked,
    _ => draft,
  };
}
