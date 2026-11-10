import 'package:flutter/foundation.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/maintenances/data/maintenance_repository.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance_order.dart';

/// Coordina la consulta y paginación de órdenes de mantenimiento.
class MaintenanceOrderController extends ChangeNotifier {
  MaintenanceOrderController(this._repository);

  final MaintenanceRepository _repository;
  static const pageSize = 20;

  /// Órdenes cargadas.
  List<MaintenanceOrder> items = const [];

  /// Indica si está cargando la primera página.
  bool isLoading = false;

  /// Indica si está cargando otra página.
  bool isLoadingMore = false;

  /// Mensaje de error para mostrar en pantalla.
  String? error;

  /// Texto de búsqueda vigente.
  String search = '';

  /// Total reportado por la API.
  int total = 0;

  bool _hasNextPage = false;
  int _page = 1;
  bool _disposed = false;

  /// Indica si hay otra página disponible.
  bool get hasNextPage => _hasNextPage;

  /// Carga o reinicia las órdenes.
  Future<void> load({String? search}) async {
    if (isLoading || isLoadingMore) return;
    if (search != null) this.search = search.trim();
    isLoading = true;
    error = null;
    items = const [];
    _notify();
    try {
      final result = await _repository.listOrders(search: this.search, limit: pageSize);
      items = result.items;
      total = result.total;
      _page = result.page;
      _hasNextPage = result.hasNextPage;
    } on ApiException catch (exception) {
      error = exception.message;
    } on Object {
      error = 'No se pudieron cargar las órdenes de mantenimiento.';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  /// Añade la página siguiente.
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !_hasNextPage) return;
    isLoadingMore = true;
    _notify();
    try {
      final result = await _repository.listOrders(page: _page + 1, limit: pageSize, search: search);
      items = [...items, ...result.items];
      total = result.total;
      _page = result.page;
      _hasNextPage = result.hasNextPage;
    } on ApiException catch (exception) {
      error = exception.message;
    } on Object {
      error = 'No se pudieron cargar más órdenes.';
    } finally {
      isLoadingMore = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
