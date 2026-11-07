import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';

class _MemoryStorage implements TokenStorage {
  String? _access;
  String? _refresh;
  UserProfile? _user;

  @override
  String? get accessToken => _access;

  @override
  String? get refreshToken => _refresh;

  @override
  UserProfile? get user => _user;

  @override
  Future<void> saveSession(AuthSession session) async {
    await saveTokens(session.tokens);
    _user = session.user;
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    _access = tokens.accessToken;
    _refresh = tokens.refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _user = null;
  }
}

void main() {
  test('El rol desconocido se resuelve como unknown', () {
    expect(UserRole.fromApi('owner'), UserRole.owner);
    expect(UserRole.fromApi('SUPERADMIN'), UserRole.superAdmin);
    expect(UserRole.fromApi('otro'), UserRole.unknown);
    expect(UserRole.fromApi(null), UserRole.unknown);
  });

  test('AuthTokens parsea la respuesta del refresh', () {
    final tokens = AuthTokens.fromJson(
      jsonDecode('{"accessToken":"a","refreshToken":"r"}')
          as Map<String, dynamic>,
    );
    expect(tokens.isValid, isTrue);
    expect(tokens.accessToken, 'a');
  });

  test('La sesión en memoria se guarda y se limpia', () async {
    final storage = _MemoryStorage();
    await storage.saveSession(
      const AuthSession(
        user: UserProfile(name: 'Juan', role: UserRole.owner, tenant: 'Tenant'),
        tokens: AuthTokens(accessToken: 'a', refreshToken: 'r'),
      ),
    );
    expect(storage.accessToken, 'a');
    expect(storage.user?.role, UserRole.owner);

    await storage.clear();
    expect(storage.accessToken, isNull);
    expect(storage.user, isNull);
  });
}
