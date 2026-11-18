import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unired/core/datos/remoto/cliente_api.dart';
import 'package:unired/models/aplicacion/controllers/aplicacion_controller.dart';
import 'package:unired/models/tutorias/widgets/lector_leccion.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'support/test_adapter.dart';

class _VideoPrueba extends VideoPlayerPlatform {
  bool playing = false;
  double volume = 1;
  Duration position = Duration.zero;
  int opened = 0;

  @override
  Future<void> init() async {}
  @override
  Future<int?> create(DataSource dataSource) async => ++opened;
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Widget buildView(int playerId) => const ColoredBox(color: Colors.black);
  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<void> seekTo(int playerId, Duration next) async => position = next;
  @override
  Future<void> setVolume(int playerId, double next) async => volume = next;
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setLooping(int playerId, bool enabled) async {}
  @override
  Future<void> play(int playerId) async => playing = true;
  @override
  Future<void> pause(int playerId) async => playing = false;
  @override
  Stream<VideoEvent> videoEventsFor(int id) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(minutes: 2),
      size: const Size(640, 360),
    ),
  );
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'a $width el video conserva volumen y posición al cambiar de tamaño',
      (t) async {
        final previous = VideoPlayerPlatform.instance;
        final video = _VideoPrueba();
        VideoPlayerPlatform.instance = video;
        addTearDown(() => VideoPlayerPlatform.instance = previous);
        final adapter = TestAdapter(
          (_) async => TestReply({
            'titulo': 'Video de práctica',
            'tipo': 'video',
            'videoArchivoId': 17,
          }),
        );
        final store = AplicacionController(
          client: ClienteApi(
            enableLiveEvents: false,
            dio: Dio()..httpClientAdapter = adapter,
          ),
        );
        AplicacionController.replaceInstanceForTesting(store);
        addTearDown(store.dispose);
        t.view.physicalSize = Size(width, 780);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LectorLeccion(courseId: '42', lessonId: '9'),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final surface = find.byKey(const ValueKey('superficie-video-leccion'));
        const doubleTapInterval = Duration(milliseconds: 70);
        const waitSingleTap = Duration(milliseconds: 320);

        await t.tap(surface);
        await t.pump(waitSingleTap);
        expect(video.playing, isTrue);
        await t.tap(surface);
        await t.pump(waitSingleTap);
        expect(video.playing, isFalse);

        await t.tap(find.byTooltip('Avanzar 10 segundos'));
        await t.pumpAndSettle();
        expect(video.position, const Duration(seconds: 10));
        await t.tapAt(t.getCenter(find.byType(Slider)) - const Offset(16, 0));
        await t.pumpAndSettle();
        final volume = video.volume;
        expect(volume, inExclusiveRange(0, 1));
        await t.tap(surface);
        await t.pump(doubleTapInterval);
        await t.tap(surface);
        await t.pumpAndSettle();
        expect(find.byTooltip('Salir de pantalla completa'), findsOneWidget);
        expect(video.playing, isFalse); // El doble toque no reproduce el video.
        expect(find.text('0:10 / 2:00'), findsOneWidget);
        await t.tap(find.byTooltip('Silenciar'));
        await t.pumpAndSettle();
        expect(video.volume, 0);
        await t.tap(find.byTooltip('Activar sonido'));
        await t.pumpAndSettle();
        expect(video.volume, volume);
        await t.tap(find.byTooltip('Salir de pantalla completa'));
        await t.pumpAndSettle();
        expect(find.byTooltip('Pantalla completa'), findsOneWidget);
        expect(find.text('0:10 / 2:00'), findsOneWidget);
        await t.tap(find.byTooltip('Pantalla completa'));
        await t.pumpAndSettle();
        await t.tap(surface);
        await t.pump(doubleTapInterval);
        await t.tap(surface);
        await t.pumpAndSettle();
        expect(find.byTooltip('Pantalla completa'), findsOneWidget);
        expect(video.opened, 1);
        expect(t.takeException(), isNull);
      },
    );
  }
}
