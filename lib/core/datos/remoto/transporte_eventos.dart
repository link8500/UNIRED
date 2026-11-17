// Archivo: lib/core/datos/remoto/transporte_eventos.dart
// Selecciona el transporte incremental de eventos disponible en la plataforma.
export 'transporte_eventos_io.dart'
    if (dart.library.js_interop) 'transporte_eventos_web.dart';
