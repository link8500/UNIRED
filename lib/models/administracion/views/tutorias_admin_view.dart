// Archivo: lib/models/administracion/views/tutorias_admin_view.dart
// Presenta la gestión y revisión administrativa de cursos y tutorías.

import 'package:flutter/material.dart';
import 'package:unired/models/administracion/widgets/moderacion_view.dart';

class TutoriasAdminView extends StatelessWidget {
  const TutoriasAdminView({super.key, this.ownerId});
  final String? ownerId;
  @override
  Widget build(BuildContext context) =>
      ModeracionView(tutorials: true, ownerId: ownerId);
}
