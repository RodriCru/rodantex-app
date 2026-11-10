import 'package:flutter/material.dart';

import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/core/theme/rodantex_palette.dart';

/// Página provisional para módulos aún no construidos.
///
/// Se usa en las pestañas del shell (Vehículos, Rutas, Más) mientras llegan sus
/// endpoints y pantallas, para que la navegación no lleve a un 404.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: RodantexBadgeTone.available.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: RodantexColors.infoDark),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
