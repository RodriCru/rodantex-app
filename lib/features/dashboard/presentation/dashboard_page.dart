import 'package:flutter/material.dart';

import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/core/theme/rodantex_palette.dart';
import 'package:rodantex_app/features/dashboard/data/dashboard_repository.dart';
import 'package:rodantex_app/features/dashboard/presentation/dashboard_controller.dart';
import 'package:rodantex_app/features/dashboard/presentation/load_status.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/fleet_breakdown_card.dart';
import 'package:rodantex_app/features/dashboard/presentation/widgets/maintenance_card.dart';

/// Pantalla de inicio: el dashboard que ve el usuario al entrar.
///
/// Estructura (se adapta de 1 a 2 columnas según el ancho):
/// 1. Saludo y periodo del resumen.
/// 2. Estado de la flota y vehículos en mantenimiento.
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
          if (_controller.isLoading &&
              _controller.summaryStatus != LoadStatus.success) {
            return const _DashboardSkeleton();
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _DashboardContent(
              controller: _controller,
              auth: widget.auth,
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
              Text(
                auth.user?.name ?? 'Usuario',
                style: theme.textTheme.titleSmall,
              ),
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
  const _DashboardContent({required this.controller, required this.auth});

  final DashboardController controller;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName =
        (auth.user?.name.trim().split(RegExp(r'\s+')).firstOrNull) ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        // En móviles usa una columna; en pantallas amplias, dos.
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
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
            final chunk = items.sublist(
              i,
              (i + columns).clamp(0, items.length),
            );
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
            Text(_subtitle(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            grid([
              _FleetSection(controller: controller),
              _MaintenanceSection(controller: controller),
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
}

class _FleetSection extends StatelessWidget {
  const _FleetSection({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    return switch (controller.summaryStatus) {
      LoadStatus.loading ||
      LoadStatus.idle ||
      LoadStatus.empty => const DashboardSection(
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
        SkeletonCard(height: 220),
        SizedBox(height: 16),
        SkeletonCard(height: 180),
      ],
    );
  }
}
