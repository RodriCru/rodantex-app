/// Registro de un servicio de mantenimiento realizado a un vehículo.
class Maintenance {
  const Maintenance({
    required this.id,
    required this.vehicleId,
    required this.supplierId,
    required this.dateOfMaintenance,
    required this.description,
    required this.cost,
    this.registeredById,
    this.invoiceUrl,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  /// Convierte `GetMaintenanceDto` a un registro tipado.
  factory Maintenance.fromJson(Map<String, dynamic> json) => Maintenance(
    id: json['id'] as String? ?? '',
    vehicleId: json['vehicleId'] as String? ?? '',
    supplierId: json['supplierId'] as String? ?? '',
    registeredById: json['registeredById'] as String?,
    dateOfMaintenance: json['dateOfMaintenance'] as String? ?? '',
    description: json['description'] as String? ?? '',
    cost: (json['cost'] as num?)?.toDouble() ?? 0,
    invoiceUrl: json['invoiceUrl'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    isDeleted: json['isDeleted'] as bool? ?? false,
  );

  /// Identificadores de mantenimiento, vehículo, proveedor y usuario creador.
  final String id;
  final String vehicleId;
  final String supplierId;
  final String? registeredById;

  /// Fecha civil del servicio en formato `yyyy-MM-dd`.
  final String dateOfMaintenance;

  /// Descripción de los trabajos efectuados.
  final String description;

  /// Costo reportado por el backend.
  final double cost;

  /// URL de factura, cuando ya se cargó un archivo.
  final String? invoiceUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
}

/// Página del listado de mantenimientos (numeración base 1).
class MaintenancePage {
  const MaintenancePage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  /// Lee `resultado: {total, page, limit, items}`.
  factory MaintenancePage.fromJson(Map<String, dynamic> json) =>
      MaintenancePage(
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Maintenance.fromJson)
            .toList(growable: false),
        total: _asInt(json['total']) ?? 0,
        page: _asInt(json['page']) ?? 1,
        limit: _asInt(json['limit']) ?? 20,
      );

  /// Registros incluidos en esta página.
  final List<Maintenance> items;

  /// Total de registros coincidentes.
  final int total;

  /// Página actual de la API, base 1.
  final int page;

  /// Cantidad máxima de registros por página.
  final int limit;

  /// Indica si hay otra página disponible.
  bool get hasNextPage => page * limit < total;

  static int? _asInt(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String number => int.tryParse(number),
    _ => null,
  };
}
