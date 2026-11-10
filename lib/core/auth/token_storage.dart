import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:rodantex_app/core/auth/models/auth_session.dart';

/// Persistencia segura de los tokens y del perfil del usuario.
///
/// Usa el almacenamiento seguro del sistema (Keychain en iOS, Keystore en
/// Android). Mantiene una copia en memoria para que el interceptor de red
/// pueda leer el token de forma síncrona.
abstract interface class TokenStorage {
  String? get accessToken;

  String? get refreshToken;

  UserProfile? get user;

  Future<void> saveSession(AuthSession session);

  Future<void> saveTokens(AuthTokens tokens);

  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const _accessKey = 'rodantex_access_token';
  static const _refreshKey = 'rodantex_refresh_token';
  static const _userKey = 'rodantex_user_profile';

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  UserProfile? _user;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  UserProfile? get user => _user;

  /// Carga la sesión guardada de una ejecución anterior.
  Future<void> restore() async {
    _accessToken = await _storage.read(key: _accessKey);
    _refreshToken = await _storage.read(key: _refreshKey);
    final rawUser = await _storage.read(key: _userKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        _user = UserProfile.fromJson(
          jsonDecode(rawUser) as Map<String, dynamic>,
        );
      } on FormatException {
        _user = null;
      }
    }
  }

  bool get hasSession =>
      (_accessToken?.isNotEmpty ?? false) &&
      (_refreshToken?.isNotEmpty ?? false);

  @override
  Future<void> saveSession(AuthSession session) async {
    await saveTokens(session.tokens);
    await saveUser(session.user);
  }

  /// Guarda cambios del perfil sin modificar los tokens existentes.
  Future<void> saveUser(UserProfile user) async {
    _user = user;
    await _storage.write(
      key: _userKey,
      value: jsonEncode({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'role': user.role.apiValue,
        'tenant': user.tenant,
      }),
    );
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    if (!tokens.isValid) {
      throw ArgumentError('Los tokens recibidos están incompletos.');
    }
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    await Future.wait([
      _storage.write(key: _accessKey, value: tokens.accessToken),
      _storage.write(key: _refreshKey, value: tokens.refreshToken),
    ]);
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _userKey),
    ]);
  }
}
