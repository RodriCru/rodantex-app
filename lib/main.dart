import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/rodantex_colors.dart';
import 'core/theme/rodantex_theme.dart';

void main() {
  runApp(const RodantexApp());
}

class RodantexApp extends StatelessWidget {
  const RodantexApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AppBar y superficies son claras: iconos oscuros en la status bar.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Rodantex',
      debugShowCheckedModeBanner: false,
      theme: RodantexTheme.light,
      darkTheme: RodantexTheme.dark,
      themeMode: ThemeMode.system,
      home: const _ThemePreviewPage(),
    );
  }
}

/// Pantalla temporal para validar el tema hasta definir la UI real.
class _ThemePreviewPage extends StatelessWidget {
  const _ThemePreviewPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget swatch(String label, Color color) => Expanded(
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Rodantex')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Paleta Fusion', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              swatch('Graphite', RodantexColors.primary),
              const SizedBox(width: 8),
              swatch('Lime', RodantexColors.secondary),
              const SizedBox(width: 8),
              swatch('Teal', RodantexColors.info),
              const SizedBox(width: 8),
              swatch('Amber', RodantexColors.accent),
              const SizedBox(width: 8),
              swatch('Coral', RodantexColors.danger),
            ],
          ),
          const SizedBox(height: 24),
          Text('Tipografía Manrope', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Control · Gestión · Movilidad',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Primario')),
              OutlinedButton(onPressed: () {}, child: const Text('Secundario')),
              TextButton(onPressed: () {}, child: const Text('Texto')),
            ],
          ),
        ],
      ),
    );
  }
}
