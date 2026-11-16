// Archivo: lib/models/market/widgets/contacto_vendedor.dart
// Gestiona la consulta y el contacto con el vendedor dentro del contexto del anuncio.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Consultar el artículo es una lectura. Solo Enviar confirma el primer contacto.
class ContactoVendedor extends StatefulWidget {
  const ContactoVendedor({super.key, required this.listingId});
  final String listingId;
  @override
  State<ContactoVendedor> createState() => _ContactoVendedorState();
}

class _ContactoVendedorState extends State<ContactoVendedor> {
  final _message = TextEditingController(text: 'Hola, ¿sigue disponible?');
  final _nonce = const Uuid().v4();
  String? _conversation, _error;
  bool _loading = false, _sent = false;
  @override
  void initState() {
    super.initState();
    if (AplicacionController.instance.currentUser != null) _load();
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
      final result = await AplicacionController.instance.api.object(
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
    if (AplicacionController.instance.currentUser == null) {
      return FilledButton.icon(
        onPressed: () => NavegadorAplicacion.go(context, RutasAplicacion.login),
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
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: ColoresAplicacion.blue,
              ),
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
            onPressed: () => NavegadorAplicacion.go(
              context,
              '${RutasAplicacion.messages}?id=$_conversation',
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
        BotonAccionApi(
          label: 'Enviar consulta',
          icon: Icons.send_outlined,
          enabled: _message.text.trim().isNotEmpty,
          action: () async {
            final response = await AplicacionController.instance.api.object(
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
          style: TextStyle(fontSize: 11, color: ColoresAplicacion.muted),
        ),
      ],
    );
  }
}
