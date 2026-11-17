// Archivo: lib/models/comercial/widgets/pago_demo.dart
// Presenta un pago ficticio. Los datos de tarjeta nunca salen de este formulario.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/core/dominio/validacion_tarjeta_demo.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

Future<Json?> mostrarPagoDemo(
  BuildContext context, {
  required String title,
  required String amount,
  required Json operation,
}) => showDialog<Json>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _PagoDemo(title: title, amount: amount, operation: operation),
);

class _PagoDemo extends StatefulWidget {
  const _PagoDemo({
    required this.title,
    required this.amount,
    required this.operation,
  });
  final String title, amount;
  final Json operation;
  @override
  State<_PagoDemo> createState() => _PagoDemoState();
}

class _PagoDemoState extends State<_PagoDemo> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController(),
      _name = TextEditingController(),
      _expiry = TextEditingController(),
      _cvv = TextEditingController();
  final _nonce = const Uuid().v4();
  bool _sending = false;
  @override
  void dispose() {
    for (final controller in [_number, _name, _expiry, _cvv]) {
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pago de demostración',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ColoresAplicacion.surfaceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Usa datos de prueba. No se hará ningún cobro ni se enviarán o guardarán los datos de la tarjeta.',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'C\$ ${widget.amount}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: ColoresAplicacion.navy,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColoresAplicacion.navy, ColoresAplicacion.blue],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.white),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            TarjetaDemo.nombre(_number.text),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      '••••  ••••  ••••  DEMO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'SIN DINERO REAL',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                enabled: !_sending,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Nombre de prueba',
                  hintText: 'Persona de prueba',
                ),
                validator: (x) => (x?.trim().length ?? 0) < 3
                    ? 'Escribe un nombre de prueba.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _number,
                enabled: !_sending,
                keyboardType: TextInputType.number,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta de prueba',
                  hintText: '4111 1111 1111 1111',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
                onChanged: (_) => setState(() {}),
                validator: (x) => TarjetaDemo.validarNumero(x ?? ''),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiry,
                      enabled: !_sending,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Vencimiento',
                        hintText: 'MM/AA',
                      ),
                      validator: (x) => TarjetaDemo.validarVencimiento(x ?? ''),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _cvv,
                      enabled: !_sending,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'CVV de prueba',
                      ),
                      validator: (x) =>
                          TarjetaDemo.validarCvv(_number.text, x ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _sending
                    ? null
                    : () async {
                        if (!_form.currentState!.validate()) return;
                        setState(() => _sending = true);
                        await runApiAction(
                          context,
                          () async {
                            // Lista explícita: nunca agrega número, titular, vencimiento ni CVV.
                            final response = await AplicacionController
                                .instance
                                .api
                                .object(
                                  '/demo/checkout',
                                  method: 'POST',
                                  data: {
                                    'concepto': widget.operation['concepto'],
                                    if (widget.operation['recursoId'] != null)
                                      'recursoId':
                                          widget.operation['recursoId'],
                                    if (widget.operation['planId'] != null)
                                      'planId': widget.operation['planId'],
                                    'importe': widget.amount,
                                    'clienteId': _nonce,
                                  },
                                );
                            AplicacionController.instance
                                .refreshPublicPromotions();
                            if (context.mounted) {
                              Navigator.pop(context, response);
                            }
                          },
                          onWorkFinished: () {
                            if (mounted) setState(() => _sending = false);
                          },
                        );
                      },
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_sending ? 'Confirmando…' : 'Simular compra'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Visa: 4111111111111111 · Mastercard: 5555555555554444\nFecha futura y CVV de prueba de 3 cifras.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: ColoresAplicacion.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
