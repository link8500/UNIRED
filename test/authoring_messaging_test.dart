import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/aplicacion/navegacion/navegador_aplicacion.dart';
import 'package:unired/models/autenticacion/models/usuario_aplicacion.dart';
import 'package:unired/models/administracion/widgets/editor_publicacion.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'package:unired/shared/widgets/editor_imagen_publicacion.dart';
import 'package:unired/shared/widgets/avisos_aplicacion.dart';
import 'support/test_adapter.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['UNIRED_PREVIEW_DIR'] != null) {
      final font = File('C:/Windows/Fonts/arial.ttf');
      if (await font.exists()) {
        await (FontLoader(
          'Arial',
        )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  late AplicacionController service;
  late TestAdapter adapter;
  late List<Json> messages;
  late Uint8List photo;
  Future<ui.Image> fixtureImage() async {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 400),
      Paint()..color = Colors.red,
    );
    canvas.drawRect(
      const Rect.fromLTWH(400, 0, 400, 400),
      Paint()..color = Colors.blue,
    );
    final picture = rec.endRecording();
    final image = await picture.toImage(800, 400);
    picture.dispose();
    return image;
  }

  setUp(() async {
    final img = await fixtureImage();
    photo = (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    img.dispose();
    messages = [
      {
        'id': '1',
        'autorId': '1',
        'contenido': 'Hola, ¿todavía está disponible?',
        'creadoEn': '2026-11-04T14:10:00Z',
      },
      {
        'id': '2',
        'autorId': '2',
        'contenido': 'Sí, todavía está disponible.',
        'creadoEn': '2026-11-04T14:11:00Z',
      },
      {
        'id': '3',
        'autorId': '2',
        'contenido': 'Te comparto los detalles.',
        'archivoId': '31',
        'adjunto': {
          'nombreOriginal': 'Información.pdf',
          'mimeDetectado': 'application/pdf',
        },
        'creadoEn': '2026-11-04T14:12:00Z',
      },
    ];
    final conversations = <Json>[
      {
        'id': '10',
        'interlocutorId': '2',
        'interlocutorNombre': 'Ana Martínez',
        'tipo': 'market',
        'anuncioId': '7',
        'recursoTitulo': 'Libro de programación',
        'ultimoMensaje': 'Te comparto los detalles.',
        'ultimoMensajeEn': '2026-11-04T14:12:00Z',
        'noLeidos': 1,
      },
      {
        'id': '11',
        'interlocutorId': '3',
        'interlocutorNombre': 'Carlos Pérez',
        'tipo': 'tutoria',
        'tutoriaId': '8',
        'recursoTitulo': 'Introducción al diseño web',
        'ultimoMensaje': 'Nos vemos en la clase.',
        'ultimoMensajeEn': '2026-11-03T14:00:00Z',
        'noLeidos': 0,
      },
    ];
    adapter = TestAdapter((r) async {
      if (r.responseType == ResponseType.bytes) return TestReply(photo);
      if (r.path == '/me/conversations') {
        return TestReply({
          'items': conversations,
          'total': 2,
          'page': 1,
          'limit': 20,
        });
      }
      if (r.path == '/conversations/10') return TestReply(conversations.first);
      if (r.path.endsWith('/read')) return TestReply({'ok': true});
      if (r.path == '/conversations/10/messages') {
        if (r.method == 'POST') {
          final m = <String, Object?>{
            'id': '${messages.length + 1}',
            'autorId': '1',
            'contenido': jsonObject(r.data)['contenido'],
            'creadoEn': '2026-11-04T14:15:00Z',
          };
          messages.add(m);
          return TestReply(m, status: 201);
        }
        return TestReply({
          'items': messages
              .where(
                (m) =>
                    intValue(m['id']) > intValue(r.queryParameters['afterId']),
              )
              .toList(),
          'total': messages.length,
          'page': 1,
          'limit': 20,
        });
      }
      return TestReply({'items': <Json>[], 'total': 0, 'page': 1, 'limit': 20});
    });
    service =
        AplicacionController(
            client: ClienteApi(
              enableLiveEvents: false,
              dio: Dio()..httpClientAdapter = adapter,
            ),
          )
          ..currentUser = const UsuarioAplicacion(
            id: '1',
            name: 'Alex Bryan',
            email: 'alex@example.test',
            university: '',
            roles: ['usuario', 'administrador'],
          )
          ..initialized = true
          ..categories = [
            {
              'id': 1,
              'nombre': 'Libros',
              'camposDetalle': [
                {'key': 'autor', 'label': 'Autor'},
                {'key': 'isbn', 'label': 'ISBN'},
              ],
            },
          ]
          ..areas = [
            {'id': 1, 'nombre': 'Software'},
          ];
    AplicacionController.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());
  Future<GlobalKey> open(WidgetTester t, String route, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TemaAplicacion.light,
          initialRoute: route,
          onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
          navigatorObservers: [NavegadorAplicacion.observer],
        ),
      ),
    );
    await t.pumpAndSettle();
    return key;
  }

  Future<void> preview(WidgetTester t, GlobalKey key, String name) async {
    final dir = Platform.environment['UNIRED_PREVIEW_DIR'];
    if (dir == null) return;
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    testWidgets('cuenta de lectura, menú y edición ${size.width}', (t) async {
      const member = UsuarioAplicacion(
        id: '12',
        name: 'Andrea Molina',
        email: 'andrea@example.test',
        university: 'Universidad Nacional',
        major: 'Ingeniería de sistemas',
        city: 'Managua',
        bio: 'Me interesa el diseño y la programación.',
        roles: ['usuario'],
      );
      service.currentUser = member;
      service.api.dio.httpClientAdapter = TestAdapter((request) async {
        if (request.path == '/me' && request.method == 'PATCH') {
          final fields = jsonObject(request.data);
          expect(fields['nombre'], 'Andrea López');
          return TestReply({
            'id': member.id,
            'nombre': fields['nombre'],
            'email': member.email,
            'estado': 'activo',
            'roles': member.roles,
            'perfil': fields,
          });
        }
        if (request.path == '/me/enrollments') {
          return TestReply({
            'items': [
              {
                'id': '18',
                'tutoriaId': '7',
                'cursoTitulo': 'Introducción a Flutter',
                'tutorNombre': 'María López',
                'estado': 'activa',
                'modalidad': 'grabada',
                'cursoDisponible': true,
                'totalLecciones': 4,
                'completadas': 2,
              },
            ],
            'page': 1,
            'limit': 50,
            'total': 1,
          });
        }
        return TestReply({'items': [], 'page': 1, 'limit': 50, 'total': 0});
      });
      final suffix = size.width > 1000 ? 'desktop' : 'mobile';
      final key = await open(t, RutasAplicacion.profile, size);
      expect(
        find.text('Me interesa el diseño y la programación.'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Mensajes'), findsNothing);
      await preview(t, key, 'account-profile-$suffix');
      await t.tap(find.byTooltip('Mi cuenta'));
      await t.pumpAndSettle();
      expect(find.text('Mensajes'), findsOneWidget);
      final popup = find.byWidgetPredicate(
        (widget) => widget is PopupMenuItem<String>,
      );
      expect(popup, findsWidgets);
      await preview(t, key, 'account-menu-$suffix');
      await t.tap(
        find.descendant(of: popup, matching: find.text('Mi aprendizaje')),
      );
      await t.pumpAndSettle();
      expect(find.text('Introducción a Flutter'), findsOneWidget);
      expect(find.text('2 de 4 lecciones completadas'), findsOneWidget);
      await preview(t, key, 'account-learning-$suffix');
      await t.tap(find.text('Volver a mi perfil'));
      await t.pumpAndSettle();
      await t.tap(find.text('Editar perfil'));
      await t.pumpAndSettle();
      await preview(t, key, 'account-edit-$suffix');
      final name = find.byKey(const ValueKey('profile-nombre'));
      await t.enterText(name, 'Andrea López');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      final save = find.text('Guardar perfil');
      await t.ensureVisible(save);
      await t.pumpAndSettle();
      await t.tap(save);
      await t.pumpAndSettle();
      expect(find.text('Andrea López'), findsOneWidget);
      expect(service.currentUser?.name, 'Andrea López');
      expect(find.byType(TextFormField), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'aviso de imagen dentro del entorno administrativo ${size.width}',
      (t) async {
        final key = await open(
          t,
          RutasAplicacion.publication(
            tutorial: false,
            admin: true,
            editing: true,
          ),
          size,
        );
        final context = t.element(find.byType(Scaffold).first);
        AvisosAplicacion.show(
          context,
          kind: TipoAviso.warning,
          title: 'No se pudo subir la imagen',
          message:
              'La fotografía supera el límite de 10 MiB. Selecciona una imagen JPG, PNG o WebP más pequeña.',
        );
        await t.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        await preview(
          t,
          key,
          size.width > 1000 ? 'image-warning-desktop' : 'image-warning-mobile',
        );
        await t.tap(find.text('Entendido'));
        await t.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(t.takeException(), isNull);
      },
    );
    testWidgets(
      'chat del administrador conserva el panel y envía mensajes ${size.width}',
      (t) async {
        final key = await open(
          t,
          '${RutasAplicacion.adminMessages}?id=10',
          size,
        );
        expect(find.text('Sí, todavía está disponible.'), findsOneWidget);
        expect(find.byTooltip('Enviar mensaje'), findsOneWidget);
        expect(find.text('Información.pdf'), findsAtLeastNWidgets(1));
        await preview(
          t,
          key,
          size.width > 1000 ? 'admin-chat-desktop' : 'admin-chat-mobile',
        );
        await t.enterText(
          find.byType(TextField).last,
          'Me interesa el artículo.',
        );
        await t.pumpAndSettle();
        await t.tap(find.byTooltip('Enviar mensaje'));
        await t.pumpAndSettle();
        final sent = adapter.requests
            .where(
              (r) =>
                  r.method == 'POST' && r.path == '/conversations/10/messages',
            )
            .single;
        expect(
          sent.data,
          containsPair('contenido', 'Me interesa el artículo.'),
        );
        expect(jsonObject(sent.data)['clienteId'], isNotEmpty);
        expect(find.text('Me interesa el artículo.'), findsOneWidget);
        if (size.width < 700) {
          await t.tap(find.byTooltip('Volver a chats'));
          await t.pumpAndSettle();
          expect(find.text('Chats'), findsOneWidget);
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('Inicio oculta el registro a una cuenta que ya inició sesión', (
    t,
  ) async {
    final key = await open(t, RutasAplicacion.home, const Size(1440, 1000));
    expect(find.text('Explorar tutorías'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsNothing);
    await preview(t, key, 'home-desktop');
    expect(t.takeException(), isNull);
  });

  testWidgets('Ajustes ubica el teléfono en Privacidad', (t) async {
    final key = await open(
      t,
      '${RutasAplicacion.profile}?tab=preferences',
      const Size(1440, 1000),
    );
    expect(find.text('Seguridad y sesiones'), findsOneWidget);
    expect(find.text('Visibilidad del teléfono'), findsNothing);
    await t.tap(find.widgetWithText(ChoiceChip, 'Privacidad'));
    await t.pumpAndSettle();
    expect(find.text('Tus datos de contacto son privados'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Solo yo'), findsNothing);
    await preview(t, key, 'account-preferences-desktop');
    expect(t.takeException(), isNull);
  });

  testWidgets('el usuario tiene bandeja propia sin navegación administrativa', (
    t,
  ) async {
    service.currentUser = const UsuarioAplicacion(
      id: '1',
      name: 'Estudiante',
      email: 'e@example.test',
      university: 'UNAN',
      roles: ['usuario'],
    );
    final key = await open(
      t,
      '${RutasAplicacion.messages}?id=10',
      const Size(1440, 1000),
    );
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('GESTIÓN'), findsNothing);
    await preview(t, key, 'student-chat-desktop');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('el chat prepara un municipio antes de enviarlo', (t) async {
    await open(
      t,
      '${RutasAplicacion.adminMessages}?id=10',
      const Size(1440, 1000),
    );
    await t.tap(find.byTooltip('Compartir municipio'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, 'leon');
    await t.pumpAndSettle();
    await t.tap(find.text('León'));
    await t.pumpAndSettle();
    expect(
      adapter.requests.where(
        (r) => r.method == 'POST' && r.path == '/conversations/10/messages',
      ),
      isEmpty,
    );
    await t.tap(find.byTooltip('Enviar mensaje'));
    await t.pumpAndSettle();
    final sent = adapter.requests.singleWhere(
      (r) => r.method == 'POST' && r.path == '/conversations/10/messages',
    );
    expect(sent.data, containsPair('contenido', 'Ubicación · León'));
    expect(find.widgetWithText(TextButton, 'León'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('los detalles del chat se abren en una pantalla intermedia', (
    t,
  ) async {
    await open(
      t,
      '${RutasAplicacion.adminMessages}?id=10',
      const Size(1024, 900),
    );
    await t.tap(find.byTooltip('Detalles de la conversación'));
    await t.pumpAndSettle();
    expect(find.text('Acerca de esta conversación'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'la categoría habilita detalles específicos y la revisión confirma la publicación',
    (t) async {
      t.view.physicalSize = const Size(1440, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: TemaAplicacion.light,
            home: Scaffold(
              body: EditorPublicacion(
                isTutorial: false,
                initial: {
                  'titulo': 'Libro para aprender programación',
                  'descripcion': 'Ejercicios prácticos y proyectos.',
                  'precioBase': '350.00',
                  'imagenes': [
                    {'archivoId': '21', 'orden': 1},
                  ],
                },
              ),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const ValueKey('publication-select-Categoría')));
      await t.pumpAndSettle();
      await t.tap(find.text('Libros').last);
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Más detalles'));
      await t.tap(find.text('Más detalles'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'ISBN'), findsOneWidget);
      await t.ensureVisible(find.text('Buscar municipio'));
      await t.pumpAndSettle();
      await t.tap(find.text('Buscar municipio'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, 'leon');
      await t.pumpAndSettle();
      await t.tap(find.text('León').last);
      await t.pumpAndSettle();
      expect(find.text('León'), findsWidgets);
      await t.tap(find.text('Siguiente'));
      await t.pumpAndSettle();
      expect(find.text('Revisa antes de publicar'), findsOneWidget);
      await preview(t, key, 'market-confirmation-desktop');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('la edición de fotografía exporta el encuadre confirmado', (
    t,
  ) async {
    t.view.physicalSize = const Size(1000, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    Uint8List? output;
    await t.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                editPublicationImage(context, photo).then((v) => output = v);
              },
              child: const Text('Editar imagen'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Editar imagen'));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await t.pumpAndSettle();
    expect(find.text('Ajustar fotografía'), findsOneWidget);
    await t.tap(find.byTooltip('Girar 90°'));
    await t.pumpAndSettle();
    await t.tap(find.text('Usar este encuadre'));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pumpAndSettle();
    expect(output, isNotNull);
    await t.runAsync(() async {
      final codec = await ui.instantiateImageCodec(output!);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1440);
      expect(frame.image.height, 810);
      frame.image.dispose();
      codec.dispose();
    });
    expect(t.takeException(), isNull);
  });
  test(
    'el encuadre exportado usa la posición elegida y conserva colores',
    () async {
      final image = await fixtureImage();
      Future<Uint8List> pixels(double x) async {
        final rec = ui.PictureRecorder();
        PintorImagenPublicacion(
          image: image,
          fill: true,
          position: Offset(x, 0),
        ).paint(Canvas(rec), const Size(100, 100));
        final pic = rec.endRecording();
        final rendered = await pic.toImage(100, 100);
        final data = (await rendered.toByteData())!.buffer.asUint8List();
        rendered.dispose();
        pic.dispose();
        return data;
      }

      final right = await pixels(1), left = await pixels(-1);
      final middle = (50 * 100 + 50) * 4;
      expect(right[middle], greaterThan(200));
      expect(left[middle + 2], greaterThan(200));
      image.dispose();
    },
  );
}
