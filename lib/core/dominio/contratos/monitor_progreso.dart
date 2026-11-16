// Archivo: lib/core/dominio/contratos/monitor_progreso.dart
// Contrato que permite informar de operaciones pendientes sin depender de un widget de Flutter.

/// Contrato sin Flutter para informar el comienzo y final de solicitudes reales.
/// La implementación visual se inyecta desde el controlador de la aplicación.
abstract interface class MonitorProgreso {
  int begin();
  void complete(int operation);
}
