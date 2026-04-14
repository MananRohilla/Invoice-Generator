import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _display = DateFormat('dd/MM/yyyy');
  static final _displayLong = DateFormat('dd MMM yyyy');
  static final _displayFull = DateFormat('EEE, dd MMM yyyy');

  static String format(DateTime date) => _display.format(date);
  static String formatLong(DateTime date) => _displayLong.format(date);
  static String formatFull(DateTime date) => _displayFull.format(date);

  static DateTime parse(String s) => _display.parse(s);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return formatLong(date);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
