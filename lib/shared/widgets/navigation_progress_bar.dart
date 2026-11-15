import 'package:flutter/material.dart';

import 'package:unired/core/utils/navigation_progress_controller.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// Overlay superior estilo web para mostrar el progreso de navegación.
class NavigationProgressBar extends StatelessWidget {
  const NavigationProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NavigationProgressController.instance;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return AnimatedOpacity(
            opacity: controller.visible ? 1 : 0,
            duration: const Duration(milliseconds: 90),
            child: LinearProgressIndicator(
              value: controller.value,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.coral),
            ),
          );
        },
      ),
    );
  }
}
