// Archivo: lib/models/tutorias/widgets/detalles_tutoria.dart
// Abre la ficha real de una tutoría mediante el navegador centralizado, conservando el identificador del curso.

import 'package:flutter/material.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/tutorias/models/tutoria.dart';

/// Abre una página real con currículo, inscripción y contenido autorizado.
void showTutorialDetails(BuildContext context, Tutoria item) =>
    NavegadorAplicacion.go(context, '${RutasAplicacion.course}?id=${item.id}');
