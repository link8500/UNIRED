// Archivo: lib/models/comercial/views/empresas_view.dart
// Afiliación de empresas, selección de planes y administración de sus campañas.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/comercial/widgets/pago_demo.dart';
import 'package:unired/models/comercial/widgets/editor_campana.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/marco_gestion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';

class EmpresasView extends StatefulWidget {
  const EmpresasView({super.key, this.companyId, this.asAdmin = false});
  final bool asAdmin;
  final String? companyId;
  @override
  State<EmpresasView> createState() => _EmpresasViewState();
}

class _EmpresasViewState extends State<EmpresasView> {
  final _api = AplicacionController.instance.api;
  String get _route =>
      widget.asAdmin ? RutasAplicacion.adminBusiness : RutasAplicacion.business;
  late Future<Json> _data = _load();
  bool _newCompany = false, _newCampaign = false;
  Json? _editCampaign;
  Future<Json> _load() async {
    final result = await Future.wait([
      _api.request('/business/plans', authenticated: false),
      widget.companyId == null
          ? _api.object('/me/businesses')
          : _api.object('/me/businesses/${widget.companyId}'),
    ]);
    return {'plans': jsonRows(result[0]), 'company': jsonObject(result[1])};
  }

  void _refresh() => setState(() {
    _data = _load();
  });
  @override
  Widget build(BuildContext context) => MarcoGestion(
    asAdmin: widget.asAdmin,
    title: 'Mis empresas',
    subtitle: 'Mi cuenta',
    route: widget.asAdmin ? RutasAplicacion.adminProfile : _route,
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
            final data = snapshot.data!, company = jsonObject(data['company']);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.companyId != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => NavegadorAplicacion.go(context, _route),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Mis empresas'),
                    ),
                  ),
                Text(
                  widget.companyId == null
                      ? 'UniRed para empresas'
                      : textValue(company['nombre']),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: ColoresAplicacion.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conecta tu negocio con la comunidad. Solicita tu afiliación, elige un plan y prepara tus campañas.',
                ),
                const SizedBox(height: 24),
                if (widget.companyId == null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () =>
                          setState(() => _newCompany = !_newCompany),
                      icon: Icon(
                        _newCompany ? Icons.close : Icons.add_business,
                      ),
                      label: Text(
                        _newCompany
                            ? 'Cerrar formulario'
                            : 'Solicitar afiliación',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_newCompany)
                    FormularioApi(
                      title: 'Datos de la empresa',
                      label: 'Enviar solicitud',
                      fields: const [
                        CampoApi('nombre', 'Nombre comercial'),
                        CampoApi('razonSocial', 'Razón social'),
                        CampoApi('ruc', 'RUC o identificación del negocio'),
                        CampoApi('emailComercial', 'Correo comercial'),
                        CampoApi('telefono', 'Teléfono comercial'),
                        CampoApi(
                          'sitioWeb',
                          'Sitio web HTTPS (opcional)',
                          required: false,
                        ),
                        CampoApi('ciudad', 'Ciudad'),
                        CampoApi(
                          'descripcion',
                          '¿Qué ofrece tu empresa?',
                          lines: 4,
                        ),
                      ],
                      submit: (fields) async {
                        await _api.object(
                          '/me/businesses',
                          method: 'POST',
                          data: fields,
                        );
                        if (mounted) {
                          setState(() {
                            _newCompany = false;
                            _data = _load();
                          });
                        }
                      },
                    ),
                  if (jsonRows(company['items']).isEmpty && !_newCompany)
                    const EstadoVacioApi(
                      message:
                          'Aún no tienes empresas vinculadas. Tu primera solicitud comenzará aquí.',
                    ),
                  for (final row in jsonRows(company['items']))
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: const Icon(
                          Icons.business_outlined,
                          color: ColoresAplicacion.blue,
                        ),
                        title: Text(
                          textValue(row['nombre']),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${textValue(row['ciudad'])} · ${textValue(row['estado'])}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => NavegadorAplicacion.go(
                          context,
                          '$_route?id=${row['id']}',
                        ),
                      ),
                    ),
                ] else
                  ..._company(context, company, jsonRows(data['plans'])),
              ],
            );
          },
        ),
      ),
    ),
  );
  List<Widget> _company(BuildContext context, Json company, List<Json> plans) {
    final subscriptions = jsonRows(company['suscripciones']);
    final active = subscriptions
        .where(
          (row) =>
              row['estado'] == 'activa' &&
              DateTime.tryParse(
                    textValue(row['venceEn']),
                  )?.isAfter(DateTime.now()) ==
                  true,
        )
        .firstOrNull;
    final approved = company['estado'] == 'aprobada';
    return [
      TarjetaSuave(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Afiliación ${textValue(company['estado'])}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(textValue(company['descripcion'])),
            if (textValue(company['motivoRevision']).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Revisión: ${company['motivoRevision']}'),
            ],
            if (!approved) ...[
              const SizedBox(height: 12),
              const Text(
                'El equipo debe aprobar la empresa antes de activar planes y campañas.',
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 26),
      if (active == null) ...[
        const Text(
          'Elige un plan de demostración',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vigencia de 30 días. Sin renovación automática ni dinero real.',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final plan in plans)
                SizedBox(
                  width: box.maxWidth >= 850
                      ? (box.maxWidth - 32) / 3
                      : box.maxWidth,
                  child: TarjetaSuave(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          textValue(plan['nombre']),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(textValue(plan['descripcion'])),
                        const SizedBox(height: 20),
                        Text(
                          'C\$ ${textValue(plan['precioMensual'])}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: ColoresAplicacion.navy,
                          ),
                        ),
                        const Text('por 30 días · demostración'),
                        const SizedBox(height: 14),
                        Text('${plan['maxCampanas']} campañas disponibles'),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: approved
                              ? () async {
                                  final result = await mostrarPagoDemo(
                                    context,
                                    title: 'Plan ${plan['nombre']} · 30 días',
                                    amount: textValue(plan['precioMensual']),
                                    operation: {
                                      'concepto': 'suscripcion_empresa',
                                      'recursoId': widget.companyId,
                                      'planId': textValue(plan['id']),
                                    },
                                  );
                                  if (result != null && context.mounted) {
                                    _refresh();
                                    await AvisosAplicacion.show(
                                      context,
                                      kind: TipoAviso.success,
                                      title: 'Plan de demostración activado',
                                      message:
                                          'Ya puedes preparar tus campañas. No se realizó ningún cobro.',
                                    );
                                  }
                                }
                              : null,
                          child: const Text('Elegir plan'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ] else
        TarjetaSuave(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu plan está activo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Vence: ${textValue(active['venceEn']).split('T').first} · Demostración',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: approved
                        ? () => setState(() {
                            _newCampaign = true;
                            _editCampaign = null;
                          })
                        : null,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Crear campaña'),
                  ),
                  BotonAccionApi(
                    label: 'Cancelar plan',
                    icon: Icons.cancel_outlined,
                    action: () async {
                      await _api.object(
                        '/me/businesses/${widget.companyId}/subscription',
                        method: 'DELETE',
                      );
                      AplicacionController.instance.refreshPublicPromotions();
                      if (mounted) _refresh();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      const SizedBox(height: 26),
      if (_newCampaign && active != null)
        EditorCampana(
          key: ValueKey(_editCampaign?['id'] ?? 'new'),
          companyId: widget.companyId!,
          subscription: active,
          initial: _editCampaign,
          finished: () {
            setState(() {
              _newCampaign = false;
              _editCampaign = null;
              _data = _load();
            });
          },
        ),
      const SizedBox(height: 18),
      const Text(
        'Campañas de tu empresa',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      if (jsonRows(company['campanas']).isEmpty)
        const EstadoVacioApi(
          message: 'Tus banners y campañas aparecerán aquí.',
        ),
      for (final campaign in jsonRows(company['campanas']))
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ImagenApi(
                      fileId: textValue(campaign['bannerArchivoId']),
                      fallback: const Center(
                        child: Icon(Icons.image_outlined, size: 36),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  textValue(campaign['titulo']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(textValue(campaign['descripcion'])),
                const SizedBox(height: 8),
                Text(
                  'Estado: ${campaign['estado']} · Hasta ${textValue(campaign['terminaEn']).split('T').first}',
                ),
                if (active != null && campaign['estado'] != 'bloqueada')
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _newCampaign = true;
                        _editCampaign = campaign;
                      }),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar campaña'),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];
  }
}
