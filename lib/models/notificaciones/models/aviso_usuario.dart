// Archivo: lib/models/notificaciones/models/aviso_usuario.dart
// Representa una notificación recibida de la API y su estado de lectura.

/// Notificación recibida de la API, con su identificador y estado de lectura.
class AvisoUsuario {
  const AvisoUsuario({
    required this.id,
    required this.title,
    required this.message,
    required this.ownerId,
    this.read = false,
  });
  final String id;
  final String title;
  final String message;
  final String ownerId;
  final bool read;
}
