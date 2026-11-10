import 'package:dio/dio.dart';

import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/dashboard/data/models/paged_block.dart';
import 'package:rodantex_app/features/dashboard/data/models/spending_history.dart';
import 'package:rodantex_app/features/dashboard/data/models/summary.dart';
import 'package:rodantex_app/features/dashboard/data/models/vehicle_in_maintenance.dart';

/// Endpoints del dashboard.
///
/// Todos son `GET`, relativos a `api/v1/` y responden envueltos en
/// `{codigo, mensaje, resultado}`: este es el único punto que desempaqueta.
/// Recibe el [ApiClient] compartido, así hereda Bearer y refresh automático.
///
/// Errores: cualquier fallo (red, HTTP, formato) sale como [ApiException] con
/// el mensaje ya en español, tal como espera la UI (ver contrato §2.4).
class DashboardRepository {
  const DashboardRepository(this._client);

  final ApiClient _client;

  /// `GET dashboard/summary?depotId`
  ///
  /// KPI globales: flota, gasto del periodo y personal.
  Future<Summary> summary({String? depotId}) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'dashboard/summary',
      query: {
        // Si no hay depósito seleccionado, se omiten los del tenant.
        if (depotId != null && depotId.isNotEmpty) 'depotId': depotId,
      },
    );
    return Summary.fromJson(_client.unwrap(response.data));
  });

  /// `GET dashboard/spending?months&depotId`
  ///
  /// Histórico de gasto mensual (compras vs mantenimiento).
  /// [months] es cuántos meses hacia atrás devuelve el backend.
  Future<SpendingHistory> spending({String? depotId, int months = 6}) =>
      _guard(() async {
        final response = await _client.get<Map<String, dynamic>>(
          'dashboard/spending',
          query: {'months': months, 'depotId': ?depotId},
        );
        return SpendingHistory.fromJson(_client.unwrap(response.data));
      });

  /// `GET dashboard/vehicles-in-maintenance?limit&depotId`
  ///
  /// Vehículos en taller con sus días acumulados. [limit] es cuántos traer.
  Future<PagedBlock<VehicleInMaintenance>> vehiclesInMaintenance({
    String? depotId,
    int limit = 6,
  }) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'dashboard/vehicles-in-maintenance',
      query: {'limit': limit, 'depotId': ?depotId},
    );
    return PagedBlock.fromJson(
      _client.unwrap(response.data),
      VehicleInMaintenance.fromJson,
    );
  });

  /// Convierte [DioException] en [ApiException] y deja pasar las
  /// [ApiException] que ya lanza `unwrap`.
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
