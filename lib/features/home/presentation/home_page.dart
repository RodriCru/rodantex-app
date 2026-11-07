import 'package:flutter/material.dart';

import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/core/theme/rodantex_palette.dart';

/// Home provisional: valida la sesión y muestra las opciones según el rol.
///
/// Las secciones definen qué módulos verá cada rol; los iconos son temporales
/// hasta construir cada pantalla.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.auth});

  final AuthController auth;

  static const _sectionsByRole =
      <UserRole, List<({String label, IconData icon})>>{
        UserRole.superAdmin: [
          (label: 'Tenants', icon: Icons.business_rounded),
          (label: 'Suscripciones', icon: Icons.receipt_long_rounded),
          (label: 'Usuarios', icon: Icons.manage_accounts_rounded),
          (label: 'Configuración', icon: Icons.settings_rounded),
        ],
        UserRole.owner: [
          (label: 'Dashboard', icon: Icons.insights_rounded),
          (label: 'Vehículos', icon: Icons.local_shipping_rounded),
          (label: 'Rutas', icon: Icons.route_rounded),
          (label: 'Mantenimiento', icon: Icons.build_rounded),
          (label: 'Documentos', icon: Icons.description_rounded),
          (label: 'Usuarios', icon: Icons.people_alt_rounded),
          (label: 'Reportes', icon: Icons.bar_chart_rounded),
        ],
        UserRole.manager: [
          (label: 'Dashboard', icon: Icons.insights_rounded),
          (label: 'Vehículos', icon: Icons.local_shipping_rounded),
          (label: 'Rutas', icon: Icons.route_rounded),
          (label: 'Mantenimiento', icon: Icons.build_rounded),
          (label: 'Documentos', icon: Icons.description_rounded),
          (label: 'Reportes', icon: Icons.bar_chart_rounded),
        ],
        UserRole.driver: [
          (label: 'Mis viajes', icon: Icons.route_rounded),
          (label: 'Mi vehículo', icon: Icons.local_shipping_rounded),
          (label: 'Incidencias', icon: Icons.report_problem_rounded),
          (label: 'Documentos', icon: Icons.description_rounded),
        ],
        UserRole.mechanic: [
          (label: 'Mantenimiento', icon: Icons.build_rounded),
          (label: 'Órdenes', icon: Icons.assignment_rounded),
          (label: 'Inventario', icon: Icons.inventory_2_rounded),
          (label: 'Vehículos', icon: Icons.local_shipping_rounded),
        ],
        UserRole.accountant: [
          (label: 'Dashboard', icon: Icons.insights_rounded),
          (label: 'Gastos', icon: Icons.payments_rounded),
          (label: 'Reportes', icon: Icons.bar_chart_rounded),
          (label: 'Documentos', icon: Icons.description_rounded),
        ],
        UserRole.unknown: [],
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = auth.user;
    final sections = _sectionsByRole[auth.role] ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rodantex'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: auth.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${user?.name ?? 'usuario'}',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(user?.tenant ?? '', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  _RoleBadge(role: auth.role),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tu espacio', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (sections.isEmpty)
            Text(
              'No hay opciones disponibles para tu rol.',
              style: theme.textTheme.bodyMedium,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720
                    ? 3
                    : constraints.maxWidth >= 450
                    ? 2
                    : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 3.2 : 2.2,
                  children: [
                    for (final section in sections)
                      _SectionTile(label: section.label, icon: section.icon),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final tone = switch (role) {
      UserRole.superAdmin || UserRole.owner => RodantexBadgeTone.active,
      UserRole.manager || UserRole.accountant => RodantexBadgeTone.available,
      UserRole.driver => RodantexBadgeTone.delay,
      UserRole.mechanic => RodantexBadgeTone.maintenance,
      UserRole.unknown => RodantexBadgeTone.idle,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: tone.foreground),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label estará disponible pronto')),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RodantexColors.infoDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: RodantexColors.infoDark),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            ],
          ),
        ),
      ),
    );
  }
}
