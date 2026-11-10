/// Estado de la flota según `resultado.fleet` de `dashboard/summary`.
class FleetSummary {
  const FleetSummary({
    required this.active,
    required this.operational,
    required this.inMaintenance,
    required this.inactive,
    required this.retired,
    required this.total,
    required this.byStatus,
  });

  factory FleetSummary.fromJson(Map<String, dynamic> json) => FleetSummary(
    active: (json['active'] as num?)?.toInt() ?? 0,
    operational: (json['operational'] as num?)?.toInt() ?? 0,
    inMaintenance: (json['inMaintenance'] as num?)?.toInt() ?? 0,
    inactive: (json['inactive'] as num?)?.toInt() ?? 0,
    retired: (json['retired'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    // Mapa crudo: tolera estados nuevos sin tocar el modelo.
    byStatus:
        (json['byStatus'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
        ) ??
        const {},
  );

  final int active;
  final int operational;
  final int inMaintenance;
  final int inactive;
  final int retired;
  final int total;

  /// Totales por estado del enum del backend (`"IN_SERVICE"` → 1, …).
  final Map<String, int> byStatus;

  /// Atajos tipados para no usar strings mágicos en la UI.
  int get inService => byStatus['IN_SERVICE'] ?? 0;
  int get maintenance => byStatus['IN_MAINTENANCE'] ?? inMaintenance;
  int get scrapped => byStatus['SCRAPPED'] ?? 0;

  /// Flota ociosa = total − operativos − en mantenimiento (nunca negativo).
  int get idle {
    final value = total - operational - inMaintenance;
    return value < 0 ? 0 : value;
  }
}
