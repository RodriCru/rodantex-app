import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';

/// `TokenStorage` en memoria: los tests de `unwrap` no necesitan sesión real.
class _NoStorage implements TokenStorage {
  @override
  String? get accessToken => null;

  @override
  String? get refreshToken => null;

  @override
  UserProfile? get user => null;

  @override
  Future<void> saveSession(AuthSession session) async {}

  @override
  Future<void> saveTokens(AuthTokens tokens) async {}

  @override
  Future<void> clear() async {}
}

DioException _dioError(int status, Object? data) {
  final options = RequestOptions(path: 'dashboard/vehicles-in-maintenance');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  late ApiClient client;

  setUp(() {
    client = ApiClient.create(storage: _NoStorage());
  });

  group('unwrap', () {
    test('Devuelve `resultado` cuando existe la envoltura', () {
      final data = {
        'codigo': 200,
        'mensaje': 'OK',
        'resultado': {'total': 1, 'items': []},
      };
      expect(client.unwrap(data), {'total': 1, 'items': []});
    });

    test('Acepta respuestas planas (auth) sin envoltura', () {
      final data = {'accessToken': 'a', 'refreshToken': 'r'};
      expect(client.unwrap(data), data);
    });

    test('Lanza ApiException si `resultado` es null', () {
      expect(
        () => client.unwrap({'codigo': 200, 'mensaje': 'Eliminado', 'resultado': null}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Eliminado')
              .having((e) => e.statusCode, 'statusCode', 200),
        ),
      );
    });

    test('Lanza ApiException si `resultado` no es objeto', () {
      expect(
        () => client.unwrap({'codigo': 200, 'resultado': 'texto'}),
        throwsA(isA<ApiException>()),
      );
    });

    test('Lanza ApiException si la respuesta no es un Map', () {
      expect(() => client.unwrap(null), throwsA(isA<ApiException>()));
      expect(() => client.unwrap([1, 2]), throwsA(isA<ApiException>()));
    });
  });

  group('unwrapList', () {
    test('Devuelve los elementos de `resultado`, que es una lista', () {
      final data = {
        'codigo': 200,
        'resultado': [
          {'id': '1'},
          {'id': '2'},
        ],
      };
      final list = client.unwrapList(data);
      expect(list, hasLength(2));
      expect(list.first['id'], '1');
    });

    test('Devuelve lista vacía si `resultado` es null', () {
      expect(
        client.unwrapList({'codigo': 200, 'resultado': null}),
        isEmpty,
      );
    });

    test('Lanza ApiException si `resultado` no es lista', () {
      expect(
        () => client.unwrapList({
          'codigo': 200,
          'resultado': {'total': 0},
        }),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('ApiException con el formato del backend', () {
    test('Lee `mensaje` (envoltura estándar)', () {
      final e = ApiException.fromDio(_dioError(404, {
        'codigo': 404,
        'mensaje': 'Vehículo no encontrado',
        'resultado': null,
      }));
      expect(e.message, 'Vehículo no encontrado');
      expect(e.statusCode, 404);
      expect(e.code, '404');
    });

    test('Prioriza `mensaje` sobre `message`', () {
      final e = ApiException.fromDio(_dioError(400, {
        'mensaje': 'Datos inválidos',
        'message': 'Bad request',
      }));
      expect(e.message, 'Datos inválidos');
    });

    test('Sigue aceptando el formato plano con `message`', () {
      final e = ApiException.fromDio(
        _dioError(409, {'message': 'La placa ya existe'}),
      );
      expect(e.message, 'La placa ya existe');
    });
  });
}
