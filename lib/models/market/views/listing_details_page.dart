import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/models/market/widgets/seller_contact_panel.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/page_frame.dart';
import 'package:unired/shared/widgets/publication_details.dart';
import 'package:unired/shared/widgets/status_pill.dart';

/// Ficha de venta entre personas: galería, condiciones y conversación directa.
class ListingDetailsPage extends StatefulWidget {
  const ListingDetailsPage({super.key, required this.id});
  final String id;
  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  late Future<Json> _details = AppService.instance.publicationDetails(
    false,
    widget.id,
  );
  @override
  Widget build(BuildContext context) => PublicPageFrame(
    route: AppRoutes.market,
    body: PageSection(
      child: FutureBuilder<Json>(
        future: _details,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                ApiErrorNotice(message: snapshot.error.toString()),
                ApiActionButton(
                  label: 'Reintentar',
                  action: () async {
                    setState(
                      () => _details = AppService.instance.publicationDetails(
                        false,
                        widget.id,
                      ),
                    );
                  },
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const ApiEmptyState(message: '', loading: true);
          }
          final row = snapshot.data!, store = AppService.instance;
          final item = store.productFromJson(row);
          final own = store.currentUser?.id == item.sellerId;
          final gallery = PublicationGallery(
            fileIds: jsonRows(
              row['imagenes'],
            ).map((r) => textValue(r['archivoId'])).toList(),
          );
          final summary = AdminSurface(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusPill(item.status.label),
                ),
                const SizedBox(height: 22),
                Text(
                  item.displayPrice,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${item.condition}${item.city.isEmpty ? '' : ' · ${item.city}'}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 21),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    AdminAvatar(name: item.seller),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Publicado por',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            item.seller,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    if (item.sellerId.isNotEmpty)
                      IconButton(
                        tooltip: 'Ver perfil del vendedor',
                        onPressed: () => AppNavigator.go(
                          context,
                          AppRoutes.memberProfile(item.sellerId),
                        ),
                        icon: const Icon(Icons.arrow_outward),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                if (!own && row['estado'] != 'vendido')
                  AnimatedBuilder(
                    animation: store,
                    builder: (_, _) => SellerContactPanel(
                      key: ValueKey('${item.id}:${store.sessionEpoch}'),
                      listingId: item.id,
                    ),
                  ),
                const SizedBox(height: 10),
                if (!own)
                  ApiActionButton(
                    label: store.isFavorite(item)
                        ? 'Quitar de favoritos'
                        : 'Guardar artículo',
                    icon: Icons.favorite_border,
                    action: () async {
                      if (store.currentUser == null) {
                        AppNavigator.go(context, AppRoutes.login);
                        return;
                      }
                      await store.toggleFavorite(item);
                      if (mounted) setState(() {});
                    },
                  ),
                if (own)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Gestionar mi artículo'),
                    onPressed: () => AppNavigator.go(
                      context,
                      AppRoutes.publication(
                        tutorial: false,
                        admin: false,
                        id: item.id,
                        editing: true,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Acuerda la entrega y las condiciones directamente con el vendedor.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          );
          final articleDetails = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 22),
              AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionHeading('Acerca de este artículo'),
                    const SizedBox(height: 12),
                    Text(
                      item.description,
                      style: const TextStyle(height: 1.8, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PublicationFacts(row: row, tutorial: false),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => AppNavigator.go(context, AppRoutes.market),
                  icon: const Icon(Icons.arrow_back, size: 17),
                  label: const Text('Marketplace'),
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (_, size) => size.maxWidth >= 850
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(children: [gallery, articleDetails]),
                          ),
                          const SizedBox(width: 28),
                          Expanded(flex: 4, child: summary),
                        ],
                      )
                    : Column(
                        children: [
                          gallery,
                          const SizedBox(height: 20),
                          summary,
                          articleDetails,
                        ],
                      ),
              ),
              if (jsonRows(row['novedades']).isNotEmpty) ...[
                const SizedBox(height: 26),
                const AdminSectionHeading('Actualizaciones del vendedor'),
                const SizedBox(height: 14),
                for (final update in jsonRows(row['novedades']))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminDate(update['creadoEn']),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            textValue(update['contenido']),
                            style: const TextStyle(height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
