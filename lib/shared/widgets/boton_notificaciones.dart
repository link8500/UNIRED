// Archivo: lib/shared/widgets/boton_notificaciones.dart
// Abre el panel flotante de notificaciones y muestra el contador de avisos pendientes.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/notificaciones/models/aviso_usuario.dart';

/// Popover anclado a la campana: no bloquea ni abandona la página actual.
/// Los avisos vienen de la API y son privados de la cuenta; se pueden marcar como leídos.
class BotonNotificaciones extends StatefulWidget {
  const BotonNotificaciones({super.key});
  @override
  State<BotonNotificaciones> createState() => _BotonNotificacionesState();
}

class _BotonNotificacionesState extends State<BotonNotificaciones> {
  final _menu = MenuController();
  @override
  Widget build(BuildContext context) {
    final store = AplicacionController.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => MenuAnchor(
        controller: _menu,
        alignmentOffset: const Offset(0, 8),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: ColoresAplicacion.line),
            ),
          ),
        ),
        menuChildren: [
          SizedBox(
            width: math.min(340, MediaQuery.sizeOf(context).width - 32),
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ColoresAplicacion.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Actividad de tu cuenta',
                      style: TextStyle(
                        fontSize: 11,
                        color: ColoresAplicacion.muted,
                      ),
                    ),
                    const Divider(height: 24),
                    if (!store.notificationsEnabled)
                      const Text(
                        'Los avisos están desactivados. Puedes activarlos en las preferencias de tu perfil.',
                      )
                    else if (store.notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No tienes notificaciones.'),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: SingleChildScrollView(
                          primary: false,
                          child: Column(
                            children: [
                              for (final notice in store.notifications)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        store.isNoticeRead(notice)
                                            ? Icons.check_circle_outline
                                            : Icons.circle,
                                        size: 14,
                                        color: store.isNoticeRead(notice)
                                            ? ColoresAplicacion.muted
                                            : ColoresAplicacion.coral,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notice.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: ColoresAplicacion.navy,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              notice.message,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (_destination(notice)
                                                case final String route)
                                              TextButton.icon(
                                                onPressed: () {
                                                  _menu.close();
                                                  NavegadorAplicacion.go(
                                                    context,
                                                    route,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.arrow_forward,
                                                  size: 14,
                                                ),
                                                label: const Text(
                                                  'Ver detalles',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Eliminar notificación',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        onPressed: () => runApiAction(
                                          context,
                                          () => store.deleteNotification(
                                            notice.id,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (store.notificationsEnabled &&
                        store.unreadNotifications > 0)
                      TextButton(
                        onPressed: () =>
                            runApiAction(context, store.markNotificationsRead),
                        child: const Text('Marcar todas como leídas'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        builder: (context, controller, _) => IconButton(
          tooltip: 'Notificaciones',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: Badge(
            isLabelVisible:
                store.notificationsEnabled && store.unreadNotifications > 0,
            label: Text('${store.unreadNotifications}'),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: ColoresAplicacion.muted,
            ),
          ),
        ),
      ),
    );
  }

  String? _destination(AvisoUsuario notice) {
    final data = notice.data;
    final admin = (ModalRoute.of(context)?.settings.name ?? '').startsWith(
      '/admin/',
    );
    if (notice.type == 'oferta') {
      return admin ? RutasAplicacion.adminOffers : RutasAplicacion.offers;
    }
    if (notice.type == 'solicitud_tutoria') {
      return Uri(
        path: admin
            ? RutasAplicacion.adminTutoringRequests
            : RutasAplicacion.tutoringRequests,
        queryParameters: {
          if (data['vista'] != null) 'view': data['vista'].toString(),
        },
      ).toString();
    }
    if (data['conversacionId'] != null) {
      return '${admin ? RutasAplicacion.adminMessages : RutasAplicacion.messages}?id=${data['conversacionId']}';
    }
    if (data['empresaId'] != null) {
      return '${admin ? RutasAplicacion.adminBusiness : RutasAplicacion.business}?id=${data['empresaId']}';
    }
    if (data['tutoriaId'] != null) {
      return '${RutasAplicacion.course}?id=${data['tutoriaId']}';
    }
    if (data['anuncioId'] != null) {
      return '${RutasAplicacion.listing}?id=${data['anuncioId']}';
    }
    return null;
  }
}
