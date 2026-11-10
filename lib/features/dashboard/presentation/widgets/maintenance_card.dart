import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/core/theme/rodantex_palette.dart';
import 'package:rodantex_app/features/dashboard/data/models/paged_block.dart';
import 'package:rodantex_app/features/dashboard/data/models/vehicle_in_maintenance.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/dashboard_section.dart';

/// Tarjeta "En mantenimiento": vehículos en taller con sus días acumulados.
///
/// El badge de días usa la paleta semántica:
/// - ≤ 7 días → amber (mantenimiento normal).
/// - 8 – 14 días → naranja de retraso.
/// - > 14 días → coral (crítico).
class MaintenanceCard extends StatelessWidget {
  const MaintenanceCard({
    super.key,
    required this.block,
    required this.onRetry,
  });

  final PagedBlock<VehicleInMaintenance> block;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardSection(
      title: 'En mantenimiento',
      subtitle: block.total == 0
          ? 'Sin vehículos en taller'
          : '${block.total} vehículos en taller',
      action: block.hasMore
          ? Text(
              'Ver todos',
              style: theme.textTheme.labelMedium?.copyWith(
                color: RodantexColors.infoDark,
              ),
            )
          : null,
      child: block.isEmpty
          ? const EmptyState(
              icon: Icons.verified_rounded,
              title: 'Todo al día',
              description: 'Ningún vehículo en mantenimiento',
              tone: RodantexBadgeTone.available,
            )
          : Column(
              children: [
                for (var i = 0; i < block.items.length; i++) ...[
                  _MaintenanceRow(vehicle: block.items[i]),
                  if (i < block.items.length - 1) const SizedBox(height: 4),
                ],
              ],
            ),
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({required this.vehicle});

  final VehicleInMaintenance vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = switch (vehicle.daysInMaintenance) {
      > 14 => RodantexBadgeTone.incident,
      > 7 => RodantexBadgeTone.delay,
      _ => RodantexBadgeTone.maintenance,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      // La ruta de detalle aún no existe; cuando se cree, este push ya apunta a
      // ella gracias a AppRoutes.vehicleDetail.
      onTap: vehicle.vehicleId.isEmpty
          ? null
          : () => context.push(AppRoutes.vehicleDetail(vehicle.vehicleId)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: RodantexColors.bgSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: RodantexColors.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.plate,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${vehicle.displayName} · Eco ${vehicle.numberEco}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    vehicle.depotName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _DaysBadge(days: vehicle.daysInMaintenance, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  const _DaysBadge({required this.days, required this.tone});

  final int days;
  final RodantexBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        days == 1 ? '1 día' : '$days días',
        style: theme.textTheme.labelMedium?.copyWith(
          color: tone.foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
