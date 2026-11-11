/// Punto de ubicación registrado durante un viaje.
class TripLocation {
  const TripLocation({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  /// Construye una ubicación desde la API o desde la cola local.
  factory TripLocation.fromJson(Map<String, dynamic> json) => TripLocation(
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    recordedAt:
        DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
        DateTime.now().toUtc(),
  );

  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  /// Serializa el body que acepta el backend.
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };
}

/// Estado de frescura de la última ubicación de una unidad.
enum LocationStatus { fresh, stale, offline, noData }

/// Última posición reportada por un vehículo en monitoreo.
class MonitoredVehicle {
  const MonitoredVehicle({
    required this.vehicleId,
    this.vehicleLabel,
    this.tripId,
    this.driverName,
    this.latitude,
    this.longitude,
    this.recordedAt,
    required this.status,
  });

  /// Construye un vehículo monitoreado desde la API.
  factory MonitoredVehicle.fromJson(Map<String, dynamic> json) =>
      MonitoredVehicle(
        vehicleId: json['vehicleId'] as String? ?? '',
        vehicleLabel:
            json['vehicleLabel'] as String? ?? json['plate'] as String?,
        tripId: json['tripId'] as String?,
        driverName: json['driverName'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? ''),
        status: _status(json['locationStatus']),
      );

  final String vehicleId;
  final String? vehicleLabel;
  final String? tripId;
  final String? driverName;
  final double? latitude;
  final double? longitude;
  final DateTime? recordedAt;
  final LocationStatus status;

  static LocationStatus _status(Object? value) => switch (value) {
    'FRESH' => LocationStatus.fresh,
    'STALE' => LocationStatus.stale,
    'OFFLINE' => LocationStatus.offline,
    _ => LocationStatus.noData,
  };
}
