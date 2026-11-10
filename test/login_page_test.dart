import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/app/auth_scope.dart';
import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/app/router.dart';
import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/theme/rodantex_theme.dart';

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
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _user = null;
  }

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
}

/// Responde 401 a todo (credenciales inválidas) y 200 al resto.
class _Adapter implements HttpClientAdapter {
  _Adapter({required this.authorized});

  final bool authorized;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (authorized && options.path.endsWith('auth/login')) {
      return ResponseBody.fromString(
        jsonEncode({
          'name': 'Juan Alberto',
          'role': 'OWNER',
          'tenant': 'Tenant de prueba',
          'accessToken': 'access',
          'refreshToken': 'refresh',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path.startsWith('dashboard/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'codigo': 200,
          'mensaje': 'OK',
          'resultado': {'total': 0, 'items': <dynamic>[], 'months': <dynamic>[]},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'Credenciales inválidas'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Future<AuthController> _boot(
  WidgetTester tester, {
  required bool authorized,
}) async {
  final storage = _MemoryStorage();
  final client = ApiClient.create(storage: storage);
  client.dio.httpClientAdapter = _Adapter(authorized: authorized);
  client.dio.options.baseUrl = 'http://localhost:8080/api/v1/';
  final auth = AuthController(client: client, storage: storage);
  await auth.restore();

  final appRouter = AppRouter(auth: auth);
  await tester.pumpWidget(
    AuthScope(
      auth: auth,
      apiClient: client,
      child: MaterialApp.router(
        theme: RodantexTheme.light,
        routerConfig: appRouter.router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('Sin sesión el router redirige al login', (tester) async {
    final auth = await _boot(tester, authorized: false);

    expect(auth.isAuthenticated, isFalse);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Tu espacio'), findsNothing);
  });

  testWidgets('Login válido navega a la home con el rol', (tester) async {
    await _boot(tester, authorized: true);

    await tester.enterText(
      find.byType(TextFormField).first,
      'grupomla2@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secreto');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    // Al entrar se abre el dashboard; el nombre va en el saludo y el rol en el
    // menú de sesión del AppBar.
    expect(find.text('Hola, Juan'), findsOneWidget);
    expect(find.text('Tenant de prueba'), findsOneWidget);
    expect(find.text('Rodantex'), findsOneWidget);
    await tester.tap(find.byTooltip('Juan Alberto'));
    await tester.pumpAndSettle();
    expect(find.text('Propietario'), findsOneWidget);
  });

  testWidgets('El login inválido muestra el error del servidor', (
    tester,
  ) async {
    await _boot(tester, authorized: false);

    await tester.enterText(
      find.byType(TextFormField).first,
      'grupomla2@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'mal');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Credenciales inválidas'), findsOneWidget);
  });

  test('Las rutas nombradas generan la URL esperada', () {
    expect(AppRoutes.login, '/login');
    expect(AppRoutes.vehicleDetail('abc'), '/vehicles/abc');
    expect(RouteNames.home, 'home');
  });
}
