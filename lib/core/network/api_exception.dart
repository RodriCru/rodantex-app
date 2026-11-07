import 'package:dio/dio.dart';

/// Error de API con un mensaje listo para mostrar al usuario.
///
/// Centraliza la traducción de los errores de Dio para toda la app. La UI solo
/// muestra [message]; [statusCode] y [code] sirven para casos especiales.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code, this.details});

  /// Traduce un [DioException] a un mensaje en español entendible.
  ///
  /// Intenta leer primero el mensaje del backend (`message` o `error` en el
  /// cuerpo) y, si no existe, usa un texto según el código HTTP.
  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final status = response?.statusCode;
    final backendMessage = _readMessage(response?.data);

    final message =
        backendMessage ??
        switch (status) {
          400 => 'La solicitud no es válida.',
          401 => 'Tu sesión expiró. Vuelve a iniciar sesión.',
          403 => 'No tienes permisos para esta acción.',
          404 => 'No se encontró el recurso solicitado.',
          409 => 'El recurso ya existe o está en conflicto.',
          422 => 'Verifica los datos ingresados.',
          429 => 'Demasiados intentos. Espera un momento.',
          _ when status != null && status >= 500 =>
            'Error del servidor. Intenta de nuevo más tarde.',
          _
              when error.type == DioExceptionType.connectionError ||
                  error.type == DioExceptionType.connectionTimeout =>
            'No se pudo conectar con el servidor. Revisa tu conexión.',
          _
              when error.type == DioExceptionType.receiveTimeout ||
                  error.type == DioExceptionType.sendTimeout =>
            'El servidor tardó demasiado en responder.',
          _ when error.type == DioExceptionType.cancel =>
            'La solicitud fue cancelada.',
          _ => 'Ocurrió un error inesperado.',
        };

    return ApiException(
      message,
      statusCode: status,
      code: _readCode(response?.data),
    );
  }

  /// El backend puede responder `{message}` o `{error}`.
  static String? _readMessage(Object? data) {
    if (data is Map) {
      for (final key in const ['message', 'error', 'detail']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    return null;
  }

  static String? _readCode(Object? data) {
    if (data is Map) {
      final value = data['code'];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  final String message;
  final int? statusCode;
  final String? code;
  final Object? details;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isServerError => (statusCode ?? 0) >= 500;

  @override
  String toString() =>
      'ApiException($statusCode${code == null ? '' : ' $code'}): $message';
}

/// La sesión expiró y no se pudo renovar: hay que volver al login.
class SessionExpiredException extends ApiException {
  const SessionExpiredException()
    : super(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
        statusCode: 401,
        code: 'SESSION_EXPIRED',
      );
}
