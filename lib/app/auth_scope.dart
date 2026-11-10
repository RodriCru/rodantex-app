import 'package:flutter/widgets.dart';

import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/features/dashboard/data/dashboard_repository.dart';
import 'package:rodantex_app/features/maintenances/data/maintenance_repository.dart';
import 'package:rodantex_app/features/inspections/data/inspection_repository.dart';
import 'package:rodantex_app/features/profile/data/profile_repository.dart';
import 'package:rodantex_app/features/vehicles/data/vehicle_repository.dart';
import 'package:rodantex_app/features/routes/data/routes_repository.dart';

/// Expone las dependencias globales ([AuthController] y [ApiClient]) a todo el
/// árbol, incluidas las rutas de go_router, sin pasarlas widget a widget.
class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.auth,
    required this.apiClient,
    required super.child,
  });

  final AuthController auth;

  /// Cliente HTTP compartido (con Bearer y refresh automático).
  final ApiClient apiClient;

  static AuthScope _of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope no encontrado en el árbol de widgets.');
    return scope!;
  }

  static AuthController of(BuildContext context) => _of(context).auth;

  /// Repository del dashboard ya conectado al cliente HTTP compartido.
  ///
  /// Los controllers lo reciben por constructor, así en tests se puede pasar
  /// un repository falso sin tocar este método.
  static DashboardRepository dashboardRepository(BuildContext context) =>
      DashboardRepository(_of(context).apiClient);

  /// Repository de vehículos conectado al cliente HTTP compartido.
  static VehicleRepository vehicleRepository(BuildContext context) =>
      VehicleRepository(_of(context).apiClient);

  /// Repository de consulta de rutas y viajes.
  static RoutesRepository routesRepository(BuildContext context) =>
      RoutesRepository(_of(context).apiClient);

  /// Repository de servicios de mantenimiento conectado al cliente compartido.
  static MaintenanceRepository maintenanceRepository(BuildContext context) =>
      MaintenanceRepository(_of(context).apiClient);

  /// Repository de inspecciones y reglas de llantas.
  static InspectionRepository inspectionRepository(BuildContext context) =>
      InspectionRepository(_of(context).apiClient);

  /// Repository del perfil del usuario autenticado.
  static ProfileRepository profileRepository(BuildContext context) =>
      ProfileRepository(_of(context).apiClient);

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      oldWidget.auth != auth || oldWidget.apiClient != apiClient;
}
