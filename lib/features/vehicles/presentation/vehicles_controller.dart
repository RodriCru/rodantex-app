import 'package:flutter/foundation.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';
import 'package:rodantex_app/features/vehicles/data/vehicle_repository.dart';

/// Estado y acciones de la lista de vehículos.
class VehiclesController extends ChangeNotifier {
  VehiclesController(this._repository);

  final VehicleRepository _repository;
  static const pageSize = 20;

  /// Vehículos de las páginas cargadas.
  List<Vehicle> vehicles = const [];

  /// Estado de carga inicial o de búsqueda.
  bool isLoading = false;

  /// Estado al solicitar más resultados.
  bool isLoadingMore = false;

  /// Mensaje del último error recuperable.
  String? error;

  /// Texto aplicado a la búsqueda del backend.
  String search = '';

  /// Total de coincidencias reportado por el backend.
  int total = 0;
  int _page = 1;
  bool _hasNextPage = false;
  bool _disposed = false;

  /// `true` si el backend tiene más páginas.
  bool get hasNextPage => _hasNextPage;

  /// Carga o reinicia la lista aplicando la búsqueda indicada.
  Future<void> load({String? search, bool refresh = false}) async {
    if (isLoading || isLoadingMore) return;
    if (search != null) this.search = search.trim();
    isLoading = true;
    error = null;
    if (!refresh) vehicles = const [];
    _notify();
    try {
      final result = await _repository.list(
        page: 1,
        limit: pageSize,
        search: this.search,
      );
      vehicles = result.items;
      total = result.total;
      _page = result.page;
      _hasNextPage = result.hasNextPage;
    } on ApiException catch (exception) {
      error = exception.message;
    } on Object {
      error = 'No se pudieron cargar los vehículos.';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  /// Añade la siguiente página sin descartar las unidades ya cargadas.
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
      vehicles = [...vehicles, ...result.items];
      total = result.total;
      _page = result.page;
      _hasNextPage = result.hasNextPage;
    } on ApiException catch (exception) {
      error = exception.message;
    } on Object {
      error = 'No se pudieron cargar más vehículos.';
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
