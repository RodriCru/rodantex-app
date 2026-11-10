import 'package:rodantex_app/features/inspections/data/models/inspection.dart';

/// Umbral de profundidad configurado para un resultado de inspección.
class InspectionRule {
  const InspectionRule({required this.status, required this.maxDepthMm});

  /// Lee un umbral del backend.
  factory InspectionRule.fromJson(Map<String, dynamic> json) => InspectionRule(
    status: InspectionTireStatus.fromApi(json['status']),
    maxDepthMm: (json['maxDepthMm'] as num?)?.toDouble() ?? 0,
  );

  /// Resultado asociado a este umbral.
  final InspectionTireStatus status;

  /// Profundidad máxima en milímetros configurada por el backend.
  final double maxDepthMm;

  /// JSON con los nombres esperados por el endpoint de reglas.
  Map<String, dynamic> toJson() => {
    'status': status.apiValue,
    'maxDepthMm': maxDepthMm,
  };
}

/// Reglas de inspección aplicables a una categoría de vehículo.
class InspectionRules {
  const InspectionRules({
    required this.carType,
    required this.source,
    required this.rules,
  });

  /// Lee configuración global de inspección.
  factory InspectionRules.fromJson(Map<String, dynamic> json) =>
      InspectionRules(
        carType: json['carType'] as String? ?? '',
        source: json['source'] as String? ?? '',
        rules: (json['rules'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(InspectionRule.fromJson)
            .toList(growable: false),
      );

  /// Tipo de vehículo al que aplica la configuración.
  final String carType;

  /// Indica si el backend aplicó reglas propias o valores por defecto.
  final String source;

  /// Umbrales por estado de llanta.
  final List<InspectionRule> rules;
}
