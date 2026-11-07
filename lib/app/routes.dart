/// Nombres y constructores de rutas de la app.
///
/// Usar siempre estos helpers en lugar de strings sueltos, así un cambio de
/// ruta se hace en un solo lugar.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';

  /// Detalle de una entidad por id, p. ej. `/vehicles/:id`.
  static const vehicleDetailPath = '/vehicles/:id';

  static String vehicleDetail(String id) => '/vehicles/$id';
}

abstract final class RouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const home = 'home';
  static const vehicleDetail = 'vehicle-detail';
}
