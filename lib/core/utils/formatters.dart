import 'package:intl/intl.dart';

/// Formateadores de moneda y fecha usados en toda la app.
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$',
    decimalDigits: 2,
  );

  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'es_ES');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy hh:mm a', 'es_ES');

  static String currency(num? value) {
    if (value == null) return _currency.format(0);
    return _currency.format(value);
  }

  static String date(DateTime? value) {
    if (value == null) return '-';
    return _date.format(value);
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '-';
    return _dateTime.format(value);
  }

  /// Parsea fechas ISO 8601 provenientes de la API de forma segura.
  static DateTime? parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
