import 'package:flutter/material.dart';
import 'package:unired/core/constants/publication_status.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/admin/widgets/catalog_management_view.dart';
import 'package:unired/models/market/models/market_item.dart';
import 'package:unired/models/tutorials/models/tutorial_item.dart';
import 'package:unired/shared/widgets/publication_price.dart';

/// Gestión propia: incluye borradores/archivados, nunca publicaciones ajenas.
/// Reutiliza la tabla del panel y aplica autorización también en el servicio.
class OwnedPublications extends StatelessWidget {
  const OwnedPublications({
    super.key,
    required this.tutorials,
    this.asAdmin = false,
  });
  final bool tutorials;
  final bool asAdmin;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppService.instance,
    builder: (context, _) => _catalog(context),
  );

  Widget _catalog(BuildContext context) {
    final store = AppService.instance;
    void open([String? id]) {
      final course = store.myTutorials.where((t) => t.id == id).firstOrNull;
      AppNavigator.go(
        context,
        AppRoutes.publication(
          tutorial: tutorials,
          admin: asAdmin,
          id: id,
          editing:
              tutorials &&
              course != null &&
              ![
                PublicationStatus.archived,
                PublicationStatus.blocked,
              ].contains(course.status),
        ),
      );
    }

    void preview() => AppNavigator.go(
      context,
      tutorials ? AppRoutes.tutorials : AppRoutes.market,
    );
    if (tutorials) {
      return CatalogManagementView<TutorialItem>(
        embedded: true,
        route: AppRoutes.profile,
        title: 'Mis tutorías',
        newLabel: 'Nueva tutoría',
        items: store.myTutorials,
        nameOf: (t) => t.title,
        categoryOf: (t) => t.category,
        statusOf: (t) => t.status,
        columns: const [
          DataColumn(label: Text('Tutoría')),
          DataColumn(label: Text('Precio / oferta')),
          DataColumn(label: Text('Modalidad / nivel')),
          DataColumn(label: Text('Inscritos')),
        ],
        cellsOf: (t) => [
          DataCell(Text(t.title)),
          DataCell(
            PublicationPrice(
              currency: t.currency,
              amount: t.amount,
              discountPercent: t.discountPercent,
            ),
          ),
          DataCell(Text(t.meta)),
          DataCell(Text('${t.students}')),
        ],
        onCreate: open,
        onEdit: (t) => open(t.id),
        onPreview: preview,
        states: const [
          PublicationStatus.draft,
          PublicationStatus.published,
          PublicationStatus.paused,
          PublicationStatus.archived,
          PublicationStatus.blocked,
        ],
      );
    }
    return CatalogManagementView<MarketItem>(
      embedded: true,
      route: AppRoutes.profile,
      title: 'Mis artículos',
      newLabel: 'Nuevo artículo',
      items: store.myProducts,
      nameOf: (p) => p.title,
      categoryOf: (p) => p.category,
      statusOf: (p) => p.status,
      columns: const [
        DataColumn(label: Text('Artículo')),
        DataColumn(label: Text('Precio / oferta')),
        DataColumn(label: Text('Condición')),
        DataColumn(label: Text('Ciudad')),
      ],
      cellsOf: (p) => [
        DataCell(Text(p.title)),
        DataCell(
          ['gratis', 'a_consultar'].contains(p.priceType)
              ? Text(p.displayPrice)
              : PublicationPrice(
                  amount: p.amount,
                  discountPercent: p.discountPercent,
                  currency: p.currency,
                ),
        ),
        DataCell(Text(p.condition)),
        DataCell(Text(p.city)),
      ],
      onCreate: open,
      onEdit: (p) => open(p.id),
      onPreview: preview,
      states: const [
        PublicationStatus.draft,
        PublicationStatus.published,
        PublicationStatus.reserved,
        PublicationStatus.sold,
        PublicationStatus.archived,
        PublicationStatus.blocked,
      ],
    );
  }
}
