/// Un vehículo que está actualmente en mantenimiento.
///
/// Modelo de **solo lectura** para la tarjeta "En mantenimiento" del dashboard
/// (`GET dashboard/vehicles-in-maintenance`). La UI nunca lo envía de vuelta.
class VehicleInMaintenance {
  const VehicleInMaintenance({
    required this.vehicleId,
    required this.plate,
    required this.numberEco,
    required this.make,
    required this.model,
    required this.depotId,
    required this.depotName,
    required this.since,
    required this.daysInMaintenance,
    this.year,
  });

  /// Lee un elemento de `resultado.items`.
  ///
  /// Los campos de texto caen a `'—'` y los numéricos a `0` para tolerar
  /// `null` sin romper la pantalla. [since] llega en ISO-8601 UTC y se guarda
  /// ya en hora local, que es la que se muestra.
  factory VehicleInMaintenance.fromJson(Map<String, dynamic> json) {
    final rawSince = json['since'] as String?;
    return VehicleInMaintenance(
      vehicleId: json['vehicleId'] as String? ?? '',
      plate: json['plate'] as String? ?? '—',
      numberEco: json['numberEco'] as String? ?? '—',
      make: json['make'] as String? ?? '—',
      model: json['model'] as String? ?? '—',
      year: json['year']?.toString(),
      depotId: json['depotId'] as String? ?? '',
      depotName: json['depotName'] as String? ?? '—',
      since: rawSince == null
          ? null
          : DateTime.tryParse(rawSince)?.toLocal(),
      daysInMaintenance: (json['daysInMaintenance'] as num?)?.toInt() ?? 0,
    );
  }

  /// Id real del vehículo (para navegar a su detalle).
  final String vehicleId;
  final String plate;
  final String numberEco; // número económico interno
  final String make;
  final String model;

  /// `"2021"` en el backend; `null` si no está capturado.
  final String? year;
  final String depotId;
  final String depotName;

  /// Desde cuándo está en taller, en hora local; `null` si no vino el dato.
  final DateTime? since;

  /// Días acumulados en mantenimiento.
  final int daysInMaintenance;

  /// `"Toyota Hilux 2021"` (omite partes vacías y placeholders como `—`).
  String get displayName => [make, model, year]
      .whereType<String>()
      .where((part) => part.isNotEmpty && part != '—')
      .join(' ');

  /// `true` cuando el vehículo lleva más de una semana parado.
  bool get isOverdue => daysInMaintenance > 7;
}
