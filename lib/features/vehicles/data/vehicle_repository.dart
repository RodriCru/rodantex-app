import 'package:dio/dio.dart';

import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/vehicles/data/models/insurance_supplier.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle_maintenance.dart';

/// Acceso a la lista y detalle de vehículos del backend.
class VehicleRepository {
  const VehicleRepository(this._client);

  final ApiClient _client;

  /// Obtiene una página de vehículos con búsqueda opcional.
  Future<VehiclePage> list({int page = 1, int limit = 20, String? search}) =>
      _guard(() async {
        final response = await _client.get<Map<String, dynamic>>(
          'vehicles',
          query: {
            'page': page,
            'limit': limit,
            'sort': 'createdAt',
            'order': 'desc',
            'isDeleted': false,
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
          },
        );
        return VehiclePage.fromJson(_client.unwrap(response.data));
      });

  /// Obtiene el detalle de un vehículo por su UUID.
  Future<Vehicle> getById(String id) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('vehicles/$id');
    return Vehicle.fromJson(_client.unwrap(response.data));
  });

  /// Consulta los datos de mantenimiento asociados a un vehículo.
  Future<VehicleMaintenance?> getMaintenance(String vehicleId) =>
      _guard(() async {
        final response = await _client.get<Map<String, dynamic>>(
          'vehicles/$vehicleId/maintenance',
        );
        final raw = response.data;
        // El backend usa HTTP 200 y `resultado: null` cuando el registro aún
        // no existe; es un estado vacío normal para el formulario de alta.
        if (raw != null &&
            raw.containsKey('resultado') &&
            raw['resultado'] == null) {
          return null;
        }
        return VehicleMaintenance.fromJson(_client.unwrap(response.data));
      });

  /// Obtiene proveedores activos del tipo aseguradora para el selector.
  Future<List<InsuranceSupplier>> insuranceSuppliers() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'suppliers',
      query: {
        'page': 1,
        'limit': 100,
        'sort': 'createdAt',
        'order': 'desc',
        'isDeleted': false,
        'supplierType': 'INSURANCE',
      },
    );
    final result = _client.unwrap(response.data);
    final items = result['items'];
    if (items is! List) return const <InsuranceSupplier>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(InsuranceSupplier.fromJson)
        .where((supplier) => supplier.id.isNotEmpty)
        .toList(growable: false);
  });

  /// Registra por primera vez los datos de mantenimiento del vehículo.
  Future<VehicleMaintenance> createMaintenance(
    String vehicleId,
    Map<String, dynamic> data,
  ) => _saveMaintenance(vehicleId, data, create: true);

  /// Actualiza los datos de mantenimiento ya registrados.
  Future<VehicleMaintenance> updateMaintenance(
    String vehicleId,
    Map<String, dynamic> data,
  ) => _saveMaintenance(vehicleId, data, create: false);

  Future<VehicleMaintenance> _saveMaintenance(
    String vehicleId,
    Map<String, dynamic> data, {
    required bool create,
  }) => _guard(() async {
    final path = 'vehicles/$vehicleId/maintenance';
    final response = create
        ? await _client.post<Map<String, dynamic>>(path, data: data)
        : await _client.patch<Map<String, dynamic>>(path, data: data);
    return VehicleMaintenance.fromJson(_client.unwrap(response.data));
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
