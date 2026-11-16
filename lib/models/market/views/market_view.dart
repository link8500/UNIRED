// Archivo: lib/models/market/views/market_view.dart
// Muestra el catálogo del Marketplace y sus mecanismos de búsqueda.

import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/catalogo_remoto.dart';

class MarketView extends StatelessWidget {
  const MarketView({super.key});
  @override
  Widget build(BuildContext context) => const CatalogoRemoto(tutorials: false);
}
