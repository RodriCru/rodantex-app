import 'package:dio/dio.dart';

import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance_supplier.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';

/// Acceso a los registros de mantenimiento y catálogos requeridos por el form.
class MaintenanceRepository {
  const MaintenanceRepository(this._client);

  final ApiClient _client;

  /// Obtiene los mantenimientos activos con búsqueda y paginación.
  Future<MaintenancePage> list({
    int page = 1,
    int limit = 20,
    String? search,
  }) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'maintenances',
      query: {
        'page': page,
        'limit': limit,
        'sort': 'dateOfMaintenance',
        'order': 'desc',
        'isDeleted': false,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return MaintenancePage.fromJson(_client.unwrap(response.data));
  });

  /// Busca mantenimientos para un vehículo en particular.
  Future<MaintenancePage> byVehicle(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  }) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'maintenances/vehicle/$vehicleId',
      query: {
        'page': page,
        'limit': limit,
        'sort': 'dateOfMaintenance',
        'order': 'desc',
        'isDeleted': false,
      },
    );
    return MaintenancePage.fromJson(_client.unwrap(response.data));
  });

  /// Obtiene un registro por UUID.
  Future<Maintenance> getById(String id) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'maintenances/$id',
    );
    return Maintenance.fromJson(_client.unwrap(response.data));
  });

  /// Registra un servicio de mantenimiento.
  Future<Maintenance> create(Map<String, dynamic> data) => _save(null, data);

  /// Actualiza los campos editables de un servicio.
  Future<Maintenance> update(String id, Map<String, dynamic> data) =>
      _save(id, data);

  Future<Maintenance> _save(String? id, Map<String, dynamic> data) => _guard(
    () async {
      final response = id == null
          ? await _client.post<Map<String, dynamic>>('maintenances', data: data)
          : await _client.patch<Map<String, dynamic>>(
              'maintenances/$id',
              data: data,
            );
      return Maintenance.fromJson(_client.unwrap(response.data));
    },
  );

  /// Elimina un registro de mantenimiento.
  Future<void> delete(String id) => _guard(() async {
    await _client.delete<Map<String, dynamic>>('maintenances/$id');
  });

  /// Obtiene hasta 100 vehículos activos para selección en el formulario.
  Future<List<Vehicle>> vehicles() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'vehicles',
      query: {
        'page': 1,
        'limit': 100,
        'sort': 'createdAt',
        'order': 'desc',
        'isDeleted': false,
      },
    );
    final items = _client.unwrap(response.data)['items'];
    if (items is! List) return const <Vehicle>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Vehicle.fromJson)
        .toList(growable: false);
  });

  /// Obtiene hasta 100 proveedores activos para asociarlos al servicio.
  Future<List<MaintenanceSupplier>> suppliers() => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'suppliers',
      query: {
        'page': 1,
        'limit': 100,
        'sort': 'name',
        'order': 'asc',
        'isDeleted': false,
      },
    );
    final items = _client.unwrap(response.data)['items'];
    if (items is! List) return const <MaintenanceSupplier>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(MaintenanceSupplier.fromJson)
        .where((supplier) => supplier.id.isNotEmpty)
        .toList(growable: false);
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
