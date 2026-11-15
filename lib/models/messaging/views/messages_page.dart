import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';
import 'package:unired/core/utils/app_navigator.dart';
import 'package:unired/shared/themes/app_colors.dart';
import 'package:unired/shared/widgets/admin_components.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/workspace_frame.dart';
import 'package:unired/shared/widgets/municipality_picker.dart';
import 'package:unired/core/constants/nicaragua_municipalities.dart';
import 'package:unired/models/messaging/widgets/conversation_subject.dart';

/// Bandeja compartida por usuario y administrador. Solo cambia el entorno;
/// la API exige ser participante, también cuando se tiene rol administrativo.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, this.id, this.asAdmin = false});
  final String? id;
  final bool asAdmin;
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _store = AppService.instance,
      _text = TextEditingController(),
      _search = TextEditingController();
  final _scroll = ScrollController();
  List<Json> _conversations = [], _messages = [];
  ApiPage? _page;
  Json? _selected, _attachment;
  String? _id, _nonce, _pendingText, _error;
  String _filter = 'all';
  bool _syncing = false, _sending = false, _loading = true, _details = false;
  bool _listing = false, _picking = false, _detailsTouched = false;
  int _request = 0, _listRequest = 0, _historyPage = 1;
  Timer? _poll, _debounce;
  @override
  void initState() {
    super.initState();
    _id = widget.id;
    if (_id != null) unawaited(_header(_id!));
    unawaited(_refresh());
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        unawaited(_sync(background: true));
        unawaited(_refresh(background: true));
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _debounce?.cancel();
    _text.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _header(String id) async {
    final generation = _request;
    try {
      final row = await _store.api.object(
        '/conversations/$id',
        foreground: false,
      );
      if (mounted && generation == _request && _id == id) {
        setState(() => _selected = {...?_selected, ...row});
      }
    } catch (e) {
      if (mounted && generation == _request) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _refresh({bool more = false, bool background = false}) async {
    if (background && _listing) return;
    _listing = true;
    final generation = ++_listRequest;
    try {
      final result = await _store.api.page(
        '/me/conversations',
        page: more ? (_page?.page ?? 0) + 1 : 1,
        foreground: !background,
        query: {
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
          if (['market', 'tutoria'].contains(_filter)) 'tipo': _filter,
          if (_filter == 'unread') 'noLeidos': 'true',
        },
      );
      if (!mounted || generation != _listRequest) return;
      setState(() {
        _page = result;
        _conversations = more
            ? [..._conversations, ...result.items]
            : result.items;
        _loading = false;
        if (!background) _error = null;
        final updated = _conversations
            .where((c) => textValue(c['id']) == _id)
            .firstOrNull;
        if (updated != null) _selected = {...?_selected, ...updated};
      });
      if (!background && _id != null) await _sync();
    } catch (e) {
      if (mounted && generation == _listRequest) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    } finally {
      if (generation == _listRequest) _listing = false;
    }
  }

  void _bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.minScrollExtent);
      }
    });
  }

  Future<void> _sync({bool background = false}) async {
    final id = _id, generation = _request;
    if (id == null || _syncing || !mounted) return;
    _syncing = true;
    try {
      final after = _messages.lastOrNull?['id'];
      var page = await _store.api.page(
        '/conversations/$id/messages',
        foreground: !background,
        query: {'afterId': ?after},
      );
      if (after == null && page.hasMore) {
        page = await _store.api.page(
          '/conversations/$id/messages',
          page: (page.total / page.limit).ceil(),
          foreground: !background,
        );
      }
      if (!mounted || generation != _request) return;
      final nearBottom =
          !_scroll.hasClients ||
          _scroll.offset - _scroll.position.minScrollExtent < 130;
      final prior = _messages.length;
      setState(() {
        if (after == null) _historyPage = page.page;
        _messages =
            {
              for (final m in [..._messages, ...page.items])
                textValue(m['id']): m,
            }.values.toList()..sort(
              (a, b) => BigInt.parse(
                textValue(a['id']),
              ).compareTo(BigInt.parse(textValue(b['id']))),
            );
        if (!background) _error = null;
      });
      if (after == null || (nearBottom && _messages.length > prior)) _bottom();
      if (_messages.isNotEmpty && (!background || _messages.length > prior)) {
        await _store.api.object(
          '/conversations/$id/read',
          method: 'PUT',
          foreground: false,
          data: {'ultimoMensajeId': _messages.last['id']},
        );
        if (mounted && generation == _request) {
          setState(() {
            if (_selected != null) _selected = {..._selected!, 'noLeidos': 0};
          });
        }
      }
    } catch (e) {
      if (mounted && generation == _request) {
        setState(() => _error = e.toString());
      }
    } finally {
      _syncing = false;
      if (mounted && generation != _request) unawaited(_sync());
    }
  }

  Future<void> _older() async {
    final id = _id, generation = _request;
    if (id == null || _historyPage <= 1) return;
    final page = await _store.api.page(
      '/conversations/$id/messages',
      page: _historyPage - 1,
    );
    if (!mounted || generation != _request) return;
    setState(() {
      _messages = [...page.items, ..._messages];
      _historyPage = page.page;
    });
  }

  void _select(Json c) {
    setState(() {
      _id = textValue(c['id']);
      _selected = c;
      _messages = [];
      _attachment = null;
      _nonce = null;
      _pendingText = null;
      _historyPage = 1;
      _error = null;
      _request++;
      _text.clear();
      _details = false;
      _detailsTouched = false;
    });
    unawaited(_header(_id!));
    unawaited(_sync());
  }

  Future<void> _send() async {
    final id = _id, content = _text.text.trim(), generation = _request;
    if (id == null ||
        _sending ||
        _picking ||
        (content.isEmpty && _attachment == null)) {
      return;
    }
    setState(() => _sending = true);
    try {
      if (_pendingText != content) _nonce = null;
      _pendingText = content;
      _nonce ??= const Uuid().v4();
      await _store.api.object(
        '/conversations/$id/messages',
        method: 'POST',
        data: {
          'clienteId': _nonce,
          if (content.isNotEmpty) 'contenido': content,
          if (_attachment != null) 'archivoId': _attachment!['id'],
        },
      );
      if (!mounted || generation != _request) return;
      setState(() {
        _text.clear();
        _attachment = null;
        _nonce = null;
      });
      await _sync();
      _bottom();
      await _refresh(background: true);
    } catch (e) {
      if (mounted && generation == _request) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(Object? value) {
    final d = DateTime.tryParse(textValue(value))?.toLocal();
    return d == null
        ? ''
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => WorkspaceFrame(
    asAdmin: widget.asAdmin,
    route: widget.asAdmin ? AppRoutes.adminMessages : AppRoutes.messages,
    title: 'Mis mensajes',
    subtitle: 'Marketplace y tutorías',
    child: LayoutBuilder(
      builder: (_, size) {
        final narrow = size.maxWidth < 700;
        return Padding(
          padding: EdgeInsets.all(narrow ? 0 : 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(narrow ? 0 : 13),
            child: Material(
              color: Colors.white,
              child: Row(
                children: [
                  if (!narrow || _id == null)
                    SizedBox(
                      width: narrow
                          ? size.maxWidth
                          : (size.maxWidth * .29).clamp(240, 350),
                      child: _inbox(narrow),
                    ),
                  if (!narrow) const VerticalDivider(width: 1),
                  if (!narrow || _id != null)
                    Expanded(
                      child: _thread(
                        narrow,
                        inlineDetails: size.maxWidth <= 1220,
                      ),
                    ),
                  if (!narrow &&
                      _id != null &&
                      (_details || !_detailsTouched) &&
                      size.maxWidth > 1220) ...[
                    const VerticalDivider(width: 1),
                    SizedBox(width: 255, child: _context()),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  Widget _inbox(bool narrow) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_error != null)
        ApiErrorNotice(message: _error!, retry: () => _refresh()),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 21, 10, 14),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Chats',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar conversaciones',
              onPressed: () => _refresh(),
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _search,
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 300),
              () => _refresh(),
            );
          },
          decoration: const InputDecoration(
            hintText: 'Buscar chats',
            prefixIcon: Icon(Icons.search, size: 20),
            isDense: true,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        child: Wrap(
          spacing: 7,
          runSpacing: 4,
          children: [
            for (final e in {
              'all': 'Todos',
              'unread': 'No leídos',
              'market': 'Market',
              'tutoria': 'Tutorías',
            }.entries)
              ChoiceChip(
                label: Text(e.value, style: const TextStyle(fontSize: 11)),
                selected: _filter == e.key,
                onSelected: (_) {
                  setState(() => _filter = e.key);
                  unawaited(_refresh());
                },
              ),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
            ? (_filter != 'all' || _search.text.trim().isNotEmpty
                  ? _emptySearch()
                  : narrow
                  ? _chatWelcome()
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No tienes conversaciones todavía.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ))
            : ListView(
                children: [
                  for (final c in _conversations)
                    Material(
                      color: _id == textValue(c['id'])
                          ? AppColors.surfaceBlue
                          : Colors.white,
                      child: InkWell(
                        onTap: () => _select(c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              ChatSubjectImage(row: c),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chatSubjectTitle(c),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _time(c['ultimoMensajeEn']),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      textValue(c['interlocutorNombre']),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      textValue(
                                        c['ultimoMensaje'],
                                        textValue(
                                          c['recursoTitulo'],
                                          'Empieza la conversación',
                                        ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['tipo'] == 'market'
                                          ? 'Marketplace'
                                          : 'Tutoría',
                                      style: const TextStyle(
                                        color: AppColors.blue,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (intValue(c['noLeidos']) > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 7),
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: AppColors.coral,
                                    child: Text(
                                      '${c['noLeidos']}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_page?.hasMore == true)
                    TextButton(
                      onPressed: () => _refresh(more: true),
                      child: const Text('Cargar más conversaciones'),
                    ),
                ],
              ),
      ),
    ],
  );
  Widget _thread(bool narrow, {bool inlineDetails = false}) {
    if (_id == null) {
      return _chatWelcome();
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              if (narrow)
                IconButton(
                  tooltip: 'Volver a chats',
                  onPressed: () => setState(() {
                    _id = null;
                    _request++;
                  }),
                  icon: const Icon(Icons.arrow_back),
                ),
              ChatSubjectImage(row: _selected, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatSubjectTitle(_selected),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      textValue(
                        _selected?['interlocutorNombre'],
                        'Conversación privada',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Detalles de la conversación',
                onPressed: () => setState(() {
                  final visible =
                      _details || (!inlineDetails && !_detailsTouched);
                  _detailsTouched = true;
                  _details = !visible;
                }),
                icon: const Icon(Icons.info_outline, size: 21),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opciones del chat',
                onSelected: (v) => runApiAction(context, () async {
                  await _store.api.object(
                    '/me/conversations/$_id',
                    method: 'PATCH',
                    data: v == 'archive'
                        ? {'archivada': true}
                        : {'silenciada': !(_selected?['silenciada'] == true)},
                  );
                  if (v == 'archive' && mounted) {
                    setState(() {
                      _id = null;
                      _messages = [];
                      _request++;
                    });
                  }
                  await _refresh();
                }),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Archivar conversación'),
                  ),
                  PopupMenuItem(
                    value: 'mute',
                    child: Text(
                      _selected?['silenciada'] == true
                          ? 'Activar avisos'
                          : 'Silenciar avisos',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_selected != null && !(_details && inlineDetails))
          ChatSubjectPreview(row: _selected!, onOpen: _openPublication),
        if (_details && inlineDetails)
          Expanded(child: _context())
        else ...[
          if (_error != null && narrow)
            ApiErrorNotice(message: _error!, retry: () => _sync()),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF1F5FA),
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Saluda y comienza la conversación.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : _chatColumn(
                      ListView(
                        controller: _scroll,
                        reverse: true,
                        padding: EdgeInsets.all(narrow ? 14 : 24),
                        children: [
                          for (var i = _messages.length - 1; i >= 0; i--) ...[
                            _bubble(_messages[i]),
                            if (i == 0 ||
                                textValue(
                                      _messages[i]['creadoEn'],
                                    ).split('T').first !=
                                    textValue(
                                      _messages[i - 1]['creadoEn'],
                                    ).split('T').first)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 17,
                                  top: 5,
                                ),
                                child: Center(
                                  child: Text(
                                    adminDate(_messages[i]['creadoEn']),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          if (_historyPage > 1)
                            Center(
                              child: TextButton.icon(
                                onPressed: () => runApiAction(context, _older),
                                icon: const Icon(Icons.history, size: 16),
                                label: const Text('Mensajes anteriores'),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
          _composer(),
        ],
      ],
    );
  }

  Widget _emptySearch() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No hay chats con estos filtros.'),
        TextButton(
          onPressed: () {
            _debounce?.cancel();
            _search.clear();
            setState(() => _filter = 'all');
            unawaited(_refresh());
          },
          child: const Text('Limpiar filtros'),
        ),
      ],
    ),
  );

  Widget _chatWelcome() {
    final canStart =
        !_loading &&
        _conversations.isEmpty &&
        _filter == 'all' &&
        _search.text.trim().isEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  color: AppColors.blue,
                  size: 31,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                canStart ? 'Empieza una conversación' : 'Tus conversaciones',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                canStart
                    ? 'Contacta al vendedor desde un artículo o al tutor desde el aula.'
                    : 'Selecciona un chat para continuar.',
                textAlign: TextAlign.center,
              ),
              if (canStart) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 9,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          AppNavigator.go(context, AppRoutes.market),
                      child: const Text('Explorar artículos'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          AppNavigator.go(context, AppRoutes.tutorials),
                      child: const Text('Explorar tutorías'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const _locationPrefix = 'Ubicación · ';

  Future<void> _shareMunicipality() async {
    final conversation = _id;
    final municipality = await pickMunicipality(context);
    if (!mounted || municipality == null || conversation != _id) return;
    final body = [
      if (_text.text.trim().isNotEmpty) _text.text.trim(),
      '$_locationPrefix$municipality',
    ].join('\n');
    if (body.length > 10000) return;
    setState(() {
      _text.value = TextEditingValue(
        text: body,
        selection: TextSelection.collapsed(offset: body.length),
      );
      _nonce = null;
    });
  }

  Widget _chatColumn(Widget child) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: child,
    ),
  );

  Widget _bubble(Json m) {
    final own = textValue(m['autorId']) == _store.currentUser?.id,
        deleted = m['eliminadoEn'] != null;
    final file = jsonObject(m['adjunto']);
    final content = textValue(m['contenido']);
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: mathWidth),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(15, 11, 12, 8),
        decoration: BoxDecoration(
          color: own ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(own ? 14 : 3),
            bottomRight: Radius.circular(own ? 3 : 14),
          ),
          border: own ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deleted)
              const Text('Mensaje eliminado')
            else if (content.isNotEmpty)
              _messageText(content, own),
            if (!deleted && m['archivoId'] != null) ...[
              if (textValue(file['mimeDetectado']).startsWith('image/'))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 245,
                      height: 155,
                      child: ApiImage(
                        fileId: textValue(m['archivoId']),
                        fit: BoxFit.contain,
                        fallback: const Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: own ? Colors.white : AppColors.blue,
                ),
                onPressed: () => runApiAction(context, () async {
                  await launchUrl(
                    await _store.fileAccess(textValue(m['archivoId'])),
                  );
                }),
                icon: const Icon(Icons.attach_file, size: 17),
                label: Text(
                  textValue(file['nombreOriginal'], 'Abrir archivo adjunto'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(m['creadoEn']),
                  style: TextStyle(
                    fontSize: 9,
                    color: own ? Colors.white70 : AppColors.muted,
                  ),
                ),
                if (own) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.check, size: 12, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageText(String content, bool own) {
    final lines = content.split('\n');
    final last = lines.last;
    final place = last.startsWith(_locationPrefix)
        ? last.substring(_locationPrefix.length)
        : '';
    final hasPlace = nicaraguaMunicipalities.contains(place);
    final color = own ? Colors.white : AppColors.ink;
    if (!hasPlace) {
      return SelectableText(
        content,
        style: TextStyle(color: color, height: 1.5, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lines.length > 1)
          SelectableText(
            lines.take(lines.length - 1).join('\n'),
            style: TextStyle(color: color, height: 1.5, fontSize: 13),
          ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: color,
            padding: EdgeInsets.zero,
          ),
          onPressed: () => runApiAction(context, () async {
            await launchUrl(
              Uri.https('www.openstreetmap.org', '/search', {
                'query': '$place, Nicaragua',
              }),
            );
          }),
          icon: const Icon(Icons.place_outlined, size: 17),
          label: Text(place),
        ),
      ],
    );
  }

  double get mathWidth =>
      (MediaQuery.sizeOf(context).width * .58).clamp(180, 490);
  Widget _composer() => Container(
    padding: const EdgeInsets.all(14),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.line)),
    ),
    child: _chatColumn(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachment != null)
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pendiente de enviar · ${textValue(_attachment!['nombreOriginal'], 'Adjunto preparado')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar adjunto',
                  onPressed: () => setState(() {
                    _attachment = null;
                    _nonce = null;
                  }),
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Adjuntar imagen o PDF',
                onPressed: _sending || _picking
                    ? null
                    : () => runApiAction(context, () async {
                        final generation = _request;
                        setState(() => _picking = true);
                        try {
                          final file = await _store.pickAndUpload(
                            'adjunto_chat',
                          );
                          if (file != null &&
                              mounted &&
                              generation == _request) {
                            setState(() {
                              _attachment = file;
                              _nonce = null;
                            });
                          }
                        } finally {
                          if (mounted) setState(() => _picking = false);
                        }
                      }),
                icon: const Icon(Icons.attach_file, color: AppColors.blue),
              ),
              IconButton(
                tooltip: 'Compartir municipio',
                onPressed: _sending ? null : _shareMunicipality,
                icon: const Icon(Icons.place_outlined, color: AppColors.blue),
              ),
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(
                      LogicalKeyboardKey.enter,
                      control: true,
                    ): () =>
                        unawaited(_send()),
                  },
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLength: 10000,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText:
                          'Escribe un mensaje… (Ctrl + Enter para enviar)',
                      counterText: '',
                      isDense: true,
                      filled: true,
                      fillColor: Color(0xFFF5F7FA),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Enviar mensaje',
                onPressed:
                    _sending ||
                        _picking ||
                        (_text.text.trim().isEmpty && _attachment == null)
                    ? null
                    : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 21),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  void _openPublication() {
    final row = _selected;
    final id = row?['anuncioId'] ?? row?['tutoriaId'];
    if (id == null) return;
    AppNavigator.go(
      context,
      '${row?['anuncioId'] != null ? AppRoutes.listing : AppRoutes.course}?id=$id',
    );
  }

  Widget _context() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Acerca de esta conversación',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      const SizedBox(height: 16),
      if (_selected != null)
        ChatSubjectPreview(
          row: _selected!,
          onOpen: _openPublication,
          detailed: true,
        ),
      const SizedBox(height: 18),
      Text(
        'Conversas con ${textValue(_selected?['interlocutorNombre'])}',
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      const Divider(height: 32),
      const Text(
        'Archivos compartidos',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      for (final m in _messages.where(
        (m) => m['archivoId'] != null && m['eliminadoEn'] == null,
      ))
        TextButton.icon(
          onPressed: () => runApiAction(context, () async {
            await launchUrl(await _store.fileAccess(textValue(m['archivoId'])));
          }),
          icon: const Icon(Icons.description_outlined, size: 17),
          label: Text(
            textValue(
              jsonObject(m['adjunto'])['nombreOriginal'],
              'Archivo adjunto',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
  );
}
