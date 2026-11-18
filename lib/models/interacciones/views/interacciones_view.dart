// Archivo: lib/models/interacciones/views/interacciones_view.dart
// Bandejas de negociación y tutoría; separa lo pendiente, activo y finalizado.
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/core/constantes/estado_publicacion.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/comercial/widgets/pago_demo.dart';
import 'package:unired/models/interacciones/widgets/valorar_interaccion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/formulario_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/marco_gestion.dart';

class InteraccionesView extends StatefulWidget {
  const InteraccionesView({
    super.key,
    this.asAdmin = false,
    this.tutorials = false,
    this.initialTab = 0,
  });
  final bool tutorials, asAdmin;
  final int initialTab;
  @override
  State<InteraccionesView> createState() => _InteraccionesViewState();
}

class _InteraccionesViewState extends State<InteraccionesView> {
  final _store = AplicacionController.instance;
  late Future<PaginaApi> _data = _load();
  late int _tab = widget.initialTab;
  int _page = 1, _revision = 0;
  String _state = '';
  final _material = <String>{};
  String get _root => widget.tutorials ? '/me/tutoring-requests' : '/me/offers';
  @override
  void initState() {
    super.initState();
    _revision = _store.notificationsRevision;
    _store.addListener(_changed);
  }

  @override
  void dispose() {
    _store.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted ||
        _store.currentUser == null ||
        _revision == _store.notificationsRevision) {
      return;
    }
    _revision = _store.notificationsRevision;
    if (_material.isEmpty) {
      setState(() {
        _data = _load(foreground: false);
      });
    }
  }

  Future<PaginaApi> _load({bool foreground = true}) => _store.api.page(
    _root,
    page: _page,
    foreground: foreground,
    query: {
      if (_state.isNotEmpty) 'estado': _state,
      if (widget.tutorials)
        'vista': ['mias', 'disponibles', 'impartidas'][_tab],
      if (!widget.tutorials && _tab > 0)
        'bandeja': _tab == 1 ? 'recibidas' : 'enviadas',
    },
  );
  void _refresh() => setState(() {
    _data = _load();
  });
  Future<void> _payRequest(Json row) async {
    final payment = await mostrarPagoDemo(
      context,
      title: textValue(row['tema']),
      amount: textValue(row['precio']),
      operation: {'concepto': 'tutoria_solicitud', 'recursoId': row['id']},
    );
    if (!mounted || payment == null) return;
    final receipt = jsonObject(payment['pago']);
    _refresh();
    await mostrarComprobanteDemo(
      context,
      textValue(row['tema']),
      receipt['importe'],
      receipt['id'],
      receipt['creadoEn'],
    );
  }

  Future<void> _decision(
    Json row,
    String state, {
    bool accept = false,
    bool ignore = false,
  }) async {
    if (['cancelada', 'finalizada'].contains(state)) {
      final ok = await AvisosAplicacion.show(
        context,
        kind: TipoAviso.warning,
        title: state == 'finalizada'
            ? 'Finalizar interacción'
            : 'Cancelar interacción',
        message:
            'Se cerrará el chat. Podrás consultar el estado desde tu historial.',
        action: 'Confirmar',
        cancel: 'Volver',
      );
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    await runApiAction(context, () async {
      await _store.api.object(
        '$_root/${row['id']}${accept
            ? '/accept'
            : ignore
            ? '/ignore'
            : ''}',
        method: accept || ignore ? 'POST' : 'PATCH',
        data: accept || ignore ? null : {'estado': state},
      );
      if (mounted) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) => MarcoGestion(
    asAdmin: widget.asAdmin,
    title: widget.tutorials ? 'Historial de solicitudes' : 'Mis ofertas',
    subtitle: 'Mi cuenta',
    route: widget.asAdmin
        ? RutasAplicacion.adminProfile
        : (widget.tutorials
              ? RutasAplicacion.tutoringRequests
              : RutasAplicacion.offers),
    child: SingleChildScrollView(
      child: SeccionPagina(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.tutorials
                  ? 'Historial de solicitudes'
                  : 'Mis ofertas del market',
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                color: ColoresAplicacion.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.tutorials
                  ? 'Aquí puedes continuar las solicitudes anteriores. Si quieres empezar a estudiar un tema, busca una tutoría publicada.'
                  : 'Revisa las propuestas recibidas y enviadas. El chat se habilita después de aceptar la oferta.',
            ),
            const SizedBox(height: 20),
            if (widget.tutorials)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => NavegadorAplicacion.go(
                    context,
                    RutasAplicacion.tutorials,
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar tutorías'),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(
                      (widget.tutorials
                          ? [
                              'Mis solicitudes',
                              'Disponibles para mí',
                              'Mis tutorías',
                            ]
                          : ['Todas', 'Recibidas', 'Enviadas'])[i],
                    ),
                    selected: _tab == i,
                    onSelected: (_) => setState(() {
                      _tab = i;
                      _page = 1;
                      _data = _load();
                    }),
                  ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: _state,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Todos los estados'),
                      ),
                      for (final state
                          in widget.tutorials
                              ? [
                                  'publicada',
                                  'aceptada',
                                  'cancelada',
                                  'finalizada',
                                ]
                              : [
                                  'pendiente',
                                  'aceptada',
                                  'rechazada',
                                  'cancelada',
                                  'finalizada',
                                ])
                        DropdownMenuItem(
                          value: state,
                          child: Text(_label(state)),
                        ),
                    ],
                    onChanged: (state) => setState(() {
                      _state = state ?? '';
                      _page = 1;
                      _data = _load();
                    }),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar bandeja',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FutureBuilder<PaginaApi>(
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
                final page = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (page.items.isEmpty)
                      EstadoVacioApi(
                        message: widget.tutorials && _tab == 1
                            ? 'Aquí verás solicitudes de las materias en las que estés acreditado.'
                            : 'No hay interacciones con estos filtros.',
                      ),
                    for (final row in page.items)
                      KeyedSubtree(key: ValueKey(row['id']), child: _card(row)),
                    PaginacionApi(
                      page: page,
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
  Widget _card(Json row) {
    final request = widget.tutorials;
    final id = textValue(row['id']), state = textValue(row['estado']);
    final owner =
        textValue(row[request ? 'alumnoId' : 'vendedorId']) ==
        _store.currentUser?.id;
    final peerId = request
        ? (owner ? row['tutorId'] : row['alumnoId'])
        : (owner ? row['compradorId'] : row['vendedorId']);
    final peerName = textValue(
      row[request
          ? (owner ? 'tutorNombre' : 'alumnoNombre')
          : (owner ? 'compradorNombre' : 'vendedorNombre')],
    );
    final title = textValue(row[request ? 'tema' : 'anuncioTitulo']);
    final priced =
        request && (double.tryParse(textValue(row['precio'])) ?? 0) > 0;
    final requiresPayment = request && row['requierePagoDemo'] == true;
    final paymentPending = requiresPayment && row['pagoDemoConfirmado'] != true;
    final courses = _store.myTutorials
        .where(
          (course) =>
              course.areaId == intValue(row['areaId']) &&
              course.status == EstadoPublicacion.published,
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TarjetaSuave(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Chip(
                  label: Text(
                    state == 'aceptada' && paymentPending
                        ? 'Pago demo pendiente'
                        : _label(state),
                  ),
                ),
              ],
            ),
            if (peerName.isNotEmpty)
              Text(
                peerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            Text(switch (state) {
              'publicada' =>
                'En espera de un tutor acreditado. Te avisaremos cuando alguien acepte.',
              'pendiente' =>
                owner
                    ? 'Revisa la propuesta. Al aceptarla se abrirá el chat con esta persona.'
                    : 'El autor está revisando tu propuesta. El chat se habilitará cuando la acepte.',
              'aceptada' =>
                paymentPending
                    ? (owner
                          ? 'Tu tutor aceptó. Confirma el pago demo para continuar.'
                          : 'En espera de que el estudiante confirme el pago demo.')
                    : 'Ya pueden conversar y acordar los detalles. Finaliza la interacción cuando hayan terminado.',
              'finalizada' =>
                'Interacción terminada. Puedes valorar tu experiencia y consultar el perfil de la otra persona.',
              'rechazada' =>
                'La propuesta no fue aceptada. Puedes continuar explorando el market.',
              _ =>
                'Interacción cancelada. Este registro se conserva en tu historial.',
            }, style: const TextStyle(color: ColoresAplicacion.muted)),
            const SizedBox(height: 10),
            if (request) ...[
              Text(
                '${textValue(row['materia'])} · ${row['duracionMinutos']} min · ${textValue(row['modalidad'])}',
              ),
              const SizedBox(height: 8),
              Text(textValue(row['descripcion'])),
              const SizedBox(height: 10),
              Text(switch ((priced, requiresPayment)) {
                (false, _) => 'Gratuita',
                (true, true) => 'Importe demo: C\$ ${textValue(row['precio'])}',
                (true, false) =>
                  'Importe registrado: C\$ ${textValue(row['precio'])}',
              }, style: const TextStyle(fontWeight: FontWeight.w700)),
            ] else ...[
              Text(textValue(row['mensaje'])),
              const SizedBox(height: 10),
              Text(
                row['tipo'] == 'intercambio'
                    ? 'Propuesta de intercambio'
                    : 'Oferta: ${textValue(row['moneda'])} ${textValue(row['importe'])}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!request && state == 'pendiente' && owner) ...[
                  BotonAccionApi(
                    label: 'Aceptar oferta',
                    action: () => _decision(row, 'aceptada'),
                  ),
                  OutlinedButton(
                    onPressed: () => _decision(row, 'rechazada'),
                    child: const Text('Rechazar'),
                  ),
                ],
                if (!request && state == 'pendiente' && !owner)
                  OutlinedButton(
                    onPressed: () => _decision(row, 'cancelada'),
                    child: const Text('Retirar oferta'),
                  ),
                if (request && state == 'publicada' && !owner) ...[
                  BotonAccionApi(
                    label: 'Aceptar solicitud',
                    action: () => _decision(row, 'aceptada', accept: true),
                  ),
                  OutlinedButton(
                    onPressed: () => _decision(row, '', ignore: true),
                    child: const Text('Omitir'),
                  ),
                ],
                if (request && state == 'publicada' && owner)
                  OutlinedButton(
                    onPressed: () => _decision(row, 'cancelada'),
                    child: const Text('Cancelar solicitud'),
                  ),
                if (state == 'aceptada') ...[
                  if (owner && paymentPending)
                    FilledButton.icon(
                      onPressed: () => _payRequest(row),
                      icon: const Icon(Icons.credit_card_outlined, size: 17),
                      label: const Text('Pagar con tarjeta de prueba'),
                    ),
                  if (row['conversacionId'] != null)
                    FilledButton.icon(
                      onPressed: () => NavegadorAplicacion.go(
                        context,
                        '${widget.asAdmin ? RutasAplicacion.adminMessages : RutasAplicacion.messages}?id=${row['conversacionId']}',
                      ),
                      icon: const Icon(Icons.forum_outlined, size: 17),
                      label: const Text('Abrir chat'),
                    ),
                  if (!paymentPending)
                    OutlinedButton(
                      onPressed: () => _decision(row, 'finalizada'),
                      child: const Text('Finalizar'),
                    ),
                  TextButton(
                    onPressed: () => _decision(row, 'cancelada'),
                    child: const Text('Cancelar'),
                  ),
                ],
                if (request && owner && row['pagoDemoId'] != null)
                  OutlinedButton.icon(
                    onPressed: () => mostrarComprobanteDemo(
                      context,
                      title,
                      row['precio'],
                      row['pagoDemoId'],
                      row['pagoDemoFecha'],
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 17),
                    label: const Text('Ver comprobante'),
                  ),
                if (request &&
                    ['aceptada', 'finalizada'].contains(state) &&
                    row['cursoId'] != null)
                  OutlinedButton.icon(
                    onPressed: () => NavegadorAplicacion.go(
                      context,
                      '${RutasAplicacion.course}?id=${row['cursoId']}&aula=1',
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 17),
                    label: const Text('Ver material'),
                  ),
                if (request &&
                    state == 'aceptada' &&
                    !owner &&
                    !paymentPending &&
                    row['cursoId'] == null)
                  OutlinedButton.icon(
                    onPressed: () => setState(
                      () => _material.contains(id)
                          ? _material.remove(id)
                          : _material.add(id),
                    ),
                    icon: const Icon(Icons.attach_file, size: 17),
                    label: const Text('Compartir material'),
                  ),
                if (state == 'finalizada')
                  BotonValorarInteraccion(
                    path: '$_root/$id/review',
                    alreadyReviewed: row['resenaPropiaId'] != null,
                    finished: _refresh,
                  ),
                if (peerId != null)
                  TextButton.icon(
                    onPressed: () => NavegadorAplicacion.go(
                      context,
                      RutasAplicacion.memberProfile(textValue(peerId)),
                    ),
                    icon: const Icon(Icons.person_outline, size: 17),
                    label: const Text('Ver perfil'),
                  ),
              ],
            ),
            if (_material.contains(id)) ...[
              const Divider(height: 30),
              if (courses.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Necesitas un curso publicado propio de esta materia para compartir videos y recursos.',
                    ),
                    TextButton(
                      onPressed: () => NavegadorAplicacion.go(
                        context,
                        RutasAplicacion.publication(
                          tutorial: true,
                          admin: false,
                          editing: true,
                        ),
                      ),
                      child: const Text('Preparar un curso'),
                    ),
                  ],
                )
              else
                FormularioApi(
                  title: 'Dar acceso al contenido',
                  label: 'Compartir curso',
                  fields: [
                    CampoApi(
                      'cursoId',
                      'Tu curso publicado',
                      kind: TipoCampoApi.choice,
                      choices: {
                        for (final course in courses) course.id: course.title,
                      },
                    ),
                  ],
                  submit: (fields) async {
                    await _store.api.object(
                      '$_root/$id/material',
                      method: 'POST',
                      data: fields,
                    );
                    if (mounted) {
                      _material.remove(id);
                      _refresh();
                    }
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _label(String state) => switch (state) {
    'publicada' => 'Buscando tutor',
    'pendiente' => 'En espera',
    'aceptada' => 'En curso',
    'finalizada' => 'Finalizada',
    'rechazada' => 'Rechazada',
    'cancelada' => 'Cancelada',
    _ => state,
  };
}
