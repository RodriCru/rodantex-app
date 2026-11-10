/// Estado de una orden de mantenimiento.
enum MaintenanceOrderStatus { inProgress, completed, canceled }

/// Orden que representa el ingreso de uno o más vehículos al taller.
class MaintenanceOrder {
  const MaintenanceOrder({
    required this.id,
    required this.vehicles,
    required this.entryDescription,
    required this.openedAt,
    required this.status,
    this.supplierId,
    this.supplierName,
    this.completedAt,
    this.serviceDate,
    this.serviceDescription,
    this.totalCost,
    this.invoiceUrl,
  });

  /// Construye una orden desde la respuesta del backend.
  factory MaintenanceOrder.fromJson(Map<String, dynamic> json) => MaintenanceOrder(
        id: json['id'] as String? ?? '',
        vehicles: (json['vehicles'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MaintenanceOrderVehicle.fromJson)
            .toList(growable: false),
        supplierId: json['supplierId'] as String?,
        supplierName: json['supplierName'] as String?,
        entryDescription: json['entryDescription'] as String? ?? '',
        openedAt: DateTime.tryParse(json['openedAt'] as String? ?? ''),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
        status: _status(json['status']),
        serviceDate: json['serviceDate'] as String?,
        serviceDescription: json['serviceDescription'] as String?,
        totalCost: (json['totalCost'] as num?)?.toDouble(),
        invoiceUrl: json['invoiceUrl'] as String?,
      );

  static MaintenanceOrderStatus _status(Object? value) => switch (value) {
        'COMPLETED' => MaintenanceOrderStatus.completed,
        'CANCELED' => MaintenanceOrderStatus.canceled,
        _ => MaintenanceOrderStatus.inProgress,
      };

  final String id;
  final List<MaintenanceOrderVehicle> vehicles;
  final String? supplierId;
  final String? supplierName;
  final String entryDescription;
  final DateTime? openedAt;
  final DateTime? completedAt;
  final MaintenanceOrderStatus status;
  final String? serviceDate;
  final String? serviceDescription;
  final double? totalCost;
  final String? invoiceUrl;
}

/// Vehículo incluido en una orden de mantenimiento.
class MaintenanceOrderVehicle {
  const MaintenanceOrderVehicle({required this.id, this.plate, required this.make, required this.model});

  /// Construye un vehículo de orden desde JSON.
  factory MaintenanceOrderVehicle.fromJson(Map<String, dynamic> json) => MaintenanceOrderVehicle(
        id: json['id'] as String? ?? '',
        plate: json['plate'] as String?,
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
      );

  final String id;
  final String? plate;
  final String make;
  final String model;
}

/// Página paginada de órdenes.
class MaintenanceOrderPage {
  const MaintenanceOrderPage({required this.items, required this.total, required this.page, required this.limit});

  /// Lee la respuesta paginada del backend.
  factory MaintenanceOrderPage.fromJson(Map<String, dynamic> json) => MaintenanceOrderPage(
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MaintenanceOrder.fromJson)
            .toList(growable: false),
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
      );

  final List<MaintenanceOrder> items;
  final int total;
  final int page;
  final int limit;

  /// Indica si existe otra página.
  bool get hasNextPage => page * limit < total;
}
