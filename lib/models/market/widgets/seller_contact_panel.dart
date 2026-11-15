import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/api_widgets.dart';

/// Consultar el artículo es una lectura. Solo Enviar confirma el primer contacto.
class SellerContactPanel extends StatefulWidget {
  const SellerContactPanel({super.key, required this.listingId});
  final String listingId;
  @override
  State<SellerContactPanel> createState() => _SellerContactPanelState();
}

class _SellerContactPanelState extends State<SellerContactPanel> {
  final _message = TextEditingController(text: 'Hola, ¿sigue disponible?');
  final _nonce = const Uuid().v4();
  String? _conversation, _error;
  bool _loading = false, _sent = false;
  @override
  void initState() {
    super.initState();
    if (AppService.instance.currentUser != null) _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AppService.instance.api.object(
        '/listings/${widget.listingId}/contact',
        foreground: false,
      );
      if (!mounted) return;
      setState(() {
        _conversation = result['conversacionId']?.toString();
        _sent = result['mensajeEnviado'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppService.instance.currentUser == null) {
      return FilledButton.icon(
        onPressed: () => AppNavigator.go(context, AppRoutes.login),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('Inicia sesión para contactar'),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_error != null) {
      return OutlinedButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar contacto con el vendedor'),
      );
    }
    if (_sent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: AppColors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ya contactaste a este vendedor.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => AppNavigator.go(
              context,
              '${AppRoutes.messages}?id=$_conversation',
            ),
            icon: const Icon(Icons.forum_outlined, size: 18),
            label: const Text('Ir a la conversación'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Escribe al vendedor',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _message,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Pregunta por el artículo…',
            counterText: '',
          ),
        ),
        const SizedBox(height: 10),
        ApiActionButton(
          label: 'Enviar consulta',
          icon: Icons.send_outlined,
          enabled: _message.text.trim().isNotEmpty,
          action: () async {
            final response = await AppService.instance.api.object(
              '/listings/${widget.listingId}/inquiry',
              method: 'POST',
              data: {'clienteId': _nonce, 'contenido': _message.text.trim()},
            );
            if (!mounted) return;
            setState(() {
              _conversation = textValue(response['conversacionId']);
              _sent = true;
            });
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Se enviará únicamente cuando pulses Enviar consulta.',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
