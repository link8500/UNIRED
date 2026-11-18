// Archivo: lib/models/administracion/widgets/editor_publicacion.dart
// Guía la creación y edición de anuncios y tutorías por etapas y confirma los datos antes de publicarlos.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/market/models/articulo_market.dart';
import 'package:unired/models/tutorias/models/tutoria.dart';
import 'package:unired/models/administracion/widgets/vista_previa_publicacion.dart';
import 'package:unired/models/market/widgets/vista_previa_market.dart';
import 'package:unired/models/tutorias/widgets/gestion_curso.dart';
import 'package:unired/models/tutorias/widgets/vista_previa_autor.dart';
import 'package:unired/models/tutorias/widgets/componentes_editor_curso.dart';
import 'package:unired/shared/widgets/editor_imagen_publicacion.dart';
import 'package:unired/shared/widgets/detalles_publicacion.dart';
import 'package:unired/core/constantes/estado_publicacion.dart';
import 'package:unired/shared/temas/colores_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/shared/widgets/selector_municipio.dart';
import 'package:unired/shared/widgets/pasos_publicacion.dart';

/// Autoría en página completa: bloques de negocio, imágenes antes de guardar,
/// vista previa y un borrador recuperable si falla la vinculación de archivos.
class EditorPublicacion extends StatefulWidget {
  const EditorPublicacion({
    super.key,
    required this.isTutorial,
    this.product,
    this.tutorial,
    this.initial = const {},
    this.asAdmin = false,
    this.onSaved,
    this.onCancel,
    this.startWithReview = false,
    this.initialSection,
  });
  final bool isTutorial;
  final ArticuloMarket? product;
  final Tutoria? tutorial;
  final Json initial;
  final bool asAdmin;
  final bool startWithReview;
  final String? initialSection;
  final void Function(String id, String section)? onSaved;
  final VoidCallback? onCancel;
  @override
  State<EditorPublicacion> createState() => _EditorPublicacionState();
}

class _EditorPublicacionState extends State<EditorPublicacion> {
  final _form = GlobalKey<FormState>();
  final _courseScroll = ScrollController(keepScrollOffset: false);
  late final _fields = <String, TextEditingController>{
    for (final key in [
      'titulo',
      'descripcion',
      'resumen',
      'objetivos',
      'requisitos',
      'dirigidoA',
      'marca',
      'modelo',
      'ciudad',
      'zonaEntrega',
      'detalleEntrega',
      'precioBase',
      'descuentoPorcentaje',
    ])
      key: TextEditingController(text: _initial(key)),
  };
  String _initial(String key) {
    final value = widget.initial[key];
    if (value is List) return value.join('\n');
    if (value != null) return value.toString();
    return switch (key) {
      'titulo' => widget.product?.title ?? widget.tutorial?.title ?? '',
      'descripcion' =>
        widget.product?.description ?? widget.tutorial?.body ?? '',
      'precioBase' =>
        (widget.product?.amount ?? widget.tutorial?.amount ?? 0)
            .toStringAsFixed(2),
      'descuentoPorcentaje' =>
        (widget.product?.discountPercent ??
                widget.tutorial?.discountPercent ??
                0)
            .toStringAsFixed(2),
      'ciudad' => widget.product?.city ?? '',
      _ => '',
    };
  }

  late String _category = textValue(
    widget.initial[widget.isTutorial ? 'areaId' : 'categoriaId'],
    (widget.isTutorial ? widget.tutorial?.areaId : widget.product?.categoryId)
            ?.toString() ??
        '',
  );
  late String _level = textValue(
    widget.initial['nivel'],
    widget.tutorial?.level ?? 'todos',
  );
  late String _modality = textValue(
    widget.initial['modalidad'],
    widget.tutorial?.modality ?? 'grabada',
  );
  late String _priceType = textValue(
    widget.initial['tipoPrecio'],
    widget.product?.priceType ?? 'fijo',
  );
  late String _publicationType = textValue(
    widget.initial['tipoPublicacion'],
    'venta',
  );
  late String _condition = textValue(
    widget.initial['condicion'],
    switch (widget.product?.condition) {
      'Nuevo' => 'nuevo',
      'Como nuevo' => 'como_nuevo',
      _ => 'usado',
    },
  );
  late String _currency = textValue(
    widget.initial['moneda'],
    widget.product?.currency ?? widget.tutorial?.currency ?? 'NIO',
  );
  late String? _workingId =
      widget.product?.id ??
      widget.tutorial?.id ??
      widget.initial['id']?.toString();
  late int _version = intValue(
    widget.initial['versionLock'] ??
        widget.product?.versionLock ??
        widget.tutorial?.versionLock ??
        1,
  );
  late String? _coverId =
      widget.initial['portadaArchivoId']?.toString() ??
      widget.tutorial?.imageId;
  late final _images = <Json>[
    ...jsonRows(widget.initial['imagenes']).map((r) => {...r, 'linked': true}),
  ];
  late final _delivery = <String>{
    ...((widget.initial['formasEntrega'] is List
            ? widget.initial['formasEntrega'] as List
            : [])
        .map((v) => v.toString())),
  };
  String _text(String key) => _fields[key]!.text.trim();
  @override
  void dispose() {
    _courseScroll.dispose();
    for (final field in _fields.values) {
      field.dispose();
    }
    for (final field in _attributes.values) {
      field.dispose();
    }
    _tags.dispose();
    _reference.dispose();
    super.dispose();
  }

  Widget _input(
    String key,
    String label, {
    int lines = 1,
    int max = 220,
    bool required = false,
    bool number = false,
    String? hint,
    String? helper,
  }) => TextFormField(
    key: ValueKey('publication-$key'),
    controller: _fields[key],
    minLines: lines > 4 ? 4 : lines,
    maxLines: lines,
    maxLength: max,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : lines > 1
        ? TextInputType.multiline
        : TextInputType.text,
    textInputAction: lines > 1 ? TextInputAction.newline : null,
    decoration: InputDecoration(
      alignLabelWithHint: lines > 1,
      labelText: label,
      hintText: hint,
      helperMaxLines: 3,
      counterText: lines > 1 || key == 'titulo' ? null : '',
      helperText:
          helper ??
          (['objetivos', 'requisitos'].contains(key)
              ? 'Uno por línea · máx. 20'
              : null),
    ),
    onChanged: (_) => setState(() {
      _confirmed = false;
    }),
    validator: (raw) {
      final value = raw?.trim() ?? '';
      if (required && value.isEmpty) return 'Completa este campo.';
      if (number && value.isNotEmpty) {
        final n = double.tryParse(value.replaceAll(',', '.'));
        if (n == null || !n.isFinite || n < 0) {
          return 'Introduce un número válido.';
        }
      }
      if (['objetivos', 'requisitos'].contains(key) && value.isNotEmpty) {
        final items = value.split('\n').where((v) => v.trim().isNotEmpty);
        if (items.length > 20 || items.any((v) => v.trim().length > 300)) {
          return 'Máximo 20 elementos de 300 caracteres.';
        }
      }
      return null;
    },
  );
  Widget _select(
    String label,
    String value,
    Map<String, String> choices,
    ValueChanged<String> change, {
    bool locked = false,
  }) => DropdownButtonFormField<String>(
    key: ValueKey('publication-select-$label'),
    initialValue: choices.containsKey(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final e in choices.entries)
        DropdownMenuItem(value: e.key, child: Text(e.value)),
    ],
    onChanged: locked
        ? null
        : (v) {
            if (v != null) {
              setState(() {
                change(v);
                _confirmed = false;
              });
            }
          },
    validator: (v) => v == null || v.isEmpty ? 'Selecciona una opción.' : null,
  );
  static const _steps = {
    'presentation': ('Página de presentación', Icons.article_outlined),
    'goals': ('Estudiantes previstos', Icons.groups_outlined),
    'media': ('Imagen del curso', Icons.image_outlined),
    'curriculum': ('Contenido y alumnos', Icons.view_agenda_outlined),
    'price': ('Precio automático', Icons.sell_outlined),
    'review': ('Revisar y publicar', Icons.fact_check_outlined),
  };
  late String _section = widget.startWithReview
      ? 'review'
      : _steps.containsKey(widget.initialSection)
      ? widget.initialSection!
      : 'presentation';
  String? _resumeSection;
  bool _saving = false;
  bool _editingContent = false;
  Json get _courseMetadata => _courseData ?? widget.initial;
  late bool _courseFree = widget.initial['gratuita'] == true;
  late int _marketStep = widget.startWithReview ? 1 : 0;
  bool _confirmed = false, _mobilePreview = false;
  Json? _courseData;
  int _courseRequest = 0;
  PestanaGestionCurso _courseTab = PestanaGestionCurso.curriculum;
  final Map<String, TextEditingController> _attributes = {};
  late final _tags = TextEditingController(
    text: (widget.initial['etiquetas'] is List
        ? (widget.initial['etiquetas'] as List).join(', ')
        : ''),
  );
  late final _reference = TextEditingController(
    text: textValue(widget.initial['referenciaPrivada']),
  );
  late String _availability = textValue(
    widget.initial['disponibilidad'],
    'unico',
  );
  List<Json> get _catalog => widget.isTutorial
      ? AplicacionController.instance.areas
      : AplicacionController.instance.categories;
  Map<String, String> get _categories => {
    for (final r in _catalog) textValue(r['id']): textValue(r['nombre']),
    if (_workingId != null &&
        _category.isNotEmpty &&
        !_catalog.any((r) => textValue(r['id']) == _category))
      _category: 'Categoría actual',
  };
  List<Json> get _attributeFields => jsonRows(
    _catalog
        .where((r) => textValue(r['id']) == _category)
        .firstOrNull?['camposDetalle'],
  );
  TextEditingController _attribute(String key) => _attributes.putIfAbsent(
    key,
    () => TextEditingController(
      text: textValue(jsonObject(widget.initial['atributos'])[key]),
    ),
  );
  double get _price => widget.isTutorial
      ? double.tryParse(
              textValue(
                jsonObject(_courseMetadata['cotizacion'])['total'],
                textValue(_courseMetadata['precioBase'], '0'),
              ),
            ) ??
            0
      : double.tryParse(_text('precioBase').replaceAll(',', '.')) ?? 0;
  double get _discount => widget.isTutorial
      ? 0
      : double.tryParse(_text('descuentoPorcentaje').replaceAll(',', '.')) ?? 0;
  String get _displayPrice => widget.isTutorial && _courseFree
      ? 'Gratis'
      : widget.isTutorial && _courseMetadata['gratuita'] == true
      ? 'Se calcula al guardar'
      : widget.isTutorial &&
            (jsonObject(_courseMetadata['cotizacion'])['pendienteContenido'] ==
                    true ||
                _workingId == null)
      ? 'Pendiente de preparar el contenido'
      : !widget.isTutorial && _priceType == 'a_consultar'
      ? 'Consultar precio'
      : (!widget.isTutorial && _priceType == 'gratis') ||
            widget.isTutorial && _price == 0
      ? 'Gratis'
      : _price <= 0
      ? 'Define el precio'
      : '$_currency ${(_price * (1 - _discount / 100)).toStringAsFixed(2)}';
  bool get _alreadyPublic => [
    'publicado',
    'publicada',
  ].contains(_courseData?['estado'] ?? widget.initial['estado']);
  Json get _preparation =>
      jsonObject((_courseData ?? widget.initial)['preparacion']);
  bool get _needsLessons => ['grabada', 'mixta'].contains(_modality);
  bool get _needsSession => ['en_vivo', 'mixta'].contains(_modality);
  bool get _readyToPublish =>
      _text('titulo').isNotEmpty &&
      _text('descripcion').isNotEmpty &&
      _category.isNotEmpty &&
      (widget.isTutorial ? _workingId != null : _images.isNotEmpty) &&
      (widget.isTutorial ||
          ['gratis', 'a_consultar'].contains(_priceType) ||
          _price > 0) &&
      (!widget.isTutorial || _alreadyPublic || _courseRequirementsMet);

  bool get _courseRequirementsMet {
    final state = _preparation;
    return state['acreditacionVigente'] == true &&
        (!_needsLessons || intValue(state['leccionesPublicadas']) > 0) &&
        (!_needsSession || state['tieneSesionFutura'] == true);
  }

  Map<String, bool> get _courseProgress => {
    'presentation':
        _text('titulo').isNotEmpty &&
        _text('descripcion').isNotEmpty &&
        _category.isNotEmpty,
    'goals': _text('objetivos').isNotEmpty && _text('dirigidoA').isNotEmpty,
    'media': _coverId != null,
    'curriculum':
        (_needsLessons
            ? intValue(_preparation['leccionesPublicadas']) > 0
            : true) &&
        (_needsSession ? _preparation['tieneSesionFutura'] == true : true) &&
        _workingId != null,
    'price':
        _workingId != null &&
        jsonObject(_courseMetadata['cotizacion'])['pendienteContenido'] != true,
  };

  Future<void> _chooseSection(String key, {PestanaGestionCurso? tab}) async {
    if (key == _section && tab == null) return;
    if (_editingContent && key != _section) {
      final discard = await AvisosAplicacion.show(
        context,
        title: 'Tienes una edición abierta',
        message:
            'Guarda la sección o lección antes de cambiar de paso, o descarta sus cambios.',
        kind: TipoAviso.warning,
        action: 'Descartar cambios',
        cancel: 'Seguir editando',
      );
      if (!discard || !mounted) return;
    }
    setState(() {
      _editingContent = false;
      _section = key;
      _confirmed = false;
      if (tab != null) _courseTab = tab;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _courseScroll.hasClients) _courseScroll.jumpTo(0);
    });
    if (['preview', 'review'].contains(key) && _workingId != null) {
      await runApiAction(context, _reloadCourse);
    }
  }

  /// Siguiente valida solo el paso visible. Al entrar al currículo crea el
  /// borrador una vez; no obliga al tutor a descubrir un guardado intermedio.
  Future<void> _nextCourseSection(String key) async {
    if (_section != 'curriculum' &&
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    if (key == 'curriculum' && _workingId == null) {
      _resumeSection = key;
      await _save();
      return;
    }
    await _chooseSection(key);
  }

  Future<void> _upload() async {
    final file = await AplicacionController.instance.pickAndUpload(
      widget.isTutorial ? 'portada_curso' : 'imagen_anuncio',
      editImage: (bytes) => editPublicationImage(context, bytes),
    );
    if (file == null || !mounted) return;
    setState(() {
      if (widget.isTutorial) {
        _coverId = textValue(file['id']);
      } else {
        _images.add({'archivoId': file['id'], 'linked': false});
      }
    });
  }

  Future<void> _adjust(String id, {Json? image}) async {
    final store = AplicacionController.instance;
    final bytes = await store.imageBytes(id, thumbnail: false);
    if (!mounted) return;
    final adjusted = await editPublicationImage(context, bytes);
    if (adjusted == null) return;
    final file = await store.uploadPublicationImage(
      widget.isTutorial ? 'portada_curso' : 'imagen_anuncio',
      adjusted,
    );
    if (!mounted) return;
    setState(() {
      if (widget.isTutorial) {
        _coverId = textValue(file['id']);
      } else if (image != null) {
        if (image['linked'] == true) image['replaces'] = image['archivoId'];
        image['archivoId'] = file['id'];
        image['linked'] = false;
      }
    });
  }

  Widget _photoTools() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Material(
        color: const Color(0xFFF5F6F8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: ColoresAplicacion.line),
        ),
        child: InkWell(
          onTap: () => runApiAction(context, _upload),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 30,
                  color: ColoresAplicacion.blue,
                ),
                const SizedBox(height: 9),
                Text(
                  widget.isTutorial
                      ? 'Seleccionar portada del curso'
                      : 'Añadir fotografías',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ajusta el encuadre antes de subir',
                  style: TextStyle(
                    fontSize: 10,
                    color: ColoresAplicacion.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (widget.isTutorial && _coverId != null)
        Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ImagenApi(
                fileId: _coverId,
                fit: BoxFit.contain,
                fallback: const Icon(Icons.image_outlined),
              ),
            ),
            TextButton.icon(
              onPressed: () => runApiAction(context, () => _adjust(_coverId!)),
              icon: const Icon(Icons.crop_rotate, size: 16),
              label: const Text('Ajustar portada'),
            ),
          ],
        ),
      if (!widget.isTutorial)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final image in _images)
              SizedBox(
                width: 100,
                child: Column(
                  children: [
                    SizedBox(
                      height: 70,
                      child: ImagenApi(
                        fileId: textValue(image['archivoId']),
                        fit: BoxFit.contain,
                        fallback: const Icon(Icons.image_outlined),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Ajustar fotografía',
                          onPressed: () => runApiAction(
                            context,
                            () => _adjust(
                              textValue(image['archivoId']),
                              image: image,
                            ),
                          ),
                          icon: const Icon(Icons.crop, size: 15),
                        ),
                        if (image['linked'] != true &&
                            image['replaces'] == null)
                          IconButton(
                            tooltip: 'Quitar fotografía',
                            onPressed: () =>
                                setState(() => _images.remove(image)),
                            icon: const Icon(Icons.close, size: 15),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
    ],
  );
  Widget _amountField() =>
      !widget.isTutorial && ['gratis', 'a_consultar'].contains(_priceType)
      ? Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            _displayPrice,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        )
      : _input('precioBase', 'Precio', number: true, max: 13);
  Widget _discountField() => _input(
    'descuentoPorcentaje',
    'Descuento opcional (%)',
    number: true,
    max: 5,
  );
  Widget _moneyFields({bool compact = false}) {
    final currency = _select(
      'Moneda',
      _currency,
      compact
          ? const {'NIO': 'C\$', 'USD': 'USD'}
          : const {'NIO': 'Córdobas · NIO', 'USD': 'Dólares · USD'},
      (v) => _currency = v,
    );
    return compact
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _amountField()),
              const SizedBox(width: 10),
              SizedBox(width: 100, child: currency),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [currency, const SizedBox(height: 16), _amountField()],
          );
  }

  Widget _marketLocation() {
    final city = _text('ciudad');
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Ciudad o municipio'),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              onPressed: () async {
                final city = await pickMunicipality(context);
                if (city == null || !mounted) return;
                setState(() {
                  _fields['ciudad']!.text = city;
                  _confirmed = false;
                });
              },
              icon: const Icon(Icons.place_outlined, size: 18),
              label: Text(city.isEmpty ? 'Buscar municipio' : city),
            ),
          ),
          if (city.isNotEmpty)
            IconButton(
              tooltip: 'Quitar ubicación',
              onPressed: () => setState(() {
                _fields['ciudad']!.clear();
                _confirmed = false;
              }),
              icon: const Icon(Icons.close, size: 17),
            ),
        ],
      ),
    );
  }

  Widget _marketFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const EncabezadoSeccionAdmin('Datos del artículo'),
      const SizedBox(height: 16),
      _input('titulo', 'Título', required: true),
      const SizedBox(height: 13),
      _moneyFields(compact: true),
      const SizedBox(height: 13),
      CuadriculaCamposAdmin(
        children: [
          _select('Categoría', _category, _categories, (v) {
            _category = v;
            _confirmed = false;
          }, locked: _workingId != null),
          _select('Estado del artículo', _condition, const {
            'nuevo': 'Nuevo',
            'como_nuevo': 'Como nuevo',
            'usado': 'Usado',
          }, (v) => _condition = v),
        ],
      ),
      const SizedBox(height: 13),
      _input(
        'descripcion',
        'Descripción',
        lines: 4,
        max: 20000,
        required: true,
      ),
      const Divider(height: 32),
      const EncabezadoSeccionAdmin('Fotografías'),
      const SizedBox(height: 12),
      _photoTools(),
      const Divider(height: 32),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: _category.isNotEmpty,
        title: const Text(
          'Más detalles',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Información específica de la categoría',
          style: TextStyle(fontSize: 10),
        ),
        children: [
          const SizedBox(height: 10),
          _select(
            'Tipo de publicación',
            _publicationType,
            const {
              'venta': 'Quiero vender',
              'compra': 'Estoy buscando comprar',
              'intercambio': 'Quiero intercambiar',
            },
            (value) => _publicationType = value,
          ),
          const SizedBox(height: 13),
          _select('Tipo de precio', _priceType, const {
            'fijo': 'Precio fijo',
            'negociable': 'Negociable',
            'gratis': 'Gratis',
            'a_consultar': 'A consultar',
          }, (v) => _priceType = v),
          const SizedBox(height: 13),
          if (!['gratis', 'a_consultar'].contains(_priceType)) ...[
            _discountField(),
            const SizedBox(height: 13),
          ],
          _input('marca', 'Marca', max: 100),
          const SizedBox(height: 13),
          _input('modelo', 'Modelo o referencia', max: 120),
          for (final field in _attributeFields)
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: field['options'] is List
                  ? DropdownButtonFormField<String>(
                      initialValue:
                          (field['options'] as List).contains(
                            _attribute(textValue(field['key'])).text,
                          )
                          ? _attribute(textValue(field['key'])).text
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: textValue(field['label']),
                      ),
                      items: [
                        for (final option in field['options'] as List)
                          DropdownMenuItem(
                            value: option.toString(),
                            child: Text(option.toString()),
                          ),
                      ],
                      onChanged: (v) => setState(
                        () =>
                            _attribute(textValue(field['key'])).text = v ?? '',
                      ),
                    )
                  : TextFormField(
                      controller: _attribute(textValue(field['key'])),
                      maxLength: 200,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: textValue(field['label']),
                        counterText: '',
                      ),
                    ),
            ),
          const SizedBox(height: 13),
          _select('Disponibilidad', _availability, const {
            'unico': 'Artículo único',
            'varias_unidades': 'Varias unidades',
          }, (v) => _availability = v),
          const SizedBox(height: 13),
          TextField(
            controller: _tags,
            maxLength: 1200,
            decoration: const InputDecoration(
              labelText: 'Etiquetas',
              helperText: 'Separadas por comas · hasta 20',
              counterText: '',
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _reference,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Referencia interna (SKU)',
              helperText: 'Solo visible para ti',
              counterText: '',
            ),
          ),
          const SizedBox(height: 13),
        ],
      ),
      _marketLocation(),
      const SizedBox(height: 13),
      _input('zonaEntrega', 'Zona de entrega', max: 180),
      const SizedBox(height: 17),
      const Text(
        'Preferencias de entrega',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      for (final entry in FichaPublicacion.deliveryLabels.entries)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(entry.value, style: const TextStyle(fontSize: 12)),
          value: _delivery.contains(entry.key),
          onChanged: (v) => setState(() {
            v == true ? _delivery.add(entry.key) : _delivery.remove(entry.key);
          }),
        ),
      _input('detalleEntrega', 'Indicaciones de entrega', lines: 2, max: 1500),
    ],
  );
  Widget _review() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Revisa antes de publicar',
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: ColoresAplicacion.ink,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        widget.isTutorial
            ? 'Comprueba el contenido y cómo se presenta tu curso.'
            : 'Tu artículo será visible para la comunidad en el marketplace.',
        style: const TextStyle(height: 1.6, color: ColoresAplicacion.muted),
      ),
      const SizedBox(height: 22),
      ListaComprobacionPublicacion(
        items: [
          (
            'Título y descripción',
            _text('titulo').isNotEmpty && _text('descripcion').isNotEmpty,
            () => widget.isTutorial
                ? _chooseSection('presentation')
                : setState(() => _marketStep = 0),
          ),
          (
            widget.isTutorial ? 'Área seleccionada' : 'Categoría seleccionada',
            _category.isNotEmpty,
            () => widget.isTutorial
                ? _chooseSection('presentation')
                : setState(() => _marketStep = 0),
          ),
          (
            widget.isTutorial
                ? 'Portada recomendada'
                : 'Fotografías preparadas',
            widget.isTutorial ? _coverId != null : _images.isNotEmpty,
            () => widget.isTutorial
                ? _chooseSection('media')
                : setState(() => _marketStep = 0),
          ),
          if (widget.isTutorial) ...[
            (
              'Borrador guardado',
              _workingId != null,
              () => _chooseSection('presentation'),
            ),
            (
              'Objetivos y estudiantes previstos',
              _text('objetivos').isNotEmpty && _text('dirigidoA').isNotEmpty,
              () => _chooseSection('goals'),
            ),
            if (_preparation.containsKey('acreditacionVigente'))
              (
                'Acreditación vigente en el área',
                _preparation['acreditacionVigente'] == true,
                () => NavegadorAplicacion.go(
                  context,
                  RutasAplicacion.accreditation,
                ),
              ),
            if (_needsLessons)
              (
                'Al menos una lección publicada',
                intValue(_preparation['leccionesPublicadas']) > 0,
                () => _chooseSection(
                  'curriculum',
                  tab: PestanaGestionCurso.curriculum,
                ),
              ),
            if (_needsSession)
              (
                'Al menos una clase futura programada',
                _preparation['tieneSesionFutura'] == true,
                () => _chooseSection(
                  'curriculum',
                  tab: PestanaGestionCurso.sessions,
                ),
              ),
          ],
        ],
      ),
      const SizedBox(height: 20),
      InformacionAdmin(
        'Se publicará como',
        AplicacionController.instance.currentUser?.name,
      ),
      InformacionAdmin('Precio mostrado', _displayPrice),
      if (widget.isTutorial && _workingId != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => runApiAction(context, _reloadCourse),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar comprobación'),
          ),
        ),
      CheckboxListTile(
        key: const ValueKey('publication-confirm'),
        contentPadding: EdgeInsets.zero,
        value: _confirmed,
        onChanged: (v) => setState(() => _confirmed = v ?? false),
        title: const Text(
          'Revisé la información y confirmo que puedo publicar este contenido.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      const SizedBox(height: 15),
      BotonAccionApi(
        label: _alreadyPublic
            ? 'Confirmar y guardar cambios'
            : 'Confirmar y publicar',
        icon: Icons.publish_outlined,
        enabled: _confirmed && _readyToPublish,
        action: () => _save(publish: !_alreadyPublic),
      ),
      const SizedBox(height: 12),
      const Text(
        'No se publicará nada hasta que confirmes.',
        style: TextStyle(fontSize: 11, color: ColoresAplicacion.muted),
      ),
    ],
  );
  Widget _marketPreview() => VistaPreviaMarket(
    title: _text('titulo'),
    price: _displayPrice,
    description: _text('descripcion'),
    seller: AplicacionController.instance.currentUser?.name ?? 'Tu perfil',
    category: _categories[_category] ?? '',
    condition: FichaPublicacion.valueLabel(_condition),
    location: _text('ciudad'),
    images: _images.map((r) => textValue(r['archivoId'])).toList(),
    attributes: {
      for (final f in _attributeFields)
        if (_attribute(textValue(f['key'])).text.isNotEmpty)
          textValue(f['label']): _attribute(textValue(f['key'])).text,
    },
  );
  Widget _marketWorkspace(bool narrow) => ColoredBox(
    color: const Color(0xFFF3F6FB),
    child: Column(
      children: [
        Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (widget.onCancel != null)
                  IconButton(
                    tooltip: 'Cerrar editor',
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.arrow_back),
                  ),
                const Expanded(
                  child: Text(
                    'Artículo en venta',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
                if (narrow)
                  IconButton(
                    tooltip: 'Cambiar vista previa',
                    onPressed: () =>
                        setState(() => _mobilePreview = !_mobilePreview),
                    icon: Icon(
                      _mobilePreview
                          ? Icons.edit_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                TextButton(
                  onPressed: () => runApiAction(context, _save),
                  child: Text(
                    narrow
                        ? 'Guardar'
                        : (_workingId == null
                              ? 'Guardar borrador'
                              : 'Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!narrow || !_mobilePreview)
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        key: ValueKey('market-$_marketStep'),
                        padding: EdgeInsets.fromLTRB(
                          narrow ? 12 : 24,
                          22,
                          narrow ? 12 : 10,
                          24,
                        ),
                        child: SuperficieAdmin(
                          padding: EdgeInsets.all(narrow ? 16 : 26),
                          child: _marketStep == 0 ? _marketFields() : _review(),
                        ),
                      ),
                    ),
                  if (!narrow || _mobilePreview)
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          narrow ? 12 : 10,
                          22,
                          narrow ? 12 : 24,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const EncabezadoSeccionAdmin('Vista previa'),
                            const SizedBox(height: 12),
                            Expanded(child: _marketPreview()),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!narrow || !_mobilePreview)
          Material(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              child: PasosPublicacion(
                label: _marketStep == 0
                    ? '1 de 2 · Datos'
                    : '2 de 2 · Revisión',
                previous: _marketStep == 1
                    ? () => setState(() {
                        _marketStep = 0;
                        _confirmed = false;
                      })
                    : null,
                next: _marketStep == 0
                    ? () {
                        if (_form.currentState!.validate()) {
                          setState(() => _marketStep = 1);
                        }
                      }
                    : null,
              ),
            ),
          ),
      ],
    ),
  );
  Future<void> _reloadCourse() async {
    final id = _workingId;
    if (id == null) return;
    final request = ++_courseRequest;
    final row = await AplicacionController.instance.publicationDetails(
      true,
      id,
      own: true,
    );
    if (!mounted || request != _courseRequest || id != _workingId) return;
    setState(() {
      _courseData = row;
      _version = intValue(row['versionLock']);
    });
  }

  Widget _coursePanel() => switch (_section) {
    'goals' => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Estudiantes previstos',
          'Define para quién es tu curso y qué conseguirán al completarlo.',
        ),
        const NotaEditorCurso(
          'Describe resultados concretos. Por ejemplo: crear componentes, configurar rutas o construir una aplicación. Escribe un resultado por línea.',
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 22),
        _input(
          'objetivos',
          '¿Qué aprenderán tus estudiantes?',
          lines: 5,
          max: 6000,
          hint:
              'Crear aplicaciones con componentes reutilizables\nOrganizar la lógica con servicios',
        ),
        const SizedBox(height: 22),
        _input(
          'requisitos',
          '¿Qué necesitan para empezar?',
          lines: 4,
          max: 6000,
          hint:
              'Conocimientos básicos del tema\nUna computadora para realizar los ejercicios',
        ),
        const SizedBox(height: 22),
        _input(
          'dirigidoA',
          '¿A quién está dirigido?',
          lines: 3,
          max: 1500,
          hint:
              'Explica para qué estudiantes y nivel de experiencia preparaste el curso.',
        ),
      ],
    ),
    'media' => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Imagen del curso',
          'Elige una imagen clara que represente el tema. Se verá en el catálogo y en la presentación del curso.',
        ),
        _photoTools(),
        const SizedBox(height: 18),
        const NotaEditorCurso(
          'Usa una imagen horizontal de proporción 16:9, sin datos personales. Puedes ajustar el encuadre antes de guardarla.',
          icon: Icons.crop_landscape_outlined,
        ),
      ],
    ),
    'price' => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Precio de esta tutoría',
          'Puedes ofrecerla gratis o usar un precio de demostración calculado con la tarifa del área y la duración del contenido publicado.',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ofrecer esta tutoría gratis'),
          value: _courseFree,
          onChanged: !_saving
              ? (value) => setState(() => _courseFree = value)
              : null,
        ),
        const NotaEditorCurso(
          'El video aporta su duración verificada, el texto se estima por tiempo de lectura y las clases en vivo aportan su duración programada. Las tarifas las administra UniRed.',
        ),
        const SizedBox(height: 20),
        if (!_courseFree &&
            _courseMetadata['gratuita'] != true &&
            _courseMetadata['cotizacion'] is Map) ...[
          InformacionAdmin(
            'Duración para el cálculo',
            '${jsonObject(_courseMetadata['cotizacion'])['duracionMinutos']} minutos',
          ),
          InformacionAdmin(
            'Tarifa por minuto',
            'C\$ ${jsonObject(_courseMetadata['cotizacion'])['precioMinuto']}',
          ),
        ],
        InformacionAdmin('Precio del curso', _displayPrice),
        const SizedBox(height: 16),
        NotaEditorCurso(
          _courseFree
              ? 'El estudiante tendrá acceso en cuanto apruebes su solicitud.'
              : 'Tras tu aprobación, el estudiante confirma el pago demo con una tarjeta de prueba para abrir el aula.',
        ),
      ],
    ),
    'curriculum' =>
      _workingId == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(
                  'Plan de estudio',
                  'Guarda la presentación para crear tu borrador. Después podrás añadir secciones, videos, clases y alumnos.',
                ),
                BotonAccionApi(
                  label: 'Crear borrador',
                  action: () async {
                    _resumeSection = 'curriculum';
                    await _save();
                  },
                ),
              ],
            )
          : GestionCurso(
              key: ValueKey(_courseTab),
              initialTab: _courseTab,
              course: _courseData ?? widget.initial,
              reload: () => unawaited(runApiAction(context, _reloadCourse)),
              onEditingChanged: (editing) {
                if (mounted) setState(() => _editingContent = editing);
              },
            ),
    'review' => _review(),
    'preview' => VistaPreviaAutor(course: _draft()),
    _ => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Página de presentación',
          'Empieza por lo esencial. Estos datos se mostrarán en la página pública de tu curso.',
        ),
        if (_resumeSection == 'curriculum') ...[
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: ColoresAplicacion.blue),
            title: Text(
              'Guarda la presentación para continuar con el contenido',
            ),
          ),
          const SizedBox(height: 14),
        ],
        _input(
          'titulo',
          'Título del curso',
          required: true,
          hint: 'Ej. Universidad Angular · De cero a experto',
        ),
        const SizedBox(height: 22),
        _input(
          'resumen',
          'Subtítulo o resumen',
          lines: 2,
          max: 500,
          hint: 'Resume en una o dos frases qué aprenderá el estudiante.',
        ),
        const SizedBox(height: 22),
        _input(
          'descripcion',
          'Descripción del curso',
          lines: 6,
          max: 20000,
          required: true,
          hint:
              'Presenta el tema, explica cómo se desarrollará el curso y qué proyectos podrán realizar.',
        ),
        const SizedBox(height: 25),
        CuadriculaCamposAdmin(
          children: [
            _select(
              'Área de enseñanza',
              _category,
              _categories,
              (v) => _category = v,
              locked: _workingId != null,
            ),
            _select('Nivel', _level, const {
              'todos': 'Todos los niveles',
              'inicial': 'Inicial',
              'intermedio': 'Intermedio',
              'avanzado': 'Avanzado',
            }, (v) => _level = v),
            _select(
              'Modalidad',
              _modality,
              const {
                'grabada': 'Curso grabado',
                'en_vivo': 'Clases en vivo',
                'mixta': 'Grabado y en vivo',
              },
              (v) => _modality = v,
              locked: _alreadyPublic,
            ),
            InformacionAdmin(
              'Idioma del curso',
              textValue(_courseMetadata['idioma'], 'Español'),
            ),
            InformacionAdmin(
              'Duración del contenido',
              _courseMetadata['duracionEstimadaMinutos'] == null
                  ? 'Se calcula al añadir clases'
                  : '${_courseMetadata['duracionEstimadaMinutos']} min',
            ),
          ],
        ),
      ],
    ),
  };
  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: ColoresAplicacion.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.7,
            color: ColoresAplicacion.muted,
          ),
        ),
      ],
    ),
  );
  Json _draft() => {
    ..._courseMetadata,
    'id': _workingId ?? 'preview',
    'titulo': _text('titulo').isEmpty
        ? 'El título de tu curso'
        : _text('titulo'),
    'descripcion': _text('descripcion'),
    'resumen': _text('resumen'),
    'areaId': _category,
    'areaNombre': _categories[_category],
    'tutorNombre': AplicacionController.instance.currentUser?.name,
    'precioBase': _price,
    'moneda': _currency,
    'descuentoPorcentaje': _discount,
    'portadaArchivoId': _coverId,
    'idioma': textValue(_courseMetadata['idioma'], 'Español'),
    'nivel': _level,
    'modalidad': _modality,
    'objetivos': _text(
      'objetivos',
    ).split('\n').where((v) => v.trim().isNotEmpty).toList(),
    'requisitos': _text(
      'requisitos',
    ).split('\n').where((v) => v.trim().isNotEmpty).toList(),
    'dirigidoA': _text('dirigidoA'),
    'duracionEstimadaMinutos': _courseMetadata['duracionEstimadaMinutos'],
    'leccionesTotal': jsonRows(
      _courseMetadata['lecciones'],
    ).where((l) => l['publicada'] == true).length,
    'seccionesTotal': jsonRows(_courseMetadata['secciones']).length,
    'recursosTotal': jsonRows(
      _courseMetadata['lecciones'],
    ).fold<int>(0, (sum, l) => sum + jsonRows(l['recursos']).length),
  };
  Widget _courseWorkspace(bool narrow) {
    final keys = _steps.keys.toList();
    final step = keys.indexOf(_section);
    final previous = step > 0 ? keys[step - 1] : null;
    final next = step >= 0 && step < keys.length - 1 ? keys[step + 1] : null;
    return ColoredBox(
      color: const Color(0xFFF3F6FB),
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 10 : 24,
                vertical: 12,
              ),
              child: Row(
                children: [
                  if (widget.onCancel != null)
                    IconButton(
                      tooltip: 'Volver a mis publicaciones',
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.arrow_back),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text('titulo').isEmpty
                              ? 'Nuevo curso'
                              : _text('titulo'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: narrow ? 15 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!narrow)
                          Text(
                            _workingId == null
                                ? 'Borrador sin guardar'
                                : EstadoPublicacion.fromApi(
                                    _courseMetadata['estado'],
                                  ).label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ColoresAplicacion.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Vista previa',
                    onPressed: () => _chooseSection('preview'),
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  const SizedBox(width: 8),
                  BotonAccionApi(
                    label: narrow
                        ? 'Guardar'
                        : (_workingId == null
                              ? 'Guardar borrador'
                              : 'Guardar cambios'),
                    action: _save,
                    enabled: !_saving && !_editingContent,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          if (narrow)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DropdownButtonFormField<String>(
                key: ValueKey(_section),
                initialValue: _section,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sección del curso',
                ),
                items: [
                  for (final e in _steps.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value.$1)),
                  const DropdownMenuItem(
                    value: 'preview',
                    child: Text('Vista previa'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) _chooseSection(v);
                },
              ),
            ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!narrow) ...[
                  SizedBox(
                    width: 235,
                    child: Material(
                      color: Colors.white,
                      child: ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          for (final (heading, sections) in const [
                            ('Planificación', ['presentation', 'goals']),
                            ('Contenido', ['media', 'curriculum']),
                            ('Publicación', ['price', 'review']),
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 15, 12, 6),
                              child: Text(
                                heading,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ColoresAplicacion.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            for (final key in sections)
                              ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                selected: _section == key,
                                selectedTileColor:
                                    ColoresAplicacion.surfaceBlue,
                                selectedColor: ColoresAplicacion.blue,
                                leading: CircleAvatar(
                                  radius: 13,
                                  backgroundColor: _section == key
                                      ? ColoresAplicacion.blue
                                      : const Color(0xffedf1f5),
                                  child: Text(
                                    '${keys.indexOf(key) + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _section == key
                                          ? Colors.white
                                          : ColoresAplicacion.muted,
                                    ),
                                  ),
                                ),
                                trailing: _courseProgress[key] == true
                                    ? const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: ColoresAplicacion.blue,
                                      )
                                    : null,
                                title: Text(
                                  _steps[key]!.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => _chooseSection(key),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: Scrollbar(
                      controller: _courseScroll,
                      thumbVisibility: true,
                      interactive: true,
                      child: SingleChildScrollView(
                        controller: _courseScroll,
                        key: ValueKey('course-$_section'),
                        padding: EdgeInsets.all(narrow ? 16 : 30),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  ['curriculum', 'preview'].contains(_section)
                                  ? 1050
                                  : 800,
                            ),
                            child: ['curriculum', 'preview'].contains(_section)
                                ? Material(
                                    type: MaterialType.transparency,
                                    child: _coursePanel(),
                                  )
                                : SuperficieAdmin(
                                    padding: EdgeInsets.all(narrow ? 18 : 32),
                                    child: _coursePanel(),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (step >= 0)
            Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                child: PasosPublicacion(
                  label: _editingContent
                      ? 'Guarda o cancela la edición para continuar'
                      : '${step + 1} de ${keys.length}',
                  enabled: !_saving && !_editingContent,
                  nextLabel: next == 'curriculum' && _workingId == null
                      ? 'Guardar y crear contenido'
                      : next == 'review'
                      ? 'Revisar curso'
                      : 'Siguiente',
                  previous: previous == null
                      ? null
                      : () => _chooseSection(previous),
                  next: next == null
                      ? null
                      : () => unawaited(
                          runApiAction(context, () => _nextCourseSection(next)),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: LayoutBuilder(
      builder: (_, box) {
        final narrow = box.maxWidth < 850;
        return SizedBox(
          height: box.hasBoundedHeight
              ? box.maxHeight
              : (MediaQuery.sizeOf(context).height -
                        (widget.asAdmin ? 160 : 115))
                    .clamp(610, 1100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
              color: Colors.white,
              child: widget.isTutorial
                  ? _courseWorkspace(narrow)
                  : _marketWorkspace(narrow),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _save({bool publish = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _persist(publish: publish);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persist({required bool publish}) async {
    if (_text('titulo').isEmpty ||
        _text('descripcion').isEmpty ||
        _category.isEmpty) {
      setState(() {
        _section = 'presentation';
        _marketStep = 0;
      });
      if (widget.isTutorial && _resumeSection != null) return;
      throw const ErrorApi(
        'Completa el título, la categoría y la descripción para guardar.',
      );
    }
    if (!_form.currentState!.validate()) return;
    final price = double.tryParse(_text('precioBase').replaceAll(',', '.'));
    final discount = double.tryParse(
      _text('descuentoPorcentaje').replaceAll(',', '.'),
    );
    final amount = price ?? 0;
    final reduction = discount ?? 0;
    final noPrice =
        widget.isTutorial || ['gratis', 'a_consultar'].contains(_priceType);
    if (!noPrice && (reduction > 90 || (reduction > 0 && amount == 0))) {
      if (widget.isTutorial) _chooseSection('price');
      throw const ErrorApi(
        'Revisa el precio y el descuento: el máximo es 90 %.',
      );
    }
    if (!widget.isTutorial && !noPrice && amount <= 0) {
      throw const ErrorApi(
        'Indica un precio mayor que cero o selecciona Gratis.',
      );
    }
    final data = <String, Object?>{
      'titulo': _text('titulo'),
      'descripcion': _text('descripcion'),
      if (!widget.isTutorial)
        'precioBase': !widget.isTutorial && _priceType == 'a_consultar'
            ? null
            : noPrice
            ? '0.00'
            : amount.toStringAsFixed(2),
      if (!widget.isTutorial)
        'descuentoPorcentaje': noPrice ? '0.00' : reduction.toStringAsFixed(2),
      'moneda': _currency,
      if (_workingId == null)
        (widget.isTutorial ? 'areaId' : 'categoriaId'): int.parse(_category),
      if (_workingId != null) 'versionLock': _version,
      if (widget.isTutorial) ...{
        'gratuita': _courseFree,
        'nivel': _level,
        'modalidad': _modality,
        'portadaArchivoId': _coverId,
        'resumen': _text('resumen'),
        'dirigidoA': _text('dirigidoA'),
        'objetivos': _text(
          'objetivos',
        ).split('\n').map((v) => v.trim()).where((v) => v.isNotEmpty).toList(),
        'requisitos': _text(
          'requisitos',
        ).split('\n').map((v) => v.trim()).where((v) => v.isNotEmpty).toList(),
      } else ...{
        'tipoPublicacion': _publicationType,
        'tipoPrecio': _priceType,
        'condicion': _condition,
        'ciudad': _text('ciudad').isEmpty ? null : _text('ciudad'),
        'marca': _text('marca'),
        'modelo': _text('modelo'),
        'zonaEntrega': _text('zonaEntrega'),
        'detalleEntrega': _text('detalleEntrega'),
        'formasEntrega': _delivery.toList(),
        'atributos': {
          for (final f in _attributeFields)
            if (_attribute(textValue(f['key'])).text.trim().isNotEmpty)
              textValue(f['key']): _attribute(textValue(f['key'])).text.trim(),
        },
        'etiquetas': _tags.text
            .split(',')
            .map((v) => v.trim())
            .where((v) => v.isNotEmpty)
            .toList(),
        'disponibilidad': _availability,
        'referenciaPrivada': _reference.text.trim(),
      },
    };
    final store = AplicacionController.instance;
    final row = await store.savePublication(
      widget.isTutorial,
      data,
      id: _workingId,
    );
    _workingId = textValue(row['id']);
    _version = intValue(row['versionLock']);
    if (widget.isTutorial) _courseData = {..._courseMetadata, ...row};
    if (!widget.isTutorial) {
      final used = _images
          .where((r) => r['linked'] == true)
          .map((r) => intValue(r['orden']))
          .toSet();
      for (final image in _images.where((r) => r['linked'] != true)) {
        if (image['replaces'] != null) {
          await store.api.object(
            '/me/listings/$_workingId/images/${image['replaces']}',
            method: 'PUT',
            data: {'archivoId': image['archivoId']},
          );
          image['linked'] = true;
          image.remove('replaces');
          used.add(intValue(image['orden']));
          continue;
        }
        final order = List.generate(
          20,
          (i) => i + 1,
        ).where((n) => !used.contains(n)).firstOrNull;
        if (order == null) {
          throw const ErrorApi(
            'Gestiona las imágenes en la pestaña Multimedia antes de añadir más.',
          );
        }
        await store.api.object(
          '/me/listings/$_workingId/images',
          method: 'POST',
          data: {'archivoId': image['archivoId'], 'orden': order},
        );
        image['linked'] = true;
        image['orden'] = order;
        used.add(order);
      }
    }
    if (publish) {
      if (widget.isTutorial) {
        await store.setTutorialStatus(
          store.tutorialFromJson(row),
          EstadoPublicacion.published,
        );
      } else {
        await store.setProductStatus(
          store.productFromJson(row),
          EstadoPublicacion.published,
        );
      }
      final latest = await store.publicationDetails(
        widget.isTutorial,
        _workingId!,
        own: true,
      );
      _version = intValue(latest['versionLock']);
    }
    if (mounted) {
      final section = _resumeSection ?? _section;
      if (_resumeSection != null) {
        _resumeSection = null;
        _chooseSection(section);
      }
      widget.onSaved?.call(_workingId!, section);
    }
  }
}
