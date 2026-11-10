/// Estados que el backend puede devolver para un vehículo.
enum VehicleStatus {
  inService('IN_SERVICE', 'En servicio'),
  inMaintenance('IN_MAINTENANCE', 'En mantenimiento'),
  inactive('INACTIVE', 'Inactivo'),
  scrapped('SCRAPPED', 'Chatarrizado'),
  lost('LOST', 'Extraviado'),
  sold('SOLD', 'Vendido'),
  donated('DONATED', 'Donado'),
  crashed('CHRASHED', 'Accidentado'),
  forParts('FOR_PARTS', 'Para piezas'),
  unknown('UNKNOWN', 'Desconocido');

  const VehicleStatus(this.apiValue, this.label);

  /// Valor exacto usado por la API.
  final String apiValue;

  /// Etiqueta en español para presentar en la app.
  final String label;

  /// Convierte el estado del API y tolera valores futuros desconocidos.
  static VehicleStatus fromApi(Object? value) {
    for (final status in VehicleStatus.values) {
      if (status.apiValue == value) return status;
    }
    return VehicleStatus.unknown;
  }
}

/// Datos básicos y de detalle entregados por `GET /vehicles` y `/vehicles/{id}`.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.status,
    this.depotId,
    this.driverId,
    this.year,
    this.gasoline,
    this.carType,
    this.fuelCapacity,
    this.numberOfTires,
    this.hasSpareTire,
    this.photoUrl,
    this.numberEco,
    this.plate,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  /// Traduce el DTO `GetVehicleDto`, manteniendo opcionales los campos no
  /// requeridos por Swagger para tolerar registros incompletos.
  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String? ?? '',
    depotId: json['depotId'] as String?,
    driverId: json['driverId'] as String?,
    make: json['make'] as String? ?? '—',
    model: json['model'] as String? ?? '—',
    year: json['year']?.toString(),
    gasoline: json['gasoline'] as String?,
    carType: json['carType'] as String?,
    fuelCapacity: (json['fuelCapacity'] as num?)?.toDouble(),
    numberOfTires: (json['numberOfTires'] as num?)?.toInt(),
    hasSpareTire: json['hasSpareTire'] as bool?,
    photoUrl: json['photoUrl'] as String?,
    numberEco: json['numberEco'] as String?,
    plate: json['plate'] as String?,
    status: VehicleStatus.fromApi(json['statusVehicle']),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    isDeleted: json['isDeleted'] as bool? ?? false,
  );

  /// UUID del vehículo.
  final String id;

  /// UUID del depósito y conductor asignado, cuando existen.
  final String? depotId;
  final String? driverId;

  /// Marca y modelo reportados por el backend.
  final String make;
  final String model;

  /// Año como string, igual que el contrato del backend.
  final String? year;
  final String? gasoline;
  final String? carType;
  final double? fuelCapacity;
  final int? numberOfTires;
  final bool? hasSpareTire;
  final String? photoUrl;
  final String? numberEco;
  final String? plate;
  final VehicleStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  /// Nombre de unidad para títulos y filas de la lista.
  String get displayName => [make, model, year]
      .whereType<String>()
      .where((part) => part.trim().isNotEmpty && part != '—')
      .join(' ');
}

/// Página del endpoint de vehículos, cuya numeración inicia en 1.
class VehiclePage {
  const VehiclePage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  /// Lee `resultado: { total, page, limit, items }` de la API.
  factory VehiclePage.fromJson(Map<String, dynamic> json) => VehiclePage(
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Vehicle.fromJson)
        .toList(growable: false),
    total: _toInt(json['total']) ?? 0,
    page: _toInt(json['page']) ?? 1,
    limit: _toInt(json['limit']) ?? 20,
  );

  /// Unidades de la página actual.
  final List<Vehicle> items;

  /// Total de registros que coincide con la consulta.
  final int total;

  /// Página actual (base 1 según el contrato del servidor).
  final int page;

  /// Tamaño máximo de página.
  final int limit;

  /// Indica si el servidor reporta otra página disponible.
  bool get hasNextPage => page * limit < total;

  static int? _toInt(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String number => int.tryParse(number),
    _ => null,
  };
}
