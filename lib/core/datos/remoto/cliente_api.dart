// Archivo: lib/core/datos/remoto/cliente_api.dart
// Implementa HTTP con Dio, adjunta JWT, renueva sesiones, agrupa el progreso y traduce errores de red.

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:unired/core/dominio/datos_api.dart';
import 'package:unired/core/dominio/contratos/monitor_progreso.dart';
import 'package:unired/core/dominio/contratos/repositorio_api.dart';
import 'package:unired/core/dominio/evento_servidor.dart';
import 'package:unired/core/datos/remoto/transporte_eventos.dart';

/// Único lugar que conoce HTTP, JWT, renovación y errores del servidor.
/// Los tokens permanecen en memoria: nunca en URLs, logs ni archivos públicos.
class ClienteApi implements RepositorioApi {
  ClienteApi({
    Dio? dio,
    String? baseUrl,
    this.progreso,
    this.retryDelay = const Duration(milliseconds: 800),
    this.enableLiveEvents = true,
    this.eventTransport = abrirEventos,
  }) : dio = dio ?? Dio() {
    final url =
        baseUrl ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://127.0.0.1:3000/api/v1',
        );
    final uri = Uri.parse(url);
    if (!uri.hasAuthority || !['http', 'https'].contains(uri.scheme)) {
      throw ArgumentError('API_BASE_URL debe ser una URL HTTP/HTTPS completa.');
    }
    this.dio.options = BaseOptions(
      baseUrl: url.replaceFirst(RegExp(r'/$'), ''),
      // En Web Dio espera aquí hasta que llegan cabeceras, incluso durante
      // el preflight. Debe cubrir también el despertar del servicio gratuito.
      connectTimeout: const Duration(seconds: 75),
      // Render Free puede tardar cerca de un minuto en despertar.
      receiveTimeout: const Duration(seconds: 75),
    );
  }
  final Dio dio;
  final MonitorProgreso? progreso;
  final Duration retryDelay;
  final bool enableLiveEvents;
  final Stream<String> Function(Uri, Map<String, String>) eventTransport;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  Future<void>? _renewing;
  int _generation = 0;
  int _pending = 0;
  int _groups = 0;
  int? _progress;
  void Function()? onSessionExpired;
  bool get hasSession => _accessToken != null;
  Uri resolve(String path) => Uri.parse(dio.options.baseUrl).resolve(path);

  Stream<EventoServidor> events({String afterId = '0'}) async* {
    final generation = _generation;
    if (!enableLiveEvents || !hasSession) return;
    if (_expiresAt != null &&
        DateTime.now().isAfter(
          _expiresAt!.subtract(const Duration(seconds: 30)),
        )) {
      await _renew();
    }
    final url = Uri.parse(
      '${dio.options.baseUrl}/me/events',
    ).replace(queryParameters: {'afterId': afterId});
    await for (final event in interpretarEventos(
      eventTransport(url, {
        'Authorization': 'Bearer $_accessToken',
        'Accept': 'text/event-stream',
      }),
    )) {
      if (generation != _generation) return;
      if (event.type == 'session-ended') {
        await _renew();
        return;
      }
      yield event;
    }
  }

  /// Una acción puede necesitar varias consultas sucesivas. La barra termina
  /// al finalizar el conjunto, sin reiniciarse entre cada respuesta HTTP.
  Future<T> withProgress<T>(Future<T> Function() work) async {
    _groups++;
    try {
      return await work();
    } finally {
      _groups--;
      _finishProgress();
    }
  }

  void _finishProgress() {
    if (_pending == 0 && _groups == 0 && _progress != null) {
      progreso?.complete(_progress!);
      _progress = null;
    }
  }

  void acceptTokens(Json data) {
    _accessToken = textValue(data['accessToken']);
    _refreshToken = textValue(data['refreshToken']);
    _expiresAt = DateTime.now().add(
      Duration(seconds: intValue(data['expiresIn'])),
    );
  }

  void clearSession() {
    _generation++;
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
  }

  Future<void> _renew() {
    if (_renewing != null) return _renewing!;
    final generation = _generation;
    final refresh = _refreshToken;
    if (refresh == null) throw const ErrorApi('Inicia sesión nuevamente.', 401);
    _renewing = (() async {
      try {
        final result = await dio.post<Object?>(
          '/auth/refresh',
          data: {'refreshToken': refresh},
        );
        if (generation == _generation) acceptTokens(jsonObject(result.data));
      } on DioException catch (error) {
        if ([400, 401, 403].contains(error.response?.statusCode) &&
            generation == _generation) {
          clearSession();
          onSessionExpired?.call();
        }
        throw ErrorApi.fromDio(error);
      }
    })().whenComplete(() => _renewing = null);
    return _renewing!;
  }

  Future<Object?> request(
    String path, {
    String method = 'GET',
    Object? data,
    Json? query,
    bool authenticated = true,
    bool foreground = true,
    bool bytes = false,
    void Function(int, int)? onSendProgress,
  }) async {
    final generation = _generation;
    void checkSession() {
      if (authenticated && generation != _generation) {
        throw const ErrorApi(
          'La sesión cambió. Vuelve a realizar la acción.',
          401,
        );
      }
    }

    if (foreground && _pending++ == 0) {
      scheduleMicrotask(() {
        if (_pending > 0 && _progress == null) {
          _progress = progreso?.begin();
        }
      });
    }
    try {
      if (authenticated &&
          hasSession &&
          _expiresAt != null &&
          DateTime.now().isAfter(
            _expiresAt!.subtract(const Duration(seconds: 30)),
          )) {
        await _renew();
      }
      Future<Response<Object?>> send() {
        checkSession();
        return dio.request<Object?>(
          path,
          data: data,
          queryParameters: query,
          options: Options(
            method: method,
            responseType: bytes ? ResponseType.bytes : ResponseType.json,
            receiveTimeout: data is FormData
                ? const Duration(minutes: 3)
                : null,
            headers: {
              if (authenticated && _accessToken != null)
                'Authorization': 'Bearer $_accessToken',
            },
          ),
          onSendProgress: onSendProgress,
        );
      }

      Future<Response<Object?>> sendReadWithRecovery() async {
        for (var attempt = 0; ; attempt++) {
          try {
            final response = await send();
            // El proxy de alojamiento puede responder HTML mientras arranca.
            // No interpretamos esa página como un catálogo JSON vacío.
            if (!bytes &&
                response.data is String &&
                response.headers
                        .value(Headers.contentTypeHeader)
                        ?.contains('text/html') ==
                    true) {
              throw DioException(
                requestOptions: response.requestOptions,
                type: DioExceptionType.connectionError,
                error: 'SERVICE_STARTING',
              );
            }
            return response;
          } on DioException catch (error) {
            checkSession();
            final temporary =
                [
                  DioExceptionType.connectionTimeout,
                  DioExceptionType.receiveTimeout,
                  DioExceptionType.connectionError,
                ].contains(error.type) ||
                [408, 502, 503, 504].contains(error.response?.statusCode);
            if (method.toUpperCase() != 'GET' ||
                data != null ||
                !temporary ||
                attempt >= 1) {
              rethrow;
            }
            // Solo consultas: nunca se repiten publicaciones, mensajes o pagos.
            await Future<void>.delayed(retryDelay);
          }
        }
      }

      final sentToken = _accessToken;
      try {
        final response = await sendReadWithRecovery();
        checkSession();
        return response.data;
      } on DioException catch (error) {
        checkSession();
        if (authenticated &&
            error.response?.statusCode == 401 &&
            _refreshToken != null &&
            data is! FormData) {
          if (sentToken == _accessToken) await _renew();
          try {
            final response = await sendReadWithRecovery();
            checkSession();
            return response.data;
          } on DioException catch (retry) {
            throw ErrorApi.fromDio(retry);
          }
        }
        throw ErrorApi.fromDio(error);
      }
    } finally {
      if (foreground) {
        _pending--;
        _finishProgress();
      }
    }
  }

  @override
  Future<Json> object(
    String path, {
    String method = 'GET',
    Object? data,
    Json? query,
    bool authenticated = true,
    bool foreground = true,
  }) async => jsonObject(
    await request(
      path,
      method: method,
      data: data,
      query: query,
      authenticated: authenticated,
      foreground: foreground,
    ),
  );
  Future<PaginaApi> page(
    String path, {
    int page = 1,
    Json? query,
    bool authenticated = true,
    bool foreground = true,
  }) async {
    final result = await request(
      path,
      query: {'page': page, 'limit': 50, ...?query},
      authenticated: authenticated,
      foreground: foreground,
    );
    if (result is List) {
      final rows = jsonRows(result);
      return PaginaApi(rows, rows.length, 1, rows.isEmpty ? 50 : rows.length);
    }
    return PaginaApi.fromJson(result);
  }
}

class ErrorApi implements Exception {
  const ErrorApi(this.message, [this.status = 0, this.code = '']);
  factory ErrorApi.fromDio(DioException error) {
    final data = jsonObject(error.response?.data);
    final code = textValue(data['code']);
    final friendly = switch (code) {
      'SCANNER_UNAVAILABLE' =>
        'No pudimos verificar el documento en este momento. Sigue privado; puedes reintentar su preparación desde Mis archivos.',
      'VIDEO_PROCESSING_UNAVAILABLE' =>
        'El servicio de preparación de vídeos no está disponible en este momento. Tu archivo se mantiene privado.',
      'PROCESSING_BUSY' =>
        'Estamos preparando otros archivos. Inténtalo de nuevo en unos segundos.',
      'PROCESSING_FAILED' =>
        'No pudimos terminar de preparar el archivo. Puedes reintentarlo desde Mis archivos.',
      _ => null,
    };
    return ErrorApi(
      friendly ??
          textValue(
            data['message'],
            error.response == null
                ? switch (error.type) {
                    DioExceptionType.receiveTimeout ||
                    DioExceptionType.connectionTimeout =>
                      'El servidor está tardando en responder. Puedes reintentar sin recargar la página.',
                    _ =>
                      'No se pudo conectar con la API. Comprueba tu conexión y vuelve a intentarlo.',
                  }
                : 'La solicitud no se pudo completar.',
          ),
      error.response?.statusCode ?? 0,
      code,
    );
  }
  final String message;
  final int status;
  final String code;
  @override
  String toString() => message;
}
