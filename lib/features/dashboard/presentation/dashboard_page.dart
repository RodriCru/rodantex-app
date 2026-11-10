import 'package:flutter/material.dart';

import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/core/theme/rodantex_palette.dart';
import 'package:rodantex_app/features/dashboard/data/dashboard_repository.dart';
import 'package:rodantex_app/features/dashboard/data/models/spending_summary.dart';
import 'package:rodantex_app/features/dashboard/data/models/summary.dart';
import 'package:rodantex_app/features/dashboard/presentation/dashboard_controller.dart';
import 'package:rodantex_app/features/dashboard/presentation/load_status.dart';
import 'package:rodantex_app/features/dashboard/presentation/money_formatter.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/fleet_breakdown_card.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/maintenance_card.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/spending_chart.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/spending_formatters.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/staff_card.dart';

/// Pantalla de inicio: el dashboard que ve el usuario al entrar.
///
/// Estructura (se adapta de 1 a 3 columnas según el ancho):
/// 1. Saludo y periodo del resumen.
/// 2. KPIs: flota, gasto en llantas, gasto en mantenimiento y personal.
/// 3. Gráfica de gasto mensual + estado de la flota.
/// 4. Vehículos en mantenimiento + personal.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.auth,
    required this.dashboardRepository,
  });

  final AuthController auth;

  /// Repository del dashboard (en la app, el del `ApiClient` compartido).
  final DashboardRepository dashboardRepository;

  /// Roles que pueden ver el dashboard. Los demás ven un aviso en su lugar.
  static const allowedRoles = {
    UserRole.superAdmin,
    UserRole.owner,
    UserRole.manager,
    UserRole.accountant,
  };

  /// Roles que además ven las cifras económicas del periodo.
  static const spendingRoles = {
    UserRole.superAdmin,
    UserRole.owner,
    UserRole.accountant,
  };

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(widget.dashboardRepository);
    if (_canView) {
      // La primera carga se lanza después del primer frame para no notificar
      // a los listeners durante la construcción del árbol.
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canView => DashboardPage.allowedRoles.contains(widget.auth.role);

  bool get _canSeeSpending =>
      DashboardPage.spendingRoles.contains(widget.auth.role);

  Future<void> _refresh() => _controller.load(refresh: true);

  @override
  Widget build(BuildContext context) {
    if (!_canView) {
      return Scaffold(
        appBar: _DashboardAppBar(auth: widget.auth, onRefresh: null),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.dashboard_customize_outlined,
              title: 'El dashboard no está disponible para tu rol',
              description: 'Usa la barra inferior para ir a tus módulos.',
              tone: RodantexBadgeTone.idle,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _DashboardAppBar(auth: widget.auth, onRefresh: _refresh),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.summaryStatus != LoadStatus.success) {
            return const _DashboardSkeleton();
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _DashboardContent(
              controller: _controller,
              auth: widget.auth,
              canSeeSpending: _canSeeSpending,
            ),
          );
        },
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar({required this.auth, required this.onRefresh});

  final AuthController auth;
  final Future<void> Function()? onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      titleSpacing: 20,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Rodantex', style: theme.textTheme.titleLarge),
          Text(
            auth.user?.tenant ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        if (onRefresh != null)
          IconButton(
            tooltip: 'Actualizar',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        _UserMenu(auth: auth),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Avatar con iniciales y menú de sesión (rol + cerrar sesión).
class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.auth});

  final AuthController auth;

  String get _initials {
    final name = auth.user?.name.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    final letters = parts.take(2).map((part) => part[0]).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: auth.user?.name ?? 'Sesión',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'logout') auth.logout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auth.user?.name ?? 'Usuario', style: theme.textTheme.titleSmall),
              Text(
                auth.role.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20),
              SizedBox(width: 10),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: RodantexColors.primary,
        child: Text(
          _initials,
          style: theme.textTheme.labelMedium?.copyWith(
            color: RodantexColors.textInverse,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Contenido con scroll: el layout que comparten todas las tarjetas.
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.controller,
    required this.auth,
    required this.canSeeSpending,
  });

  final DashboardController controller;
  final AuthController auth;
  final bool canSeeSpending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName =
        (auth.user?.name.trim().split(RegExp(r'\s+')).firstOrNull) ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        // > 1100 px: 3 columnas · > 760 px: 2 columnas · resto: 1 columna.
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        final gap = 16.0;

        /// Reparte [items] en filas de hasta [columns] tarjetas del mismo ancho.
        /// Cada hijo ya viene sin `Expanded`: el helper lo añade en filas y lo
        /// omite en columna, para no anidar dos `Expanded` en el mismo eje.
        Widget grid(List<Widget> items) {
          if (columns == 1) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  items[i],
                ],
              ],
            );
          }
          final rows = <Widget>[];
          for (var i = 0; i < items.length; i += columns) {
            final chunk = items.sublist(i, (i + columns).clamp(0, items.length));
            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    if (j < chunk.length)
                      Expanded(child: chunk[j])
                    else
                      const Spacer(),
                  ],
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                rows[i],
              ],
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              firstName.isEmpty ? 'Bienvenido' : 'Hola, $firstName',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 2),
            Text(
              _subtitle(),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            grid([
              _KpiFleet(
                status: controller.summaryStatus,
                summary: controller.summary,
              ),
              canSeeSpending
                  ? _KpiSpending(
                      title: 'Gasto en llantas',
                      icon: Icons.tire_repair_rounded,
                      status: controller.summaryStatus,
                      summary: controller.summary,
                      select: (s) => s.tireSpending,
                    )
                  : _kpiRestricted('Gasto en llantas', Icons.tire_repair_rounded),
              canSeeSpending
                  ? _KpiSpending(
                      title: 'Gasto en mantenimiento',
                      icon: Icons.build_circle_outlined,
                      status: controller.summaryStatus,
                      summary: controller.summary,
                      select: (s) => s.maintenanceSpending,
                    )
                  : _kpiRestricted(
                      'Gasto en mantenimiento',
                      Icons.build_circle_outlined,
                    ),
              _StaffKpi(status: controller.summaryStatus, summary: controller.summary),
            ]),
            SizedBox(height: gap),
            grid([
              _SpendingSection(controller: controller),
              _FleetSection(controller: controller),
              _MaintenanceSection(controller: controller),
              _StaffSection(controller: controller),
            ]),
          ],
        );
      },
    );
  }

  String _subtitle() {
    final period = controller.summary?.periodLabel ?? '';
    return period.isEmpty ? 'Resumen de tu operación' : 'Periodo $period';
  }

  Widget _kpiRestricted(String title, IconData icon) {
    return KpiCard(
      label: title,
      value: '—',
      icon: icon,
      accentTone: RodantexBadgeTone.idle,
      footer: const Text('Solo administración'),
    );
  }
}

/// KPI "Vehículos" con el desglose operativos / en taller.
class _KpiFleet extends StatelessWidget {
  const _KpiFleet({required this.status, required this.summary});

  final LoadStatus status;
  final Summary? summary;

  @override
  Widget build(BuildContext context) {
    final fleet = summary?.fleet;
    return KpiCard(
      label: 'Vehículos',
      value: status == LoadStatus.loading || fleet == null ? '—' : '${fleet.total}',
      icon: Icons.local_shipping_rounded,
      accentTone: RodantexBadgeTone.active,
      footer: fleet == null
          ? null
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                TrendPill(
                  icon: Icons.check_circle_outline_rounded,
                  label: '${fleet.operational} operativos',
                  tone: RodantexBadgeTone.available,
                ),
                TrendPill(
                  icon: Icons.build_rounded,
                  label: '${fleet.inMaintenance} en taller',
                  tone: fleet.inMaintenance > 0
                      ? RodantexBadgeTone.maintenance
                      : RodantexBadgeTone.idle,
                ),
              ],
            ),
    );
  }
}

/// KPI de dinero del periodo (llantas o mantenimiento) con su tendencia.
class _KpiSpending extends StatelessWidget {
  const _KpiSpending({
    required this.title,
    required this.icon,
    required this.status,
    required this.summary,
    required this.select,
  });

  final String title;
  final IconData icon;
  final LoadStatus status;
  final Summary? summary;
  final SpendingSummary Function(Summary) select;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = summary == null ? null : select(summary!);
    final loading = status == LoadStatus.loading || data == null;

    Widget? footer;
    if (data != null) {
      final label = data.changeLabel;
      final color = data.tone.color(scheme);
      footer = Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (label != null)
            TrendPill(
              icon: data.trendIcon,
              label: label,
              tone: switch (data.tone) {
                ChangeTone.positive => RodantexBadgeTone.available,
                ChangeTone.negative => RodantexBadgeTone.maintenance,
                ChangeTone.neutral => RodantexBadgeTone.idle,
              },
            ),
          Text(
            switch ((label, data.trend)) {
              (null, _) => 'Sin periodo previo',
              (_, 'UP') => 'más que el periodo anterior',
              (_, 'DOWN') => 'menos que el periodo anterior',
              _ => 'igual que el periodo anterior',
            },
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      );
    }

    return KpiCard(
      label: title,
      value: loading
          ? '—'
          : MoneyFormatter.format(data.amount, currency: summary!.currency),
      icon: icon,
      accentTone: RodantexBadgeTone.maintenance,
      footer: footer,
    );
  }
}

class _SpendingSection extends StatelessWidget {
  const _SpendingSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final history = controller.spending;
    return DashboardSection(
      title: 'Gasto mensual',
      subtitle: history == null
          ? 'Compras vs. mantenimiento'
          : 'Compras vs. mantenimiento · últimos ${history.months.length} meses',
      child: switch (controller.spendingStatus) {
        LoadStatus.loading || LoadStatus.idle => const SkeletonCard(height: 190),
        LoadStatus.failure => ErrorRetry(
          message: controller.spendingError ?? 'No se pudo cargar el gasto.',
          onRetry: () => controller.load(refresh: true),
        ),
        LoadStatus.empty => const EmptyState(
          icon: Icons.bar_chart_rounded,
          title: 'Sin movimientos de gasto',
          description: 'Aún no hay compras ni mantenimientos en el periodo',
          tone: RodantexBadgeTone.idle,
        ),
        LoadStatus.success => SpendingChart(history: history!),
      },
    );
  }
}

class _FleetSection extends StatelessWidget {
  const _FleetSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    return switch (controller.summaryStatus) {
      LoadStatus.loading || LoadStatus.idle || LoadStatus.empty =>
        const DashboardSection(
          title: 'Estado de la flota',
          child: SkeletonCard(height: 190),
        ),
      LoadStatus.failure => DashboardSection(
        title: 'Estado de la flota',
        child: ErrorRetry(
          message: controller.summaryError ?? 'No se pudo cargar la flota.',
          onRetry: () => controller.load(refresh: true),
        ),
      ),
      LoadStatus.success => FleetBreakdownCard(fleet: summary!.fleet),
    };
  }
}

/// KPI "Personal" con la composición por tipo de colaborador.
class _StaffKpi extends StatelessWidget {
  const _StaffKpi({required this.status, required this.summary});

  final LoadStatus status;
  final Summary? summary;

  @override
  Widget build(BuildContext context) {
    final staff = summary?.staff;
    return KpiCard(
      label: 'Personal',
      value: status == LoadStatus.loading || staff == null ? '—' : '${staff.total}',
      icon: Icons.group_rounded,
      accentTone: RodantexBadgeTone.available,
      footer: staff == null
          ? null
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                TrendPill(
                  icon: Icons.badge_outlined,
                  label: '${staff.drivers} conductores',
                  tone: RodantexBadgeTone.available,
                ),
                TrendPill(
                  icon: Icons.build_outlined,
                  label: '${staff.mechanics} mecánicos',
                  tone: staff.mechanics > 0
                      ? RodantexBadgeTone.maintenance
                      : RodantexBadgeTone.idle,
                ),
              ],
            ),
    );
  }
}

class _StaffSection extends StatelessWidget {
  const _StaffSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    return switch (controller.summaryStatus) {
      LoadStatus.loading || LoadStatus.idle || LoadStatus.empty =>
        const DashboardSection(
          title: 'Personal',
          child: SkeletonCard(height: 150),
        ),
      LoadStatus.failure => DashboardSection(
        title: 'Personal',
        child: ErrorRetry(
          message: controller.summaryError ?? 'No se pudo cargar el personal.',
          onRetry: () => controller.load(refresh: true),
        ),
      ),
      LoadStatus.success => StaffCard(staff: summary!.staff),
    };
  }
}

class _MaintenanceSection extends StatelessWidget {
  const _MaintenanceSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.maintenanceStatus) {
      LoadStatus.loading || LoadStatus.idle => const DashboardSection(
        title: 'En mantenimiento',
        child: SkeletonCard(height: 150),
      ),
      LoadStatus.failure => DashboardSection(
        title: 'En mantenimiento',
        child: ErrorRetry(
          message:
              controller.maintenanceError ??
              'No se pudieron cargar los vehículos en taller.',
          onRetry: () => controller.load(refresh: true),
        ),
      ),
      LoadStatus.success || LoadStatus.empty => MaintenanceCard(
        block: controller.maintenance,
        onRetry: () => controller.load(refresh: true),
      ),
    };
  }
}

/// Esqueleto de la primera carga: mantiene la forma del dashboard.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: const [
        SkeletonCard(height: 44),
        SizedBox(height: 20),
        _SkeletonRow(),
        SizedBox(height: 16),
        SkeletonCard(height: 220),
        SizedBox(height: 16),
        SkeletonCard(height: 180),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: SkeletonCard(height: 140)),
        SizedBox(width: 16),
        Expanded(child: SkeletonCard(height: 140)),
        SizedBox(width: 16),
        Expanded(child: SkeletonCard(height: 140)),
      ],
    );
  }
}
