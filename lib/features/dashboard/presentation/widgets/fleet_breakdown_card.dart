import 'package:flutter/material.dart';

import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/core/theme/rodantex_palette.dart';
import 'package:rodantex_app/features/dashboard/data/models/fleet_summary.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/dashboard_section.dart';

/// Distribución de la flota por estado operativo.
///
/// Reutiliza las cifras de `summary.fleet`, así el bloque concuerda siempre con
/// el KPI "Vehículos" de la misma respuesta.
class FleetBreakdownCard extends StatelessWidget {
  const FleetBreakdownCard({super.key, required this.fleet});

  final FleetSummary fleet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = [
      _FleetEntry(
        label: 'Operativos',
        value: fleet.operational,
        color: RodantexColors.info,
      ),
      _FleetEntry(
        label: 'En mantenimiento',
        value: fleet.inMaintenance,
        color: RodantexColors.accent,
      ),
      _FleetEntry(
        label: 'Ociosos',
        value: fleet.idle,
        color: RodantexColors.textMuted,
      ),
      _FleetEntry(
        label: 'Dados de baja',
        value: fleet.retired,
        color: RodantexColors.danger,
      ),
    ];

    return DashboardSection(
      title: 'Estado de la flota',
      subtitle: '${fleet.total} vehículos registrados',
      child: fleet.total == 0
          ? const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Aún no hay vehículos registrados',
              tone: RodantexBadgeTone.idle,
            )
          : Column(
              children: [
                _StackedBar(entries: entries, total: fleet.total),
                const SizedBox(height: 16),
                for (final entry in entries) ...[
                  _FleetRow(entry: entry, total: fleet.total),
                  if (entry != entries.last) const SizedBox(height: 10),
                ],
                if (fleet.inMaintenance > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${fleet.inMaintenance} de ${fleet.total} vehículos en taller',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _FleetEntry {
  const _FleetEntry({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.entries, required this.total});

  final List<_FleetEntry> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Distribución de la flota por estado',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 10,
          child: Row(
            children: [
              for (final entry in entries)
                if (entry.value > 0)
                  Expanded(
                    flex: entry.value,
                    child: ColoredBox(color: entry.color),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetRow extends StatelessWidget {
  const _FleetRow({required this.entry, required this.total});

  final _FleetEntry entry;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = total == 0 ? 0 : (entry.value / total * 100).round();
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: entry.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(entry.label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          '${entry.value}',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 38,
          child: Text(
            '$percent %',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
