import 'package:dio/dio.dart';

import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';

/// Lectura y actualización del perfil de la sesión actual.
class ProfileRepository {
  const ProfileRepository(this._client);

  final ApiClient _client;

  /// Obtiene el perfil autenticado mediante `GET users/me`.
  Future<UserProfile> getMe() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('users/me');
    return UserProfile.fromJson(_client.unwrap(response.data));
  });

  /// Actualiza campos permitidos mediante `PATCH users/me`.
  Future<UserProfile> updateMe(Map<String, dynamic> data) => _guard(() async {
    final response = await _client.patch<Map<String, dynamic>>(
      'users/me',
      data: data,
    );
    return UserProfile.fromJson(_client.unwrap(response.data));
  });

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
