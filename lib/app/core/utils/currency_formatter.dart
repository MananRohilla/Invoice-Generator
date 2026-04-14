import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _indianFormatNoSymbol = NumberFormat(
    '#,##,##0.00',
    'en_IN',
  );

  static String format(double amount) {
    return _indianFormat.format(amount);
  }

  static String formatNoSymbol(double amount) {
    return _indianFormatNoSymbol.format(amount);
  }

  static String compact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
