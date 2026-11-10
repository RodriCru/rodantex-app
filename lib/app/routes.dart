/// Nombres y constructores de rutas de la app.
///
/// Usar siempre estos helpers en lugar de strings sueltos, así un cambio de
/// ruta se hace en un solo lugar.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';

  /// Raíz del shell autenticado (barra inferior + pestañas).
  static const home = '/home';

  // ===== Pestañas del shell =====
  static const dashboard = '/home/dashboard';
  static const vehicles = '/home/vehicles';
  static const routes = '/home/routes';
  static const more = '/home/more';
  static const maintenances = '/home/more/maintenances';
  static const inspections = '/home/more/inspections';
  static const inspectionRules = '/home/more/inspections/rules';
  static const profile = '/home/more/profile';

  /// Detalle de una entidad por id, p. ej. `/vehicles/:id`.
  static const vehicleDetailPath = '/vehicles/:id';

  static String vehicleDetail(String id) => '$vehicles/$id';

  /// Ruta de detalle de un mantenimiento.
  static String maintenanceDetail(String id) => '$maintenances/$id';

  /// Ruta de detalle de una inspección.
  static String inspectionDetail(String id) => '$inspections/$id';
}

abstract final class RouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const home = 'home';
  static const dashboard = 'dashboard';
  static const vehicles = 'vehicles';
  static const routes = 'routes';
  static const more = 'more';
  static const maintenances = 'maintenances';
  static const maintenanceDetail = 'maintenance-detail';
  static const inspections = 'inspections';
  static const inspectionRules = 'inspection-rules';
  static const inspectionDetail = 'inspection-detail';
  static const profile = 'profile';
  static const vehicleDetail = 'vehicle-detail';
}
