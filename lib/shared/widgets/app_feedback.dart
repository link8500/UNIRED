import 'dart:async';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:unired/shared/themes/app_colors.dart';

enum FeedbackKind { info, success, warning, error }

/// Un único estilo para los avisos de toda la aplicación. Los avisos iguales
/// comparten su resultado; los distintos esperan su turno sin apilar ventanas.
abstract final class AppFeedback {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _pending = <NavigatorState, Map<String, Future<bool>>>{};

  static Future<bool> show(
    BuildContext context, {
    required String message,
    String? title,
    FeedbackKind kind = FeedbackKind.info,
    String action = 'Entendido',
    String? cancel,
  }) {
    final navigator =
        Navigator.maybeOf(context, rootNavigator: true) ??
        navigatorKey.currentState;
    if (navigator == null) return Future.value(false);
    final queue = _pending.putIfAbsent(navigator, () => {});
    final key = '$kind:$title:$message:$action:$cancel';
    if (queue.containsKey(key)) return queue[key]!;
    final previous = queue.values.lastOrNull;
    final result = Completer<bool>();
    queue[key] = result.future;
    () async {
      try {
        await previous;
        if (!navigator.mounted || navigator.overlay == null) {
          result.complete(false);
          return;
        }
        final modalContext = navigator.overlay!.context;
        if (!modalContext.mounted) {
          result.complete(false);
          return;
        }
        final reduceMotion = MediaQuery.disableAnimationsOf(modalContext);
        final accepted = await showModal<bool>(
          context: modalContext,
          configuration: FadeScaleTransitionConfiguration(
            barrierLabel: 'Cerrar aviso',
            barrierColor: AppColors.navy.withValues(alpha: .35),
            transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 160),
            reverseTransitionDuration: Duration(
              milliseconds: reduceMotion ? 0 : 100,
            ),
          ),
          builder: (context) => _FeedbackDialog(
            message: message,
            title: title,
            kind: kind,
            action: action,
            cancel: cancel,
          ),
        );
        result.complete(accepted ?? false);
      } catch (error, stack) {
        result.completeError(error, stack);
      } finally {
        queue.remove(key);
        if (queue.isEmpty) _pending.remove(navigator);
      }
    }();
    return result.future;
  }

  static Future<bool> error(BuildContext context, Object error) => show(
    context,
    kind: error is FormatException ? FeedbackKind.warning : FeedbackKind.error,
    title: error is FormatException
        ? 'Revisa el archivo'
        : 'No se pudo completar',
    message: error is FormatException ? error.message : error.toString(),
  );
}

class _FeedbackDialog extends StatelessWidget {
  const _FeedbackDialog({
    required this.message,
    required this.title,
    required this.kind,
    required this.action,
    required this.cancel,
  });
  final String message, action;
  final String? title, cancel;
  final FeedbackKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, color, heading) = switch (kind) {
      FeedbackKind.info => (
        Icons.info_outline_rounded,
        AppColors.blue,
        'Información',
      ),
      FeedbackKind.success => (
        Icons.check_circle_outline_rounded,
        const Color(0xFF20846A),
        'Listo',
      ),
      FeedbackKind.warning => (
        Icons.warning_amber_rounded,
        const Color(0xFFAC7215),
        'Revisa los datos',
      ),
      FeedbackKind.error => (
        Icons.error_outline_rounded,
        AppColors.coralDark,
        'No se pudo completar',
      ),
    };
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cerrar aviso',
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title ?? heading,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 26),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (cancel != null)
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(cancel!),
                    ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(action),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los errores de carga se anuncian una vez por mensaje, después del build.
/// Reconstruir o sondear la misma vista no vuelve a interrumpir al usuario.
class ApiErrorNotice extends StatefulWidget {
  const ApiErrorNotice({super.key, required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  State<ApiErrorNotice> createState() => _ApiErrorNoticeState();
}

class _ApiErrorNoticeState extends State<ApiErrorNotice> {
  String? _announced;
  @override
  Widget build(BuildContext context) {
    if (_announced != widget.message) {
      _announced = widget.message;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent != false) {
          unawaited(AppFeedback.error(context, widget.message));
        }
      });
    }
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        icon: Icon(
          widget.retry == null ? Icons.info_outline : Icons.refresh,
          size: 18,
        ),
        label: Text(widget.retry == null ? 'Ver aviso' : 'Reintentar'),
        onPressed:
            widget.retry ?? () => AppFeedback.error(context, widget.message),
      ),
    );
  }
}
