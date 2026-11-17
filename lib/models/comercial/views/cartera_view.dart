// Archivo: lib/models/comercial/views/cartera_view.dart
// Muestra saldo ficticio, recargas y el historial sin almacenar información bancaria.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/comercial/widgets/pago_demo.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_gestion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';

class CarteraView extends StatefulWidget {
  const CarteraView({super.key, this.asAdmin = false});
  final bool asAdmin;
  @override
  State<CarteraView> createState() => _CarteraViewState();
}

class _CarteraViewState extends State<CarteraView> {
  final _store = AplicacionController.instance;
  late Future<Json> _data = _load();
  int _revision = 0;
  String _amount = '100.00';
  Future<Json> _load() async {
    final rows = await Future.wait([
      _store.api.object('/me/wallet'),
      _store.api.object('/commerce/config'),
    ]);
    return {...rows[0], 'config': rows[1]};
  }

  void _refresh() => setState(() {
    _revision++;
    _data = _load();
  });
  @override
  Widget build(BuildContext context) => MarcoGestion(
    asAdmin: widget.asAdmin,
    title: 'Mi cartera y compras',
    subtitle: 'Mi cuenta',
    route: widget.asAdmin
        ? RutasAplicacion.adminProfile
        : RutasAplicacion.wallet,
    child: SingleChildScrollView(
      child: SeccionPagina(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<Json>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AvisoErrorApi(
                message: snapshot.error.toString(),
                retry: _refresh,
              );
            }
            if (!snapshot.hasData) {
              return const EstadoVacioApi(message: '', loading: true);
            }
            final data = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Mi cartera',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: ColoresAplicacion.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explora las recargas y consulta tus operaciones. Todos los importes son de demostración.',
                ),
                const SizedBox(height: 24),
                TarjetaSuave(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SALDO DE PRUEBA',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          color: ColoresAplicacion.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'C\$ ${textValue(data['saldoDemo'], '0.00')}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: ColoresAplicacion.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Este saldo no representa dinero real y no puede retirarse.',
                      ),
                      const SizedBox(height: 20),
                      if (_store.tutorGrants.isNotEmpty) ...[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final amount in ['100.00', '250.00', '500.00'])
                              ChoiceChip(
                                label: Text('C\$ $amount'),
                                selected: _amount == amount,
                                onSelected: (_) =>
                                    setState(() => _amount = amount),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            final result = await mostrarPagoDemo(
                              context,
                              title: 'Recarga de saldo de prueba',
                              amount: _amount,
                              operation: {'concepto': 'recarga_tutor'},
                            );
                            if (result == null || !context.mounted) return;
                            _refresh();
                            await AvisosAplicacion.show(
                              context,
                              kind: TipoAviso.success,
                              title: 'Recarga simulada realizada',
                              message:
                                  'Tu saldo de demostración se actualizó. No se efectuó ningún cobro.',
                            );
                          },
                          icon: const Icon(Icons.add_card),
                          label: const Text('Simular recarga'),
                        ),
                      ] else
                        OutlinedButton.icon(
                          onPressed: () => NavegadorAplicacion.go(
                            context,
                            RutasAplicacion.accreditation,
                          ),
                          icon: const Icon(Icons.school_outlined),
                          label: const Text(
                            'Solicitar acreditación como tutor',
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Comisión de demostración configurada: ${textValue(jsonObject(data['config'])['comisionPorcentaje'])} %',
                        style: const TextStyle(
                          color: ColoresAplicacion.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Movimientos de saldo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (jsonRows(data['movimientos']).isEmpty)
                  const EstadoVacioApi(
                    message: 'Aún no tienes movimientos de demostración.',
                  ),
                for (final movement in jsonRows(data['movimientos']))
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: ColoresAplicacion.blue,
                      ),
                      title: Text(textValue(movement['descripcion'])),
                      subtitle: Text(textValue(movement['creadoEn'])),
                      trailing: Text(
                        'C\$ ${textValue(movement['importe'])}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                const Text(
                  'Mis compras de demostración',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ColeccionApi(
                  key: ValueKey(_revision),
                  path: '/me/demo-payments',
                  empty: const EstadoVacioApi(
                    message: 'Tus confirmaciones aparecerán aquí.',
                  ),
                  builder: (rows) => Column(
                    children: [
                      for (final row in rows)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(
                              textValue(row['concepto']).replaceAll('_', ' '),
                            ),
                            subtitle: Text(
                              'Simulado · ${textValue(row['creadoEn'])}',
                            ),
                            trailing: Text('C\$ ${textValue(row['importe'])}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
