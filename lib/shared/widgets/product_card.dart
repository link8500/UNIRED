import 'package:flutter/material.dart';

import 'package:unired/models/market/models/market_item.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/page_frame.dart';

/// Tarjeta única para cualquier producto del marketplace.
///
/// `prominent` permite que Home use una tarjeta más grande sin duplicar la
/// estructura del componente que utiliza Market.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.item, this.prominent = false});

  final MarketItem item;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: item.accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: prominent ? 15 : 12,
                    left: prominent ? 15 : 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .86),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      item.icon,
                      size: prominent ? 82 : 68,
                      color: AppColors.navy.withValues(alpha: .72),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.navy,
                      size: prominent ? 20 : 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              prominent ? 17 : 14,
              prominent ? 15 : 13,
              prominent ? 17 : 14,
              prominent ? 17 : 15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: prominent ? 11 : 10,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: prominent ? 15 : 14,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      item.price,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.coralDark,
                        fontSize: prominent ? 14 : 13,
                      ),
                    ),
                    const Spacer(),
                    if (!prominent)
                      const Icon(
                        Icons.arrow_outward_rounded,
                        color: AppColors.blue,
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
