import 'package:flutter/material.dart';

import 'package:rodantex_app/core/theme/rodantex_colors.dart';

/// Paleta semántica para los badges de estados operativos, alertas y documentos.
///
/// Regla de accesibilidad (paleta-saas.html): el texto del badge siempre es
/// oscuro sobre un fondo suave.
enum RodantexBadgeTone {
  /// En ruta / activo / éxito.
  active(background: Color(0xFFE8F2C6), foreground: Color(0xFF3D5210)),

  /// Disponible / info.
  available(background: Color(0xFFD9F2EE), foreground: Color(0xFF0F4C5C)),

  /// Detenido / inactivo / no aplica.
  idle(background: Color(0xFFE7EBEE), foreground: Color(0xFF293B4B)),

  /// Mantenimiento / advertencia / por vencer.
  maintenance(background: Color(0xFFFBEED4), foreground: Color(0xFF7A4E0F)),

  /// Incidente / error / vencido.
  incident(background: Color(0xFFFBE3DC), foreground: Color(0xFF8A2E1A)),

  /// Retraso / desvío.
  delay(background: Color(0xFFFCE8D6), foreground: Color(0xFF8A4A12));

  const RodantexBadgeTone({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

/// Colores para gráficas y mapas.
abstract final class RodantexChartColors {
  static const primary = RodantexColors.secondary;
  static const secondary = RodantexColors.info;
  static const warning = RodantexColors.accent;
  static const alert = RodantexColors.danger;
  static const neutral = RodantexColors.primaryLight;
  static const soft = RodantexColors.infoLight;

  static const List<Color> series = [
    primary,
    secondary,
    warning,
    alert,
    neutral,
    soft,
  ];
}
