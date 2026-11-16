import 'dart:io';

/// Verificación local y de CI de las fronteras del núcleo de Flutter.
/// Los casos de uso y contratos no pueden importar widgets, Dio ni módulos UI.
void main() {
  var revisados = 0;
  final importacion = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''');
  for (final archivo in Directory('lib/core').listSync(recursive: true)) {
    if (archivo is! File || !archivo.path.endsWith('.dart')) continue;
    revisados++;
    final ruta = archivo.path.replaceAll('\\', '/');
    final puro = ruta.contains('/dominio/') || ruta.contains('/aplicacion/');
    for (final coincidencia in importacion.allMatches(
      archivo.readAsStringSync(),
    )) {
      final destino = coincidencia.group(1)!;
      final moduloVisual =
          destino.contains('package:unired/models/') ||
          destino.contains('package:unired/shared/');
      final detalleExterno =
          puro &&
          (destino.startsWith('package:flutter/') ||
              destino.startsWith('package:dio/') ||
              destino.contains('core/datos/'));
      if (moduloVisual || detalleExterno) {
        throw StateError('Dependencia invertida: $ruta -> $destino');
      }
    }
  }
  stdout.writeln(
    'OK: $revisados archivos de core con dependencias permitidas.',
  );
}
