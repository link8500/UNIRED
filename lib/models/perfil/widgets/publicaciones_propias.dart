// Archivo: lib/models/perfil/widgets/publicaciones_propias.dart
// Muestra los anuncios y cursos propios y sus accesos de gestión.

import 'package:flutter/material.dart';
import 'package:unired/core/constantes/estado_publicacion.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/administracion/widgets/gestion_catalogo_view.dart';
import 'package:unired/models/market/models/articulo_market.dart';
import 'package:unired/models/tutorias/models/tutoria.dart';
import 'package:unired/shared/widgets/precio_publicacion.dart';

/// Gestión propia: incluye borradores/archivados, nunca publicaciones ajenas.
/// Reutiliza la tabla del panel y aplica autorización también en el servicio.
class PublicacionesPropias extends StatelessWidget {
  const PublicacionesPropias({
    super.key,
    required this.tutorials,
    this.asAdmin = false,
  });
  final bool tutorials;
  final bool asAdmin;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AplicacionController.instance,
    builder: (context, _) => _catalog(context),
  );

  Widget _catalog(BuildContext context) {
    final store = AplicacionController.instance;
    void open([String? id]) {
      final course = store.myTutorials.where((t) => t.id == id).firstOrNull;
      NavegadorAplicacion.go(
        context,
        RutasAplicacion.publication(
          tutorial: tutorials,
          admin: asAdmin,
          id: id,
          editing:
              tutorials &&
              course != null &&
              ![
                EstadoPublicacion.archived,
                EstadoPublicacion.blocked,
              ].contains(course.status),
        ),
      );
    }

    void preview() => NavegadorAplicacion.go(
      context,
      tutorials ? RutasAplicacion.tutorials : RutasAplicacion.market,
    );
    if (tutorials) {
      return GestionCatalogoView<Tutoria>(
        embedded: true,
        route: RutasAplicacion.profile,
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
            PrecioPublicacion(
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
          EstadoPublicacion.draft,
          EstadoPublicacion.published,
          EstadoPublicacion.paused,
          EstadoPublicacion.archived,
          EstadoPublicacion.blocked,
        ],
      );
    }
    return GestionCatalogoView<ArticuloMarket>(
      embedded: true,
      route: RutasAplicacion.profile,
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
              : PrecioPublicacion(
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
        EstadoPublicacion.draft,
        EstadoPublicacion.published,
        EstadoPublicacion.reserved,
        EstadoPublicacion.sold,
        EstadoPublicacion.archived,
        EstadoPublicacion.blocked,
      ],
    );
  }
}
