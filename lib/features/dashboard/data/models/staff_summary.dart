/// Personal del tenant según `resultado.staff` de `dashboard/summary`.
class StaffSummary {
  const StaffSummary({
    required this.total,
    required this.drivers,
    required this.mechanics,
    required this.admins,
    required this.byRole,
  });

  factory StaffSummary.fromJson(Map<String, dynamic> json) => StaffSummary(
    total: (json['total'] as num?)?.toInt() ?? 0,
    drivers: (json['drivers'] as num?)?.toInt() ?? 0,
    mechanics: (json['mechanics'] as num?)?.toInt() ?? 0,
    admins: (json['admins'] as num?)?.toInt() ?? 0,
    byRole:
        (json['byRole'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
        ) ??
        const {},
  );

  final int total;
  final int drivers;
  final int mechanics;
  final int admins;

  /// Totales por rol del backend (`"OWNER"` → 2, `"DRIVER"` → 1, …).
  final Map<String, int> byRole;

  int get owners => byRole['OWNER'] ?? 0;
  int get superadmins => byRole['SUPERADMIN'] ?? 0;
  int get managers => byRole['MANAGER'] ?? 0;
}
