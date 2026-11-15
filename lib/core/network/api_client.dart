import 'dart:async';
import 'package:dio/dio.dart';
import 'package:unired/core/network/api_data.dart';
import 'package:unired/core/utils/navigation_progress_controller.dart';

/// Único lugar que conoce HTTP, JWT, renovación y errores del servidor.
/// Los tokens permanecen en memoria: nunca en URLs, logs ni archivos públicos.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl}) : dio = dio ?? Dio() {
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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    );
  }
  final Dio dio;
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
      NavigationProgressController.instance.complete(_progress!);
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
    if (refresh == null) throw const ApiError('Inicia sesión nuevamente.', 401);
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
        throw ApiError.fromDio(error);
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
        throw const ApiError(
          'La sesión cambió. Vuelve a realizar la acción.',
          401,
        );
      }
    }

    if (foreground && _pending++ == 0) {
      scheduleMicrotask(() {
        if (_pending > 0 && _progress == null) {
          _progress = NavigationProgressController.instance.begin();
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

      final sentToken = _accessToken;
      try {
        final response = await send();
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
            final response = await send();
            checkSession();
            return response.data;
          } on DioException catch (retry) {
            throw ApiError.fromDio(retry);
          }
        }
        throw ApiError.fromDio(error);
      }
    } finally {
      if (foreground) {
        _pending--;
        _finishProgress();
      }
    }
  }

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
  Future<ApiPage> page(
    String path, {
    int page = 1,
    Json? query,
    bool foreground = true,
  }) async {
    final result = await request(
      path,
      query: {'page': page, 'limit': 50, ...?query},
      foreground: foreground,
    );
    if (result is List) {
      final rows = jsonRows(result);
      return ApiPage(rows, rows.length, 1, rows.isEmpty ? 50 : rows.length);
    }
    return ApiPage.fromJson(result);
  }
}

class ApiError implements Exception {
  const ApiError(this.message, [this.status = 0, this.code = '']);
  factory ApiError.fromDio(DioException error) {
    final data = jsonObject(error.response?.data);
    return ApiError(
      textValue(
        data['message'],
        error.response == null
            ? 'No se pudo conectar con la API. Comprueba el servidor y tu conexión.'
            : 'La solicitud no se pudo completar.',
      ),
      error.response?.statusCode ?? 0,
      textValue(data['code']),
    );
  }
  final String message;
  final int status;
  final String code;
  @override
  String toString() => message;
}
