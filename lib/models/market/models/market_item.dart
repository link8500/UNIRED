import 'package:flutter/material.dart';

/// Modelo visual de un producto del marketplace.
///
/// No contiene lógica de compra; únicamente describe los datos que necesita
/// `ProductCard` para representar un producto.
class MarketItem {
  const MarketItem({
    required this.title,
    required this.price,
    required this.category,
    required this.icon,
    required this.accent,
    this.badge = 'Nuevo',
  });

  final String title;
  final String price;
  final String category;
  final IconData icon;
  final Color accent;
  final String badge;
}
