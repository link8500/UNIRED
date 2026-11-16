// Archivo: lib/core/constantes/limites_archivos.dart
// Centraliza los límites de imágenes, vídeos y documentos, incluidos los límites del navegador.

import 'package:flutter/foundation.dart';

/// Límites de presentación; NestJS vuelve a validar su configuración real.
/// Dio Web reúne el multipart antes de enviarlo: se limita el video en la web
/// para evitar reservar varios GiB en RAM. El cliente nativo usa el flujo.
abstract final class LimitesArchivos {
  static const image = 10 * 1024 * 1024;
  static const document = 20 * 1024 * 1024;
  static const video = 1024 * 1024 * 1024;
  static const webVideo = 128 * 1024 * 1024;
  static int forSelection(String purpose, String name, {bool web = kIsWeb}) =>
      purpose == 'video_leccion' ||
          (purpose == 'galeria_curso' &&
              RegExp(r'\.(mp4|webm)$', caseSensitive: false).hasMatch(name))
      ? (web ? webVideo : video)
      : RegExp(r'\.(pdf|zip)$', caseSensitive: false).hasMatch(name)
      ? document
      : image;
}
