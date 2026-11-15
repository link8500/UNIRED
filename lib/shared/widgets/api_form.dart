import 'package:flutter/material.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/shared/widgets/api_widgets.dart';
import 'package:unired/shared/widgets/admin_components.dart';

enum ApiFieldKind {
  text,
  integer,
  money,
  flag,
  choice,
  integerChoice,
  date,
  list,
}

class ApiField {
  const ApiField(
    this.key,
    this.label, {
    this.kind = ApiFieldKind.text,
    this.required = true,
    this.clearable = false,
    this.lines = 1,
    this.choices = const {},
  });
  final String key;
  final String label;
  final ApiFieldKind kind;
  final bool required;
  final bool clearable;
  final int lines;
  final Map<String, String> choices;
}

/// Formularios de negocio reutilizables; traduce fechas/importes antes de HTTP.
class ApiForm extends StatefulWidget {
  const ApiForm({
    super.key,
    required this.title,
    required this.fields,
    required this.submit,
    this.initial = const {},
    this.label = 'Guardar',
  });
  final String title;
  final String label;
  final List<ApiField> fields;
  final Json initial;
  final Future<void> Function(Json) submit;
  @override
  State<ApiForm> createState() => _ApiFormState();
}

class _ApiFormState extends State<ApiForm> {
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
    for (final f in widget.fields.where((f) => f.kind == ApiFieldKind.flag))
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
  Widget build(BuildContext context) => AdminSurface(
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
            child: ApiActionButton(
              label: widget.label,
              action: () async {
                if (!_form.currentState!.validate()) return;
                final data = <String, Object?>{};
                for (final f in widget.fields) {
                  final value = _controllers[f.key]!.text.trim();
                  if (f.kind == ApiFieldKind.flag) {
                    data[f.key] = _flags[f.key];
                    continue;
                  }
                  if (value.isEmpty && !f.required) {
                    if (f.clearable) {
                      data[f.key] = f.kind == ApiFieldKind.list
                          ? <String>[]
                          : null;
                    }
                    continue;
                  }
                  data[f.key] = switch (f.kind) {
                    ApiFieldKind.integer ||
                    ApiFieldKind.integerChoice => int.parse(value),
                    ApiFieldKind.money => double.parse(
                      value.replaceAll(',', '.'),
                    ).toStringAsFixed(2),
                    ApiFieldKind.date => DateTime.parse(
                      value,
                    ).toUtc().toIso8601String(),
                    ApiFieldKind.list =>
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
  Widget _input(ApiField field) {
    if (field.kind == ApiFieldKind.flag) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label),
        value: _flags[field.key]!,
        onChanged: (v) => setState(() => _flags[field.key] = v),
      );
    }
    if ([
      ApiFieldKind.choice,
      ApiFieldKind.integerChoice,
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
      keyboardType: field.kind == ApiFieldKind.money
          ? const TextInputType.numberWithOptions(decimal: true)
          : field.kind == ApiFieldKind.integer
          ? TextInputType.number
          : field.lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: field.lines > 1 ? TextInputAction.newline : null,
      decoration: InputDecoration(
        alignLabelWithHint: field.lines > 1,
        labelText: field.label,
        helperText: field.kind == ApiFieldKind.list
            ? 'Separados por coma'
            : null,
        suffixIcon: field.kind == ApiFieldKind.date
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
        if (field.kind == ApiFieldKind.integer && int.tryParse(value) == null) {
          return 'Número entero inválido.';
        }
        if (field.kind == ApiFieldKind.money) {
          final n = double.tryParse(value.replaceAll(',', '.'));
          if (n == null || !n.isFinite || n < 0) return 'Importe inválido.';
        }
        if (field.kind == ApiFieldKind.date &&
            DateTime.tryParse(value) == null) {
          return 'Selecciona una fecha y hora.';
        }
        return null;
      },
    );
  }
}
