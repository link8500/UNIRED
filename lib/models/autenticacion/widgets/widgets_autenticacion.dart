// Archivo: lib/models/autenticacion/widgets/widgets_autenticacion.dart
// Agrupa títulos, campos y enlaces visuales que comparten las pantallas de acceso.

import 'package:flutter/material.dart';

import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/logo_marca.dart';

/// Título común para los formularios de Login y Registro.
class TituloAutenticacion extends StatelessWidget {
  const TituloAutenticacion({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LogoMarca(compact: true),
        const SizedBox(height: 28),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Campo de formulario con la misma etiqueta, espaciado y decoración.
class CampoAutenticacion extends StatelessWidget {
  const CampoAutenticacion({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: ColoresAplicacion.navy,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon, size: 18),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Enlace inferior para alternar entre iniciar sesión y registrarse.
class AlternadorAutenticacion extends StatelessWidget {
  const AlternadorAutenticacion({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          question,
          style: const TextStyle(color: ColoresAplicacion.muted, fontSize: 12),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 5)),
          child: Text(
            action,
            style: const TextStyle(
              color: ColoresAplicacion.blue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
