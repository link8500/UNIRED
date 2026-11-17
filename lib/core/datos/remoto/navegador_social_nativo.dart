import 'package:unired/core/dominio/contratos/navegador_social.dart';
import 'package:unired/core/dominio/datos_api.dart';

NavegadorSocial crearNavegadorSocial() => _NavegadorNoWeb();

class _NavegadorNoWeb implements NavegadorSocial {
  @override
  bool get disponible => false;
  @override
  String get origen => '';
  @override
  Json? leer() => null;
  @override
  void limpiar() {}
  @override
  void limpiarRetorno() {}
  @override
  void guardar(Json intento) => throw UnsupportedError(
    'Usa la versión web para continuar con Google o Facebook.',
  );
  @override
  void redirigir(Uri destino) =>
      throw UnsupportedError('Este acceso está disponible en la versión web.');
}
