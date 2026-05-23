import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final _date = DateFormat('dd/MM/yyyy', 'es_AR');
  static final _short = DateFormat('dd MMM', 'es_AR');

  static String format(DateTime date) => _date.format(date);
  static String formatShort(DateTime date) => _short.format(date);

  static int daysSince(DateTime date) =>
      DateTime.now().difference(date).inDays;

  static String relative(DateTime date) {
    final days = daysSince(date);
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Ayer';
    if (days < 7) return 'Hace $days días';
    if (days < 30) return 'Hace ${(days / 7).floor()} semanas';
    if (days < 365) return 'Hace ${(days / 30).floor()} meses';
    return 'Hace más de un año';
  }

  static DebtAgeStatus debtAgeStatus(DateTime date) {
    final days = daysSince(date);
    if (days >= 60) return DebtAgeStatus.critical;
    if (days >= 30) return DebtAgeStatus.warning;
    return DebtAgeStatus.ok;
  }
}

enum DebtAgeStatus { ok, warning, critical }