import 'package:flutter/material.dart';
import 'package:unired/core/constants/publication_status.dart';

/// Anuncio del marketplace recibido desde la API.
///
/// Precio base y oferta se presentan sin inventario, carrito ni ventas inferidas.
class MarketItem {
  const MarketItem({
    required this.id,
    required this.title,
    required this.price,
    required this.amount,
    required this.category,
    required this.icon,
    required this.accent,
    this.badge = 'Nuevo',
    this.seller = 'Comunidad UniRed',
    this.description = 'Un recurso útil compartido por estudiantes.',
    this.sellerId = '',
    this.status = PublicationStatus.published,
    this.discountPercent = 0,
    this.condition = 'Nuevo',
    this.categoryId = 0,
    this.versionLock = 1,
    this.imageId,
    this.city = '',
    this.priceType = 'fijo',
    this.currency = 'NIO',
  });

  final String id;
  final String title;
  final String price;
  final double amount;
  final String category;
  final IconData icon;
  final Color accent;
  final String badge;
  final String seller;
  final String description;
  final String sellerId;
  final PublicationStatus status;
  final double discountPercent;
  final String condition;
  final int categoryId;
  final int versionLock;
  final String? imageId;
  final String city;
  final String priceType;
  final String currency;

  /// La oferta no sustituye el precio base ni modifica el ranking de ventas.
  double get effectiveAmount =>
      double.parse((amount * (1 - discountPercent / 100)).toStringAsFixed(2));
  String get displayPrice => switch (priceType) {
    'gratis' => 'Gratis',
    'a_consultar' => 'Consultar precio',
    _ =>
      '${currency == 'NIO' ? 'C\$' : currency} ${effectiveAmount.toStringAsFixed(2)}',
  };

  /// Copia inmutable: permite editar sin perder las métricas del artículo.
  MarketItem copyWith({
    String? title,
    double? amount,
    String? category,
    String? seller,
    String? sellerId,
    String? description,
    PublicationStatus? status,
    double? discountPercent,
    String? condition,
  }) {
    return MarketItem(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      price: 'C\$ ${(amount ?? this.amount).toStringAsFixed(2)}',
      category: category ?? this.category,
      icon: icon,
      accent: accent,
      badge: badge,
      seller: seller ?? this.seller,
      sellerId: sellerId ?? this.sellerId,
      description: description ?? this.description,
      status: status ?? this.status,
      discountPercent: discountPercent ?? this.discountPercent,
      condition: condition ?? this.condition,
      categoryId: categoryId,
      versionLock: versionLock,
      imageId: imageId,
      city: city,
      priceType: priceType,
      currency: currency,
    );
  }
}
