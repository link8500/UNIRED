import 'package:flutter_test/flutter_test.dart';
import 'package:unired/models/inicio/widgets/formato_anuncio_inicio.dart';

void main() {
  test('el bloque entre secciones solo se elige si cabe completo', () {
    expect(FormatoAnuncioInicio.entreSecciones(249), isNull);
    expect(
      FormatoAnuncioInicio.entreSecciones(250),
      FormatoAnuncioInicio.cuadrado,
    );
    expect(
      FormatoAnuncioInicio.entreSecciones(727),
      FormatoAnuncioInicio.cuadrado,
    );
    expect(
      FormatoAnuncioInicio.entreSecciones(728),
      FormatoAnuncioInicio.horizontal,
    );
  });

  test(
    'el bloque lateral reserva espacio completo para el formato vertical',
    () {
      expect(FormatoAnuncioInicio.vertical.width, 300);
      expect(FormatoAnuncioInicio.vertical.height, 600);
    },
  );
}
