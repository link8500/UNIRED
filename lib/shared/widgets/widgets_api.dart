// Archivo: lib/shared/widgets/widgets_api.dart
// Acciones, imágenes privadas, paginación, estados vacíos y avisos de conexión reutilizados por las vistas.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
export 'package:unired/shared/widgets/avisos_aplicacion.dart'
    show AvisoErrorApi;

/// Espera al servidor; no muestra confirmaciones cuando una operación falla.
Future<bool> runApiAction(
  BuildContext context,
  Future<void> Function() work, {
  String? success,
  VoidCallback? onWorkFinished,
}) async {
  Object? failure;
  try {
    await AplicacionController.instance.api.withProgress(work);
  } catch (error) {
    failure = error;
  } finally {
    onWorkFinished?.call();
  }
  if (context.mounted) {
    if (failure != null) {
      await AvisosAplicacion.error(context, failure);
    } else if (success != null) {
      await AvisosAplicacion.show(
        context,
        message: success,
        kind: TipoAviso.success,
      );
    }
  }
  return failure == null;
}

class BotonAccionApi extends StatefulWidget {
  const BotonAccionApi({
    super.key,
    required this.label,
    required this.action,
    this.icon = Icons.check_rounded,
    this.success,
    this.enabled = true,
  });
  final String label;
  final String? success;
  final Future<void> Function() action;
  final IconData icon;
  final bool enabled;
  @override
  State<BotonAccionApi> createState() => _BotonAccionApiState();
}

class _BotonAccionApiState extends State<BotonAccionApi> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: _busy || !widget.enabled
        ? null
        : () async {
            setState(() => _busy = true);
            await runApiAction(
              context,
              widget.action,
              success: widget.success,
              onWorkFinished: () {
                if (mounted) setState(() => _busy = false);
              },
            );
          },
    icon: _busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(widget.icon, size: 17),
    label: Text(_busy ? 'Procesando…' : widget.label),
  );
}

/// Descarga autorizada compatible con Web, sin colocar el JWT en URLs.
class ImagenApi extends StatelessWidget {
  const ImagenApi({
    super.key,
    this.fileId,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.thumbnail = true,
  });
  final String? fileId;
  final Widget fallback;
  final BoxFit fit;
  final bool thumbnail;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AplicacionController.instance,
    builder: (_, _) => fileId == null
        ? fallback
        : FutureBuilder<Uint8List>(
            future: AplicacionController.instance.imageBytes(
              fileId!,
              thumbnail: thumbnail,
            ),
            builder: (_, snapshot) => snapshot.hasData
                ? Image.memory(
                    snapshot.data!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: fit,
                    errorBuilder: (_, _, _) => fallback,
                  )
                : fallback,
          ),
  );
}

class AvisoEstadoApi extends StatelessWidget {
  const AvisoEstadoApi({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AplicacionController.instance,
    builder: (_, _) {
      final store = AplicacionController.instance;
      if (store.lastError == null) return const SizedBox.shrink();
      return AvisoErrorApi(
        message: store.lastError!,
        retry: store.loading ? null : () => store.initialize(force: true),
      );
    },
  );
}

class EstadoVacioApi extends StatelessWidget {
  const EstadoVacioApi({
    super.key,
    required this.message,
    this.loading = false,
  });
  final String message;
  final bool loading;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(30),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const CircularProgressIndicator()
          else
            const Icon(
              Icons.inbox_outlined,
              color: ColoresAplicacion.blue,
              size: 32,
            ),
          const SizedBox(height: 12),
          Text(
            loading ? 'Cargando datos…' : message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class PaginacionApi extends StatelessWidget {
  const PaginacionApi({super.key, required this.page, required this.load});
  final PaginaApi? page;
  final Future<void> Function(int) load;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('Página ${page?.page ?? 1} · ${page?.total ?? 0} registros'),
      const SizedBox(width: 12),
      IconButton(
        onPressed: (page?.page ?? 1) > 1
            ? () => runApiAction(context, () => load(page!.page - 1))
            : null,
        icon: const Icon(Icons.chevron_left),
      ),
      IconButton(
        onPressed: page?.hasMore == true
            ? () => runApiAction(context, () => load(page!.page + 1))
            : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}
