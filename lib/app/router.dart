import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/app/auth_scope.dart';
import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/features/auth/presentation/login_page.dart';
import 'package:rodantex_app/features/home/presentation/home_page.dart';

/// Router central de la app con guardas basadas en la sesión.
///
/// Reglas:
/// - Mientras [AuthStatus.unknown] se muestra el splash.
/// - Sin sesión, todas las rutas redirigen a `/login`.
/// - Con sesión, `/login` y `/` redirigen a `/home`.
/// - Las rutas protegidas se añaden en [routes] siguiendo el ejemplo comentado.
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
    GoRoute(
      path: AppRoutes.home,
      name: RouteNames.home,
      builder: (context, state) => HomePage(auth: AuthScope.of(context)),
    ),
    // Ruta con parámetro de id (ejemplo):
    // GoRoute(
    //   path: AppRoutes.vehicleDetailPath,
    //   name: RouteNames.vehicleDetail,
    //   builder: (context, state) =>
    //       VehicleDetailPage(id: state.pathParameters['id']!),
    // ),
  ];

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.uri.path;
    final isLogin = location == AppRoutes.login;
    final isSplash = location == AppRoutes.splash;

    return switch (_auth.status) {
      AuthStatus.unknown => isSplash ? null : AppRoutes.splash,
      AuthStatus.unauthenticated => isLogin ? null : AppRoutes.login,
      AuthStatus.authenticated => (isLogin || isSplash) ? AppRoutes.home : null,
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
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
