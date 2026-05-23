import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final _full = NumberFormat.currency(
    locale: 'es_AR', symbol: '\$', decimalDigits: 2,
  );

  static final _compact = NumberFormat.compactCurrency(
    locale: 'es_AR', symbol: '\$', decimalDigits: 0,
  );

  /// Formato completo: $1.250,50
  static String format(double amount) => _full.format(amount);

  /// Formato compacto para stats: $1,2K
  static String compact(double amount) =>
      amount >= 1000 ? _compact.format(amount) : _full.format(amount);

  /// Parsea string a double, 0 si inválido
  static double parse(String value) {
    final cleaned = value
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll('\$', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}