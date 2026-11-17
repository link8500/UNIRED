// Conserva únicamente el verificador PKCE durante la ida y vuelta al proveedor.
import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:unired/core/dominio/contratos/navegador_social.dart';
import 'package:unired/core/dominio/datos_api.dart';

NavegadorSocial crearNavegadorSocial() => _NavegadorWeb();

class _NavegadorWeb implements NavegadorSocial {
  static const _key = 'unired.acceso-social.temporal';
  @override
  bool get disponible => true;
  @override
  String get origen => web.window.location.origin;
  @override
  void guardar(Json intento) {
    try {
      web.window.sessionStorage.setItem(_key, jsonEncode(intento));
    } catch (_) {
      throw const FormatException(
        'Permite el almacenamiento de esta pestaña para continuar con el acceso social.',
      );
    }
  }

  @override
  Json? leer() {
    try {
      final raw = web.window.sessionStorage.getItem(_key);
      return raw == null ? null : jsonObject(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  void limpiar() {
    try {
      web.window.sessionStorage.removeItem(_key);
    } catch (_) {}
  }

  @override
  void redirigir(Uri destino) => web.window.location.assign(destino.toString());
  @override
  void limpiarRetorno() => web.window.history.replaceState(
    null,
    '',
    '${web.window.location.pathname}#/auth/social',
  );
}
