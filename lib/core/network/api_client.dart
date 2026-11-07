import 'package:dio/dio.dart';

import 'package:rodantex_app/core/config/api_config.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';
import 'package:rodantex_app/core/auth/data/auth_api.dart';

/// Cliente HTTP único de la app.
///
/// - Añade `Authorization: Bearer <accessToken>` a cada request si hay sesión.
/// - Al recibir un 401 renueva el token automáticamente y reintenta la request.
/// - Serializa los refresh concurrentes: varias peticiones que fallan a la vez
///   comparten una única llamada a `auth/refresh`.
/// - Si el refresh falla, limpia la sesión y avisa mediante [onSessionExpired].
class ApiClient {
  ApiClient({
    required this._storage,
    required this._dio,
    required this._authApi,
  });

  /// Crea el cliente con la configuración por defecto.
  factory ApiClient.create({required TokenStorage storage}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.resolvedBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.json,
      ),
    );
    final authApi = AuthApi(dio);
    final client = ApiClient(storage: storage, dio: dio, authApi: authApi);
    dio.interceptors.add(client._authInterceptor);
    return client;
  }

  static const _retriedFlag = 'rodantex_retried';

  final Dio _dio;
  final AuthApi _authApi;
  final TokenStorage _storage;

  /// Se invoca cuando la sesión deja de ser válida y no se pudo renovar.
  void Function()? onSessionExpired;

  Dio get dio => _dio;

  AuthApi get authApi => _authApi;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _dio.delete<T>(path, data: data);

  /// Refresh en curso; varias requests que fallan a la vez lo comparten.
  Future<AuthTokens>? _refreshing;

  Interceptor get _authInterceptor => InterceptorsWrapper(
    onRequest: (options, handler) {
      final isPublic = options.extra[_isPublicKey] == true;
      final token = _storage.accessToken;
      if (!isPublic && token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      final request = error.requestOptions;
      final shouldRetry =
          error.response?.statusCode == 401 &&
          request.extra[_isPublicKey] != true &&
          request.extra[_retriedFlag] != true &&
          _storage.refreshToken != null;

      if (!shouldRetry) {
        handler.next(error);
        return;
      }

      try {
        final tokens = await _refreshTokens();
        request.extra[_retriedFlag] = true;
        request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        final response = await _dio.fetch<dynamic>(request);
        handler.resolve(response);
      } on Object catch (refreshError) {
        await _storage.clear();
        onSessionExpired?.call();
        handler.next(
          DioException(
            requestOptions: request,
            response: error.response,
            type: DioExceptionType.badResponse,
            error: refreshError,
          ),
        );
      }
    },
  );

  Future<AuthTokens> _refreshTokens() {
    // Si ya hay un refresh en curso, todas las requests esperan el mismo.
    final pending = _refreshing;
    if (pending != null) return pending;

    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return Future.error(const SessionExpiredException());
    }

    final future = _authApi
        .refresh(refreshToken)
        .then((tokens) async {
          if (!tokens.isValid) throw const SessionExpiredException();
          await _storage.saveTokens(tokens);
          return tokens;
        })
        .whenComplete(() => _refreshing = null);

    _refreshing = future;
    return future;
  }

  /// Marca una request como pública (login/refresh) para no enviar el token.
  static Options publicOptions() => Options(extra: {_isPublicKey: true});

  static const _isPublicKey = 'rodantex_public';
}
