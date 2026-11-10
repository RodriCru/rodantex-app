import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection_rules.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection_tire.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';

/// Acceso a inspecciones, llantas y reglas de inspección del backend.
class InspectionRepository {
  const InspectionRepository(this._client);

  final ApiClient _client;

  /// Obtiene el historial paginado de inspecciones para un vehículo.
  Future<InspectionPage> byVehicle(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  }) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'inspections/vehicle/$vehicleId',
      query: {'page': page, 'limit': limit},
    );
    return InspectionPage.fromJson(_client.unwrap(response.data));
  });

  /// Consulta el detalle de una inspección y las mediciones de sus llantas.
  Future<TireInspection> getById(String id) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>('inspections/$id');
    return TireInspection.fromJson(_client.unwrap(response.data));
  });

  /// Registra una inspección nueva con lecturas por llanta.
  Future<TireInspection> create(Map<String, dynamic> data) => _guard(() async {
    final response = await _client.post<Map<String, dynamic>>(
      'inspections',
      data: data,
    );
    return TireInspection.fromJson(_client.unwrap(response.data));
  });

  /// Actualiza fecha, descripción y lecturas de una inspección.
  Future<TireInspection> update(String id, Map<String, dynamic> data) =>
      _guard(() async {
        final response = await _client.patch<Map<String, dynamic>>(
          'inspections/$id',
          data: data,
        );
        return TireInspection.fromJson(_client.unwrap(response.data));
      });

  /// Elimina una inspección por UUID.
  Future<void> delete(String id) => _guard(() async {
    await _client.delete<Map<String, dynamic>>('inspections/$id');
  });

  /// Carga evidencia multipart para una llanta inspeccionada.
  Future<TireInspection> uploadEvidence({
    required String inspectionId,
    required String tireId,
    required Uint8List bytes,
    required String filename,
  }) => _guard(() async {
    final body = FormData.fromMap({
      'evidence': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _client.patch<Map<String, dynamic>>(
      'inspections/$inspectionId/tires/$tireId/evidence',
      data: body,
    );
    return TireInspection.fromJson(_client.unwrap(response.data));
  });

  /// Obtiene las llantas montadas actualmente en un vehículo.
  Future<List<VehicleInspectionTire>> tiresForVehicle(String vehicleId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        'vehicles/$vehicleId/tires',
      );
      return _client
          .unwrapList(response.data)
          .map(VehicleInspectionTire.fromJson)
          .where((tire) => tire.id.isNotEmpty)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Obtiene vehículos activos para elegir el vehículo de la inspección.
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

  /// Obtiene reglas configuradas para el tipo de vehículo indicado.
  Future<InspectionRules> getRules({String? carType}) => _guard(() async {
    final response = await _client.get<Map<String, dynamic>>(
      'tire-inspection-rules',
      query: {'carType': ?carType},
    );
    return InspectionRules.fromJson(_client.unwrap(response.data));
  });

  /// Guarda reglas de profundidad para el tipo de vehículo.
  Future<InspectionRules> saveRules({
    required String carType,
    required List<InspectionRule> rules,
  }) => _guard(() async {
    final response = await _client.put<Map<String, dynamic>>(
      'tire-inspection-rules',
      data: {
        'carType': carType,
        'rules': rules.map((rule) => rule.toJson()).toList(),
      },
    );
    return InspectionRules.fromJson(_client.unwrap(response.data));
  });

  /// Restablece reglas guardadas para todas las categorías o una sola.
  Future<void> resetRules({String? carType}) => _guard(() async {
    await _client.dio.delete<void>(
      'tire-inspection-rules',
      queryParameters: {'carType': ?carType},
    );
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
