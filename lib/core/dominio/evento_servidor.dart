// Archivo: lib/core/dominio/evento_servidor.dart
// Interpreta eventos SSE incluso cuando la red divide una línea entre paquetes.
import 'dart:convert';
import 'package:unired/core/dominio/datos_api.dart';

class EventoServidor {
  const EventoServidor({
    required this.type,
    required this.id,
    required this.data,
  });
  final String type, id;
  final Json data;
}

Stream<EventoServidor> interpretarEventos(Stream<String> source) async* {
  var type = 'message', id = '';
  var data = <String>[];
  var size = 0;
  await for (final line in source.transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        yield EventoServidor(
          type: type,
          id: id,
          data: jsonObject(jsonDecode(data.join('\n'))),
        );
      }
      type = 'message';
      data = [];
      size = 0;
    } else if (!line.startsWith(':')) {
      size += line.length;
      if (size > 1048576) {
        throw const FormatException('Evento demasiado grande.');
      }
      final colon = line.indexOf(':');
      final field = colon < 0 ? line : line.substring(0, colon);
      var value = colon < 0 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      switch (field) {
        case 'event':
          type = value;
        case 'id':
          if (!value.contains('\u0000')) id = value;
        case 'data':
          data.add(value);
      }
    }
  }
}
