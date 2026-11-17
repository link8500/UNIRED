// Archivo: lib/models/perfil/widgets/formulario_perfil.dart
// Construye campos personales y académicos de acuerdo con la definición de perfil de la API.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

/// Formulario único para el perfil propio y la corrección administrativa.
/// Los permisos y longitudes vuelven a comprobarse en NestJS.
class FormularioPerfil extends StatefulWidget {
  const FormularioPerfil({
    super.key,
    required this.initial,
    required this.administrator,
    required this.onSave,
    this.requireReason = false,
    this.selfEdit = false,
    this.enabled = true,
    this.label = 'Guardar perfil',
    this.onChanged,
    this.onCancel,
  });
  final Json initial;
  final bool administrator;
  final Future<void> Function(Json) onSave;
  final bool requireReason, selfEdit;
  final bool enabled;
  final String label;
  final VoidCallback? onChanged, onCancel;
  @override
  State<FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<FormularioPerfil> {
  final _form = GlobalKey<FormState>();
  static const _definitions = <String, (String, int)>{
    'nombre': ('Nombre completo', 180),
    'telefono': ('Teléfono', 30),
    'pais': ('País', 80),
    'departamento': ('Departamento o provincia', 120),
    'ciudad': ('Ciudad o municipio', 120),
    'universidad': ('Universidad o institución', 180),
    'sede': ('Sede o recinto', 180),
    'carrera': ('Carrera', 180),
    'edad': ('Edad', 3),
    'anioEstudio': ('Año de estudio', 2),
    'areaProfesional': ('Área profesional', 160),
    'ocupacion': ('Ocupación o puesto', 160),
    'presentacion': ('Sobre mí', 5000),
    'motivo': ('Motivo de la corrección', 2000),
  };
  late final _fields = {
    for (final key in _definitions.keys)
      key: TextEditingController(text: textValue(widget.initial[key])),
  };
  late String _employment = widget.initial['trabaja'] == true
      ? 'si'
      : widget.initial['trabaja'] == false
      ? 'no'
      : 'sin_indicar';
  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _field(String key) {
    final spec = _definitions[key]!;
    final numeric = key == 'edad' || key == 'anioEstudio';
    final multiline = key == 'presentacion' || key == 'motivo';
    return TextFormField(
      key: ValueKey('profile-$key'),
      controller: _fields[key],
      enabled: widget.enabled,
      maxLength: spec.$2,
      maxLines: key == 'presentacion'
          ? 3
          : key == 'motivo'
          ? 2
          : 1,
      keyboardType: numeric
          ? TextInputType.number
          : key == 'telefono'
          ? TextInputType.phone
          : multiline
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: multiline ? TextInputAction.newline : null,
      decoration: InputDecoration(
        alignLabelWithHint: multiline,
        labelText: spec.$1,
        counterText: '',
        helperText: key == 'motivo'
            ? 'La corrección queda registrada en auditoría.'
            : null,
      ),
      validator: (raw) {
        final value = raw?.trim() ?? '';
        if ((key == 'nombre' || key == 'motivo') &&
            value.length < (key == 'motivo' ? 5 : 1)) {
          return 'Completa este campo.';
        }
        if (numeric && value.isNotEmpty) {
          final number = int.tryParse(value);
          if (number == null ||
              number < (key == 'edad' ? 0 : 1) ||
              number > (key == 'edad' ? 130 : 15)) {
            return key == 'edad'
                ? 'Usa una edad entre 0 y 130.'
                : 'Usa un año entre 1 y 15.';
          }
        }
        if (key == 'telefono' &&
            value.isNotEmpty &&
            (!RegExp(r'^[+\d\s().-]+$').hasMatch(value) ||
                !RegExp(
                  r'^\d{7,15}$',
                ).hasMatch(value.replaceAll(RegExp(r'\D'), '')))) {
          return 'Usa entre 7 y 15 dígitos.';
        }
        return null;
      },
    );
  }

  Widget _section(String title, String subtitle, List<Widget> fields) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoSeccionAdmin(title, subtitle: subtitle),
        const SizedBox(height: 18),
        ...fields,
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: widget.selfEdit ? 14 : 24),
      child: widget.selfEdit ? SuperficieAdmin(child: content) : content,
    );
  }

  Widget _grid(List<String> keys) =>
      CuadriculaCamposAdmin(children: [for (final key in keys) _field(key)]);

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    onChanged: widget.onChanged,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(
          'Identidad y contacto',
          'El teléfono solo se publica si lo autorizas.',
          [
            _grid(['nombre', 'telefono', if (!widget.administrator) 'edad']),
          ],
        ),
        _section(
          'Lugar de residencia',
          'No es necesario indicar una dirección exacta.',
          [
            _grid(['pais', 'departamento', 'ciudad']),
          ],
        ),
        if (!widget.administrator)
          _section(
            'Información académica',
            'Tus estudios y tu lugar de residencia son datos independientes.',
            [
              _grid(['universidad', 'sede', 'carrera', 'anioEstudio']),
            ],
          ),
        _section(
          'Situación laboral',
          'Estos datos son privados y opcionales.',
          [
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const ValueKey('profile-trabaja'),
              initialValue: _employment,
              decoration: const InputDecoration(
                labelText: '¿Actualmente trabajas?',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'sin_indicar',
                  child: Text('Prefiero no indicarlo'),
                ),
                DropdownMenuItem(value: 'si', child: Text('Sí, trabajo')),
                DropdownMenuItem(
                  value: 'no',
                  child: Text('No trabajo actualmente'),
                ),
              ],
              onChanged: widget.enabled
                  ? (value) => setState(() => _employment = value!)
                  : null,
            ),
            const SizedBox(height: 16),
            CuadriculaCamposAdmin(
              children: [
                _field('areaProfesional'),
                if (_employment == 'si') _field('ocupacion'),
              ],
            ),
          ],
        ),
        _section('Presentación', 'El texto se muestra en tu perfil.', [
          _field('presentacion'),
        ]),
        if (widget.requireReason) ...[
          const SizedBox(height: 12),
          _field('motivo'),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            if (widget.onCancel != null)
              OutlinedButton(
                onPressed: widget.enabled ? widget.onCancel : null,
                child: const Text('Descartar cambios'),
              ),
            BotonAccionApi(
              label: widget.label,
              icon: Icons.save_outlined,
              enabled: widget.enabled,
              action: () async {
                if (!_form.currentState!.validate()) return;
                final data = <String, Object?>{};
                for (final key in [
                  'nombre',
                  'telefono',
                  'pais',
                  'departamento',
                  'ciudad',
                  'areaProfesional',
                  'presentacion',
                  if (!widget.administrator) ...[
                    'edad',
                    'universidad',
                    'sede',
                    'carrera',
                    'anioEstudio',
                  ],
                  if (widget.requireReason) 'motivo',
                ]) {
                  final value = _fields[key]!.text.trim();
                  data[key] = value.isEmpty
                      ? null
                      : key == 'edad' || key == 'anioEstudio'
                      ? int.parse(value)
                      : value;
                }
                data['trabaja'] = _employment == 'sin_indicar'
                    ? null
                    : _employment == 'si';
                data['ocupacion'] =
                    _employment == 'si' &&
                        _fields['ocupacion']!.text.trim().isNotEmpty
                    ? _fields['ocupacion']!.text.trim()
                    : null;
                if (!widget.selfEdit) data['telefonoPublico'] = false;
                await widget.onSave(data);
              },
              success: 'Información guardada correctamente.',
            ),
          ],
        ),
      ],
    ),
  );
}
