import 'package:dio/dio.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/routes/data/models/route.dart';
import 'package:rodantex_app/features/routes/data/models/trip.dart';
import 'package:rodantex_app/features/routes/data/models/trip_expense.dart';
import 'package:rodantex_app/features/routes/data/models/trip_location.dart';

/// Acceso de solo consulta a rutas y viajes, más estados de viaje.
class RoutesRepository {
  const RoutesRepository(this._client);
  final ApiClient _client;

  /// Obtiene todas las rutas visibles para la sesión.
  Future<List<FleetRoute>> listRoutes() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('routes');
    return _client
        .unwrapList(response.data)
        .map(FleetRoute.fromJson)
        .toList(growable: false);
  });

  /// Obtiene el detalle de una ruta.
  Future<FleetRoute> getRoute(String id) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('routes/$id');
    return FleetRoute.fromJson(_client.unwrap(response.data));
  });

  /// Obtiene los viajes visibles para el usuario autenticado.
  Future<List<FleetTrip>> listTrips() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('trips');
    return _client
        .unwrapList(response.data)
        .map(FleetTrip.fromJson)
        .toList(growable: false);
  });

  /// Obtiene el detalle de un viaje.
  Future<FleetTrip> getTrip(String id) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('trips/$id');
    return FleetTrip.fromJson(_client.unwrap(response.data));
  });

  /// Actualiza el estado del viaje sin crear ni modificar su contenido.
  Future<FleetTrip> updateTripStatus(String id, TripStatus status) =>
      _guard(() async {
        final value = switch (status) {
          TripStatus.scheduled => 'SCHEDULED',
          TripStatus.inProgress => 'IN_PROGRESS',
          TripStatus.completed => 'COMPLETED',
          TripStatus.canceled => 'CANCELED',
          TripStatus.incident => 'INCIDENT',
        };
        final response = await _client.patch<Map<String, dynamic>>(
          'trips/$id/status',
          data: {'status': value},
        );
        return FleetTrip.fromJson(_client.unwrap(response.data));
      });

  /// Obtiene los gastos registrados para un viaje.
  Future<List<TripExpense>> listTripExpenses(String tripId) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'trips/$tripId/expenses',
    );
    return _client
        .unwrapList(response.data)
        .map(TripExpense.fromJson)
        .toList(growable: false);
  });

  /// Registra un gasto en un viaje.
  Future<TripExpense> createTripExpense(
    String tripId,
    Map<String, dynamic> data,
  ) => _guard(() async {
    final response = await _client.post<Map<String, dynamic>>(
      'trips/$tripId/expenses',
      data: data,
    );
    return TripExpense.fromJson(_client.unwrap(response.data));
  });

  /// Actualiza un gasto existente.
  Future<TripExpense> updateTripExpense(
    String expenseId,
    Map<String, dynamic> data,
  ) => _guard(() async {
    final response = await _client.put<Map<String, dynamic>>(
      'trips/expenses/$expenseId',
      data: data,
    );
    return TripExpense.fromJson(_client.unwrap(response.data));
  });

  /// Elimina lógicamente un gasto.
  Future<void> deleteTripExpense(String expenseId) => _guard(() async {
    await _client.delete<Map<String, dynamic>>('trips/expenses/$expenseId');
  });

  /// Registra una ubicación del viaje.
  Future<void> createTripLocation(String tripId, TripLocation location) =>
      _guard(() async {
        await _client.post<Map<String, dynamic>>(
          'trips/$tripId/locations',
          data: location.toJson(),
        );
      });

  /// Obtiene el historial de ubicaciones de un viaje.
  Future<List<TripLocation>> listTripLocations(String tripId) =>
      _guard(() async {
        final response = await _client.get<Map<String, dynamic>>(
          'trips/$tripId/locations',
        );
        return _client
            .unwrapList(response.data)
            .map(TripLocation.fromJson)
            .toList(growable: false);
      });

  /// Obtiene los vehículos que tienen viajes activos o programados.
  Future<List<MonitoredVehicle>> listMonitoredVehicles() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'monitoring/vehicles',
    );
    return _client
        .unwrapList(response.data)
        .map(MonitoredVehicle.fromJson)
        .toList(growable: false);
  });

  /// Obtiene la última ubicación conocida de un vehículo.
  Future<MonitoredVehicle> getLastVehicleLocation(String vehicleId) =>
      _guard(() async {
        final response = await _client.get<Map<String, dynamic>>(
          'monitoring/vehicles/$vehicleId/last-location',
        );
        return MonitoredVehicle.fromJson(_client.unwrap(response.data));
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
