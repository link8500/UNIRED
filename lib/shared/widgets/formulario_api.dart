// Archivo: lib/shared/widgets/formulario_api.dart
// Construye formularios reutilizables a partir de definiciones de campos y guarda sus valores.

import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';

enum TipoCampoApi {
  text,
  integer,
  money,
  flag,
  choice,
  integerChoice,
  date,
  list,
}

class CampoApi {
  const CampoApi(
    this.key,
    this.label, {
    this.kind = TipoCampoApi.text,
    this.required = true,
    this.clearable = false,
    this.lines = 1,
    this.choices = const {},
  });
  final String key;
  final String label;
  final TipoCampoApi kind;
  final bool required;
  final bool clearable;
  final int lines;
  final Map<String, String> choices;
}

/// Formularios de negocio reutilizables; traduce fechas/importes antes de HTTP.
class FormularioApi extends StatefulWidget {
  const FormularioApi({
    super.key,
    required this.title,
    required this.fields,
    required this.submit,
    this.initial = const {},
    this.label = 'Guardar',
  });
  final String title;
  final String label;
  final List<CampoApi> fields;
  final Json initial;
  final Future<void> Function(Json) submit;
  @override
  State<FormularioApi> createState() => _FormularioApiState();
}

class _FormularioApiState extends State<FormularioApi> {
  final _form = GlobalKey<FormState>();
  late final _controllers = <String, TextEditingController>{
    for (final f in widget.fields)
      f.key: TextEditingController(
        text: widget.initial[f.key] is List
            ? (widget.initial[f.key] as List).join(', ')
            : textValue(widget.initial[f.key]),
      ),
  };
  late final _flags = <String, bool>{
    for (final f in widget.fields.where((f) => f.kind == TipoCampoApi.flag))
      f.key: widget.initial[f.key] == true,
  };
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SuperficieAdmin(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          for (final field in widget.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _input(field),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: BotonAccionApi(
              label: widget.label,
              action: () async {
                if (!_form.currentState!.validate()) return;
                final data = <String, Object?>{};
                for (final f in widget.fields) {
                  final value = _controllers[f.key]!.text.trim();
                  if (f.kind == TipoCampoApi.flag) {
                    data[f.key] = _flags[f.key];
                    continue;
                  }
                  if (value.isEmpty && !f.required) {
                    if (f.clearable) {
                      data[f.key] = f.kind == TipoCampoApi.list
                          ? <String>[]
                          : null;
                    }
                    continue;
                  }
                  data[f.key] = switch (f.kind) {
                    TipoCampoApi.integer ||
                    TipoCampoApi.integerChoice => int.parse(value),
                    TipoCampoApi.money => double.parse(
                      value.replaceAll(',', '.'),
                    ).toStringAsFixed(2),
                    TipoCampoApi.date => DateTime.parse(
                      value,
                    ).toUtc().toIso8601String(),
                    TipoCampoApi.list =>
                      value
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList(),
                    _ => value,
                  };
                }
                await widget.submit(data);
              },
            ),
          ),
        ],
      ),
    ),
  );
  Widget _input(CampoApi field) {
    if (field.kind == TipoCampoApi.flag) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label),
        value: _flags[field.key]!,
        onChanged: (v) => setState(() => _flags[field.key] = v),
      );
    }
    if ([
      TipoCampoApi.choice,
      TipoCampoApi.integerChoice,
    ].contains(field.kind)) {
      final value = _controllers[field.key]!.text;
      return DropdownButtonFormField<String>(
        initialValue: field.choices.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: field.label),
        items: [
          for (final e in field.choices.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) => _controllers[field.key]!.text = v ?? '',
        validator: (v) => field.required && (v?.isEmpty ?? true)
            ? 'Selecciona una opción.'
            : null,
      );
    }
    return TextFormField(
      controller: _controllers[field.key],
      maxLines: field.lines,
      keyboardType: field.kind == TipoCampoApi.money
          ? const TextInputType.numberWithOptions(decimal: true)
          : field.kind == TipoCampoApi.integer
          ? TextInputType.number
          : field.lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: field.lines > 1 ? TextInputAction.newline : null,
      decoration: InputDecoration(
        alignLabelWithHint: field.lines > 1,
        labelText: field.label,
        helperText: field.kind == TipoCampoApi.list
            ? 'Separados por coma'
            : null,
        suffixIcon: field.kind == TipoCampoApi.date
            ? IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 1825)),
                  );
                  if (date == null || !mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time == null || !mounted) return;
                  setState(
                    () => _controllers[field.key]!.text = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    ).toIso8601String(),
                  );
                },
              )
            : null,
      ),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) {
          return field.required ? 'Completa este campo.' : null;
        }
        if (field.kind == TipoCampoApi.integer && int.tryParse(value) == null) {
          return 'Número entero inválido.';
        }
        if (field.kind == TipoCampoApi.money) {
          final n = double.tryParse(value.replaceAll(',', '.'));
          if (n == null || !n.isFinite || n < 0) return 'Importe inválido.';
        }
        if (field.kind == TipoCampoApi.date &&
            DateTime.tryParse(value) == null) {
          return 'Selecciona una fecha y hora.';
        }
        return null;
      },
    );
  }
}
