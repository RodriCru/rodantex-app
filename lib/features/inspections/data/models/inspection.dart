/// Resultado global del estado de una inspección de llantas.
enum InspectionStatus {
  notInspected('NOT_INSPECTED', 'Sin inspeccionar'),
  notInspectedWithReason('NOT_INSPECTED_WITH_REASON', 'No inspeccionada'),
  inspected('INSPECTED', 'Inspeccionada'),
  inspectedWithAlert('INSPECTED_WITH_ALERT', 'Inspeccionada con alertas'),
  unknown('UNKNOWN', 'Desconocido');

  const InspectionStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  /// Traduce el valor recibido y resiste estados futuros del backend.
  static InspectionStatus fromApi(Object? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return InspectionStatus.unknown;
  }
}

/// Estado individual asignado a una llanta durante la inspección.
enum InspectionTireStatus {
  optimal('OPTIMAL', 'Óptima'),
  changeRequired('CHANGE_REQUIRED', 'Requiere cambio'),
  needsDisassembly('NEEDS_DISASSEMBLY', 'Requiere desmontaje'),
  needsImmediateDisassembly(
    'NEEDS_IMMEDIATE_DISASSEMBLY',
    'Desmontaje inmediato',
  ),
  inspectionImpossible('INSPECTION_IMPOSSIBLE', 'No se pudo inspeccionar'),
  danger('DANGER', 'Peligro'),
  unknown('UNKNOWN', 'Desconocido');

  const InspectionTireStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  /// Convierte el enum del servidor al valor utilizable en UI.
  static InspectionTireStatus fromApi(Object? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return InspectionTireStatus.unknown;
  }
}

/// Inspección de vehículo, con el desglose de las mediciones por llanta.
class TireInspection {
  const TireInspection({
    required this.id,
    required this.vehicleId,
    required this.dateOfInspection,
    required this.status,
    required this.description,
    this.registeredById,
    this.createdAt,
    this.updatedAt,
    this.tires = const [],
  });

  /// Traduce el DTO de detalle o resumen de inspección.
  factory TireInspection.fromJson(Map<String, dynamic> json) => TireInspection(
    id: json['id'] as String? ?? '',
    vehicleId: json['vehicleId'] as String? ?? '',
    registeredById: json['registeredById'] as String?,
    dateOfInspection: json['dateOfInspection'] as String? ?? '',
    status: InspectionStatus.fromApi(json['inspectionStatus']),
    description: json['description'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    tires: (json['tires'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InspectionTire.fromJson)
        .toList(growable: false),
  );

  /// UUID del registro y vehículo inspeccionado.
  final String id;
  final String vehicleId;
  final String? registeredById;

  /// Fecha de la inspección en formato `yyyy-MM-dd`.
  final String dateOfInspection;

  /// Estado general y descripción de la revisión.
  final InspectionStatus status;
  final String description;

  /// Auditoría de creación y modificación.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Lecturas y alertas de las llantas incluidas.
  final List<InspectionTire> tires;
}

/// Lecturas y resultado de una llanta en una inspección.
class InspectionTire {
  const InspectionTire({
    required this.id,
    required this.tireId,
    required this.status,
    this.currentPosition,
    this.firstReading,
    this.secondReading,
    this.thirdReading,
    this.averageDepth,
    this.referenceDepthMm,
    this.remainingPercentage,
    this.evidenceUrl,
    this.note,
  });

  /// Convierte el DTO `TireItem` del detalle.
  factory InspectionTire.fromJson(Map<String, dynamic> json) => InspectionTire(
    id: json['id'] as String? ?? '',
    tireId: json['tireId'] as String? ?? '',
    currentPosition: json['currentPosition'] as String?,
    firstReading: (json['firstReading'] as num?)?.toDouble(),
    secondReading: (json['secondReading'] as num?)?.toDouble(),
    thirdReading: (json['thirdReading'] as num?)?.toDouble(),
    averageDepth: (json['averageDepth'] as num?)?.toDouble(),
    referenceDepthMm: (json['referenceDepthMm'] as num?)?.toDouble(),
    remainingPercentage: (json['remainingPercentage'] as num?)?.toDouble(),
    status: InspectionTireStatus.fromApi(json['inspectionStatusTire']),
    evidenceUrl: json['evidenceUrl'] as String?,
    note: json['note'] as String?,
  );

  /// UUID del ítem de inspección y UUID de la llanta de la flota.
  final String id;
  final String tireId;

  /// Posición física y tres mediciones de profundidad.
  final String? currentPosition;
  final double? firstReading;
  final double? secondReading;
  final double? thirdReading;
  final double? averageDepth;
  final double? referenceDepthMm;
  final double? remainingPercentage;

  /// Resultado, evidencia y nota de la llanta.
  final InspectionTireStatus status;
  final String? evidenceUrl;
  final String? note;
}

/// Inspecciones de una página devueltas para un vehículo.
class InspectionPage {
  const InspectionPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  /// Lee la página paginada del endpoint de historial por vehículo.
  factory InspectionPage.fromJson(Map<String, dynamic> json) => InspectionPage(
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TireInspection.fromJson)
        .toList(growable: false),
    total: _number(json['total']) ?? 0,
    page: _number(json['page']) ?? 1,
    limit: _number(json['limit']) ?? 20,
  );

  /// Registros en esta página.
  final List<TireInspection> items;

  /// Total de inspecciones del vehículo.
  final int total;

  /// Número de página base 1.
  final int page;

  /// Tamaño de página solicitado.
  final int limit;

  /// Indica si existe una página adicional.
  bool get hasNextPage => page * limit < total;

  static int? _number(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String number => int.tryParse(number),
    _ => null,
  };
}
