/// Estado operativo de un viaje.
enum TripStatus { scheduled, inProgress, completed, canceled, incident }

/// Viaje asignado a un vehículo y conductor.
class FleetTrip {
  const FleetTrip({
    required this.id,
    this.routeId,
    required this.vehicleId,
    required this.driverId,
    required this.driverName,
    this.vehicleLabel,
    this.originName,
    required this.originLatitude,
    required this.originLongitude,
    this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.scheduledDepartureAt,
    this.scheduledArrivalAt,
    this.actualDepartureAt,
    this.actualArrivalAt,
    required this.status,
    this.notes,
  });

  /// Construye un viaje desde JSON.
  factory FleetTrip.fromJson(Map<String, dynamic> json) => FleetTrip(
    id: json['id'] as String? ?? '',
    routeId: json['routeId'] as String?,
    vehicleId: json['vehicleId'] as String? ?? '',
    driverId: json['driverId'] as String? ?? '',
    driverName: json['driverName'] as String? ?? '',
    vehicleLabel: json['vehicleLabel'] as String?,
    originName: json['originName'] as String?,
    originLatitude: (json['originLatitude'] as num?)?.toDouble() ?? 0,
    originLongitude: (json['originLongitude'] as num?)?.toDouble() ?? 0,
    destinationName: json['destinationName'] as String?,
    destinationLatitude: (json['destinationLatitude'] as num?)?.toDouble() ?? 0,
    destinationLongitude:
        (json['destinationLongitude'] as num?)?.toDouble() ?? 0,
    scheduledDepartureAt: DateTime.tryParse(
      json['scheduledDepartureAt'] as String? ?? '',
    ),
    scheduledArrivalAt: DateTime.tryParse(
      json['scheduledArrivalAt'] as String? ?? '',
    ),
    actualDepartureAt: DateTime.tryParse(
      json['actualDepartureAt'] as String? ?? '',
    ),
    actualArrivalAt: DateTime.tryParse(
      json['actualArrivalAt'] as String? ?? '',
    ),
    status: _status(json['status']),
    notes: json['notes'] as String?,
  );
  static TripStatus _status(Object? value) => switch (value) {
    'IN_PROGRESS' => TripStatus.inProgress,
    'COMPLETED' => TripStatus.completed,
    'CANCELED' => TripStatus.canceled,
    'INCIDENT' => TripStatus.incident,
    _ => TripStatus.scheduled,
  };
  final String id;
  final String? routeId;
  final String vehicleId, driverId, driverName;
  final String? vehicleLabel, originName, destinationName, notes;
  final double originLatitude,
      originLongitude,
      destinationLatitude,
      destinationLongitude;
  final DateTime? scheduledDepartureAt,
      scheduledArrivalAt,
      actualDepartureAt,
      actualArrivalAt;
  final TripStatus status;
}
