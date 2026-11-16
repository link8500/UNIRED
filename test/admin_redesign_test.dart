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
import 'package:unired/models/perfil/widgets/formulario_perfil.dart';
import 'package:unired/models/administracion/widgets/editor_publicacion.dart';
import 'package:unired/shared/temas/tema_aplicacion.dart';
import 'package:unired/shared/widgets/componentes_administracion.dart';
import 'package:unired/shared/widgets/widgets_api.dart';
import 'support/test_adapter.dart';

/// Datos ilustrativos exclusivos de pruebas; jamás se insertan en la aplicación.
void main() {
  setUpAll(() async {
    // Las capturas locales usan la tipografía real; las pruebas no dependen de ella.
    if (Platform.environment['UNIRED_PREVIEW_DIR'] != null) {
      final font = File('C:/Windows/Fonts/arial.ttf');
      if (await font.exists()) {
        final loader = FontLoader('Arial')
          ..addFont(
            font.readAsBytes().then((data) => ByteData.sublistView(data)),
          );
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  late AplicacionController service;
  late TestAdapter adapter;
  final account = <String, Object?>{
    'id': 2,
    'nombre': 'Fernando Herrera',
    'email': 'fernando@example.test',
    'roles': ['usuario'],
    'estado': 'activo',
    'edad': 23,
    'creadoEn': '2026-10-12T12:00:00Z',
    'perfil': {
      'ciudad': 'Managua',
      'pais': 'Nicaragua',
      'universidad': 'UNAN-Managua',
      'carrera': 'Ingeniería en Sistemas',
      'sede': 'Central',
      'anioEstudio': 3,
      'telefono': '+505 8888 8888',
      'trabaja': true,
      'ocupacion': 'Desarrollador',
      'presentacion': 'Aprender y compartir conocimientos con la comunidad.',
    },
    'resumen': {
      'publicaciones': 12,
      'tutorias': 3,
      'inscripciones': 2,
      'sesionesActivas': 1,
    },
    'publicaciones': [
      {
        'id': '1',
        'titulo': 'Libro de programación',
        'estado': 'publicado',
        'precioBase': '350.00',
        'moneda': 'NIO',
      },
    ],
    'tutorias': [
      {
        'id': '1',
        'titulo': 'Desarrollo web desde cero',
        'estado': 'publicada',
        'precioBase': '250.00',
        'moneda': 'NIO',
      },
    ],
  };
  setUp(() {
    adapter = TestAdapter(
      (request) async => TestReply(
        request.path == '/admin/users/2'
            ? account
            : request.path == '/me'
            ? {
                ...account,
                'id': 1,
                'nombre': 'Alex Bryan',
                'roles': ['usuario', 'administrador'],
              }
            : request.path.contains('/files/')
            ? []
            : {
                'items': [
                  for (var i = 0; i < 6; i++)
                    {
                      'id': i + 2,
                      'nombre': i == 0
                          ? 'Fernando Herrera'
                          : [
                              'Marc Cucurella',
                              'Ubaldo Acosta',
                              'Ana Martínez',
                              'Sofía López',
                              'Carlos Pérez',
                            ][i - 1],
                      'email': 'usuario${i + 1}@example.test',
                      'estado': i == 2 ? 'suspendido' : 'activo',
                      'roles': ['usuario'],
                      'ciudad': i.isEven ? 'Managua' : 'León',
                      'universidad': 'UNAN-Managua',
                      'publicaciones': 12 - i,
                      'tutorias': i == 0 ? 3 : 0,
                      'tutorVerificado': i == 0,
                    },
                ],
                'total': 6,
                'page': 1,
                'limit': 20,
              },
      ),
    );
    service = AplicacionController(
      client: ClienteApi(dio: Dio()..httpClientAdapter = adapter),
    );
    service.currentUser = const UsuarioAplicacion(
      id: '1',
      name: 'Alex Bryan',
      email: 'admin@example.test',
      university: '',
      roles: ['usuario', 'administrador'],
    );
    service.dashboard = {
      'usuarios': 2753,
      'cursos': 128,
      'anuncios': 412,
      'solicitudesPendientes': 4,
      'denunciasPendientes': 2,
      'conversaciones': 189,
    };
    service.analytics = {
      'actividad': [
        for (var i = 0; i < 30; i++)
          {
            'dia': '2026-10-${(i + 1).toString().padLeft(2, '0')}',
            'usuariosRegistrados': [2, 4, 3, 6, 3, 5, 7][i % 7],
            'anunciosCreados': [1, 2, 1, 3, 1, 2, 4][i % 7],
            'cursosCreados': i % 3,
            'inscripcionesCreadas': [0, 1, 2, 1, 3, 2, 1][i % 7],
          },
      ],
      'estadosUsuarios': [
        {'estado': 'activo', 'total': 2480},
        {'estado': 'pendiente_email', 'total': 230},
        {'estado': 'suspendido', 'total': 43},
      ],
      'tutoresDemandados': [
        for (var i = 0; i < 5; i++)
          {
            'id': i + 2,
            'nombre': [
              'Fernando Herrera',
              'Ubaldo Acosta',
              'Sofía López',
              'Ana Martínez',
              'Carlos Pérez',
            ][i],
            'alumnos': 180 - i * 29,
            'cursos': 6 - i,
          },
      ],
      'solicitudesRecientes': [
        {'id': 1, 'nombre': 'María González', 'area': 'Matemáticas'},
        {'id': 2, 'nombre': 'José Ramírez', 'area': 'Programación'},
      ],
      'actividadReciente': [
        for (var i = 0; i < 5; i++)
          {
            'id': i + 1,
            'accion': [
              'perfil.actualizado',
              'anuncio.creado',
              'usuario.roles_actualizados',
              'catalogo.actualizado',
              'tutoria.creada',
            ][i],
            'actorNombre': [
              'Fernando Herrera',
              'Ana Martínez',
              'Alex Bryan',
              'Alex Bryan',
              'Sofía López',
            ][i],
            'entidad': i.isEven ? 'usuario' : 'anuncio',
            'entidadId': '${i + 2}',
            'creadoEn': '2026-10-30T12:00:00Z',
          },
      ],
    };
    AplicacionController.replaceInstanceForTesting(service);
  });
  tearDown(() => service.dispose());

  Future<GlobalKey> open(WidgetTester tester, String route, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TemaAplicacion.light,
          initialRoute: route,
          navigatorObservers: [NavegadorAplicacion.observer],
          onGenerateRoute: NavegadorAplicacion.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key;
  }

  Future<void> preview(WidgetTester tester, GlobalKey key, String name) async {
    final dir = Platform.environment['UNIRED_PREVIEW_DIR'];
    if (dir == null) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  void installPublicationFixture() {
    final current = service.currentUser;
    service.dispose();
    final listing = <String, Object?>{
      'id': '7',
      'vendedorId': '1',
      'vendedorNombre': 'Fernando Herrera',
      'titulo': 'Libro de programación',
      'categoriaId': 1,
      'categoriaNombre': 'Libros',
      'descripcion':
          'Ejemplos, proyectos y ejercicios para aprender programación.',
      'estado': 'publicado',
      'versionLock': 3,
      'precioBase': '350.00',
      'moneda': 'NIO',
      'tipoPrecio': 'fijo',
      'condicion': 'como_nuevo',
      'marca': 'Editorial universitaria',
      'modelo': 'Edición 2026',
      'ciudad': 'Managua',
      'zonaEntrega': 'Centro de la ciudad',
      'formasEntrega': ['retiro', 'punto_acordado'],
      'imagenes': <Json>[],
      'novedades': <Json>[],
    };
    final course = <String, Object?>{
      'id': '7',
      'tutorId': '1',
      'tutorNombre': 'Fernando Herrera',
      'titulo': 'Desarrollo web desde cero',
      'areaId': 1,
      'areaNombre': 'Software',
      'descripcion':
          'Aprende con ejercicios, videos y acompañamiento del tutor.',
      'resumen': 'De tus primeras líneas de código a una aplicación web.',
      'idioma': 'Español',
      'nivel': 'inicial',
      'modalidad': 'mixta',
      'objetivos': ['Diseñar interfaces', 'Construir una API'],
      'requisitos': ['Una computadora'],
      'duracionEstimadaMinutos': 120,
      'dirigidoA': 'Estudiantes que comienzan en programación',
      'estado': 'publicada',
      'precioBase': '250.00',
      'moneda': 'NIO',
      'versionLock': 3,
      'secciones': <Json>[],
      'lecciones': <Json>[],
      'galeria': <Json>[],
    };
    adapter = TestAdapter(
      (r) async => TestReply(
        ['/me/listings/7', '/listings/7'].contains(r.path)
            ? {
                ...listing,
                ...(r.method == 'PATCH'
                    ? jsonObject(r.data)
                    : <String, Object?>{}),
              }
            : (r.method == 'POST' && r.path == '/me/courses') ||
                  ['/me/courses/7', '/courses/7'].contains(r.path)
            ? {
                ...course,
                ...(r.method == 'PATCH'
                    ? jsonObject(r.data)
                    : <String, Object?>{}),
              }
            : ['/areas', '/categories', '/me/tutor-grants'].contains(r.path)
            ? [
                {'id': 1, 'nombre': 'Software'},
              ]
            : {'items': <Json>[], 'total': 0, 'page': 1, 'limit': 20},
      ),
    );
    service =
        AplicacionController(
            client: ClienteApi(dio: Dio()..httpClientAdapter = adapter),
          )
          ..currentUser = current
          ..initialized = true
          ..categories = [
            {'id': 1, 'nombre': 'Libros'},
          ]
          ..areas = [
            {'id': 1, 'nombre': 'Software'},
          ];
    AplicacionController.replaceInstanceForTesting(service);
  }

  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    for (final tutorial in [false, true]) {
      testWidgets('ficha pública $tutorial ${size.width}', (tester) async {
        installPublicationFixture();
        final key = await open(
          tester,
          '${tutorial ? RutasAplicacion.course : RutasAplicacion.listing}?id=7',
          size,
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            tutorial ? 'Desarrollo web desde cero' : 'Libro de programación',
          ),
          findsOneWidget,
        );
        await preview(
          tester,
          key,
          '${tutorial ? 'course' : 'listing'}-details-${size.width > 1000 ? 'desktop' : 'mobile'}',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'administrador edita su curso dentro del panel y conserva los campos enriquecidos',
    (tester) async {
      installPublicationFixture();
      await open(
        tester,
        RutasAplicacion.publication(
          tutorial: true,
          admin: true,
          id: '7',
          editing: true,
        ),
        const Size(1440, 1000),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Estudio de tutorías'), findsOneWidget);
      final button = tester.widget<BotonAccionApi>(
        find.ancestor(
          of: find.text('Guardar cambios'),
          matching: find.byType(BotonAccionApi),
        ),
      );
      await tester.runAsync(button.action);
      await tester.pumpAndSettle();
      final request = adapter.requests.singleWhere(
        (r) => r.method == 'PATCH' && r.path == '/me/courses/7',
      );
      expect(
        request.data,
        containsPair('objetivos', ['Diseñar interfaces', 'Construir una API']),
      );
      expect(
        (request.data as Map).containsKey('duracionEstimadaMinutos'),
        isFalse,
      );
      expect((request.data as Map).containsKey('idioma'), isFalse);
      expect(request.data, containsPair('versionLock', 3));
      expect((request.data as Map).containsKey('tutorId'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('una creación terminada no reutiliza el formulario anterior', (
    tester,
  ) async {
    installPublicationFixture();
    final route = RutasAplicacion.publication(tutorial: false, admin: false);
    await open(tester, route, const Size(1440, 1000));
    await tester.enterText(
      find.byKey(const ValueKey('publication-titulo')),
      'Mi primer borrador',
    );
    tester.widget<EditorPublicacion>(find.byType(EditorPublicacion)).onSaved!(
      '7',
      'presentation',
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    NavegadorAplicacion.go(tester.element(find.byType(Scaffold).first), route);
    await tester.pumpAndSettle();
    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('publication-titulo')),
    );
    expect(field.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });
  test('separa estudios, residencia y empleo al leer /me', () {
    final user = UsuarioAplicacion.fromJson(account);
    expect(user.university, 'UNAN-Managua');
    expect(user.city, 'Managua');
    expect(user.major, 'Ingeniería en Sistemas');
    expect(user.age, 23);
    expect(user.works, true);
    expect(user.profileData['anioEstudio'], '3');
    expect(user.copyWith(name: 'Otro').avatarId, user.avatarId);
  });
  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    testWidgets('dashboard compacto sin overflow ${size.width}', (
      tester,
    ) async {
      final key = await open(tester, RutasAplicacion.dashboard, size);
      expect(find.text('Usuarios totales'), findsOneWidget);
      expect(find.text('Actividad de la comunidad'), findsOneWidget);
      final card = find
          .ancestor(
            of: find.text('Usuarios totales'),
            matching: find.byType(SuperficieAdmin),
          )
          .first;
      await preview(
        tester,
        key,
        size.width > 1000 ? 'dashboard-desktop' : 'dashboard-mobile',
      );
      expect(tester.getSize(card).height, lessThan(210));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'ficha administrativa incluye estudios y contenido sin recargas accidentales',
    (tester) async {
      await tester.runAsync(service.loadAdminUsers);
      final key = await open(
        tester,
        RutasAplicacion.user,
        const Size(1440, 1000),
      );
      await tester.tap(find.text('Fernando Herrera'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Datos del usuario'), findsOneWidget);
      expect(find.text('UNAN-Managua'), findsOneWidget);
      service.setCompactAdminCards(true);
      await tester.pumpAndSettle();
      expect(
        adapter.requests.where((r) => r.path == '/admin/users/2').length,
        1,
      );
      await preview(tester, key, 'users-desktop');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('el perfil administrador no envía edad o universidad', (
    tester,
  ) async {
    Json? sent;
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FormularioPerfil(
              initial: const {'nombre': 'Administrador', 'ciudad': 'León'},
              administrator: true,
              onSave: (data) async => sent = data,
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('profile-universidad')), findsNothing);
    expect(find.byKey(const ValueKey('profile-edad')), findsNothing);
    await tester.ensureVisible(find.text('Guardar perfil'));
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    expect(sent, containsPair('ciudad', 'León'));
    expect(sent!.containsKey('universidad'), isFalse);
    expect(sent!.containsKey('edad'), isFalse);
    expect(sent!['trabaja'], isNull);
    expect(tester.takeException(), isNull);
  });
  for (final route in [
    RutasAplicacion.adminMarket,
    RutasAplicacion.adminTutorials,
    RutasAplicacion.adminReports,
    RutasAplicacion.adminAudit,
    RutasAplicacion.adminCatalogs,
    RutasAplicacion.adminProfile,
    RutasAplicacion.settings,
    RutasAplicacion.adminMessages,
    RutasAplicacion.adminOwnMarket,
    RutasAplicacion.adminOwnCourses,
    RutasAplicacion.adminApplications,
    RutasAplicacion.adminTutors,
    RutasAplicacion.adminExpiringTutors,
    RutasAplicacion.adminTutorHistory,
    RutasAplicacion.adminSessions,
    RutasAplicacion.adminParticipation,
    RutasAplicacion.adminReviews,
    RutasAplicacion.adminTrainingAreas,
    RutasAplicacion.adminMarketUpdates,
    RutasAplicacion.adminMarketCategories,
    RutasAplicacion.adminSupport,
    '${RutasAplicacion.user}?view=access',
  ]) {
    testWidgets('módulo administrativo adaptable sin desbordes $route', (
      tester,
    ) async {
      await open(tester, route, const Size(390, 844));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  for (final tutorial in [false, true]) {
    for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
      testWidgets('estudio de publicación $tutorial ${size.width}', (
        tester,
      ) async {
        service.categories = [
          {'id': 1, 'nombre': 'Libros y material'},
        ];
        service.areas = [
          {'id': 1, 'nombre': 'Desarrollo de software'},
        ];
        final key = await open(
          tester,
          RutasAplicacion.publication(tutorial: tutorial, admin: false),
          size,
        );
        expect(
          tutorial
              ? find.byTooltip('Vista previa')
              : find.text('Artículo en venta'),
          findsOneWidget,
        );
        expect(
          find.text(size.width < 850 ? 'Guardar' : 'Guardar borrador'),
          findsOneWidget,
        );
        if (tutorial) {
          expect(
            find.byKey(const ValueKey('publication-titulo')),
            findsOneWidget,
          );
          await preview(
            tester,
            key,
            'course-goals-${size.width > 1000 ? 'desktop' : 'mobile'}',
          );
        }
        await tester.enterText(
          find.byKey(const ValueKey('publication-titulo')),
          tutorial
              ? 'Desarrollo web desde cero'
              : 'Libro de programación en excelente estado',
        );
        await tester.enterText(
          find.byKey(const ValueKey('publication-descripcion')),
          tutorial
              ? 'Aprende a construir aplicaciones web paso a paso con ejercicios, videos y acompañamiento.'
              : 'Libro de programación con ejemplos prácticos. Todas las páginas están completas. Entrega en un punto acordado.',
        );
        await tester.pumpAndSettle();
        await preview(
          tester,
          key,
          '${tutorial ? 'course' : 'listing'}-editor-${size.width > 1000 ? 'desktop' : 'mobile'}',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(size.width < 850 ? 'Guardar' : 'Guardar borrador'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Completa el título, la categoría y la descripción para guardar.',
          ),
          findsOneWidget,
        );
        expect(
          adapter.requests.where(
            (r) =>
                r.method == 'POST' &&
                ['/me/listings', '/me/courses'].contains(r.path),
          ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('guardar borrador devuelve al contenido sin perder el curso', (
    tester,
  ) async {
    installPublicationFixture();
    await open(
      tester,
      RutasAplicacion.publication(tutorial: true, admin: false),
      const Size(1440, 1000),
    );
    await tester.tap(find.text('Contenido y alumnos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear borrador'));
    await tester.pumpAndSettle();
    expect(
      find.text('Guarda la presentación para continuar con el contenido'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('publication-titulo')),
      'Curso de Flutter',
    );
    await tester.enterText(
      find.byKey(const ValueKey('publication-descripcion')),
      'Primer párrafo\n\nSegundo párrafo',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('publication-select-Área de enseñanza')),
    );
    await tester.tap(
      find.byKey(const ValueKey('publication-select-Área de enseñanza')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Software').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    expect(find.text('Contenido y acompañamiento'), findsOneWidget);
    final request = adapter.requests.singleWhere(
      (r) => r.method == 'POST' && r.path == '/me/courses',
    );
    expect(
      request.data,
      containsPair('descripcion', 'Primer párrafo\n\nSegundo párrafo'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('editar conserva información entre secciones del curso', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    service.areas = [
      {'id': 1, 'nombre': 'Software'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.light,
        home: Scaffold(
          body: EditorPublicacion(
            isTutorial: true,
            initial: const {
              'id': '4',
              'areaId': 1,
              'titulo': 'Curso',
              'descripcion': 'Descripción',
              'objetivos': ['Aprender Dart', 'Construir interfaces'],
              'requisitos': ['Una computadora'],
              'idioma': 'Español',
              'duracionEstimadaMinutos': 120,
              'versionLock': 3,
            },
          ),
        ),
      ),
    );
    expect(find.text('120 min'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('publication-duracionEstimadaMinutos')),
      findsNothing,
    );
    await tester.tap(find.text('Estudiantes previstos'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('publication-objetivos')),
          )
          .controller!
          .text,
      'Aprender Dart\nConstruir interfaces',
    );
    expect(tester.takeException(), isNull);
  });
  for (final tutorial in [false, true]) {
    testWidgets('publicar requiere confirmación explícita $tutorial', (
      tester,
    ) async {
      service.categories = [
        {'id': 1, 'nombre': 'Libros', 'camposDetalle': <Json>[]},
      ];
      service.areas = [
        {'id': 1, 'nombre': 'Software'},
      ];
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaAplicacion.light,
          home: Scaffold(
            body: EditorPublicacion(
              isTutorial: tutorial,
              startWithReview: true,
              initial: {
                'id': '7',
                'titulo': 'Publicación',
                'descripcion': 'Descripción',
                'areaId': 1,
                'categoriaId': 1,
                'precioBase': '100.00',
                'estado': 'borrador',
                'preparacion': {
                  'acreditacionVigente': true,
                  'leccionesPublicadas': 1,
                },
                'imagenes': [
                  {'archivoId': '21', 'orden': 1},
                ],
              },
            ),
          ),
        ),
      );
      final button = find.ancestor(
        of: find.text('Confirmar y publicar'),
        matching: find.byType(BotonAccionApi),
      );
      expect(tester.widget<BotonAccionApi>(button).enabled, isFalse);
      await tester.ensureVisible(
        find.byKey(const ValueKey('publication-confirm')),
      );
      await tester.tap(find.byKey(const ValueKey('publication-confirm')));
      await tester.pumpAndSettle();
      expect(tester.widget<BotonAccionApi>(button).enabled, isTrue);
      expect(
        adapter.requests.where(
          (r) => r.path.endsWith('/publish') || r.path.endsWith('/state'),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final route in [
    RutasAplicacion.login,
    RutasAplicacion.register,
    RutasAplicacion.adminLogin,
  ]) {
    testWidgets('acceso permite regresar al inicio $route', (tester) async {
      await open(tester, route, const Size(390, 844));
      expect(find.text('Volver al inicio'), findsOneWidget);
      await tester.tap(find.text('Volver al inicio'));
      await tester.pumpAndSettle();
      expect(find.text('Volver al inicio'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
