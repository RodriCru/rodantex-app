/// Página de resultados devuelta por los endpoints paginados de la API.
///
/// Formato esperado (Spring):
/// ```json
/// { "content": [ … ], "totalElements": 42, "page": 0, "size": 20 }
/// ```
/// También acepta el formato `{ items: [...] }` con metadatos opcionales, para
/// no acoplar la UI a un único backend.
class PageResponse<T> {
  const PageResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
  });

  /// Página vacía (útil como estado inicial y en tests).
  const PageResponse.empty()
    : items = const [],
      page = 0,
      size = 0,
      totalElements = 0;

  /// Construye la página a partir del JSON y del parser de cada elemento.
  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawItems =
        (json['content'] ?? json['items'] ?? const <dynamic>[])
            as List<dynamic>;

    final size = _asInt(json['size']) ?? rawItems.length;
    final total = _asInt(json['totalElements']) ?? rawItems.length;

    return PageResponse<T>(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(itemParser)
          .toList(growable: false),
      page: _asInt(json['page'] ?? json['number']) ?? 0,
      size: size,
      totalElements: total,
    );
  }

  final List<T> items;
  final int page;
  final int size;
  final int totalElements;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  /// Número total de páginas (mínimo 1 para no dividir entre cero en la UI).
  int get totalPages => size <= 0 ? 1 : (totalElements / size).ceil();

  bool get hasNextPage => page + 1 < totalPages;

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}
