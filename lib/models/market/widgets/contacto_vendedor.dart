// Envía el primer mensaje sobre un anuncio y abre la conversación privada.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:uuid/uuid.dart';

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
  String? _nonce, _lastMessage;
  late Future<Json> _contact = _load();

  Future<Json> _load() => _store.api.object(
    '/listings/${widget.listingId}/contact',
    foreground: false,
  );

  void _open(String id) =>
      NavegadorAplicacion.go(context, '${RutasAplicacion.messages}?id=$id');

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _store.currentUser;
    if (user == null || !user.verified) {
      return FilledButton.icon(
        onPressed: () => NavegadorAplicacion.go(
          context,
          user == null ? RutasAplicacion.login : RutasAplicacion.verifyEmail,
        ),
        icon: const Icon(Icons.login, size: 18),
        label: Text(
          user == null
              ? 'Inicia sesión para enviar un mensaje'
              : 'Verifica tu correo para enviar un mensaje',
        ),
      );
    }
    return FutureBuilder<Json>(
      future: _contact,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AvisoErrorApi(
            message: snapshot.error.toString(),
            retry: () => setState(() {
              _contact = _load();
            }),
          );
        }
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final conversation = textValue(snapshot.data!['conversacionId']);
        if (conversation.isNotEmpty) {
          return FilledButton.icon(
            onPressed: () => _open(conversation),
            icon: const Icon(Icons.forum_outlined, size: 18),
            label: const Text('Abrir conversación'),
          );
        }
        return Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _message,
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Mensaje sobre el anuncio',
                ),
                validator: (value) => value?.trim().isNotEmpty == true
                    ? null
                    : 'Escribe un mensaje.',
              ),
              const SizedBox(height: 8),
              BotonAccionApi(
                label: 'Enviar mensaje',
                icon: Icons.send_outlined,
                action: () async {
                  if (!_form.currentState!.validate()) return;
                  final message = _message.text.trim();
                  if (_lastMessage != message) {
                    _lastMessage = message;
                    _nonce = const Uuid().v4();
                  }
                  final result = await _store.api.object(
                    '/listings/${widget.listingId}/inquiry',
                    method: 'POST',
                    data: {'clienteId': _nonce, 'contenido': message},
                  );
                  if (!mounted) return;
                  final id = textValue(result['conversacionId']);
                  if (id.isEmpty) {
                    throw const FormatException(
                      'No se pudo abrir la conversación.',
                    );
                  }
                  setState(() {
                    _contact = Future.value(result);
                  });
                  _open(id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
