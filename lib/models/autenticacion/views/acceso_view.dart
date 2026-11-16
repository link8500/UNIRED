// Archivo: lib/models/autenticacion/views/acceso_view.dart
// Compone la pantalla de inicio de sesión de los usuarios.

import 'package:flutter/material.dart';
import 'package:unired/models/autenticacion/views/estructura_autenticacion.dart';
import 'package:unired/models/autenticacion/widgets/formulario_acceso.dart';

class AccesoView extends StatelessWidget {
  const AccesoView({super.key});
  @override
  Widget build(BuildContext context) => const EstructuraAutenticacion(
    isRegister: false,
    form: FormularioAcceso(),
  );
}
