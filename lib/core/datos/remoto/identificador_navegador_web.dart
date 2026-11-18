import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

const _key = 'unired.navegador.v1';
final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// ID aleatorio de este sitio y perfil de navegador. No contiene credenciales.
String? leerIdentificadorNavegador() {
  try {
    final storage = web.window.localStorage;
    final saved = storage.getItem(_key);
    if (saved != null && _uuidV4.hasMatch(saved)) return saved;
    final id = const Uuid().v4();
    storage.setItem(_key, id);
    return id;
  } catch (_) {
    // No impide iniciar sesión cuando el navegador bloquea el almacenamiento.
    return null;
  }
}
