// Archivo: lib/models/perfil/widgets/widgets_perfil.dart
// Filas informativas y estados vacíos reutilizados dentro de las pantallas de perfil.

import 'package:flutter/material.dart';

import 'package:unired/shared/temas/colores_aplicacion.dart';

/// Fila de información reutilizable para el perfil del estudiante.
class FilaInformacionPerfil extends StatelessWidget {
  const FilaInformacionPerfil({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: ColoresAplicacion.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w800,
                    color: ColoresAplicacion.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ColoresAplicacion.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta vacía para listas sin favoritos.
class EstadoPerfilVacio extends StatelessWidget {
  const EstadoPerfilVacio({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            size: 36,
            color: ColoresAplicacion.coral,
          ),
          const SizedBox(height: 9),
          const Text(
            'Todavía no tienes favoritos',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ColoresAplicacion.navy,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Guarda productos que quieras revisar después.',
            style: TextStyle(fontSize: 11, color: ColoresAplicacion.muted),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Explorar Market'),
          ),
        ],
      ),
    );
  }
}
