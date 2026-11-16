// Archivo: lib/models/tutorias/views/tutorias_view.dart
// Muestra el catálogo de tutorías y cursos publicados.

import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/catalogo_remoto.dart';

class TutoriasView extends StatelessWidget {
  const TutoriasView({super.key});
  @override
  Widget build(BuildContext context) => const CatalogoRemoto(tutorials: true);
}
