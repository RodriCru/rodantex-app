import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/core/network/api_exception.dart';

DioException _error({int? status, Object? data, DioExceptionType? type}) {
  final options = RequestOptions(path: 'vehiculos');
  return DioException(
    requestOptions: options,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('Usa el mensaje del backend si existe', () {
    final e = ApiException.fromDio(
      _error(status: 409, data: {'message': 'La placa ya existe'}),
    );
    expect(e.message, 'La placa ya existe');
    expect(e.statusCode, 409);
  });

  test('Traduce códigos HTTP sin mensaje', () {
    expect(
      ApiException.fromDio(_error(status: 403)).message,
      'No tienes permisos para esta acción.',
    );
    expect(ApiException.fromDio(_error(status: 500)).isServerError, isTrue);
    expect(ApiException.fromDio(_error(status: 401)).isUnauthorized, isTrue);
  });

  test('Traduce errores de conexión', () {
    final e = ApiException.fromDio(
      _error(type: DioExceptionType.connectionError),
    );
    expect(e.message, contains('No se pudo conectar'));
    expect(e.statusCode, isNull);
  });

  test('SessionExpiredException está marcada como no autorizada', () {
    const e = SessionExpiredException();
    expect(e.isUnauthorized, isTrue);
    expect(e.code, 'SESSION_EXPIRED');
  });
}
