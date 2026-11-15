import 'package:flutter/material.dart';
import 'package:unired/shared/themes/app_colors.dart';

class CampusCover extends StatelessWidget {
  const CampusCover({super.key});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/profile-cover.webp',
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.surfaceBlue),
  );
}
