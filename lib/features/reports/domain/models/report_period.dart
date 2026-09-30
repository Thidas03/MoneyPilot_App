import 'package:flutter/material.dart';

/// Supported reporting time horizons.
enum ReportPeriod {
  week,
  month,
  year;

  String get label {
    switch (this) {
      case ReportPeriod.week:
        return 'Week';
      case ReportPeriod.month:
        return 'Month';
      case ReportPeriod.year:
        return 'Year';
    }
  }

  /// Calculates the inclusive [DateTimeRange] for this period given a [referenceDate].
  DateTimeRange getDateRange([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);

    switch (this) {
      case ReportPeriod.week:
        final start = today.subtract(Duration(days: ref.weekday - 1));
        final end = DateTime(
          start.year,
          start.month,
          start.day + 6,
          23,
          59,
          59,
          999,
        );
        return DateTimeRange(start: start, end: end);

      case ReportPeriod.month:
        final start = DateTime(ref.year, ref.month, 1);
        final nextMonthFirst = DateTime(ref.year, ref.month + 1, 1);
        final end = nextMonthFirst.subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);

      case ReportPeriod.year:
        final start = DateTime(ref.year, 1, 1);
        final nextYearFirst = DateTime(ref.year + 1, 1, 1);
        final end = nextYearFirst.subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }

  /// Returns total calendar days in the period (for safe daily averages).
  int getDaysInPeriod([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    switch (this) {
      case ReportPeriod.week:
        return 7;
      case ReportPeriod.month:
        // Day 0 of next month is the last day of the current month
        return DateTime(ref.year, ref.month + 1, 0).day;
      case ReportPeriod.year:
        final isLeapYear = (ref.year % 4 == 0 && ref.year % 100 != 0) || (ref.year % 400 == 0);
        return isLeapYear ? 366 : 365;
    }
  }

  /// True if [date] falls within this period.
  bool containsDate(DateTime date, [DateTime? referenceDate]) {
    final range = getDateRange(referenceDate);
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }
}
