import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/core/theme/rodantex_colors.dart';

/// Contenedor de las pestañas principales con barra de navegación inferior.
///
/// [StatefulShellRoute] mantiene el estado de cada pestaña (scroll, filtros,
/// datos ya cargados) al cambiar entre ellas. Las pestañas se definen en
/// [AppRouter.tabs] y sus rutas en `AppRouter.routes`.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        currentIndex: navigationShell.currentIndex,
        // `initialLocation: true` vuelve a la raíz de la pestaña al tocarla
        // de nuevo, igual que en las apps nativas.
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onSelected,
          height: 68,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: RodantexColors.secondaryLight,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final tab in AppRouterTabs.all)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(
                  tab.selectedIcon,
                  color: RodantexColors.primary,
                ),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Definición de una pestaña del shell.
class AppTab {
  const AppTab({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}

/// Pestañas de la app, en el mismo orden con que se declaran en el router.
abstract final class AppRouterTabs {
  static const dashboard = AppTab(
    label: 'Inicio',
    path: AppRoutes.dashboard,
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
  );

  static const vehicles = AppTab(
    label: 'Vehículos',
    path: AppRoutes.vehicles,
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping_rounded,
  );

  static const routes = AppTab(
    label: 'Rutas',
    path: AppRoutes.routes,
    icon: Icons.route_outlined,
    selectedIcon: Icons.route_rounded,
  );

  static const more = AppTab(
    label: 'Más',
    path: AppRoutes.more,
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
  );

  static const all = [dashboard, vehicles, routes, more];
}
