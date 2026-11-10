/// Formato de dinero y de números para el dashboard.
///
/// Se implementa a mano para no depender de `intl` (ni de la inicialización de
/// locales) y para que las pruebas sean deterministas.
abstract final class MoneyFormatter {
  /// Moneda → símbolo que va **antes** del importe.
  static const _symbols = {'MXN': r'$', 'USD': r'$', 'EUR': '€'};

  /// Formatea [amount] con separadores de miles y dos decimales.
  ///
  /// - `format(1234567.5)` → `"$1,234,567.50"`
  /// - `format(-98.4, currency: 'EUR')` → `"-€98.40"`
  /// - Moneda desconocida: el código va al final → `"1,234.00 CAD"`.
  static String format(num amount, {String currency = 'MXN'}) {
    final sign = amount < 0 ? '-' : '';
    final absolute = amount.abs().toStringAsFixed(2);
    final parts = absolute.split('.');
    final grouped = _groupThousands(parts.first);
    final decimals = parts.length > 1 ? parts[1] : '00';

    final symbol = _symbols[currency];
    if (symbol == null) return '$sign$grouped.$decimals $currency';
    return '$sign$symbol$grouped.$decimals';
  }

  /// Versión corta para tarjetas y ejes: `"850.00"`, `"12.3 k"`, `"1.2 M"`.
  ///
  /// Sin símbolo: quien lo use decide si lo antepone.
  static String compact(num amount) {
    final absolute = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (absolute < 1000) return '$sign${absolute.toStringAsFixed(0)}';
    if (absolute < 1000000) {
      final text = _oneDecimal(absolute / 1000);
      return '$sign$text k';
    }
    final text = _oneDecimal(absolute / 1000000);
    return '$sign$text M';
  }

  /// Una décima, sin `.0` sobrante: `12.0` → `"12"`, `12.34` → `"12.3"`.
  static String _oneDecimal(double value) {
    final text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  /// Inserta comas cada tres dígitos: `"1234567"` → `"1,234,567"`.
  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
