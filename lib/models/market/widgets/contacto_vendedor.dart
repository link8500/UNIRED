// Archivo: lib/models/market/widgets/contacto_vendedor.dart
// Envía una oferta y habilita el chat únicamente después de la aceptación del autor.
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

class ContactoVendedor extends StatefulWidget {
  const ContactoVendedor({super.key, required this.listingId});
  final String listingId;
  @override
  State<ContactoVendedor> createState() => _ContactoVendedorState();
}

class _ContactoVendedorState extends State<ContactoVendedor> {
  final _store = AplicacionController.instance;
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController(
    text: 'Hola, me interesa esta publicación.',
  );
  final _amount = TextEditingController();
  String _nonce = const Uuid().v4();
  Json? _offer;
  String? _conversation, _error;
  bool _loading = false, _exchange = false;
  @override
  void initState() {
    super.initState();
    _store.addListener(_changed);
    if (_store.currentUser != null) _load();
  }

  void _changed() {
    if (_offer?['estado'] == 'pendiente' && !_loading) _load();
  }

  @override
  void dispose() {
    _store.removeListener(_changed);
    _message.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final data = await _store.api.object(
        '/listings/${widget.listingId}/contact',
        foreground: false,
      );
      if (!mounted) return;
      setState(() {
        _offer = data['oferta'] is Map ? jsonObject(data['oferta']) : null;
        _conversation = data['conversacionId']?.toString();
        if (_amount.text.isEmpty) {
          _amount.text = textValue(data['importeSugerido'], '0.00');
        }
        _error = null;
      });
    } catch (error) {
      if (mounted && _offer == null) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_store.currentUser == null) {
      return FilledButton.icon(
        onPressed: () => NavegadorAplicacion.go(context, RutasAplicacion.login),
        icon: const Icon(Icons.login, size: 18),
        label: const Text('Inicia sesión para hacer una oferta'),
      );
    }
    if (_loading && _amount.text.isEmpty) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (_error != null) return AvisoErrorApi(message: _error!, retry: _load);
    if (_offer != null) {
      final state = textValue(_offer!['estado']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(switch (state) {
            'pendiente' => 'Tu oferta está pendiente',
            'aceptada' => 'Tu oferta fue aceptada',
            'rechazada' => 'El autor rechazó la oferta',
            'finalizada' => 'La negociación finalizó',
            _ => 'La oferta fue cancelada',
          }, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            state == 'pendiente'
                ? 'El autor revisará tu propuesta. El chat se abrirá cuando la acepte.'
                : 'Importe propuesto: ${textValue(_offer!['moneda'])} ${textValue(_offer!['importe'])}',
          ),
          const SizedBox(height: 12),
          if (state == 'aceptada' && _conversation != null)
            FilledButton.icon(
              onPressed: () => NavegadorAplicacion.go(
                context,
                '${RutasAplicacion.messages}?id=$_conversation',
              ),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('Abrir conversación'),
            ),
          if (state == 'pendiente')
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Comprobar respuesta'),
            ),
          TextButton(
            onPressed: () =>
                NavegadorAplicacion.go(context, RutasAplicacion.offers),
            child: const Text('Gestionar mis ofertas'),
          ),
          if (!['pendiente', 'aceptada'].contains(state))
            OutlinedButton(
              onPressed: () => setState(() {
                _offer = null;
                _nonce = const Uuid().v4();
              }),
              child: const Text('Preparar otra oferta'),
            ),
        ],
      );
    }
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Haz una propuesta al autor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envía tu oferta de compra o intercambio. No se realiza ningún cobro.',
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Proponer intercambio'),
            value: _exchange,
            onChanged: (value) => setState(() => _exchange = value),
          ),
          if (!_exchange) ...[
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Importe de tu oferta',
              ),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                return amount == null || !amount.isFinite || amount < 0
                    ? 'Escribe un importe válido.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _message,
            minLines: 2,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: _exchange
                  ? '¿Qué propones intercambiar?'
                  : 'Mensaje para el autor',
            ),
            validator: (value) => (value?.trim().length ?? 0) < 3
                ? 'Escribe tu propuesta.'
                : null,
          ),
          const SizedBox(height: 12),
          BotonAccionApi(
            label: 'Enviar oferta',
            icon: Icons.send_outlined,
            action: () async {
              if (!_form.currentState!.validate()) return;
              final result = await _store.api.object(
                '/listings/${widget.listingId}/offers',
                method: 'POST',
                data: {
                  'clienteId': _nonce,
                  'tipo': _exchange ? 'intercambio' : 'compra',
                  'importe': _exchange
                      ? '0.00'
                      : _amount.text.replaceAll(',', '.'),
                  'mensaje': _message.text.trim(),
                },
              );
              if (mounted) setState(() => _offer = result);
            },
          ),
        ],
      ),
    );
  }
}
