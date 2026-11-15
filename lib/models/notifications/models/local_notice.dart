/// Aviso de esta sesión. No representa mensajes de un servidor.
class LocalNotice {
  const LocalNotice({
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
