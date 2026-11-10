/// Gasto de un mes concreto (`resultado.months[]` de `dashboard/spending`).
class MonthlySpending {
  const MonthlySpending({
    required this.month,
    required this.purchases,
    required this.maintenance,
  });

  /// [month] llega como `"2026-06"` (año-mes, sin día).
  factory MonthlySpending.fromJson(Map<String, dynamic> json) =>
      MonthlySpending(
        month: json['month'] as String? ?? '',
        purchases: (json['purchases'] as num?)?.toDouble() ?? 0,
        maintenance: (json['maintenance'] as num?)?.toDouble() ?? 0,
      );

  /// Clave del mes en formato `YYYY-MM`.
  final String month;

  /// Gasto en compras (llantas, refacciones…).
  final double purchases;

  /// Gasto en mantenimiento.
  final double maintenance;

  /// Total del mes (compras + mantenimiento).
  double get total => purchases + maintenance;

  /// Mes y año parseados de [month]; `null` si el formato no es válido.
  DateTime? get date {
    final parts = month.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final monthNumber = int.tryParse(parts[1]);
    if (year == null || monthNumber == null) return null;
    if (monthNumber < 1 || monthNumber > 12) return null;
    return DateTime(year, monthNumber);
  }

  /// Abreviatura del mes: `"jun"`, `"jul"`… (vacía si no se puede parsear).
  String get monthLabel {
    final value = date;
    if (value == null) return month;
    return _monthAbbreviations[value.month - 1];
  }

  static const _monthAbbreviations = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
}
