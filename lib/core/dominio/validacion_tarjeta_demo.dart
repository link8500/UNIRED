// Archivo: lib/core/dominio/validacion_tarjeta_demo.dart
// Validación local para la maqueta de pago. No consulta bancos ni autoriza cobros.
enum MarcaTarjetaDemo { visa, mastercard, amex, desconocida }

class TarjetaDemo {
  static const numeroVisa = '4111111111111111';
  static const _numerosDePrueba = {
    numeroVisa,
    '5555555555554444',
    '2221000000000009',
    '378282246310005',
  };

  static String digitos(String value) => value.replaceAll(RegExp(r'[ -]'), '');
  static MarcaTarjetaDemo marca(String number) {
    final value = digitos(number);
    if (value.startsWith('4')) return MarcaTarjetaDemo.visa;
    final first =
        int.tryParse(value.length >= 2 ? value.substring(0, 2) : '') ?? 0;
    final firstFour =
        int.tryParse(value.length >= 4 ? value.substring(0, 4) : '') ?? 0;
    if ((first >= 51 && first <= 55) ||
        (firstFour >= 2221 && firstFour <= 2720)) {
      return MarcaTarjetaDemo.mastercard;
    }
    if (first == 34 || first == 37) return MarcaTarjetaDemo.amex;
    return MarcaTarjetaDemo.desconocida;
  }

  static String nombre(String number) => switch (marca(number)) {
    MarcaTarjetaDemo.visa => 'Visa',
    MarcaTarjetaDemo.mastercard => 'Mastercard',
    MarcaTarjetaDemo.amex => 'American Express',
    MarcaTarjetaDemo.desconocida => 'Tarjeta de prueba',
  };
  static String? validarNumero(String value) {
    final number = digitos(value);
    return _numerosDePrueba.contains(number)
        ? null
        : 'Selecciona «Usar tarjeta de prueba» o escribe un número demo compatible.';
  }

  static String? validarVencimiento(String value, {DateTime? ahora}) {
    final match = RegExp(
      r'^(0[1-9]|1[0-2])/(\d{2}|\d{4})$',
    ).firstMatch(value.trim());
    if (match == null) return 'Usa el formato MM/AA.';
    final month = int.parse(match[1]!);
    final rawYear = int.parse(match[2]!);
    final year = match[2]!.length == 2 ? 2000 + rawYear : rawYear;
    final now = ahora ?? DateTime.now();
    return year < now.year ||
            (year == now.year && month < now.month) ||
            year > now.year + 20
        ? 'La fecha de vencimiento no es válida.'
        : null;
  }

  static String? validarCvv(String number, String cvv) =>
      RegExp(
        marca(number) == MarcaTarjetaDemo.amex ? r'^\d{4}$' : r'^\d{3}$',
      ).hasMatch(cvv)
      ? null
      : 'Revisa el código de seguridad de prueba.';
}
