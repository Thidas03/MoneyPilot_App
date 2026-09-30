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
  });
}
