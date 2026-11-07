import 'package:flutter/material.dart';

import 'rodantex_colors.dart';

/// Tema de la aplicación Rodantex, construido con la paleta "Fusion".
///
/// - Lime es el color de acción principal (CTA, elementos activos).
/// - Graphite estructura la app (AppBar, sidebar, texto principal).
/// - Teal indica información, Amber advertencia y Coral estado crítico.
abstract final class RodantexTheme {
  static const fontFamily = 'Manrope';

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _colorScheme(isDark);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? RodantexColors.bgAppDark
          : RodantexColors.bgApp,
    );

    final textTheme = _textTheme(base.textTheme, colorScheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? RodantexColors.bgSurfaceDark
            : RodantexColors.bgSurface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: shape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: colorScheme.outline),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          textStyle: textTheme.labelLarge,
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? RodantexColors.bgElevatedDark
            : RodantexColors.bgSurface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: RodantexColors.info, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: RodantexColors.danger),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? RodantexColors.bgSurfaceDark
            : RodantexColors.bgSurface,
        indicatorColor: RodantexColors.secondaryLight,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: RodantexColors.primary,
        selectedIconTheme: const IconThemeData(
          color: RodantexColors.textOnLime,
        ),
        unselectedIconTheme: IconThemeData(
          color: RodantexColors.textInverse.withValues(alpha: 0.75),
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: RodantexColors.textOnLime,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: RodantexColors.textInverse.withValues(alpha: 0.75),
        ),
        indicatorColor: RodantexColors.secondary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? RodantexColors.bgElevatedDark
            : RodantexColors.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: RodantexColors.textInverse,
        ),
        shape: shape,
      ),
    );
  }

  /// El *seed* es Graphite para mantener la estructura oscura; Lime, Teal,
  /// Amber y Coral se asignan explícitamente según su rol semántico.
  static ColorScheme _colorScheme(bool isDark) {
    final scheme = ColorScheme.fromSeed(
      seedColor: RodantexColors.primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    if (isDark) {
      return scheme.copyWith(
        primary: RodantexColors.secondaryDark,
        onPrimary: RodantexColors.textOnLime,
        secondary: RodantexColors.infoLight,
        onSecondary: RodantexColors.textOnLime,
        tertiary: RodantexColors.accent,
        error: RodantexColors.dangerLight,
        surface: RodantexColors.bgSurfaceDark,
        onSurface: RodantexColors.bgApp,
        onSurfaceVariant: RodantexColors.textSecondaryDark,
        outline: RodantexColors.borderDark,
        outlineVariant: RodantexColors.bgElevatedDark,
      );
    }

    return scheme.copyWith(
      primary: RodantexColors.secondary,
      onPrimary: RodantexColors.textOnLime,
      secondary: RodantexColors.info,
      onSecondary: RodantexColors.textInverse,
      tertiary: RodantexColors.accent,
      error: RodantexColors.danger,
      surface: RodantexColors.bgSurface,
      onSurface: RodantexColors.textPrimary,
      onSurfaceVariant: RodantexColors.textSecondary,
      outline: RodantexColors.border,
      outlineVariant: RodantexColors.bgSubtle,
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme colorScheme) {
    final body = base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return body.copyWith(
      displaySmall: body.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: body.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineSmall: body.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: body.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      labelMedium: body.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: body.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
