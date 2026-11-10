/// Datos de mantenimiento y vigencia documental asociados a un vehículo.
class VehicleMaintenance {
  const VehicleMaintenance({
    this.id,
    this.vehicleId,
    this.nextVerification,
    this.insuranceExpiration,
    this.insuranceSupplierId,
    this.insurancePolicy,
    this.maintenanceIntervalKm,
    this.odometer,
    this.licensePlateExpiration,
    this.odometerUpdatedBy,
    this.insuranceUpdatedBy,
    this.plateAndVerificationUpdatedBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Lee el DTO de mantenimiento enviado por el backend.
  factory VehicleMaintenance.fromJson(Map<String, dynamic> json) =>
      VehicleMaintenance(
        id: json['id'] as String?,
        vehicleId: json['vehicleId'] as String?,
        nextVerification: _date(json['nextVerification']),
        insuranceExpiration: _date(json['insuranceExpiration']),
        insuranceSupplierId: json['insuranceSupplierId'] as String?,
        insurancePolicy: json['insurancePolicy'] as String?,
        maintenanceIntervalKm: (json['maintenanceIntervalKm'] as num?)?.toInt(),
        odometer: (json['odometer'] as num?)?.toDouble(),
        licensePlateExpiration: _date(json['licensePlateExpiration']),
        odometerUpdatedBy: json['odometerUpdatedBy'] as String?,
        insuranceUpdatedBy: json['insuranceUpdatedBy'] as String?,
        plateAndVerificationUpdatedBy:
            json['plateAndVerificationUpdatedBy'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );

  /// Identificadores de este registro y del vehículo.
  final String? id;
  final String? vehicleId;

  /// Fechas civiles en formato `yyyy-MM-dd` que define Swagger.
  final String? nextVerification;
  final String? insuranceExpiration;
  final String? licensePlateExpiration;

  /// Póliza y aseguradora vinculadas al vehículo.
  final String? insuranceSupplierId;
  final String? insurancePolicy;

  /// Odómetro y distancia entre mantenimientos preventivos.
  final int? maintenanceIntervalKm;
  final double? odometer;

  /// UUIDs de auditoría informados por el backend.
  final String? odometerUpdatedBy;
  final String? insuranceUpdatedBy;
  final String? plateAndVerificationUpdatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String? _date(Object? value) => value is String ? value : null;
}
