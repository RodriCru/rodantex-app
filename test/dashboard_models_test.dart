import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/dashboard/data/dashboard_repository.dart';
import 'package:rodantex_app/features/dashboard/data/models/summary.dart';
import 'package:rodantex_app/features/dashboard/presentation/money_formatter.dart';

/// Respuesta real de `dashboard/summary` documentada por el backend.
const _summaryJson = {
  'codigo': 200,
  'mensaje': 'Resumen obtenido exitosamente',
  'resultado': {
    'fleet': {
      'active': 1,
      'operational': 1,
      'inMaintenance': 0,
      'inactive': 0,
      'retired': 0,
      'total': 1,
      'byStatus': {
        'IN_SERVICE': 1,
        'IN_MAINTENANCE': 0,
        'INACTIVE': 0,
        'SCRAPPED': 0,
        'LOST': 0,
        'SOLD': 0,
        'DONATED': 0,
        'CHRASHED': 0,
        'FOR_PARTS': 0,
      },
    },
    'tireSpending': {
      'amount': 0,
      'previousAmount': 0,
      'changePercent': null,
      'trend': 'FLAT',
    },
    'maintenanceSpending': {
      'amount': 1500.5,
      'previousAmount': 1000,
      'changePercent': 50.05,
      'trend': 'UP',
    },
    'staff': {
      'total': 3,
      'drivers': 1,
      'mechanics': 0,
      'admins': 2,
      'byRole': {
        'SUPERADMIN': 0,
        'OWNER': 2,
        'MANAGER': 0,
        'DRIVER': 1,
        'MECHANIC': 0,
        'ACCOUNTANT': 0,
      },
    },
    'currency': 'MXN',
    'periodStart': '2026-11-01',
    'periodEnd': '2026-11-07',
  },
};

const _spendingJson = {
  'codigo': 200,
  'mensaje': 'Gasto obtenido exitosamente',
  'resultado': {
    'currency': 'MXN',
    'months': [
      {'month': '2026-06', 'purchases': 0, 'maintenance': 0},
      {'month': '2026-07', 'purchases': 2200, 'maintenance': 800},
      {'month': '2026-08', 'purchases': 0, 'maintenance': 0},
      {'month': '2026-09', 'purchases': 100, 'maintenance': 0},
      {'month': '2026-10', 'purchases': 0, 'maintenance': 0},
      {'month': '2026-11', 'purchases': 0, 'maintenance': 0},
    ],
    'totalPurchases': 2300,
    'totalMaintenance': 800,
  },
};

const _maintenanceJson = {
  'codigo': 0,
  'mensaje': 'string',
  'resultado': {
    'total': 2,
    'items': [
      {
        'vehicleId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'plate': 'ABC-123',
        'numberEco': 'ECO-01',
        'make': 'Toyota',
        'model': 'Hilux',
        'year': '2021',
        'depotId': '3fa85f64-5717-4562-b3fc-2c963f66afa7',
        'depotName': 'Depósito Norte',
        'since': '2026-11-08T01:20:17.381Z',
        'daysInMaintenance': 12,
      },
      {
        'vehicleId': '2fa85f64-5717-4562-b3fc-2c963f66afa6',
        'plate': null,
        'numberEco': null,
        'make': 'Nissan',
        'model': null,
        'year': null,
        'depotId': '3fa85f64-5717-4562-b3fc-2c963f66afa7',
        'depotName': null,
        'since': null,
        'daysInMaintenance': null,
      },
    ],
  },
};

class _MemoryStorage implements TokenStorage {
  @override
  String? get accessToken => 'token';

  @override
  String? get refreshToken => 'refresh';

  @override
  UserProfile? get user => null;

  @override
  Future<void> clear() async {}

  @override
  Future<void> saveSession(AuthSession session) async {}

  @override
  Future<void> saveTokens(AuthTokens tokens) async {}
}

/// Adaptador falso: devuelve la respuesta por endpoint y guarda las queries.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.failSpending = false});

  final bool failSpending;
  final Map<String, Map<String, dynamic>?> queries = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    queries[options.path] = options.queryParameters.cast<String, dynamic>();

    if (options.path == 'dashboard/spending' && failSpending) {
      return ResponseBody.fromString(
        jsonEncode({'codigo': 500, 'mensaje': 'Gasto no disponible'}),
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final body = switch (options.path) {
      'dashboard/summary' => _summaryJson,
      'dashboard/spending' => _spendingJson,
      'dashboard/vehicles-in-maintenance' => _maintenanceJson,
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

({ApiClient client, _Adapter adapter}) _client({bool fail = false}) {
  final adapter = _Adapter(failSpending: fail);
  final client = ApiClient.create(storage: _MemoryStorage())
    ..dio.httpClientAdapter = adapter;
  client.dio.options.baseUrl = 'http://localhost:8080/api/v1/';
  return (client: client, adapter: adapter);
}

void main() {
  group('DashboardRepository', () {
    test('summary desempaqueta la envoltura y no manda depotId vacío', () async {
      final (:client, :adapter) = _client();
      final summary = await DashboardRepository(client).summary();

      expect(summary.fleet.total, 1);
      expect(summary.staff.owners, 2);
      expect(summary.currency, 'MXN');
      expect(adapter.queries['dashboard/summary'], isEmpty);
    });

    test('spending manda months y depotId cuando se indica', () async {
      final (:client, :adapter) = _client();
      final history = await DashboardRepository(
        client,
      ).spending(depotId: 'depot-1', months: 3);

      expect(history.months, hasLength(6));
      expect(history.maxMonthlyTotal, 2200);
      expect(history.months[1].monthLabel, 'jul');
      expect(adapter.queries['dashboard/spending'], {
        'months': 3,
        'depotId': 'depot-1',
      });
    });

    test('vehicles-in-maintenance manda limit y parsea el bloque', () async {
      final (:client, :adapter) = _client();
      final block = await DashboardRepository(client).vehiclesInMaintenance();

      expect(adapter.queries['dashboard/vehicles-in-maintenance'], {'limit': 6});
      expect(block.total, 2);
      expect(block.hasMore, isFalse);
      expect(block.items.first.plate, 'ABC-123');
      expect(block.items.first.displayName, 'Toyota Hilux 2021');
      expect(block.items.first.isOverdue, isTrue);
      expect(block.items.first.since, isNotNull);
    });

    test('tolera nulos en los vehículos', () async {
      final (:client, adapter: _) = _client();
      final block = await DashboardRepository(client).vehiclesInMaintenance();
      final second = block.items.last;

      expect(second.plate, '—');
      expect(second.depotName, '—');
      expect(second.since, isNull);
      expect(second.daysInMaintenance, 0);
      expect(second.displayName, 'Nissan');
    });

    test('traduce el error del backend con ApiException', () async {
      final (:client, adapter: _) = _client(fail: true);

      expect(
        () => DashboardRepository(client).spending(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Gasto no disponible')
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('Summary', () {
    test('lee la envoltura y sus bloques', () {
      final summary = Summary.fromJson(_summaryJson);

      expect(summary.fleet.inService, 1);
      expect(summary.staff.drivers, 1);
      expect(summary.periodLabel, '1 – 7 nov 2026');
      expect(summary.maintenanceSpending.amount, 1500.5);
    });

    test('sin periodo previo el cambio es null', () {
      final summary = Summary.fromJson(_summaryJson);

      expect(summary.tireSpending.changePercent, isNull);
      expect(summary.tireSpending.isFlat, isTrue);
      expect(summary.maintenanceSpending.isUp, isTrue);
    });

    test('acepta el resultado desempaquetado y tolera campos vacíos', () {
      final summary = Summary.fromJson(const {'fleet': null});

      expect(summary.fleet.total, 0);
      expect(summary.staff.total, 0);
      expect(summary.currency, 'MXN');
      expect(summary.periodLabel, '');
    });
  });

  group('MoneyFormatter', () {
    test('formatea con miles, decimales y moneda', () {
      expect(MoneyFormatter.format(0), r'$0.00');
      expect(MoneyFormatter.format(1234567.5), r'$1,234,567.50');
      expect(MoneyFormatter.format(-98.4, currency: 'EUR'), '-€98.40');
      expect(MoneyFormatter.format(10, currency: 'CAD'), '10.00 CAD');
    });

    test('compacto para tarjetas', () {
      expect(MoneyFormatter.compact(850), '850');
      expect(MoneyFormatter.compact(12300), '12.3 k');
      expect(MoneyFormatter.compact(2000000), '2 M');
      expect(MoneyFormatter.compact(-1500), '-1.5 k');
    });
  });
}
