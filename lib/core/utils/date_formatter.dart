import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dayOfWeekDayMonth = DateFormat('EEEE, d MMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _timeOnly = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _isoMonth = DateFormat('yyyy-MM');

  /// Human friendly date grouping header:
  /// "Hari ini", "Kemarin", or "Senin, 3 Nov 2026"
  static String formatGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = today.difference(target).inDays;
    if (diff == 0) {
      return 'Hari ini';
    } else if (diff == 1) {
      return 'Kemarin';
    } else {
      return _dayOfWeekDayMonth.format(date);
    }
  }

  static String formatShort(DateTime date) {
    return _dayMonthYear.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeOnly.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  static String toIsoDate(DateTime date) {
    return _isoDate.format(date);
  }

  static String toYearMonth(DateTime date) {
    return _isoMonth.format(date);
  }

  static DateTime parseIsoDate(String dateStr) {
    return DateTime.parse(dateStr);
  }
}
