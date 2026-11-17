@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:unired/core/datos/remoto/navegador_social.dart';

void main() {
  test(
    'navegador social web: conserva el intento al reconstruir la app y lo borra al terminar',
    () {
      final browser = crearNavegadorSocial();
      addTearDown(browser.limpiar);
      browser.guardar({'verificador': 'verificador-ficticio', 'creadoEn': 1});
      expect(
        crearNavegadorSocial().leer()?['verificador'],
        'verificador-ficticio',
      );
      expect(
        web.window.localStorage.getItem('unired.acceso-social.temporal'),
        isNull,
      );
      browser.limpiar();
      expect(crearNavegadorSocial().leer(), isNull);
    },
  );
  test(
    'navegador social web: retira el código efímero de la dirección sin recargar',
    () {
      final original = web.window.location.href;
      addTearDown(() => web.window.history.replaceState(null, '', original));
      web.window.history.replaceState(null, '', '#/auth/social?codigo=efimero');
      crearNavegadorSocial().limpiarRetorno();
      expect(web.window.location.hash, '#/auth/social');
      expect(web.window.location.href.contains('efimero'), false);
    },
  );
}
