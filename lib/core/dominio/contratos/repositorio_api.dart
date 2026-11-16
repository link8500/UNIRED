// Archivo: lib/core/dominio/contratos/repositorio_api.dart
// Contrato de consulta consumido por los casos de uso; evita que conozcan Dio.

import 'package:unired/core/dominio/datos_api.dart';

/// Puerto de consulta para casos de uso. No conoce Dio, widgets ni el navegador.
abstract interface class RepositorioApi {
  Future<Json> object(
    String path, {
    String method = 'GET',
    Object? data,
    Json? query,
    bool authenticated = true,
    bool foreground = true,
  });
}
