// Archivo: lib/shared/widgets/coleccion_api.dart
// Carga y presenta colecciones paginadas con sus acciones y estados de respuesta.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Una lectura por página, con reintento y paginación reutilizable.
class ColeccionApi extends StatefulWidget {
  const ColeccionApi({
    super.key,
    required this.path,
    required this.builder,
    this.query = const {},
    this.empty,
  });
  final String path;
  final Json query;
  final Widget Function(List<Json>) builder;
  final Widget? empty;
  @override
  State<ColeccionApi> createState() => _ColeccionApiState();
}

class _ColeccionApiState extends State<ColeccionApi> {
  late Future<PaginaApi> _result = _load();
  Future<PaginaApi> _load([int page = 1]) => AplicacionController.instance.api
      .page(widget.path, page: page, query: widget.query);
  @override
  Widget build(BuildContext context) => FutureBuilder<PaginaApi>(
    future: _result,
    builder: (_, snapshot) {
      if (snapshot.hasError) {
        return Column(
          children: [
            AvisoErrorApi(message: snapshot.error.toString()),
            BotonAccionApi(
              label: 'Reintentar',
              action: () async {
                setState(() => _result = _load());
              },
            ),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const EstadoVacioApi(message: '', loading: true);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (snapshot.data!.items.isEmpty)
            widget.empty ??
                const EstadoVacioApi(message: 'Todavía no hay registros.')
          else
            widget.builder(snapshot.data!.items),
          if (snapshot.data!.hasMore || snapshot.data!.page > 1)
            PaginacionApi(
              page: snapshot.data,
              load: (page) async {
                setState(() => _result = _load(page));
              },
            ),
        ],
      );
    },
  );
}
