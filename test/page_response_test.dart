import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/core/network/page_response.dart';

void main() {
  test('PageResponse parsea el formato de Spring', () {
    final page = PageResponse.fromJson({
      'content': [
        {'id': '1', 'placa': 'ABC-123'},
        {'id': '2', 'placa': 'XYZ-987'},
      ],
      'totalElements': 42,
      'page': 1,
      'size': 2,
    }, (json) => json['placa'] as String);

    expect(page.items, ['ABC-123', 'XYZ-987']);
    expect(page.page, 1);
    expect(page.size, 2);
    expect(page.totalElements, 42);
    expect(page.totalPages, 21);
    expect(page.hasNextPage, isTrue);
  });

  test('PageResponse acepta el formato items y lista vacía', () {
    final page = PageResponse.fromJson({
      'items': <Map<String, dynamic>>[],
    }, (json) => json);

    expect(page.isEmpty, isTrue);
    expect(page.page, 0);
    expect(page.totalPages, 1);
    expect(page.hasNextPage, isFalse);
  });

  test('PageResponse ignora elementos que no son objetos', () {
    final page = PageResponse.fromJson({
      'content': [
        {'id': '1'},
        'basura',
        null,
      ],
    }, (json) => json['id'] as String);

    expect(page.items, ['1']);
  });
}
