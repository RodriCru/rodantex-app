import 'package:flutter/foundation.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/maintenances/data/maintenance_repository.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance.dart';

/// Estado de listado, búsqueda y paginación de mantenimientos.
class MaintenanceController extends ChangeNotifier {
  MaintenanceController(this._repository);

  final MaintenanceRepository _repository;
  static const pageSize = 20;

  /// Elementos cargados de las páginas solicitadas.
  List<Maintenance> items = const [];

  /// Indicadores de actividad de la carga inicial y carga incremental.
  bool isLoading = false;
  bool isLoadingMore = false;

  /// Error legible para la página.
  String? error;

  /// Búsqueda aplicada.
  String search = '';

  /// Cantidad total reportada por el servidor.
  int total = 0;
  int _page = 1;
  bool _hasNextPage = false;
  bool _disposed = false;

  /// Indica si hay más resultados por pedir.
  bool get hasNextPage => _hasNextPage;

  /// Carga o reinicia la lista con el término de búsqueda dado.
  Future<void> load({String? search}) async {
    if (isLoading || isLoadingMore) return;
    if (search != null) this.search = search.trim();
    isLoading = true;
    error = null;
    items = const [];
    _notify();
    try {
      final result = await _repository.list(
        page: 1,
        limit: pageSize,
        search: this.search,
      );
      items = result.items;
      total = result.total;
      _page = result.page;
      _hasNextPage = result.hasNextPage;
    } on ApiException catch (exception) {
      error = exception.message;
    } on Object {
      error = 'No se pudieron cargar los mantenimientos.';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  /// Añade la página siguiente sin retirar lo ya cargado.
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !_hasNextPage) return;
    isLoadingMore = true;
    error = null;
    _notify();
    try {
      final result = await _repository.list(
        page: _page + 1,
        limit: pageSize,
        search: search,
      );
      items = [...items, ...result.items];
      total = result.total;
      _page = result.page;
      _hasNextPage = result.hasNextPage;
    } on ApiException catch (exception) {
      error = exception.message;
    } on Object {
      error = 'No se pudieron cargar más mantenimientos.';
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
