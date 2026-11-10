import 'package:flutter/material.dart';

import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/features/dashboard/data/models/spending_summary.dart';

/// Interpretación visual del cambio de gasto de un periodo a otro.
///
/// En gasto, **bajar es bueno**: se pinta teal (positivo) y subir en amber
/// (atención). No se usa coral porque un aumento de gasto no es un incidente.
enum ChangeTone { positive, negative, neutral }

/// Textos e iconos derivados de [SpendingSummary].
extension SpendingSummaryView on SpendingSummary {
  /// Porcentaje sin signo: `"12.5 %"`; `null` si no hay periodo previo.
  String? get changeLabel {
    final value = changePercent;
    if (value == null) return null;
    final rounded = value.abs().toStringAsFixed(1);
    final text = rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
    return '$text %';
  }

  IconData get trendIcon => switch (trend) {
    'UP' => Icons.trending_up_rounded,
    'DOWN' => Icons.trending_down_rounded,
    _ => Icons.trending_flat_rounded,
  };

  ChangeTone get tone => switch (trend) {
    'UP' => ChangeTone.negative,
    'DOWN' => ChangeTone.positive,
    _ => ChangeTone.neutral,
  };
}

/// `true` si la tendencia sube (para el orden "▲ 12 % más").
extension ChangeToneView on ChangeTone {
  Color color(ColorScheme scheme) => switch (this) {
    ChangeTone.positive => RodantexColors.infoDark,
    ChangeTone.negative => RodantexColors.accentHover,
    ChangeTone.neutral => scheme.onSurfaceVariant,
  };
}
