/// Parada de una ruta reutilizable.
class RouteStop {
  const RouteStop({
    required this.order,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Construye una parada desde JSON.
  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    order: (json['order'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
  );
  final int order;
  final String name;
  final double latitude;
  final double longitude;
}

/// Ruta que puede utilizarse en uno o más viajes.
class FleetRoute {
  const FleetRoute({
    required this.id,
    required this.name,
    this.description,
    this.originName,
    required this.originLatitude,
    required this.originLongitude,
    this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    required this.active,
    required this.stops,
  });

  /// Construye una ruta desde JSON.
  factory FleetRoute.fromJson(Map<String, dynamic> json) => FleetRoute(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    originName: json['originName'] as String?,
    originLatitude: (json['originLatitude'] as num?)?.toDouble() ?? 0,
    originLongitude: (json['originLongitude'] as num?)?.toDouble() ?? 0,
    destinationName: json['destinationName'] as String?,
    destinationLatitude: (json['destinationLatitude'] as num?)?.toDouble() ?? 0,
    destinationLongitude:
        (json['destinationLongitude'] as num?)?.toDouble() ?? 0,
    estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble(),
    estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num?)
        ?.toInt(),
    active: json['active'] as bool? ?? false,
    stops: (json['stops'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RouteStop.fromJson)
        .toList(growable: false),
  );
  final String id, name;
  final String? description, originName, destinationName;
  final double originLatitude,
      originLongitude,
      destinationLatitude,
      destinationLongitude;
  final double? estimatedDistanceKm;
  final int? estimatedDurationMinutes;
  final bool active;
  final List<RouteStop> stops;
}
