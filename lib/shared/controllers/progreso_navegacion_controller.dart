// Archivo: lib/shared/controllers/progreso_navegacion_controller.dart
// Implementa el estado visual de la barra de carga y completa cada grupo cuando terminan sus solicitudes.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:unired/core/dominio/contratos/monitor_progreso.dart';

/// Estado de la barra de progreso que acompaña solicitudes reales a la API.
///
/// Avanza hasta un límite seguro mientras quedan operaciones pendientes.
/// ClienteApi la completa al recibir todas las respuestas. No simula porcentajes
/// de descarga y no aparece por seleccionar una ruta ya guardada en memoria.
class ProgresoNavegacionController extends ChangeNotifier
    implements MonitorProgreso {
  ProgresoNavegacionController._();

  /// Instancia global usada por el overlay de la aplicación.
  static final instance = ProgresoNavegacionController._();

  Timer? _timer;
  Timer? _hideTimer;
  int _operation = 0;
  double _value = 0;
  bool _visible = false;

  double get value => _value;
  bool get visible => _visible;

  /// Inicia una nueva operación y devuelve un identificador para completarla.
  @override
  int begin() {
    _operation++;
    _timer?.cancel();
    _hideTimer?.cancel();
    _value = .06;
    _visible = true;
    notifyListeners();

    // El límite evita que la barra anuncie un 100% antes de que la vista esté
    // realmente lista. El timer no bloquea la construcción del frame.
    _timer = Timer.periodic(const Duration(milliseconds: 45), (_) {
      if (_value >= .88) return;
      _value = (_value + .025).clamp(0, .88);
      notifyListeners();
    });
    return _operation;
  }

  /// Completa la operación cuando su conjunto de solicitudes ha terminado.
  @override
  void complete(int operation) {
    if (operation != _operation || !_visible) return;
    _timer?.cancel();
    _timer = null;
    _value = 1;
    notifyListeners();
    _hideTimer = Timer(const Duration(milliseconds: 180), () {
      if (operation != _operation) return;
      _visible = false;
      _value = 0;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }
}
