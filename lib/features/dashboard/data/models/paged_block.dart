/// Bloque paginado simple: `{total, items}`.
///
/// Lo usan los endpoints de *widget* del dashboard (p. ej.
/// `vehicles-in-maintenance`), que devuelven `total` real y solo los `limit`
/// elementos pedidos. No es [PageResponse] porque no hay número de página ni
/// tamaño de página: solo "cuántos hay en total y aquí van estos pocos".
class PagedBlock<T> {
  const PagedBlock({required this.total, required this.items});

  /// Lee `total`/`items` y aplica [itemParser] a cada elemento.
  ///
  /// - Si falta `items`, el bloque queda vacío.
  /// - Si falta `total`, se usa `items.length`.
  factory PagedBlock.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return PagedBlock<T>(
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      items: raw.whereType<Map<String, dynamic>>().map(itemParser).toList(),
    );
  }

  /// Total real en el backend (puede ser mayor que `items.length`).
  final int total;

  /// Los `limit` elementos pedidos.
  final List<T> items;

  bool get isEmpty => items.isEmpty;

  /// `true` cuando hay más registros de los que se muestran.
  bool get hasMore => total > items.length;
}
