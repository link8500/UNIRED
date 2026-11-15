import 'package:flutter/material.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// La leyenda se coloca sobre los botones cuando no caben en la misma fila.
class PublicationStepNavigation extends StatelessWidget {
  const PublicationStepNavigation({
    super.key,
    required this.label,
    this.previous,
    this.next,
    this.nextLabel = 'Siguiente',
    this.enabled = true,
  });
  final String label;
  final VoidCallback? previous, next;
  final String nextLabel;
  final bool enabled;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final caption = Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      );
      final nextButton = FilledButton(
        onPressed: enabled ? next : null,
        child: Text(nextLabel, textAlign: TextAlign.center),
      );
      final actions = Row(
        children: [
          if (previous != null)
            TextButton(
              onPressed: enabled ? previous : null,
              child: const Text('Anterior'),
            ),
          if (size.maxWidth >= 480)
            Expanded(child: caption)
          else if (next != null)
            const SizedBox(width: 12)
          else
            const Spacer(),
          if (next != null)
            if (size.maxWidth < 480)
              Expanded(child: nextButton)
            else
              nextButton,
        ],
      );
      return size.maxWidth >= 480
          ? actions
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [caption, const SizedBox(height: 4), actions],
            );
    },
  );
}
