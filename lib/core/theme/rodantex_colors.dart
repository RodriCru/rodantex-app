import 'package:flutter/material.dart';

/// Tokens de color de la paleta "Fusion" de Rodantex.
///
/// Fuente de verdad: `paleta-saas.html` en la raíz del proyecto.
/// No inventar colores aquí: cualquier nuevo color debe añadirse primero a la
/// paleta oficial.
abstract final class RodantexColors {
  // ===== Estructura (Graphite) =====
  static const primary = Color(0xFF17232F);
  static const primaryHover = Color(0xFF0F1922);
  static const primaryLight = Color(0xFF293B4B);

  // ===== Acción positiva (Lime) =====
  static const secondary = Color(0xFFB8D957);
  static const secondaryHover = Color(0xFFA6C644);
  static const secondaryLight = Color(0xFFD4E894);
  static const secondaryDark = Color(0xFFC6E86A);

  // ===== Info / disponible (Teal) =====
  static const info = Color(0xFF2A9D8F);
  static const infoHover = Color(0xFF21867A);
  static const infoLight = Color(0xFF5DC4B8);
  static const infoDark = Color(0xFF0F4C5C);

  // ===== Advertencia (Amber) =====
  static const accent = Color(0xFFE9A23B);
  static const accentHover = Color(0xFFD18E2A);
  static const accentLight = Color(0xFFF2C77F);

  // ===== Crítico (Coral) =====
  static const danger = Color(0xFFE76F51);
  static const dangerHover = Color(0xFFD45A3D);
  static const dangerLight = Color(0xFFF4A38F);

  // ===== Marca (logo, no cambia) =====
  static const brandTeal = Color(0xFF0F4C5C);
  static const brandGreen = Color(0xFF2A9D8F);
  static const brandCoral = Color(0xFFE76F51);

  // ===== Superficies =====
  static const bgApp = Color(0xFFF3F5F6);
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgSubtle = Color(0xFFE7EBEE);
  static const border = Color(0xFFD2D8DD);

  // ===== Texto =====
  static const textPrimary = Color(0xFF17232F);
  static const textSecondary = Color(0xFF4A5A6B);
  static const textMuted = Color(0xFF8795A3);
  static const textInverse = Color(0xFFFFFFFF);
  static const textOnLime = Color(0xFF17232F);

  // ===== Modo oscuro =====
  static const bgAppDark = Color(0xFF0F1922);
  static const bgSurfaceDark = Color(0xFF17232F);
  static const bgElevatedDark = Color(0xFF293B4B);
  static const borderDark = Color(0xFF3A4D5F);
  static const textSecondaryDark = Color(0xFF9FB0BE);
}
