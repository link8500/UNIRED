import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/brand_logo.dart';

/// Título común para los formularios de Login y Registro.
class AuthTitle extends StatelessWidget {
  const AuthTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandLogo(compact: true),
        const SizedBox(height: 28),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Campo de formulario con la misma etiqueta, espaciado y decoración.
class AuthField extends StatelessWidget {
  const AuthField({
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
            color: AppColors.navy,
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
class AuthSwitch extends StatelessWidget {
  const AuthSwitch({
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
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 5)),
          child: Text(
            action,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
