import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'package:unired/shared/widgets/editor_imagen_publicacion.dart';
import 'dart:typed_data';

void main() {
  testWidgets(
    'el aviso global abre el modal desde el builder exterior al navegador',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: AvisosAplicacion.navigatorKey,
          theme: TemaAplicacion.light,
          builder: (_, child) => Column(
            children: [
              Expanded(child: child!),
              const AvisoErrorApi(message: 'Servidor no disponible'),
            ],
          ),
          home: const Scaffold(body: Text('Inicio')),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Servidor no disponible'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      await t.tap(find.text('Entendido'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  Future<void> open(WidgetTester t, void Function(BuildContext) action) =>
      t.pumpWidget(
        MaterialApp(
          theme: TemaAplicacion.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => action(context),
                child: const Text('Probar aviso'),
              ),
            ),
          ),
        ),
      );

  testWidgets(
    'los errores de una acción aparecen en un modal y permiten reintentar',
    (t) async {
      var attempts = 0;
      Future<bool>? result;
      await open(t, (context) {
        result = runApiAction(context, () async {
          attempts++;
          throw const ErrorApi('La imagen supera el límite permitido.');
        });
      });
      await t.tap(find.text('Probar aviso'));
      await t.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text('La imagen supera el límite permitido.'),
        findsOneWidget,
      );
      await t.tap(find.text('Entendido'));
      await t.pumpAndSettle();
      expect(await result, isFalse);
      await t.tap(find.text('Probar aviso'));
      await t.pumpAndSettle();
      expect(attempts, 2);
      await t.tap(find.byTooltip('Cerrar aviso'));
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'avisos simultáneos iguales no se duplican y los distintos esperan',
    (t) async {
      await open(t, (context) {
        final first = AvisosAplicacion.show(context, message: 'Primer aviso');
        expect(
          identical(
            first,
            AvisosAplicacion.show(context, message: 'Primer aviso'),
          ),
          isTrue,
        );
        unawaited(AvisosAplicacion.show(context, message: 'Segundo aviso'));
      });
      await t.tap(find.text('Probar aviso'));
      await t.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Segundo aviso'), findsNothing);
      await t.tap(find.text('Entendido'));
      await t.pumpAndSettle();
      expect(find.text('Segundo aviso'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      await t.tap(find.text('Entendido'));
      await t.pumpAndSettle();
    },
  );

  testWidgets('un error de carga no vuelve a abrirse al reconstruir la vista', (
    t,
  ) async {
    final rebuild = ValueNotifier(0);
    addTearDown(rebuild.dispose);
    await t.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: rebuild,
            builder: (_, _, _) => const AvisoErrorApi(message: 'Sin conexión'),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Sin conexión'), findsOneWidget);
    await t.tap(find.text('Entendido'));
    await t.pumpAndSettle();
    rebuild.value++;
    await t.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await t.tap(find.text('Ver aviso'));
    await t.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await t.tap(find.text('Entendido'));
    await t.pumpAndSettle();
  });

  testWidgets(
    'una imagen inválida muestra una explicación legible en el modal',
    (t) async {
      await open(t, (context) {
        unawaited(
          runApiAction(context, () async {
            await editPublicationImage(context, Uint8List.fromList([1, 2, 3]));
          }),
        );
      });
      await t.tap(find.text('Probar aviso'));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pumpAndSettle();
      expect(find.text('Revisa el archivo'), findsOneWidget);
      expect(find.textContaining('JPG, PNG o WebP'), findsOneWidget);
      await t.tap(find.text('Entendido'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('el modal cabe en móvil con texto ampliado y permite cancelar', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    bool? answer;
    await t.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.6)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => answer = await AvisosAplicacion.show(
                context,
                kind: TipoAviso.warning,
                message:
                    'Revisa los datos antes de continuar con la publicación.',
                action: 'Continuar',
                cancel: 'Cancelar',
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Cancelar'));
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(answer, isFalse);
    expect(t.takeException(), isNull);
  });
}
