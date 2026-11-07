import 'package:dio/dio.dart';

import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';

export 'package:rodantex_app/core/network/api_exception.dart';

/// Endpoints de autenticación de la API.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  /// `POST auth/login` — devuelve usuario + tokens.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/login',
      data: {'email': email, 'contrasena': password},
      options: ApiClient.publicOptions(),
    );
    final data = response.data ?? const <String, dynamic>{};
    return AuthSession(
      user: UserProfile.fromJson(data),
      tokens: AuthTokens.fromJson(data),
    );
  }

  /// `POST auth/refresh` — renueva el par de tokens.
  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/refresh',
      data: {'refreshToken': refreshToken},
      options: ApiClient.publicOptions(),
    );
    return AuthTokens.fromJson(response.data ?? const <String, dynamic>{});
  }

  /// `POST auth/logout` — el access token viaja en `Authorization: Bearer`.
  Future<void> logout() async {
    try {
      await _dio.post<void>('auth/logout');
    } on DioException {
      // El logout local nunca debe verse bloqueado por el servidor.
    }
  }
}

/// Se mantiene por compatibilidad: los errores de auth son [ApiException].
typedef AuthException = ApiException;
