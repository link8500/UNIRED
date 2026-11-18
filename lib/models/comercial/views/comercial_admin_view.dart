// Archivo: lib/models/comercial/views/comercial_admin_view.dart
// Revisión empresarial y publicitaria, con configuración comercial centralizada.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/coleccion_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/marco_gestion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

class ComercialAdminView extends StatefulWidget {
  const ComercialAdminView({super.key});
  @override
  State<ComercialAdminView> createState() => _ComercialAdminViewState();
}

class _ComercialAdminViewState extends State<ComercialAdminView> {
  final _api = AplicacionController.instance.api;
  int _tab = 0, _page = 1;
  late Future<Json> _data = _load();
  Future<Json> _load() => _api.object(
    _tab == 0
        ? '/admin/businesses'
        : _tab == 1
        ? '/admin/campaigns'
        : '/commerce/config',
    query: _tab < 2 ? {'page': _page, 'limit': 20} : null,
  );
  void _refresh() => setState(() {
    _data = _load();
  });
  Future<void> _review(Json row, String state) async {
    final done = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ),
                FormularioApi(
                  title: _tab == 0
                      ? 'Revisión de ${row['nombre']}'
                      : 'Retirar campaña',
                  label: 'Confirmar revisión',
                  fields: const [
                    CampoApi(
                      'motivo',
                      'Explica el motivo de la decisión',
                      lines: 4,
                    ),
                  ],
                  submit: (data) async {
                    await _api.object(
                      _tab == 0
                          ? '/admin/businesses/${row['id']}/review'
                          : '/admin/campaigns/${row['id']}/block',
                      method: _tab == 0 ? 'PATCH' : 'POST',
                      data: {...data, if (_tab == 0) 'estado': state},
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (done == true && mounted) {
      AplicacionController.instance.refreshPublicPromotions();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => MarcoGestion(
    asAdmin: true,
    route: RutasAplicacion.adminCommerce,
    title: 'Empresas y publicidad',
    subtitle: 'Afiliación / Campañas / Configuración',
    child: SingleChildScrollView(
      child: SeccionPagina(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(
                      ['Empresas', 'Campañas', 'Tarifas y comisión'][i],
                    ),
                    selected: _tab == i,
                    onSelected: (_) => setState(() {
                      _tab = i;
                      _page = 1;
                      _data = _load();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FutureBuilder<Json>(
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
                if (_tab == 2) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormularioApi(
                        title: 'Configuración comercial',
                        initial: data,
                        fields: const [
                          CampoApi(
                            'comisionPorcentaje',
                            'Comisión global (%)',
                            kind: TipoCampoApi.money,
                          ),
                          CampoApi(
                            'precioDestacado',
                            'Precio de destacar una publicación (C\$)',
                            kind: TipoCampoApi.money,
                          ),
                          CampoApi(
                            'diasDestacado',
                            'Días de publicación destacada',
                            kind: TipoCampoApi.integer,
                          ),
                          CampoApi(
                            'precioMinutoOnline',
                            'Tarifa por minuto online (C\$)',
                            kind: TipoCampoApi.money,
                          ),
                          CampoApi(
                            'precioMinutoPresencial',
                            'Tarifa por minuto presencial (C\$)',
                            kind: TipoCampoApi.money,
                          ),
                        ],
                        submit: (fields) async {
                          await _api.object(
                            '/admin/commerce/config',
                            method: 'PATCH',
                            data: fields,
                          );
                          if (mounted) _refresh();
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tarifas por área de enseñanza',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Personaliza solo las áreas que necesiten otro precio. Las demás utilizan las tarifas generales de arriba.',
                      ),
                      const SizedBox(height: 16),
                      ColeccionApi(
                        key: ValueKey(_data),
                        path: '/commerce/rates',
                        builder: (rows) => Column(
                          children: [
                            for (final rate in rows)
                              Card(
                                child: ExpansionTile(
                                  title: Text(textValue(rate['areaNombre'])),
                                  subtitle: Text(
                                    'En línea: C\$ ${rate['precioMinutoOnline']}/min · Presencial: C\$ ${rate['precioMinutoPresencial']}/min',
                                  ),
                                  childrenPadding: const EdgeInsets.all(16),
                                  children: [
                                    FormularioApi(
                                      title: 'Precio por minuto',
                                      initial: rate,
                                      label: 'Guardar tarifas del área',
                                      fields: const [
                                        CampoApi(
                                          'precioMinutoOnline',
                                          'En línea (C\$)',
                                          kind: TipoCampoApi.money,
                                        ),
                                        CampoApi(
                                          'precioMinutoPresencial',
                                          'Presencial (C\$)',
                                          kind: TipoCampoApi.money,
                                        ),
                                      ],
                                      submit: (fields) async {
                                        await _api.object(
                                          '/admin/commerce/rates/${rate['areaId']}',
                                          method: 'PATCH',
                                          data: fields,
                                        );
                                        if (mounted) _refresh();
                                      },
                                    ),
                                    BotonAccionApi(
                                      label: 'Usar las tarifas generales',
                                      action: () async {
                                        await _api.object(
                                          '/admin/commerce/rates/${rate['areaId']}',
                                          method: 'PATCH',
                                          data: {
                                            'precioMinutoOnline': null,
                                            'precioMinutoPresencial': null,
                                          },
                                        );
                                        if (mounted) _refresh();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                final rows = jsonRows(data['items']);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (rows.isEmpty)
                      EstadoVacioApi(
                        message: _tab == 0
                            ? 'Todavía no hay solicitudes empresariales.'
                            : 'Todavía no hay campañas publicitarias.',
                      ),
                    for (final row in rows)
                      TarjetaSuave(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                textValue(row[_tab == 0 ? 'nombre' : 'titulo']),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Estado: ${row['estado']}'),
                              const SizedBox(height: 12),
                              if (_tab == 0) ...[
                                SelectableText(
                                  'Razón social: ${row['razonSocial']}\nRUC: ${row['ruc']}\nCorreo comercial: ${row['emailComercial']}\nTeléfono: ${row['telefono']}\nCiudad: ${row['ciudad']}',
                                ),
                                const SizedBox(height: 10),
                                Text(textValue(row['descripcion'])),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final state in [
                                      'aprobada',
                                      'rechazada',
                                      'suspendida',
                                    ])
                                      OutlinedButton(
                                        onPressed: () => _review(row, state),
                                        child: Text(
                                          {
                                            'aprobada': 'Aprobar',
                                            'rechazada': 'Rechazar',
                                            'suspendida': 'Suspender',
                                          }[state]!,
                                        ),
                                      ),
                                  ],
                                ),
                              ] else ...[
                                SizedBox(
                                  height: 160,
                                  child: ImagenApi(
                                    fileId: textValue(row['bannerArchivoId']),
                                    fallback: const Icon(Icons.image_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(textValue(row['descripcion'])),
                                SelectableText(textValue(row['enlace'])),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: row['estado'] == 'bloqueada'
                                        ? null
                                        : () => _review(row, 'bloqueada'),
                                    icon: const Icon(Icons.block_outlined),
                                    label: const Text('Retirar campaña'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    PaginacionApi(
                      page: PaginaApi.fromJson(data),
                      load: (page) async {
                        setState(() {
                          _page = page;
                          _data = _load();
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
