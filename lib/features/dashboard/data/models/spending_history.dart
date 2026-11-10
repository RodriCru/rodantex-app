import 'package:rodantex_app/features/dashboard/data/models/monthly_spending.dart';

/// Respuesta de `GET dashboard/spending` (histórico de gasto por mes).
class SpendingHistory {
  const SpendingHistory({
    required this.currency,
    required this.months,
    required this.totalPurchases,
    required this.totalMaintenance,
  });

  factory SpendingHistory.fromJson(Map<String, dynamic> json) {
    final rawMonths = json['months'] as List<dynamic>? ?? const [];
    return SpendingHistory(
      currency: json['currency'] as String? ?? 'MXN',
      months: rawMonths
          .whereType<Map<String, dynamic>>()
          .map(MonthlySpending.fromJson)
          .toList(growable: false),
      totalPurchases: (json['totalPurchases'] as num?)?.toDouble() ?? 0,
      totalMaintenance: (json['totalMaintenance'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Moneda ISO-4217 en la que vienen las cifras (p. ej. `"MXN"`).
  final String currency;

  /// Serie mensual, del mes más antiguo al más reciente.
  final List<MonthlySpending> months;

  final double totalPurchases;
  final double totalMaintenance;

  /// Total de todo el periodo mostrado.
  double get total => totalPurchases + totalMaintenance;

  /// Mayor gasto mensual entre todas las series; `0` si no hay datos.
  ///
  /// Lo usa la gráfica para escalar sus barras.
  double get maxMonthlyTotal {
    var max = 0.0;
    for (final month in months) {
      if (month.purchases > max) max = month.purchases;
      if (month.maintenance > max) max = month.maintenance;
    }
    return max;
  }

  bool get isEmpty => months.isEmpty;
}
