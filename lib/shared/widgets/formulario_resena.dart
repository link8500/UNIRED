import 'package:flutter/material.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/shared/widgets/marco_pagina.dart';
import 'package:unired/shared/widgets/widgets_api.dart';

class FormularioResena extends StatefulWidget {
  const FormularioResena({
    super.key,
    required this.title,
    required this.submit,
    this.commentRequired = false,
    this.label = 'Guardar reseña',
    this.success,
  });
  final String title, label;
  final Future<void> Function(Json) submit;
  final bool commentRequired;
  final String? success;

  @override
  State<FormularioResena> createState() => _FormularioResenaState();
}

class _FormularioResenaState extends State<FormularioResena> {
  static const _ratings = [
    'Muy mala',
    'Regular',
    'Buena',
    'Muy buena',
    'Excelente',
  ];
  final _form = GlobalKey<FormState>();
  final _comment = TextEditingController();
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TarjetaSuave(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Selecciona de una a cinco estrellas.'),
          Wrap(
            children: [
              for (var i = 1; i <= 5; i++)
                Semantics(
                  selected: i == _rating,
                  child: IconButton(
                    tooltip: i == 1 ? '1 estrella' : '$i estrellas',
                    onPressed: _sending
                        ? null
                        : () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: i <= _rating ? const Color(0xFF9B5600) : null,
                      size: 29,
                    ),
                  ),
                ),
            ],
          ),
          if (_rating > 0)
            Semantics(
              liveRegion: true,
              child: Text('$_rating de 5 · ${_ratings[_rating - 1]}'),
            ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _comment,
            enabled: !_sending,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: widget.commentRequired
                  ? 'Comparte tu experiencia'
                  : 'Comentario (opcional)',
              hintText: '¿Qué te gustó o qué se podría mejorar?',
            ),
            validator: (value) =>
                widget.commentRequired && (value?.trim().isEmpty ?? true)
                ? 'Escribe un comentario sobre tu experiencia.'
                : null,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: BotonAccionApi(
              label: widget.label,
              enabled: _rating != 0,
              success: widget.success,
              action: () async {
                if (_rating == 0 || !_form.currentState!.validate()) return;
                final comment = _comment.text.trim();
                setState(() => _sending = true);
                try {
                  await widget.submit({
                    'puntuacion': _rating,
                    if (comment.isNotEmpty) 'comentario': comment,
                  });
                } finally {
                  if (mounted) setState(() => _sending = false);
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}
