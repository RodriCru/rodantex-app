import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';
import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/network/api_client.dart';

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

/// Servidor falso: el access token "expired" provoca un 401 una sola vez.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.storage});

  final _MemoryStorage storage;
  bool refreshed = false;
  int refreshCalls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.endsWith('auth/login')) {
      return ResponseBody.fromString(
        jsonEncode({
          'name': 'Juan Alberto',
          'role': 'OWNER',
          'tenant': 'Tenant de prueba',
          'accessToken': 'expired',
          'refreshToken': 'refresh-1',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.endsWith('auth/refresh')) {
      refreshCalls++;
      refreshed = true;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return ResponseBody.fromString(
        jsonEncode({'accessToken': 'new-access', 'refreshToken': 'refresh-2'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (path.endsWith('auth/logout')) {
      return ResponseBody.fromString('', 200);
    }

    // Endpoint protegido.
    final auth = options.headers['Authorization'];
    if (!refreshed && auth == 'Bearer expired') {
      return ResponseBody.fromString('', 401);
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  late _MemoryStorage storage;
  late ApiClient client;
  late _FakeAdapter adapter;

  setUp(() {
    storage = _MemoryStorage();
    client = ApiClient.create(storage: storage);
    adapter = _FakeAdapter(storage: storage);
    client.dio.httpClientAdapter = adapter;
    client.dio.options.baseUrl = 'http://localhost:8080/api/v1/';
  });

  test('login guarda la sesión y expone el rol', () async {
    final auth = AuthController(client: client, storage: storage);
    await auth.login(email: 'grupomla2@gmail.com', password: 'x');

    expect(auth.isAuthenticated, isTrue);
    expect(auth.role, UserRole.owner);
    expect(auth.user?.tenant, 'Tenant de prueba');
    expect(storage.accessToken, 'expired');
  });

  test('un 401 renueva el token y reintenta la petición', () async {
    final auth = AuthController(client: client, storage: storage);
    await auth.login(email: 'a@b.co', password: 'x');

    final responses = await Future.wait([
      client.get<Map<String, dynamic>>('vehicles'),
      client.get<Map<String, dynamic>>('routes'),
    ]);

    expect(responses, hasLength(2));
    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(adapter.refreshCalls, 1, reason: 'refresh debe ser único');
    expect(storage.accessToken, 'new-access');
    expect(storage.refreshToken, 'refresh-2');
  });

  test('logout limpia la sesión', () async {
    final auth = AuthController(client: client, storage: storage);
    await auth.login(email: 'a@b.co', password: 'x');
    await auth.logout();

    expect(auth.isAuthenticated, isFalse);
    expect(storage.accessToken, isNull);
  });
}
