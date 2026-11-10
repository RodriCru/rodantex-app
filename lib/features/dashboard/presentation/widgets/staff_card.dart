import 'package:flutter/material.dart';

import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/core/theme/rodantex_palette.dart';
import 'package:rodantex_app/features/dashboard/data/models/staff_summary.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/dashboard_section.dart';

/// Composición del personal: conductores, mecánicos y administradores.
class StaffCard extends StatelessWidget {
  const StaffCard({super.key, required this.staff});

  final StaffSummary staff;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Personal',
      subtitle: '${staff.total} personas en la empresa',
      child: staff.total == 0
          ? const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Sin personal registrado',
              tone: RodantexBadgeTone.idle,
            )
          : Column(
              children: [
                _StaffRow(
                  label: 'Conductores',
                  value: staff.drivers,
                  total: staff.total,
                  tone: RodantexBadgeTone.available,
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _StaffRow(
                  label: 'Mecánicos',
                  value: staff.mechanics,
                  total: staff.total,
                  tone: RodantexBadgeTone.maintenance,
                  icon: Icons.build_outlined,
                ),
                const SizedBox(height: 12),
                _StaffRow(
                  label: 'Administración',
                  value: staff.admins,
                  total: staff.total,
                  tone: RodantexBadgeTone.active,
                  icon: Icons.workspace_premium_outlined,
                ),
              ],
            ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.label,
    required this.value,
    required this.total,
    required this.tone,
    required this.icon,
  });

  final String label;
  final int value;
  final int total;
  final RodantexBadgeTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: RodantexColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text('$value', style: theme.textTheme.titleSmall),
            Text(
              ' / $total',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DistributionBar(
          color: tone.foreground,
          value: value,
          total: total,
        ),
      ],
    );
  }
}
