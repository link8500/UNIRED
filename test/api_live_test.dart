import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:unired/core/constants/publication_status.dart';
import 'package:unired/core/network/api_client.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/services/app_service.dart';

/// Solo se ejecuta mediante el contenedor temporal del harness; nunca lee .env.
void main() {
  final fixturePath = Platform.environment['UNIRED_TEST_FIXTURE'];
  test(
    'Flutter realiza los recorridos reales de UniRed sobre PostgreSQL aislado',
    () async {
      final fixture = jsonObject(
        jsonDecode(await File(fixturePath!).readAsString()),
      );
      final base = textValue(fixture['baseUrl']);
      final stores = <AppService>[];
      AppService create() {
        final service = AppService(client: ApiClient(baseUrl: base));
        stores.add(service);
        return service;
      }

      Future<String> mailToken(String email) async {
        for (var i = 0; i < 160; i++) {
          final folder = Directory(textValue(fixture['mailsRoot']));
          if (await folder.exists()) {
            for (final item in await folder.list().toList()) {
              if (item is! File) continue;
              final mail = jsonObject(jsonDecode(await item.readAsString()));
              final content = textValue(mail['text']);
              if (mail['to'] == email &&
                  content.contains('verificar_email: ')) {
                return content.split('verificar_email: ')[1].split('\n')[0];
              }
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
        throw StateError('No llegó la verificación de prueba.');
      }

      Future<AppService> account(
        String name,
        String email,
        String password,
      ) async {
        final service = create();
        await service.register(name: name, email: email, password: password);
        await service.api.object(
          '/auth/verify-email',
          method: 'POST',
          authenticated: false,
          data: {'token': await mailToken(email)},
        );
        await service.signIn(email: email, password: password);
        return service;
      }

      Future<Json> upload(
        AppService service,
        String purpose,
        String path,
      ) async => jsonObject(
        await service.api.request(
          '/files',
          method: 'POST',
          data: FormData.fromMap({
            'proposito': purpose,
            'file': MultipartFile.fromBytes(
              await File(path).readAsBytes(),
              filename: path.split(Platform.pathSeparator).last,
            ),
          }),
        ),
      );
      try {
        final admin = create();
        await admin.initialize();
        expect(admin.initialized, isTrue);
        expect(admin.publishedProducts, isEmpty);
        await admin.signInAdmin(
          username: textValue(fixture['adminEmail']),
          password: textValue(fixture['adminPassword']),
        );
        expect(admin.isAdministrator, isTrue);
        final tutor = await account(
          'Tutor Flutter',
          'flutter-tutor@example.test',
          'Prueba-flutter-tutor-2026!',
        );
        final student = await account(
          'Alumno Flutter',
          'flutter-alumno@example.test',
          'Prueba-flutter-alumno-2026!',
        );
        await tutor.initialize();
        await student.initialize();
        expect(tutor.currentUser!.verified, isTrue);
        expect(tutor.isAdmin, isFalse);
        await tutor.saveProfileData({
          'nombre': 'Tutor Flutter',
          'universidad': 'UNAN-Managua',
          'ciudad': 'Managua',
          'areaProfesional': 'Programación',
          'presentacion': 'Tutor de pruebas',
        });
        expect(tutor.currentUser!.university, 'UNAN-Managua');
        expect(tutor.currentUser!.city, 'Managua');
        final category = intValue(tutor.categories.first['id']);
        final area = intValue(tutor.areas.first['id']);
        final listing = await tutor.savePublication(false, {
          'categoriaId': category,
          'titulo': 'Material de Flutter',
          'descripcion': 'Artículo real de la base temporal',
          'tipoPrecio': 'fijo',
          'precioBase': '100.00',
          'moneda': 'NIO',
        });
        expect(listing['estado'], 'borrador');
        final image = await upload(
          tutor,
          'imagen_anuncio',
          textValue(fixture['imagePath']),
        );
        expect(image['estado'], 'listo');
        expect(image['escaneo'], 'limpio');
        await tutor.api.object(
          '/me/listings/${textValue(listing['id'])}/images',
          method: 'POST',
          data: {'archivoId': image['id'], 'orden': 1},
        );
        await tutor.setProductStatus(
          tutor.productFromJson(listing),
          PublicationStatus.published,
        );
        await student.initialize(force: true);
        final product = student.publishedProducts.first;
        expect(product.title, 'Material de Flutter');
        expect(product.imageId, isNotNull);
        await student.toggleFavorite(product);
        expect(student.isFavorite(product), isTrue);
        expect((await student.imageBytes(product.imageId!)).length > 8, isTrue);
        final conversation = await student.api.object(
          '/listings/${product.id}/conversations',
          method: 'POST',
        );
        final messageData = {
          'clienteId': const Uuid().v4(),
          'contenido': 'Hola, ¿está disponible?',
        };
        final first = await student.api.object(
          '/conversations/${textValue(conversation['id'])}/messages',
          method: 'POST',
          data: messageData,
        );
        final retry = await student.api.object(
          '/conversations/${textValue(conversation['id'])}/messages',
          method: 'POST',
          data: messageData,
        );
        expect(first['id'] == retry['id'], isTrue);
        final history = await tutor.api.page(
          '/conversations/${textValue(conversation['id'])}/messages',
        );
        expect(history.items.first['contenido'], 'Hola, ¿está disponible?');
        final application = await tutor.api.object(
          '/me/tutor-applications',
          method: 'POST',
          data: {'areaId': area},
        );
        final evidence = await upload(
          tutor,
          'evidencia_tutor',
          textValue(fixture['imagePath']),
        );
        final appPath =
            '/me/tutor-applications/${textValue(application['id'])}';
        await tutor.api.object(
          '$appPath/documents',
          method: 'POST',
          data: {
            'archivoId': evidence['id'],
            'tipo': 'certificado',
            'versionLock': application['versionLock'],
          },
        );
        var details = await tutor.api.object(appPath);
        await tutor.api.object(
          '$appPath/submit',
          method: 'POST',
          data: {'versionLock': details['versionLock']},
        );
        details = await tutor.api.object(appPath);
        final reviewPath =
            '/admin/tutor-applications/${textValue(application['id'])}';
        await admin.api.object(
          '$reviewPath/claim',
          method: 'POST',
          data: {'versionLock': details['versionLock']},
        );
        details = await admin.api.object(reviewPath);
        await admin.api.object(
          '$reviewPath/decision',
          method: 'POST',
          data: {
            'versionLock': details['versionLock'],
            'envioId': jsonRows(details['envios']).first['id'],
            'decision': 'aprobada',
            'motivo': 'Evidencia verificada en la prueba aislada',
          },
        );
        await tutor.refreshAccountData();
        expect(
          tutor.tutorGrants.any((grant) => grant['estado'] == 'vigente'),
          isTrue,
        );
        expect(tutor.isAdmin, isFalse);
        final course = await tutor.savePublication(true, {
          'areaId': area,
          'titulo': 'Curso Flutter',
          'descripcion': 'Curso grabado con video verificado',
          'modalidad': 'grabada',
          'nivel': 'inicial',
          'precioBase': '0.00',
          'moneda': 'NIO',
        });
        final courseId = textValue(course['id']);
        final section = await tutor.api.object(
          '/me/courses/$courseId/sections',
          method: 'POST',
          data: {'titulo': 'Introducción', 'orden': 1},
        );
        final video = await upload(
          tutor,
          'video_leccion',
          textValue(fixture['videoPath']),
        );
        expect(video['estado'], 'listo');
        final lesson = await tutor.api.object(
          '/me/courses/$courseId/lessons',
          method: 'POST',
          data: {
            'seccionId': section['id'],
            'titulo': 'Primera lección',
            'tipo': 'video',
            'videoArchivoId': video['id'],
            'orden': 1,
            'publicada': true,
            'vistaPrevia': false,
          },
        );
        await tutor.setTutorialStatus(
          tutor.tutorialFromJson(course),
          PublicationStatus.published,
        );
        await student.initialize(force: true);
        final enrollment = await student.startTutorial(
          student.publishedTutorials.first,
        );
        expect(enrollment['estado'], 'solicitada');
        await tutor.api.object(
          '/me/courses/$courseId/enrollments/${textValue(enrollment['id'])}',
          method: 'PATCH',
          data: {
            'estado': 'activa',
            'motivo': 'Solicitud aceptada por el tutor de prueba',
          },
        );
        await student.refreshEnrollments();
        final content = await student.api.object(
          '/courses/$courseId/lessons/${textValue(lesson['id'])}',
        );
        expect(content['videoArchivoId'] == video['id'], isTrue);
        final ticket = await student.fileAccess(textValue(video['id']));
        final range = await student.api.dio.get<List<int>>(
          ticket.toString(),
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Range': 'bytes=0-31'},
          ),
        );
        expect(range.statusCode, 206);
        expect(range.data!.length, 32);
        await student.api.object(
          '/me/enrollments/${textValue(enrollment['id'])}/progress/${textValue(lesson['id'])}',
          method: 'PUT',
          data: {
            'posicionSegundos': numberValue(video['duracionSegundos']).floor(),
            'completada': true,
          },
        );
        final progress = await student.api.object(
          '/me/enrollments/${textValue(enrollment['id'])}',
        );
        expect(intValue(progress['porcentaje']), 100);
        final live = await tutor.savePublication(true, {
          'areaId': area,
          'titulo': 'Clase en vivo Flutter',
          'descripcion': 'Sesión con cupos y reserva',
          'modalidad': 'en_vivo',
          'precioBase': '0.00',
          'moneda': 'NIO',
        });
        final liveId = textValue(live['id']);
        final start = DateTime.now().toUtc().add(const Duration(days: 2));
        final session = await tutor.api.object(
          '/me/courses/$liveId/sessions',
          method: 'POST',
          data: {
            'titulo': 'Encuentro en vivo',
            'inicioEn': start.toIso8601String(),
            'finEn': start.add(const Duration(hours: 1)).toIso8601String(),
            'capacidad': 2,
            'enlaceReunion': 'https://example.com/reunion-de-prueba',
          },
        );
        await tutor.setTutorialStatus(
          tutor.tutorialFromJson(live),
          PublicationStatus.published,
        );
        final liveDetails = await student.api.object('/courses/$liveId');
        final liveEnrollment = await student.startTutorial(
          student.tutorialFromJson(liveDetails),
        );
        await tutor.api.object(
          '/me/courses/$liveId/enrollments/${textValue(liveEnrollment['id'])}',
          method: 'PATCH',
          data: {
            'estado': 'activa',
            'motivo': 'Solicitud de clase en vivo aceptada',
          },
        );
        final booking = await student.api.object(
          '/courses/$liveId/sessions/${textValue(session['id'])}/reservations',
          method: 'POST',
        );
        final agenda = await student.api.page('/courses/$liveId/sessions');
        expect(
          textValue(agenda.items.first['reservaSesionId']).isNotEmpty,
          isTrue,
        );
        expect(
          agenda.items.first['reservaSesionId'] == booking['sesionId'],
          isTrue,
        );
        await student.api.object(
          '/me/reservations/${textValue(agenda.items.first['reservaSesionId'])}',
          method: 'DELETE',
        );
        final cancelled = await student.api.page('/courses/$liveId/sessions');
        expect(cancelled.items.first.containsKey('reservaSesionId'), isFalse);
        final latest = await tutor.publicationDetails(
          false,
          product.id,
          own: true,
        );
        await tutor.savePublication(false, {
          'versionLock': latest['versionLock'],
          'descuentoPorcentaje': '10.00',
        }, id: product.id);
        final offered = await student.publicationDetails(false, product.id);
        expect(student.productFromJson(offered).effectiveAmount, 90);
        final sessions = await student.api.page('/me/sessions');
        expect(sessions.total > 0, isTrue);
        await admin.loadDashboard();
        expect(intValue(admin.dashboard['usuarios']) >= 3, isTrue);
        expect(jsonRows(admin.analytics['actividad']).length, 30);
        await student.api.object(
          '/me',
          method: 'PATCH',
          data: {'notificacionesActivas': false},
        );
        await student.refreshMe();
        expect(student.notificationsEnabled, isFalse);
        await student.logout();
        expect(student.currentUser, isNull);
        expect(student.favoriteProducts, isEmpty);
      } finally {
        for (final service in stores) {
          service.dispose();
        }
      }
    },
    skip: fixturePath == null
        ? 'Usa node tool/test_api_integration.cjs para la base aislada.'
        : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
