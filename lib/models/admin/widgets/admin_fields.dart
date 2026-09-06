import 'package:flutter/material.dart';

/// Campo compacto para el acceso administrativo.
class AdminField extends StatelessWidget {
  const AdminField({
    super.key,
    required this.label,
    required this.icon,
    this.obscure = false,
  });

  final String label;
  final IconData icon;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 11),
    );
  }
}
