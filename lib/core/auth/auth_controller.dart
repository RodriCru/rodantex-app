import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:rodantex_app/core/auth/data/auth_api.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';
import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Fuente única de verdad de la sesión.
///
/// Expone el usuario y su rol, que la UI usa para decidir qué pantallas y
/// opciones mostrar.
class AuthController extends ChangeNotifier {
  AuthController({required this._client, required this._storage}) {
    _client.onSessionExpired = _handleSessionExpired;
  }
  final ApiClient _client;
  final TokenStorage _storage;

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _user;

  AuthStatus get status => _status;

  UserProfile? get user => _user;

  UserRole get role => _user?.role ?? UserRole.unknown;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Recupera la sesión guardada al arrancar la app.
  ///
  /// Acepta cualquier [TokenStorage]: el seguro lee del Keychain/Keystore y
  /// otras implementaciones (tests, memoria) ya tienen la sesión cargada.
  Future<void> restore() async {
    final storage = _storage;
    if (storage is SecureTokenStorage) {
      await storage.restore();
    }
    if (storage.accessToken?.isNotEmpty == true &&
        storage.refreshToken?.isNotEmpty == true &&
        storage.user != null) {
      _user = storage.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Inicia sesión. Lanza [ApiException] con un mensaje listo para la UI.
  Future<void> login({required String email, required String password}) async {
    try {
      final session = await _client.authApi.login(
        email: email.trim(),
        password: password,
      );
      if (!session.tokens.isValid) {
        throw const ApiException('La respuesta del servidor no es válida.');
      }
      await _storage.saveSession(session);
      _user = session.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Cierra la sesión en el servidor (si es posible) y localmente.
  Future<void> logout() async {
    await _client.authApi.logout();
    await _clearSession();
  }

  /// Actualiza el perfil actual y lo persiste cuando se usa almacenamiento seguro.
  Future<void> updateProfile(UserProfile profile) async {
    final current = _user;
    final updated = profile.copyWith(
      tenant: profile.tenant.isEmpty ? current?.tenant : profile.tenant,
    );
    if (_storage is SecureTokenStorage) {
      await _storage.saveUser(updated);
    }
    _user = updated;
    notifyListeners();
  }

  Future<void> _handleSessionExpired() async {
    if (_status == AuthStatus.unauthenticated) return;
    await _clearSession();
  }

  Future<void> _clearSession() async {
    await _storage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.onSessionExpired = null;
    super.dispose();
  }
}
