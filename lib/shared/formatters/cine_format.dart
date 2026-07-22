import 'package:intl/intl.dart';

class CineFormat {
  CineFormat._();

  static final NumberFormat _whole = NumberFormat.decimalPattern('en_US');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _fullDate = DateFormat('MMM d, y');
  static final DateFormat _time = DateFormat('hh:mm a');

  static String currency(num amount, {bool compact = false}) {
    if (!compact) return 'PKR ${_whole.format(amount.round())}';
    if (amount.abs() >= 1000000) {
      return 'PKR ${_trim(amount / 1000000)}M';
    }
    if (amount.abs() >= 1000) return 'PKR ${_trim(amount / 1000)}K';
    return 'PKR ${_whole.format(amount.round())}';
  }

  static String count(num value, {bool compact = false}) {
    if (compact && value.abs() >= 1000000) return '${_trim(value / 1000000)}M';
    if (compact && value.abs() >= 1000) return '${_trim(value / 1000)}K';
    return _whole.format(value.round());
  }

  static String percentage(num value) => '${value.round()}%';

  static String date(DateTime value, {bool includeYear = false}) =>
      (includeYear ? _fullDate : _shortDate).format(value);

  static String time(DateTime value) => _time.format(value);

  static String normalizeCurrency(String value) {
    if (!value.contains('PKR')) return value;
    return value.replaceAllMapped(
      RegExp(r'(?<=\d)k\b'),
      (_) => 'K',
    );
  }

  static String _trim(num value) {
    final text = value.toStringAsFixed(value.abs() >= 10 ? 1 : 2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
