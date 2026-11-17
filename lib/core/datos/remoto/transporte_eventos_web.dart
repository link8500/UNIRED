// Archivo: lib/core/datos/remoto/transporte_eventos_web.dart
// Usa el progreso de XHR para leer SSE sin poner el JWT en la URL del navegador.
import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Stream<String> abrirEventos(Uri url, Map<String, String> headers) {
  final request = web.XMLHttpRequest();
  var offset = 0, closed = false;
  late StreamController<String> controller;
  void emit() {
    if (closed || request.status != 200) return;
    final text = request.responseText;
    if (text.length > offset) {
      controller.add(text.substring(offset));
      offset = text.length;
    }
  }

  void finish([Object? error]) {
    if (closed) return;
    if (error != null) controller.addError(error);
    closed = true;
    unawaited(controller.close());
  }

  controller = StreamController<String>(
    onListen: () {
      request.open('GET', url.toString());
      request.responseType = 'text';
      headers.forEach((name, value) => request.setRequestHeader(name, value));
      request.onprogress = ((web.Event _) => emit()).toJS;
      request.onload = ((web.Event _) {
        emit();
        finish(
          request.status == 200
              ? null
              : StateError('No se pudo abrir el canal de notificaciones.'),
        );
      }).toJS;
      request.onerror = ((web.Event _) => finish(
        StateError('Canal de notificaciones desconectado.'),
      )).toJS;
      request.onabort = ((web.Event _) => finish()).toJS;
      request.send();
    },
    onCancel: () {
      closed = true;
      request.abort();
    },
  );
  return controller.stream;
}
