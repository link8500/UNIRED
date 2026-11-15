import 'package:flutter/material.dart';

import 'package:unired/shared/themes/app_colors.dart';

/// Botón principal coral compartido por los formularios y llamadas a la acción.
class CoralButton extends StatelessWidget {
  const CoralButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 17),
      label: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botón de acceso social con la marca visual de Google.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, this.onPressed, this.expand = false});

  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Text(
        'G',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
        ),
      ),
      label: const Text('Continuar con Google'),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botón social genérico para las opciones decorativas del acceso.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 238,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: AppColors.coral),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .92),
          foregroundColor: AppColors.coralDark,
          side: BorderSide.none,
          minimumSize: const Size(0, 38),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
