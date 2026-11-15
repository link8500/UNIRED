import 'package:flutter/material.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// Un solo cálculo/presentación de precios para artículos y tutorías.
class PublicationPrice extends StatelessWidget {
  const PublicationPrice({
    super.key,
    required this.amount,
    this.discountPercent = 0,
    this.compact = false,
    this.currency = 'NIO',
  });
  final double amount;
  final double discountPercent;
  final bool compact;
  final String currency;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        '${currency == 'NIO' ? 'C\$' : currency} ${(amount * (1 - discountPercent / 100)).toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      if (discountPercent > 0) ...[
        Text(
          '${currency == 'NIO' ? 'C\$' : currency} ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 10,
            decoration: TextDecoration.lineThrough,
            color: AppColors.muted,
          ),
        ),
        Text(
          '-${discountPercent.toStringAsFixed(discountPercent % 1 == 0 ? 0 : 1)}%',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.coralDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ],
  );
}
