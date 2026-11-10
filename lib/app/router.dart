import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/app/app_shell.dart';
import 'package:rodantex_app/app/auth_scope.dart';
import 'package:rodantex_app/app/more_page.dart';
import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/features/auth/presentation/login_page.dart';
import 'package:rodantex_app/features/dashboard/presentation/dashboard_page.dart';
import 'package:rodantex_app/features/maintenances/presentation/maintenance_detail_page.dart';
import 'package:rodantex_app/features/maintenances/presentation/maintenance_orders_page.dart';
import 'package:rodantex_app/features/inspections/presentation/inspection_detail_page.dart';
import 'package:rodantex_app/features/inspections/presentation/inspection_rules_page.dart';
import 'package:rodantex_app/features/inspections/presentation/inspections_page.dart';
import 'package:rodantex_app/features/profile/presentation/profile_page.dart';
import 'package:rodantex_app/features/routes/presentation/routes_page.dart';
import 'package:rodantex_app/features/vehicles/presentation/vehicle_detail_page.dart';
import 'package:rodantex_app/features/vehicles/presentation/vehicles_page.dart';

/// Router central de la app con guardas basadas en la sesión.
///
/// Reglas:
/// - Mientras [AuthStatus.unknown] se muestra el splash.
/// - Sin sesión, todas las rutas redirigen a `/login`.
/// - Con sesión, `/login` y `/` redirigen a `/home`; `/home` abre el dashboard.
/// - Las pestañas del shell viven bajo `/home/...` y conservan su estado.
class AppRouter {
  AppRouter({required AuthController auth}) : _auth = auth {
    _router = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: auth,
      redirect: _redirect,
      routes: routes,
      errorBuilder: (context, state) => NotFoundPage(location: state.uri.path),
    );
  }

  final AuthController _auth;
  late final GoRouter _router;

  GoRouter get router => _router;

  /// Rutas de la app. Añadir aquí las pantallas nuevas.
  static final List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: RouteNames.login,
      builder: (context, state) => LoginPage(auth: AuthScope.of(context)),
    ),
    StatefulShellRoute.indexedStack(
      // `navigationShell` es la rama activa: `AppShell` conserva su estado.
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: RouteNames.dashboard,
              builder: (context, state) => DashboardPage(
                auth: AuthScope.of(context),
                dashboardRepository: AuthScope.dashboardRepository(context),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.vehicles,
              name: RouteNames.vehicles,
              builder: (context, state) => VehiclesPage(
                vehicleRepository: AuthScope.vehicleRepository(context),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  name: RouteNames.vehicleDetail,
                  builder: (context, state) => VehicleDetailPage(
                    vehicleRepository: AuthScope.vehicleRepository(context),
                    vehicleId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.routes,
              name: RouteNames.routes,
              builder: (context, state) => RoutesPage(
                repository: AuthScope.routesRepository(context),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.more,
              name: RouteNames.more,
              builder: (context, state) => const MorePage(),
              routes: [
                GoRoute(
                  path: 'maintenances',
                  name: RouteNames.maintenances,
                  builder: (context, state) => MaintenanceOrdersPage(
                    repository: AuthScope.maintenanceRepository(context),
                  ),
                  routes: [
                    GoRoute(
                      path: ':id',
                      name: RouteNames.maintenanceDetail,
                      builder: (context, state) => MaintenanceDetailPage(
                        repository: AuthScope.maintenanceRepository(context),
                        maintenanceId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'inspections',
                  name: RouteNames.inspections,
                  builder: (context, state) => InspectionsPage(
                    repository: AuthScope.inspectionRepository(context),
                  ),
                  routes: [
                    GoRoute(
                      path: 'rules',
                      name: RouteNames.inspectionRules,
                      builder: (context, state) => InspectionRulesPage(
                        repository: AuthScope.inspectionRepository(context),
                      ),
                    ),
                    GoRoute(
                      path: ':id',
                      name: RouteNames.inspectionDetail,
                      builder: (context, state) => InspectionDetailPage(
                        repository: AuthScope.inspectionRepository(context),
                        inspectionId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'profile',
                  name: RouteNames.profile,
                  builder: (context, state) => ProfilePage(
                    auth: AuthScope.of(context),
                    repository: AuthScope.profileRepository(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.path;
    final isLogin = location == AppRoutes.login;
    final isSplash = location == AppRoutes.splash;

    // `/home` es la raíz del shell: lleva al dashboard.
    if (location == AppRoutes.home) return AppRoutes.dashboard;

    return switch (_auth.status) {
      AuthStatus.unknown => isSplash ? null : AppRoutes.splash,
      AuthStatus.unauthenticated => isLogin ? null : AppRoutes.login,
      AuthStatus.authenticated =>
        (isLogin || isSplash) ? AppRoutes.dashboard : null,
    };
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_off_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No encontramos "$location"',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
