// Archivo: lib/core/datos/remoto/transporte_eventos_io.dart
// Recibe SSE mediante HTTP nativo y cierra la conexión al cancelar la escucha.
import 'dart:convert';
import 'dart:io';

Stream<String> abrirEventos(Uri url, Map<String, String> headers) async* {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(url);
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(const Duration(seconds: 75));
    if (response.statusCode != 200 ||
        response.headers.contentType?.mimeType != 'text/event-stream') {
      throw const HttpException('No se pudo abrir el canal de notificaciones.');
    }
    yield* response.transform(utf8.decoder);
  } finally {
    client.close(force: true);
  }
}
