import 'package:intl/intl.dart';

class DateFormatter {
  static DateFormat get _dayMonthYear {
    try {
      return DateFormat('d MMM yyyy', 'id_ID');
    } catch (_) {
      return DateFormat('d MMM yyyy');
    }
  }

  static DateFormat get _dayOfWeekDayMonth {
    try {
      return DateFormat('EEEE, d MMM yyyy', 'id_ID');
    } catch (_) {
      return DateFormat('EEEE, d MMM yyyy');
    }
  }

  static DateFormat get _monthYear {
    try {
      return DateFormat('MMMM yyyy', 'id_ID');
    } catch (_) {
      return DateFormat('MMMM yyyy');
    }
  }

  static DateFormat get _timeOnly {
    try {
      return DateFormat('HH:mm', 'id_ID');
    } catch (_) {
      return DateFormat('HH:mm');
    }
  }

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
