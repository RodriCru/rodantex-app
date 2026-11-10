import 'package:flutter/foundation.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/dashboard/data/dashboard_repository.dart';
import 'package:rodantex_app/features/dashboard/data/models/paged_block.dart';
import 'package:rodantex_app/features/dashboard/data/models/spending_history.dart';
// `foundation` también exporta `Summary`: se importa con prefijo.
import 'package:rodantex_app/features/dashboard/data/models/summary.dart'
    as dashboard;
import 'package:rodantex_app/features/dashboard/data/models/vehicle_in_maintenance.dart';
import 'package:rodantex_app/features/dashboard/presentation/load_status.dart';

/// Estado de la pantalla Dashboard (inicio).
///
/// Carga **en paralelo** los tres bloques del dashboard y expone cada uno con
/// su propio estado, para que una tarjeta con error no tumbe a las demás:
///
/// - `summaryStatus` → KPIs (flota, gasto del periodo, personal).
/// - `spendingStatus` → gráfica de gasto mensual.
/// - `maintenanceStatus` → lista de vehículos en mantenimiento.
///
/// [load] es idempotente frente a recargas concurrentes: si ya hay una carga en
/// curso, la nueva la espera en lugar de disparar otra tanda de peticiones.
class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);

  final DashboardRepository _repository;

  /// Cuántos vehículos pide la tarjeta de mantenimiento.
  static const maintenanceLimit = 6;

  /// Meses que pide la gráfica de gasto.
  static const spendingMonths = 6;

  LoadStatus summaryStatus = LoadStatus.idle;
  dashboard.Summary? summary;
  String? summaryError;

  LoadStatus spendingStatus = LoadStatus.idle;
  SpendingHistory? spending;
  String? spendingError;

  LoadStatus maintenanceStatus = LoadStatus.idle;

  /// Vehículos en mantenimiento y el total real del backend.
  PagedBlock<VehicleInMaintenance> maintenance = PagedBlock(
    total: 0,
    items: const [],
  );
  String? maintenanceError;

  /// Depósito por el que se filtra; `null` = todos los del tenant.
  ///
  /// Ya se envía como query param a los endpoints, pero aún no hay selector en
  /// la UI porque falta el endpoint de depósitos.
  String? depotId;

  bool _isLoading = false;
  bool _disposed = false;

  /// `true` mientras hay una carga en curso.
  bool get isLoading => _isLoading;

  /// `true` cuando al menos un bloque está en estado de error.
  bool get hasError =>
      summaryStatus == LoadStatus.failure ||
      spendingStatus == LoadStatus.failure ||
      maintenanceStatus == LoadStatus.failure;

  /// Recarga todo el dashboard con un filtro [depotId] opcional.
  Future<void> load({String? depotId, bool refresh = false}) async {
    if (depotId != null) this.depotId = depotId;
    if (_isLoading && !refresh) return;

    _isLoading = true;
    if (!refresh) {
      // En un refresco (pull-to-refresh) se conservan los datos en pantalla y
      // solo se actualizan al llegar la respuesta; en la primera carga se
      // muestran los skeletons.
      summaryStatus = LoadStatus.loading;
      spendingStatus = LoadStatus.loading;
      maintenanceStatus = LoadStatus.loading;
    }
    _safeNotify();

    await Future.wait([
      _loadSummary(),
      _loadSpending(),
      _loadMaintenance(),
    ]);

    _isLoading = false;
    _safeNotify();
  }

  Future<void> _loadSummary() async {
    try {
      final data = await _repository.summary(depotId: depotId);
      summary = data;
      summaryError = null;
      summaryStatus = LoadStatus.success;
    } on ApiException catch (error) {
      summaryError = error.message;
      summaryStatus = LoadStatus.failure;
    } on Object {
      summaryError = 'No se pudo cargar el resumen.';
      summaryStatus = LoadStatus.failure;
    }
  }

  Future<void> _loadSpending() async {
    try {
      final data = await _repository.spending(
        depotId: depotId,
        months: spendingMonths,
      );
      spending = data;
      spendingError = null;
      spendingStatus = data.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } on ApiException catch (error) {
      spendingError = error.message;
      spendingStatus = LoadStatus.failure;
    } on Object {
      spendingError = 'No se pudo cargar el gasto.';
      spendingStatus = LoadStatus.failure;
    }
  }

  Future<void> _loadMaintenance() async {
    try {
      final block = await _repository.vehiclesInMaintenance(
        depotId: depotId,
        limit: maintenanceLimit,
      );
      maintenance = block;
      maintenanceError = null;
      maintenanceStatus = block.isEmpty
          ? LoadStatus.empty
          : LoadStatus.success;
    } on ApiException catch (error) {
      maintenanceError = error.message;
      maintenanceStatus = LoadStatus.failure;
    } on Object {
      maintenanceError = 'No se pudieron cargar los vehículos en taller.';
      maintenanceStatus = LoadStatus.failure;
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
