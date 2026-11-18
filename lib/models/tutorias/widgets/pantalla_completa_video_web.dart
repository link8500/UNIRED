import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Sale del modo nativo solo si esta instancia lo activó.
class PantallaCompletaVideo {
  Future<void>? _request;
  JSFunction? _listener;
  bool _entered = false;

  void entrar(void Function() onExit) {
    final document = web.document;
    final root = document.documentElement;
    if (root == null ||
        !document.fullscreenEnabled ||
        document.fullscreenElement != null ||
        _request != null) {
      return;
    }
    final listener = ((web.Event _) {
      if (document.fullscreenElement == root) {
        _entered = true;
      } else if (_entered) {
        _entered = false;
        onExit();
      }
    }).toJS;
    _listener = listener;
    document.addEventListener('fullscreenchange', listener);
    // Debe invocarse directamente desde el toque o clic, antes de cualquier await.
    try {
      _request = root.requestFullscreen().toDart.then<void>(
        (_) => _entered = document.fullscreenElement == root,
        onError: (Object _, StackTrace _) => _removeListener(),
      );
    } catch (_) {
      _removeListener(); // El diálogo sigue disponible si el navegador lo bloquea.
    }
  }

  void _removeListener() {
    final listener = _listener;
    if (listener == null) return;
    web.document.removeEventListener('fullscreenchange', listener);
    _listener = null;
  }

  Future<void> salir() async {
    _removeListener();
    await _request;
    final document = web.document;
    if (!_entered || document.fullscreenElement != document.documentElement) {
      return;
    }
    _entered = false;
    try {
      await document.exitFullscreen().toDart;
    } catch (_) {
      // Escape o el sistema pueden haber salido en paralelo.
    }
  }
}
