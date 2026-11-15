import 'package:flutter/material.dart';
import 'package:unired/core/utils/app_navigator.dart';

enum AccountSection {
  profile('data', 'Mi perfil', Icons.person_outline),
  learning('learning', 'Mi aprendizaje', Icons.school_outlined),
  products('products', 'Mis artículos', Icons.storefront_outlined),
  tutorials('tutorials', 'Mis tutorías', Icons.video_library_outlined),
  favorites('favorites', 'Favoritos', Icons.favorite_border),
  preferences('preferences', 'Ajustes', Icons.tune_rounded),
  security('security', 'Seguridad y sesiones', Icons.shield_outlined),
  edit('edit', 'Editar perfil', Icons.edit_outlined);

  const AccountSection(this.tab, this.label, this.icon);
  final String tab;
  final String label;
  final IconData icon;

  static AccountSection fromTab(String tab) =>
      values.where((section) => section.tab == tab).firstOrNull ?? profile;

  String route({bool asAdmin = false}) {
    final base = asAdmin ? AppRoutes.adminProfile : AppRoutes.profile;
    return this == profile ? base : '$base?tab=$tab';
  }
}
