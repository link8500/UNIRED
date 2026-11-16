// Archivo: lib/core/utilidades/formato_presentacion.dart
// Formatea cantidades, fechas y otros valores recibidos de la API para presentarlos en pantalla.

/// Duración breve compartida por las lecciones del catálogo y del temario.
String lessonDuration(Object? seconds) {
  final value = num.tryParse(seconds?.toString() ?? '')?.toInt() ?? 0;
  return '${value ~/ 60}:${(value % 60).toString().padLeft(2, '0')}';
}

/// La API guarda fechas UTC; la interfaz usa la hora local del dispositivo.
String localDateTime(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return 'Sin fecha';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
}
