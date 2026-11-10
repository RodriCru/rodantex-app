import 'package:dio/dio.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/routes/data/models/route.dart';
import 'package:rodantex_app/features/routes/data/models/trip.dart';

/// Acceso de solo consulta a rutas y viajes, más estados de viaje.
class RoutesRepository {
  const RoutesRepository(this._client);
  final ApiClient _client;

  /// Obtiene todas las rutas visibles para la sesión.
  Future<List<FleetRoute>> listRoutes() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('routes');
    return _client.unwrapList(response.data).map(FleetRoute.fromJson).toList(growable: false);
  });

  /// Obtiene el detalle de una ruta.
  Future<FleetRoute> getRoute(String id) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('routes/$id');
    return FleetRoute.fromJson(_client.unwrap(response.data));
  });

  /// Obtiene los viajes visibles para el usuario autenticado.
  Future<List<FleetTrip>> listTrips() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('trips');
    return _client.unwrapList(response.data).map(FleetTrip.fromJson).toList(growable: false);
  });

  /// Obtiene el detalle de un viaje.
  Future<FleetTrip> getTrip(String id) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('trips/$id');
    return FleetTrip.fromJson(_client.unwrap(response.data));
  });

  /// Actualiza el estado del viaje sin crear ni modificar su contenido.
  Future<FleetTrip> updateTripStatus(String id, TripStatus status) => _guard(() async {
    final value = switch (status) { TripStatus.scheduled => 'SCHEDULED', TripStatus.inProgress => 'IN_PROGRESS', TripStatus.completed => 'COMPLETED', TripStatus.canceled => 'CANCELED', TripStatus.incident => 'INCIDENT' };
    final response = await _client.patch<Map<String, dynamic>>('trips/$id/status', data: {'status': value});
    return FleetTrip.fromJson(_client.unwrap(response.data));
  });

  Future<T> _guard<T>(Future<T> Function() request) async { try { return await request(); } on ApiException { rethrow; } on DioException catch (error) { throw ApiException.fromDio(error); } }
}
