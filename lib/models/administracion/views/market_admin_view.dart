// Archivo: lib/models/administracion/views/market_admin_view.dart
// Presenta la gestión y moderación administrativa de anuncios del Marketplace.

import 'package:flutter/material.dart';
import 'package:unired/models/administracion/widgets/moderacion_view.dart';

class MarketAdminView extends StatelessWidget {
  const MarketAdminView({super.key, this.ownerId});
  final String? ownerId;
  @override
  Widget build(BuildContext context) =>
      ModeracionView(tutorials: false, ownerId: ownerId);
}
