// Archivo: lib/models/administracion/views/revision_conversacion_view.dart
// Permite al personal autorizado revisar una conversación en el contexto de su auditoría.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/core/utilidades/formato_presentacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/estructura_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Revisión separada de la bandeja personal. No envía ni modifica lecturas.
class RevisionConversacionView extends StatefulWidget {
  const RevisionConversacionView({super.key, this.kind = '', this.userId});
  final String kind;
  final String? userId;
  @override
  State<RevisionConversacionView> createState() =>
      _RevisionConversacionViewState();
}

class _RevisionConversacionViewState extends State<RevisionConversacionView> {
  final _search = TextEditingController();
  final _api = AplicacionController.instance.api;
  PaginaApi? _list, _messages;
  Json? _selected;
  bool _loading = true, _opening = false;
  String? _error;
  int _request = 0, _messageRequest = 0;
  Timer? _debounce;
  String get _route => switch (widget.kind) {
    'tutoria' => RutasAplicacion.adminCourseConversations,
    'market' => RutasAplicacion.adminMarketConversations,
    _ => RutasAplicacion.adminConversations,
  };
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([int page = 1]) async {
    final request = ++_request;
    setState(() => _loading = true);
    try {
      final result = await _api.page(
        '/admin/conversations',
        page: page,
        query: {
          if (widget.kind.isNotEmpty) 'tipo': widget.kind,
          if (widget.userId != null) 'usuarioId': widget.userId,
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        },
      );
      if (mounted && request == _request) {
        setState(() {
          _list = result;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e.toString());
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _open(Json row, [int page = 1]) async {
    final request = ++_messageRequest;
    setState(() {
      _selected = row;
      _opening = true;
      _error = null;
    });
    try {
      final id = textValue(row['id']);
      final header = await _api.object('/admin/conversations/$id');
      final messages = await _api.page(
        '/admin/conversations/$id/messages',
        page: page,
        query: {'limit': 50},
      );
      if (mounted && request == _messageRequest) {
        setState(() {
          _selected = header;
          _messages = messages;
        });
      }
    } catch (e) {
      if (mounted && request == _messageRequest) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted && request == _messageRequest) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => EstructuraAdministracion(
    current: _route,
    child: Column(
      children: [
        const BarraSuperiorAdmin(
          title: 'Conversaciones',
          subtitle: 'Revisión de tutorías y marketplace',
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tab in [
                ('', 'Todas'),
                ('tutoria', 'Tutorías'),
                ('market', 'Marketplace'),
              ])
                ChoiceChip(
                  label: Text(tab.$2),
                  selected: widget.kind == tab.$1,
                  onSelected: (_) {
                    final route = switch (tab.$1) {
                      'tutoria' => RutasAplicacion.adminCourseConversations,
                      'market' => RutasAplicacion.adminMarketConversations,
                      _ => RutasAplicacion.adminConversations,
                    };
                    NavegadorAplicacion.go(
                      context,
                      widget.userId == null
                          ? route
                          : '$route?user=${widget.userId}',
                    );
                  },
                ),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Persona, artículo o curso',
                    prefixIcon: Icon(Icons.search, size: 19),
                  ),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 350),
                      () => _load(),
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Actualizar conversaciones',
                onPressed: () => _load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (_error != null)
          AvisoErrorApi(message: _error!, retry: () => _load()),
        Expanded(
          child: LayoutBuilder(
            builder: (context, size) {
              final wide = size.maxWidth >= 950;
              if (!wide) {
                return _selected == null ? _inbox() : _detail(compact: true);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 330, child: _inbox()),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _selected == null
                        ? const EstadoVacioApi(
                            message:
                                'Selecciona una conversación para revisar su historial.',
                          )
                        : _detail(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
  Widget _inbox() => Material(
    color: Colors.white,
    child: Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _list?.items.isEmpty != false
              ? const EstadoVacioApi(
                  message:
                      'No hay conversaciones que coincidan con la búsqueda.',
                )
              : ListView.separated(
                  itemCount: _list!.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = _list!.items[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      selected: c['id'] == _selected?['id'],
                      selectedTileColor: ColoresAplicacion.surfaceBlue,
                      leading: Icon(
                        c['tipo'] == 'market'
                            ? Icons.storefront_outlined
                            : Icons.school_outlined,
                        color: ColoresAplicacion.blue,
                        size: 22,
                      ),
                      title: Text(
                        textValue(
                          c['recursoTitulo'],
                          'Publicación no disponible',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          '${textValue(c['consultanteNombre'])} · ${textValue(c['propietarioNombre'])}\n${textValue(c['mensajes'])} mensajes',
                          style: const TextStyle(fontSize: 11, height: 1.7),
                        ),
                      ),
                      onTap: () => _open(c),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: PaginacionApi(page: _list, load: (p) => _load(p)),
        ),
      ],
    ),
  );
  Widget _detail({bool compact = false}) {
    final c = _selected!;
    return Column(
      children: [
        if (compact)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.arrow_back, size: 17),
              label: const Text('Volver a conversaciones'),
            ),
          ),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    color: ColoresAplicacion.blue,
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Revisión administrativa · solo lectura',
                      style: TextStyle(
                        fontSize: 11,
                        color: ColoresAplicacion.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                textValue(c['recursoTitulo']),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${textValue(c['consultanteNombre'])}  ↔  ${textValue(c['propietarioNombre'])}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColoresAplicacion.muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La consulta queda registrada en auditoría. Los mensajes conservan su estado de lectura.',
                style: TextStyle(
                  fontSize: 11,
                  color: ColoresAplicacion.muted.withValues(alpha: .9),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _opening
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    for (final m in _messages?.items ?? <Json>[]) _bubble(m, c),
                    if (_messages?.items.isEmpty == true)
                      const EstadoVacioApi(
                        message: 'Esta conversación no tiene mensajes.',
                      ),
                    PaginacionApi(
                      page: _messages,
                      load: (page) => _open(c, page),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _bubble(Json m, Json c) {
    final owner = textValue(m['autorId']) == textValue(c['propietarioId']);
    final deleted = m['eliminadoEn'] != null;
    final attachment = jsonObject(m['adjunto']);
    return Align(
      alignment: owner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: owner ? ColoresAplicacion.surfaceBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColoresAplicacion.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              textValue(c[owner ? 'propietarioNombre' : 'consultanteNombre']),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ColoresAplicacion.blue,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              deleted ? 'Mensaje eliminado' : textValue(m['contenido']),
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),
            if (!deleted && m['archivoId'] != null) ...[
              if (textValue(attachment['mimeDetectado']).startsWith('image/'))
                SizedBox(
                  width: 260,
                  height: 180,
                  child: ImagenApi(
                    fileId: textValue(m['archivoId']),
                    fit: BoxFit.contain,
                    fallback: const Icon(Icons.image_outlined),
                  ),
                ),
              TextButton.icon(
                icon: const Icon(Icons.attach_file, size: 16),
                label: Text(
                  textValue(attachment['nombreOriginal'], 'Archivo adjunto'),
                ),
                onPressed: () => runApiAction(context, () async {
                  await launchUrl(
                    await AplicacionController.instance.fileAccess(
                      textValue(m['archivoId']),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              localDateTime(m['creadoEn']),
              style: const TextStyle(
                fontSize: 10,
                color: ColoresAplicacion.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
