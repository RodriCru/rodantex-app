import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';
import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/theme/rodantex_theme.dart';
import 'package:rodantex_app/features/dashboard/data/dashboard_repository.dart';
import 'package:rodantex_app/features/dashboard/presentation/dashboard_page.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/spending_chart.dart';

/// Reemplazo de `SecureTokenStorage` sin plugin: implementa `restore()` en
/// memoria para que `AuthController.restore()` encuentre la sesión sembrada.
class _MemoryStorage implements TokenStorage {
  String? _access;
  String? _refresh;
  UserProfile? _user;

  void seed(UserProfile user) {
    _access = 'access';
    _refresh = 'refresh';
    _user = user;
  }

  /// Mismo contrato que `SecureTokenStorage.restore`; aquí es idempotente.
  Future<void> restore() async {}

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

const _summary = {
  'codigo': 200,
  'mensaje': 'Resumen obtenido exitosamente',
  'resultado': {
    'fleet': {
      'active': 10,
      'operational': 8,
      'inMaintenance': 2,
      'inactive': 0,
      'retired': 0,
      'total': 10,
      'byStatus': {'IN_SERVICE': 8, 'IN_MAINTENANCE': 2},
    },
    'tireSpending': {
      'amount': 12500,
      'previousAmount': 10000,
      'changePercent': 25,
      'trend': 'UP',
    },
    'maintenanceSpending': {
      'amount': 0,
      'previousAmount': 0,
      'changePercent': null,
      'trend': 'FLAT',
    },
    'staff': {
      'total': 7,
      'drivers': 4,
      'mechanics': 1,
      'admins': 2,
      'byRole': {'OWNER': 2, 'DRIVER': 4, 'MECHANIC': 1},
    },
    'currency': 'MXN',
    'periodStart': '2026-11-01',
    'periodEnd': '2026-11-07',
  },
};

const _spending = {
  'codigo': 200,
  'mensaje': 'Gasto obtenido exitosamente',
  'resultado': {
    'currency': 'MXN',
    'months': [
      {'month': '2026-10', 'purchases': 5000, 'maintenance': 1000},
      {'month': '2026-11', 'purchases': 1000, 'maintenance': 0},
    ],
    'totalPurchases': 6000,
    'totalMaintenance': 1000,
  },
};

const _maintenance = {
  'codigo': 200,
  'mensaje': 'OK',
  'resultado': {
    'total': 8,
    'items': [
      {
        'vehicleId': 'v-1',
        'plate': 'ABC-123',
        'numberEco': 'ECO-01',
        'make': 'Toyota',
        'model': 'Hilux',
        'year': '2021',
        'depotId': 'd-1',
        'depotName': 'Depósito Norte',
        'since': '2026-11-01T10:00:00Z',
        'daysInMaintenance': 20,
      },
    ],
  },
};

class _Adapter implements HttpClientAdapter {
  _Adapter({this.failMaintenance = false});

  final bool failMaintenance;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == 'dashboard/vehicles-in-maintenance' && failMaintenance) {
      return ResponseBody.fromString(
        jsonEncode({'codigo': 503, 'mensaje': 'Taller no disponible'}),
        503,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    final body = switch (options.path) {
      'dashboard/summary' => _summary,
      'dashboard/spending' => _spending,
      'dashboard/vehicles-in-maintenance' => _maintenance,
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// Monta la pantalla con un usuario [role] ya autenticado.
Future<AuthController> pumpDashboardForTest(
  WidgetTester tester, {
  UserRole role = UserRole.owner,
  bool failMaintenance = false,
  Size size = const Size(1000, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final storage = _MemoryStorage()
    ..seed(
      UserProfile(
        name: 'Juan Alberto Pérez',
        role: role,
        tenant: 'Transportes MLA',
      ),
    );
  final client = ApiClient.create(storage: storage)
    ..dio.httpClientAdapter = _Adapter(failMaintenance: failMaintenance);
  client.dio.options.baseUrl = 'http://localhost:8080/api/v1/';
  final auth = AuthController(client: client, storage: storage);
  await auth.restore();

  await tester.pumpWidget(
    MaterialApp(
      theme: RodantexTheme.light,
      home: DashboardPage(
        auth: auth,
        dashboardRepository: DashboardRepository(client),
      ),
    ),
  );
  // Sin `pumpAndSettle`: el `CircularProgressIndicator` del `RefreshIndicator`
  // nunca deja de animar y haría el settle infinito.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  return auth;
}

void main() {
  testWidgets('con datos muestra saludo, KPIs y tarjetas', (tester) async {
    await pumpDashboardForTest(tester);

    expect(find.text('Hola, Juan'), findsOneWidget);
    expect(find.text('Transportes MLA'), findsOneWidget);
    expect(find.text('Periodo 1 – 7 nov 2026'), findsOneWidget);

    // KPIs.
    expect(find.text('10'), findsOneWidget); // vehículos
    expect(find.text(r'$12,500.00'), findsOneWidget); // llantas
    expect(find.text('7'), findsOneWidget); // personal

    // Tarjetas.
    expect(find.text('Gasto mensual'), findsOneWidget);
    expect(find.text('Estado de la flota'), findsOneWidget);
    // Título de la tarjeta + fila del desglose de flota.
    expect(find.text('En mantenimiento'), findsNWidgets(2));
    expect(find.text('8 vehículos en taller'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);

    // Vehículo en taller con badge crítico (> 14 días).
    expect(find.text('ABC-123'), findsOneWidget);
    expect(find.text('20 días'), findsOneWidget);
    expect(find.text('Toyota Hilux 2021 · Eco ECO-01'), findsOneWidget);
  });

  testWidgets('una tarjeta con error no tumba el resto', (tester) async {
    await pumpDashboardForTest(tester, failMaintenance: true);

    expect(find.text('Taller no disponible'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    // El resumen y la gráfica siguen visibles.
    expect(find.text(r'$12,500.00'), findsOneWidget);
    expect(find.text('Estado de la flota'), findsOneWidget);
  });

  testWidgets('un rol sin acceso ve el aviso', (tester) async {
    await pumpDashboardForTest(tester, role: UserRole.driver);

    expect(
      find.text('El dashboard no está disponible para tu rol'),
      findsOneWidget,
    );
    expect(find.text('Estado de la flota'), findsNothing);
  });

  testWidgets('en pantalla angosta las tarjetas se apilan', (tester) async {
    // 360 px de ancho lógico: una sola columna, sin overflow.
    await pumpDashboardForTest(tester, size: const Size(360, 2200));

    expect(tester.takeException(), isNull);
    expect(find.text('Estado de la flota'), findsOneWidget);
  });

  testWidgets('tocar la gráfica selecciona el mes', (tester) async {
    await pumpDashboardForTest(tester);

    // El mes "nov" es el más reciente y la gráfica tiene 2 grupos: se toca el
    // centro del segundo grupo.
    final chart = find
        .descendant(
          of: find.byType(SpendingChart),
          matching: find.byType(GestureDetector),
        )
        .first;
    final box = tester.getRect(chart);
    await tester.tapAt(Offset(box.left + box.width * 0.70, box.top + 60));
    await tester.pump();

    expect(find.text('Gasto de nov'), findsOneWidget);
    // `$1,000.00` aparece en la leyenda y en el total del mes seleccionado.
    expect(find.text(r'$1,000.00'), findsNWidgets(2));
  });
}
