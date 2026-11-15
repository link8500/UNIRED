import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/shared/themes/app_colors.dart';

/// Popover anclado a la campana: no bloquea ni abandona la página actual.
/// Los avisos vienen de la API y son privados de la cuenta; se pueden marcar como leídos.
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppService.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => MenuAnchor(
        alignmentOffset: const Offset(0, 8),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.line),
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
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Actividad de tu cuenta',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const Divider(height: 24),
                    if (!store.notificationsEnabled)
                      const Text(
                        'Los avisos están desactivados. Puedes activarlos en las preferencias de tu perfil.',
                      )
                    else if (store.notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No tienes notificaciones nuevas.'),
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
                                            ? AppColors.muted
                                            : AppColors.coral,
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
                                                color: AppColors.navy,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              notice.message,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
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
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
