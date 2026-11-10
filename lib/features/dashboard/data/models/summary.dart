import 'package:rodantex_app/features/dashboard/data/models/fleet_summary.dart';
import 'package:rodantex_app/features/dashboard/data/models/spending_summary.dart';
import 'package:rodantex_app/features/dashboard/data/models/staff_summary.dart';

/// Respuesta de `GET dashboard/summary`.
///
/// [Summary.fromJson] recibe el **body completo** (con la envoltura
/// `{codigo, mensaje, resultado}`) y lee `resultado`; también acepta el
/// `resultado` ya desempaquetado, así sirve para tests con fixtures.
class Summary {
  const Summary({
    required this.fleet,
    required this.tireSpending,
    required this.maintenanceSpending,
    required this.staff,
    required this.currency,
    required this.periodStart,
    required this.periodEnd,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    final data = json['resultado'] is Map<String, dynamic>
        ? json['resultado'] as Map<String, dynamic>
        : json;

    return Summary(
      fleet: FleetSummary.fromJson(
        data['fleet'] as Map<String, dynamic>? ?? const {},
      ),
      tireSpending: SpendingSummary.fromJson(
        data['tireSpending'] as Map<String, dynamic>? ?? const {},
      ),
      maintenanceSpending: SpendingSummary.fromJson(
        data['maintenanceSpending'] as Map<String, dynamic>? ?? const {},
      ),
      staff: StaffSummary.fromJson(
        data['staff'] as Map<String, dynamic>? ?? const {},
      ),
      currency: data['currency'] as String? ?? 'MXN',
      // Fechas de negocio (`YYYY-MM-DD`), no instantes: se guardan como texto.
      periodStart: data['periodStart'] as String? ?? '',
      periodEnd: data['periodEnd'] as String? ?? '',
    );
  }

  final FleetSummary fleet;
  final SpendingSummary tireSpending;
  final SpendingSummary maintenanceSpending;
  final StaffSummary staff;

  /// Moneda de los importes (p. ej. `"MXN"`).
  final String currency;

  /// Primer día del periodo comparado (`"2026-11-01"`).
  final String periodStart;

  /// Último día del periodo comparado (`"2026-11-07"`).
  final String periodEnd;

  static const _yearMonths = [
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

  /// Periodo comparable para el subtítulo: `"1 – 7 nov 2026"`.
  ///
  /// Devuelve cadena vacía si las fechas no son válidas.
  String get periodLabel {
    final start = DateTime.tryParse(periodStart);
    final end = DateTime.tryParse(periodEnd);
    if (start == null || end == null) return '';
    return '${start.day} – ${end.day} ${_yearMonths[end.month - 1]} ${end.year}';
  }
}
