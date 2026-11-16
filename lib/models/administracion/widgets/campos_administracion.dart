// Archivo: lib/models/administracion/widgets/campos_administracion.dart
// Define los campos de formularios usados por las vistas de administración.

import 'package:flutter/material.dart';

/// Campo compacto para el acceso administrativo.
class CampoAdmin extends StatelessWidget {
  const CampoAdmin({
    super.key,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.controller,
    this.validator,
    this.textInputAction,
    this.suffixIcon,
  });

  final String label;
  final IconData icon;
  final bool obscure;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 16),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 11),
    );
  }
}
