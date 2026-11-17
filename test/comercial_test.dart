import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/validacion_tarjeta_demo.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/comercial/views/empresas_view.dart';
import 'package:unired/models/comercial/views/cartera_view.dart';
import 'package:unired/models/comercial/views/comercial_admin_view.dart';
import 'package:unired/models/comercial/widgets/pago_demo.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'support/test_adapter.dart';

void main() {
  test(
    'detecta marcas y valida los números de demostración sin conectarse a una pasarela',
    () {
      for (final value in [
        '4111111111111111',
        '5555555555554444',
        '378282246310005',
      ]) {
        expect(TarjetaDemo.validarNumero(value), isNull);
      }
      expect(TarjetaDemo.marca('4111111111111111'), MarcaTarjetaDemo.visa);
      expect(
        TarjetaDemo.marca('5555555555554444'),
        MarcaTarjetaDemo.mastercard,
      );
      expect(
        TarjetaDemo.marca('2221000000000009'),
        MarcaTarjetaDemo.mastercard,
      );
      expect(TarjetaDemo.marca('378282246310005'), MarcaTarjetaDemo.amex);
      for (final value in [
        '4111111111111112',
        '123',
        'abc4111111111111111',
        '9999999999999999',
      ]) {
        expect(TarjetaDemo.validarNumero(value), isNotNull);
      }
      expect(TarjetaDemo.validarCvv('378282246310005', '1234'), isNull);
      expect(TarjetaDemo.validarCvv('378282246310005', '123'), isNotNull);
      expect(
        TarjetaDemo.validarVencimiento('11/26', ahora: DateTime(2026, 11, 30)),
        isNull,
      );
      expect(
        TarjetaDemo.validarVencimiento('10/26', ahora: DateTime(2026, 11)),
        isNotNull,
      );
    },
  );
  late AplicacionController store;
  late TestAdapter adapter;
  setUp(() {
    adapter = TestAdapter((r) async {
      if (r.path == '/demo/checkout') {
        return TestReply({
          'simulado': true,
          'mensaje': 'Compra simulada realizada',
        }, status: 201);
      }
      if (r.path == '/commerce/config') {
        return TestReply({
          'comisionPorcentaje': '10.00',
          'precioDestacado': '50.00',
          'diasDestacado': 7,
          'precioMinutoOnline': '3.00',
          'precioMinutoPresencial': '4.00',
        });
      }
      if (r.path == '/me/wallet') {
        return TestReply({'saldoDemo': '250.00', 'movimientos': []});
      }
      if (r.path == '/business/plans') {
        return TestReply([
          for (var i = 1; i <= 3; i++)
            {
              'id': '$i',
              'nombre': 'Plan $i',
              'descripcion': 'Plan de demostración para empresas',
              'precioMensual': '199.00',
              'maxCampanas': i,
            },
        ]);
      }
      if (r.path == '/me/businesses/1') {
        return TestReply({
          'id': '1',
          'nombre': 'Negocio universitario',
          'estado': 'aprobada',
          'descripcion': 'Artículos de la comunidad',
          'campanas': [],
          'suscripciones': [],
        });
      }
      return TestReply({'items': [], 'total': 0, 'page': 1, 'limit': 20});
    });
    store =
        AplicacionController(
            client: ClienteApi(
              enableLiveEvents: false,
              dio: Dio()..httpClientAdapter = adapter,
            ),
          )
          ..currentUser = const UsuarioAplicacion(
            id: '1',
            name: 'Persona de prueba',
            email: 'test@example.test',
            university: 'Universidad',
            roles: ['administrador'],
          );
    AplicacionController.replaceInstanceForTesting(store);
  });
  tearDown(() => store.dispose());
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'pago demo a $width: confirma sin enviar ningún campo de tarjeta',
      (t) async {
        t.view.physicalSize = Size(width, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          MaterialApp(
            theme: TemaAplicacion.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => mostrarPagoDemo(
                    context,
                    title: 'Destacar artículo',
                    amount: '50.00',
                    operation: {
                      'concepto': 'destacar_anuncio',
                      'recursoId': '7',
                    },
                  ),
                  child: const Text('Abrir pago'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Abrir pago'));
        await t.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await t.enterText(fields.at(0), 'Persona de prueba');
        await t.enterText(fields.at(1), '4111111111111111');
        await t.enterText(fields.at(2), '12/30');
        await t.enterText(fields.at(3), '123');
        expect(find.text('Visa'), findsOneWidget);
        await t.ensureVisible(find.text('Simular compra'));
        await t.tap(find.text('Simular compra'));
        await t.pumpAndSettle();
        final request = adapter.requests.single;
        expect(request.path, '/demo/checkout');
        final payload = jsonEncode(request.data);
        for (final private in [
          '4111111111111111',
          '12/30',
          'Persona de prueba',
          'cvv',
          'numeroTarjeta',
        ]) {
          expect(payload.contains(private), false);
        }
        expect(find.text('Pago de demostración'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );
    for (final kind in [0, 1, 2]) {
      testWidgets('gestión comercial $kind adaptable a $width', (t) async {
        t.view.physicalSize = Size(width, 950);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          MaterialApp(
            theme: TemaAplicacion.light,
            home: kind == 0
                ? const EmpresasView(companyId: '1')
                : kind == 1
                ? const CarteraView()
                : const ComercialAdminView(),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }
  }
}
