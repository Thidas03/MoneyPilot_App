import 'package:intl/intl.dart';

/// Formatting utilities for dates throughout MoneyPilot.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _standard = DateFormat('MMM d, yyyy');
  static final DateFormat _short = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _monthShortYear = DateFormat("MMM 'yy");

  /// Formats date to "Sep 16, 2026"
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return _standard.format(date);
  }

  /// Formats date to "2026-09-16"
  static String formatShort(DateTime? date) {
    if (date == null) return '';
    return _short.format(date);
  }

  /// Formats date to "September 2026"
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '';
    return _monthYear.format(date);
  }

  /// Formats date to "Sep '26" (for chart axis)
  static String formatMonthShortYear(DateTime? date) {
    if (date == null) return '';
    return _monthShortYear.format(date);
  }

  /// Formats date with relative descriptions ("Today", "Yesterday", or "MMM d")
  static String formatRelative(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(aDate).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';

    return _standard.format(date);
  }

  /// Safe ISO-8601 string parser
  static DateTime? parse(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString);
  }
}
