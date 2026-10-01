import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/features/budgets/data/budgets_provider.dart';
import 'package:moneypilot/features/goals/data/goals_provider.dart';
import 'package:moneypilot/features/reports/domain/models/models.dart';
import 'package:moneypilot/features/reports/presentation/providers/reports_provider.dart';
import 'package:moneypilot/features/transactions/data/transactions_provider.dart';
import 'package:moneypilot/features/transactions/domain/transaction_model.dart';

void main() {
  group('Reports Domain & Model Unit Tests', () {
    test('ReportSummary.calculate computes metrics and handles balance safely', () {
      final summary = ReportSummary.calculate(
        totalIncome: 100000.0,
        totalExpenses: 40000.0,
        transactionCount: 5,
        daysInPeriod: 30,
      );

      expect(summary.totalIncome, 100000.0);
      expect(summary.totalExpenses, 40000.0);
      expect(summary.balance, 60000.0);
      expect(summary.transactionCount, 5);
      expect(summary.averageDailyExpense, closeTo(1333.33, 0.01));
      expect(summary.savingsRate, closeTo(60.0, 0.01));
    });

    test('ReportSummary handles empty / zero datasets without NaN or Infinity', () {
      final emptySummary = ReportSummary.calculate(
        totalIncome: 0.0,
        totalExpenses: 0.0,
        transactionCount: 0,
        daysInPeriod: 0,
      );

      expect(emptySummary.totalIncome, 0.0);
      expect(emptySummary.totalExpenses, 0.0);
      expect(emptySummary.balance, 0.0);
      expect(emptySummary.transactionCount, 0);
      expect(emptySummary.averageDailyExpense, 0.0);
      expect(emptySummary.averageDailyExpense.isNaN, isFalse);
      expect(emptySummary.averageDailyExpense.isInfinite, isFalse);
      expect(emptySummary.savingsRate, 0.0);
    });

    test('ReportPeriod provides correct date ranges and days', () {
      final refDate = DateTime(2026, 9, 15); // Tuesday

      // Week Range
      final weekRange = ReportPeriod.week.getDateRange(refDate);
      expect(weekRange.start.weekday, DateTime.monday);
      expect(weekRange.end.weekday, DateTime.sunday);
      expect(ReportPeriod.week.getDaysInPeriod(refDate), 7);
      expect(ReportPeriod.week.containsDate(DateTime(2026, 9, 14), refDate), isTrue); // Monday
      expect(ReportPeriod.week.containsDate(DateTime(2026, 9, 21), refDate), isFalse); // Next Monday

      // Month Range (September has 30 days)
      final monthRange = ReportPeriod.month.getDateRange(refDate);
      expect(monthRange.start, DateTime(2026, 9, 1));
      expect(ReportPeriod.month.getDaysInPeriod(refDate), 30);
      expect(ReportPeriod.month.containsDate(DateTime(2026, 9, 30), refDate), isTrue);
      expect(ReportPeriod.month.containsDate(DateTime(2026, 10, 1), refDate), isFalse);

      // Year Range
      final yearRange = ReportPeriod.year.getDateRange(refDate);
      expect(yearRange.start, DateTime(2026, 1, 1));
      expect(ReportPeriod.year.getDaysInPeriod(refDate), 365);
      expect(ReportPeriod.year.containsDate(DateTime(2026, 12, 31), refDate), isTrue);
      expect(ReportPeriod.year.containsDate(DateTime(2027, 1, 1), refDate), isFalse);
    });

    test('CategorySpending ratio and percentage calculations', () {
      const spending = CategorySpending(
        category: 'Groceries',
        amount: 15000.0,
        percentage: 30.0,
        transactionCount: 3,
        color: Color(0xFFF59E0B),
        icon: Icons.category,
      );

      expect(spending.ratio, 0.3);
      expect(spending.percentage, 30.0);
      expect(spending.amount, 15000.0);
    });

    test('BudgetComparison calculates limits, usage, and over-budget correctly', () {
      const normal = BudgetComparison(
        budgetId: 'b1',
        category: 'Food',
        budgetAmount: 20000.0,
        actualSpent: 10000.0,
        color: Color(0xFF10B981),
        icon: Icons.category,
      );
      expect(normal.usagePercentage, 50.0);
      expect(normal.remaining, 10000.0);
      expect(normal.isOverBudget, isFalse);
      expect(normal.isNearLimit, isFalse);

      const nearLimit = BudgetComparison(
        budgetId: 'b2',
        category: 'Transport',
        budgetAmount: 10000.0,
        actualSpent: 8500.0,
        color: Color(0xFFF59E0B),
        icon: Icons.category,
      );
      expect(nearLimit.usagePercentage, 85.0);
      expect(nearLimit.isNearLimit, isTrue);
      expect(nearLimit.isOverBudget, isFalse);

      const overLimit = BudgetComparison(
        budgetId: 'b3',
        category: 'Entertainment',
        budgetAmount: 5000.0,
        actualSpent: 6500.0,
        color: Color(0xFFDC2626),
        icon: Icons.category,
      );
      expect(overLimit.isOverBudget, isTrue);
      expect(overLimit.overBudgetAmount, 1500.0);
      expect(overLimit.remaining, 0.0);
    });
  });

  group('Reports Provider Integration Tests', () {
    test('reportsProvider computes metrics reactively and updates when period changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default period is month
      final initialData = container.read(reportsProvider);
      expect(initialData.period, ReportPeriod.month);
      expect(initialData.summary.totalIncome, greaterThanOrEqualTo(0.0));
      expect(initialData.summary.balance, initialData.summary.totalIncome - initialData.summary.totalExpenses);

      // Change period to week
      container.read(reportPeriodProvider.notifier).setPeriod(ReportPeriod.week);
      final weekData = container.read(reportsProvider);
      expect(weekData.period, ReportPeriod.week);
      expect(weekData.trendPoints.length, 7);

      // Change period to year
      container.read(reportPeriodProvider.notifier).setPeriod(ReportPeriod.year);
      final yearData = container.read(reportsProvider);
      expect(yearData.period, ReportPeriod.year);
      expect(yearData.trendPoints.length, 12);
    });

    test('reportsProvider recalculates automatically when transactions change', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Ensure Month period
      container.read(reportPeriodProvider.notifier).setPeriod(ReportPeriod.month);
      final before = container.read(reportsProvider);
      final initialIncome = before.summary.totalIncome;

      // Add a new income transaction in current month
      final now = DateTime.now();
      await container.read(transactionsProvider.notifier).addTransaction(
            title: 'Freelance Bonus',
            amount: 25000.0,
            type: TransactionType.income,
            categoryId: 'cat-investments',
            categoryName: 'Investments',
            date: now,
          );

      final after = container.read(reportsProvider);
      expect(after.summary.totalIncome, initialIncome + 25000.0);
      expect(after.summary.balance, after.summary.totalIncome - after.summary.totalExpenses);
    });

    test('reportsProvider reflects budgets and active goals', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final data = container.read(reportsProvider);
      final budgets = container.read(budgetsProvider);
      final goals = container.read(goalsProvider);

      expect(data.budgetComparisons.length, budgets.length);
      expect(data.activeGoals.length, goals.where((g) => !g.isCompleted).length);
      expect(data.insights, isNotEmpty);
    });

    test('changing reportReferenceDateProvider causes reportsProvider to recalculate historical data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set period to month
      container.read(reportPeriodProvider.notifier).setPeriod(ReportPeriod.month);

      // Add a transaction in August 2026
      final augustDate = DateTime(2026, 8, 15);
      await container.read(transactionsProvider.notifier).addTransaction(
            title: 'August Historical Consulting',
            amount: 75000.0,
            type: TransactionType.income,
            categoryId: 'cat-sys-1',
            categoryName: 'Salary',
            date: augustDate,
          );

      // Initially viewing current month
      final currentMonthData = container.read(reportsProvider);
      final currentMonthAugustTxs = currentMonthData.periodTransactions
          .where((t) => t.title == 'August Historical Consulting')
          .toList();
      expect(currentMonthAugustTxs, isEmpty);

      // Navigate reference date to August 2026
      container.read(reportReferenceDateProvider.notifier).setDate(augustDate);
      final augustData = container.read(reportsProvider);

      expect(augustData.dateRange.start, DateTime(2026, 8, 1));
      expect(augustData.summary.totalIncome, greaterThanOrEqualTo(75000.0));
      expect(
        augustData.periodTransactions.any((t) => t.title == 'August Historical Consulting'),
        isTrue,
      );

      // Switching period from Month to Week resets reference date to current period
      container.read(reportPeriodProvider.notifier).setPeriod(ReportPeriod.week);
      final resetWeekData = container.read(reportsProvider);
      expect(resetWeekData.period, ReportPeriod.week);
      final currentWeekRange = ReportPeriod.week.getDateRange(DateTime.now());
      expect(resetWeekData.dateRange.start, currentWeekRange.start);
    });
  });

  group('Reports Historical Navigation Domain & Boundary Tests', () {
    test('Week navigation shifts exactly 7 days', () {
      final ref = DateTime(2026, 9, 15); // Tuesday
      final prev = ReportPeriod.week.previousDate(ref);
      expect(prev, DateTime(2026, 9, 8));

      final next = ReportPeriod.week.nextDate(prev, ref);
      expect(next, DateTime(2026, 9, 15));
    });

    test('Month navigation moves exactly one calendar month safely', () {
      final ref = DateTime(2026, 9, 15);
      final prev = ReportPeriod.month.previousDate(ref);
      expect(prev, DateTime(2026, 8, 1));

      final next = ReportPeriod.month.nextDate(prev, ref);
      expect(next, DateTime(2026, 9, 1));
    });

    test('Month navigation handles Jan 31 and month end without overflow', () {
      final jan31 = DateTime(2026, 1, 31);
      final prev = ReportPeriod.month.previousDate(jan31);
      expect(prev.year, 2025);
      expect(prev.month, 12);
      expect(prev.day, 1);
    });

    test('Year navigation moves exactly one year', () {
      final ref = DateTime(2026, 9, 15);
      final prev = ReportPeriod.year.previousDate(ref);
      expect(prev, DateTime(2025, 1, 1));

      final next = ReportPeriod.year.nextDate(prev, ref);
      expect(next, DateTime(2026, 1, 1));
    });

    test('Boundary cases: January 2026 -> December 2025 and December 2025 -> January 2026', () {
      final jan2026 = DateTime(2026, 1, 15);
      final dec2025 = ReportPeriod.month.previousDate(jan2026);
      expect(dec2025.year, 2025);
      expect(dec2025.month, 12);

      final backToJan = ReportPeriod.month.nextDate(dec2025, jan2026);
      expect(backToJan.year, 2026);
      expect(backToJan.month, 1);
    });

    test('Leap year boundary: February 2028 has 29 days', () {
      final feb2028 = DateTime(2028, 2, 15);
      expect(ReportPeriod.month.getDaysInPeriod(feb2028), 29);

      final prev = ReportPeriod.month.previousDate(feb2028);
      expect(prev.year, 2028);
      expect(prev.month, 1);

      final febAgain = ReportPeriod.month.nextDate(prev, feb2028);
      expect(febAgain.year, 2028);
      expect(febAgain.month, 2);
    });

    test('Week crossing month boundary calculates and formats correctly', () {
      // Sep 28 to Oct 4, 2026
      final weekInCrossing = DateTime(2026, 10, 1);
      final range = ReportPeriod.week.getDateRange(weekInCrossing);
      expect(range.start, DateTime(2026, 9, 28));
      expect(range.end.year, 2026);
      expect(range.end.month, 10);
      expect(range.end.day, 4);

      final label = ReportPeriod.week.formatPeriodLabel(weekInCrossing);
      expect(label, 'Sep 28 \u2013 Oct 4, 2026');

      final prevWeek = ReportPeriod.week.previousDate(weekInCrossing);
      final prevRange = ReportPeriod.week.getDateRange(prevWeek);
      expect(prevRange.start, DateTime(2026, 9, 21));
      expect(prevRange.end.day, 27);
      expect(ReportPeriod.week.formatPeriodLabel(prevWeek), 'Sep 21 \u2013 Sep 27, 2026');
    });

    test('Week crossing year boundary calculates and formats correctly', () {
      // Dec 29, 2025 to Jan 4, 2026
      final weekCrossingYear = DateTime(2026, 1, 1);
      final range = ReportPeriod.week.getDateRange(weekCrossingYear);
      expect(range.start.year, 2025);
      expect(range.start.month, 12);
      expect(range.start.day, 29);
      expect(range.end.year, 2026);
      expect(range.end.month, 1);
      expect(range.end.day, 4);

      final label = ReportPeriod.week.formatPeriodLabel(weekCrossingYear);
      expect(label, 'Dec 29, 2025 \u2013 Jan 4, 2026');
    });

    test('Future restriction prevents navigation past current period', () {
      final now = DateTime(2026, 9, 15);

      // Month
      expect(ReportPeriod.month.canNavigateNext(DateTime(2026, 9, 1), now), isFalse);
      expect(ReportPeriod.month.canNavigateNext(DateTime(2026, 8, 1), now), isTrue);
      expect(ReportPeriod.month.canNavigateNext(DateTime(2026, 10, 1), now), isFalse);

      // Week
      expect(ReportPeriod.week.canNavigateNext(DateTime(2026, 9, 15), now), isFalse);
      expect(ReportPeriod.week.canNavigateNext(DateTime(2026, 9, 8), now), isTrue);

      // Year
      expect(ReportPeriod.year.canNavigateNext(DateTime(2026, 1, 1), now), isFalse);
      expect(ReportPeriod.year.canNavigateNext(DateTime(2025, 1, 1), now), isTrue);

      // nextDate returns same date when next is blocked
      final blocked = ReportPeriod.month.nextDate(DateTime(2026, 9, 1), now);
      expect(blocked, DateTime(2026, 9, 1));
    });

    test('ReportReferenceDateNotifier supports previous, next, reset, and respects future bound', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(reportReferenceDateProvider.notifier);

      // Current date initially
      final initialDate = container.read(reportReferenceDateProvider);

      // Attempting next when at current period does not move forward
      notifier.next(ReportPeriod.month);
      expect(container.read(reportReferenceDateProvider), initialDate);

      // Month: previous and next
      notifier.previous(ReportPeriod.month);
      final prevMonth = container.read(reportReferenceDateProvider);
      expect(prevMonth.isBefore(initialDate), isTrue);

      notifier.next(ReportPeriod.month);
      final backToCurrentMonth = container.read(reportReferenceDateProvider);
      expect(backToCurrentMonth.month, initialDate.month);
      expect(backToCurrentMonth.year, initialDate.year);

      // Week: previous and next
      notifier.previous(ReportPeriod.week);
      final prevWeek = container.read(reportReferenceDateProvider);
      expect(prevWeek.isBefore(backToCurrentMonth), isTrue);

      notifier.next(ReportPeriod.week);
      final backToCurrentWeek = container.read(reportReferenceDateProvider);
      expect(backToCurrentWeek.isAfter(prevWeek), isTrue);

      // Year: previous and next
      notifier.previous(ReportPeriod.year);
      final prevYear = container.read(reportReferenceDateProvider);
      expect(prevYear.year, initialDate.year - 1);

      notifier.next(ReportPeriod.year);
      final backToCurrentYear = container.read(reportReferenceDateProvider);
      expect(backToCurrentYear.year, initialDate.year);

      // Reset
      notifier.previous(ReportPeriod.year);
      notifier.reset();
      expect(container.read(reportReferenceDateProvider).year, initialDate.year);
      expect(container.read(reportReferenceDateProvider).month, initialDate.month);
    });

    test('Period switching resets reference date across all combinations: Month -> Year and Year -> Week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final periodNotifier = container.read(reportPeriodProvider.notifier);
      final dateNotifier = container.read(reportReferenceDateProvider.notifier);

      // Navigate to past month
      dateNotifier.setDate(DateTime(2025, 5, 1));
      expect(container.read(reportReferenceDateProvider), DateTime(2025, 5, 1));

      // Switch to Year
      periodNotifier.setPeriod(ReportPeriod.year);
      final yearData = container.read(reportsProvider);
      expect(yearData.period, ReportPeriod.year);
      expect(yearData.dateRange.start.year, DateTime.now().year);

      // Navigate to past year
      dateNotifier.setDate(DateTime(2020, 1, 1));
      expect(container.read(reportReferenceDateProvider), DateTime(2020, 1, 1));

      // Switch to Week
      periodNotifier.setPeriod(ReportPeriod.week);
      final weekData = container.read(reportsProvider);
      expect(weekData.period, ReportPeriod.week);
      final currentWeekStart = ReportPeriod.week.getDateRange(DateTime.now()).start;
      expect(weekData.dateRange.start, currentWeekStart);
    });

    test('Navigating to historical period with no transactions yields empty state without error', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set to historical year 2010 where no mock transactions exist
      container.read(reportPeriodProvider.notifier).setPeriod(ReportPeriod.year);
      container.read(reportReferenceDateProvider.notifier).setDate(DateTime(2010, 1, 1));

      final data = container.read(reportsProvider);
      expect(data.isEmpty, isTrue);
      expect(data.periodTransactions, isEmpty);
      expect(data.summary.totalIncome, 0.0);
      expect(data.summary.totalExpenses, 0.0);
      expect(data.summary.balance, 0.0);
      expect(data.summary.transactionCount, 0);
      expect(data.summary.averageDailyExpense, 0.0);
      expect(data.summary.savingsRate, 0.0);
      expect(data.categorySpendings, isEmpty);
    });

    test('Human-readable labels format dynamically for Week, Month, and Year', () {
      final date = DateTime(2026, 9, 15);
      expect(ReportPeriod.month.formatPeriodLabel(date), 'September 2026');
      expect(ReportPeriod.year.formatPeriodLabel(date), '2026');
      expect(ReportPeriod.week.formatPeriodLabel(date), 'Sep 14 \u2013 Sep 20, 2026');
    });
  });
}

