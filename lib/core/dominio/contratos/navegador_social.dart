// Puerto del navegador. Los JWT siguen solo en memoria; aquí solo hay un reto temporal.
import 'package:unired/core/dominio/datos_api.dart';

abstract interface class NavegadorSocial {
  bool get disponible;
  String get origen;
  void guardar(Json intento);
  Json? leer();
  void limpiar();
  void redirigir(Uri destino);
  void limpiarRetorno();
}
