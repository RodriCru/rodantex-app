/// Configuración del entorno de la API.
///
/// Se puede sobrescribir en tiempo de compilación:
///   flutter run --dart-define=API_BASE_URL=https://api.rodantex.com/
///
/// El host por defecto es `localhost` (servidor local del desarrollador).
/// Nota: en dispositivos físicos "localhost" apunta al teléfono; usa la IP de
/// la Mac con `--dart-define`. El emulador Android usa 10.0.2.2.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'localhost',
  );

  /// Todas las rutas se resuelven contra `http://<host>:8080/api/v1/`.
  static const int port = 8080;

  static const String apiPrefix = 'api/v1';

  static String normalizeBaseUrl(String url) {
    final value = url.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value.endsWith('/') ? value : '$value/';
    }
    return 'http://$value:$port/';
  }

  /// URL completa del prefijo de la API, terminada en `/`.
  static String get resolvedBaseUrl =>
      '${normalizeBaseUrl(baseUrl)}$apiPrefix/';
}
