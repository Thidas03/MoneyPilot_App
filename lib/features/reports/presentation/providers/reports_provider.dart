import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../budgets/data/budgets_provider.dart';
import '../../../goals/data/goals_provider.dart';
import '../../../transactions/data/transactions_provider.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../domain/models/models.dart';

/// State notifier managing the reference date for report calculations.
class ReportReferenceDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  @override
  set state(DateTime value) => super.state = value;
  @override
  DateTime get state => super.state;

  void setDate(DateTime date) {
    state = date;
  }

  void previous(ReportPeriod period) {
    state = period.previousDate(state);
  }

  void next(ReportPeriod period) {
    if (period.canNavigateNext(state)) {
      state = period.nextDate(state);
    }
  }

  void reset() {
    state = DateTime.now();
  }
}

/// Provider for the reference date from which report periods are computed.
final reportReferenceDateProvider =
    NotifierProvider<ReportReferenceDateNotifier, DateTime>(
  ReportReferenceDateNotifier.new,
);

/// State notifier managing the currently selected reporting time period.
class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.month;

  void setPeriod(ReportPeriod period) {
    if (state != period) {
      state = period;
      ref.read(reportReferenceDateProvider.notifier).reset();
    }
  }
}

/// Provider for the active reporting time period.
final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
  ReportPeriodNotifier.new,
);

/// Central provider deriving all reporting and analytics metrics from existing application data.
final reportsProvider = Provider<ReportData>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final referenceDate = ref.watch(reportReferenceDateProvider);
  final allTransactions = ref.watch(transactionsProvider);
  final allBudgets = ref.watch(budgetsProvider);
  final allGoals = ref.watch(goalsProvider);

  final dateRange = period.getDateRange(referenceDate);

  // 1. Filter transactions within the active period range
  final periodTransactions = allTransactions.where((tx) {
    return !tx.date.isBefore(dateRange.start) && !tx.date.isAfter(dateRange.end);
  }).toList();

  // 2. Compute summary metrics
  double totalIncome = 0.0;
  double totalExpenses = 0.0;

  for (final tx in periodTransactions) {
    if (tx.isIncome) {
      totalIncome += tx.amount;
    } else if (tx.isExpense) {
      totalExpenses += tx.amount;
    }
  }

  final daysInPeriod = period.getDaysInPeriod(dateRange.start);
  final summary = ReportSummary.calculate(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    transactionCount: periodTransactions.length,
    daysInPeriod: daysInPeriod,
  );

  // 3. Compute Category Spending Breakdown
  final categoryMap = <String, double>{};
  final countMap = <String, int>{};

  for (final tx in periodTransactions) {
    if (tx.isExpense) {
      final cat = tx.category.trim().isEmpty ? 'General' : tx.category.trim();
      categoryMap[cat] = (categoryMap[cat] ?? 0.0) + tx.amount;
      countMap[cat] = (countMap[cat] ?? 0) + 1;
    }
  }

  final categorySpendings = categoryMap.entries.map((entry) {
    final catName = entry.key;
    final amount = entry.value;
    final pct = totalExpenses > 0 ? (amount / totalExpenses * 100.0) : 0.0;

    return CategorySpending(
      category: catName,
      amount: amount,
      percentage: pct,
      transactionCount: countMap[catName] ?? 1,
      color: AppCategories.getColor(catName),
      icon: AppCategories.getIcon(catName),
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  // 4. Compute Income vs Expense Trend Points
  final trendPoints = _computeTrendPoints(period, dateRange, periodTransactions);

  // 5. Compute Budget vs Actual Comparisons
  final budgetComparisons = allBudgets.map((b) {
    // Exact spending matching category in current period
    final actualSpent = periodTransactions.where((tx) {
      if (!tx.isExpense) return false;
      final txCat = tx.category.trim().toLowerCase();
      final bCat = b.category.trim().toLowerCase();

      if (tx.categoryId.isNotEmpty &&
          b.categoryId.isNotEmpty &&
          tx.categoryId == b.categoryId) {
        return true;
      }
      if (txCat == bCat) return true;
      if ((bCat == 'food & dining' || bCat == 'food and dining' || bCat == 'food') &&
          (txCat == 'dining out' || txCat == 'food & dining' || txCat == 'food')) {
        return true;
      }
      return false;
    }).fold<double>(0.0, (sum, tx) => sum + tx.amount);

    // Scale budget target proportionally to the reporting period
    double periodBudgetAmount = b.amount;
    if (period == ReportPeriod.week) {
      periodBudgetAmount = (b.amount / 4.0);
    } else if (period == ReportPeriod.year) {
      periodBudgetAmount = (b.amount * 12.0);
    }

    return BudgetComparison(
      budgetId: b.id,
      category: b.category,
      budgetAmount: periodBudgetAmount,
      actualSpent: actualSpent,
      color: AppCategories.getColor(b.category),
      icon: AppCategories.getIcon(b.category),
    );
  }).toList();

  // 6. Compute Data-Driven Factual Financial Insights
  final insights = _computeInsights(
    period: period,
    summary: summary,
    categories: categorySpendings,
    budgets: budgetComparisons,
  );

  return ReportData(
    period: period,
    dateRange: dateRange,
    summary: summary,
    categorySpendings: categorySpendings,
    trendPoints: trendPoints,
    budgetComparisons: budgetComparisons,
    activeGoals: allGoals.where((g) => !g.isCompleted).toList(),
    insights: insights,
    periodTransactions: periodTransactions,
  );
});

List<TrendPoint> _computeTrendPoints(
  ReportPeriod period,
  DateTimeRange dateRange,
  List<Transaction> transactions,
) {
  switch (period) {
    case ReportPeriod.week:
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final start = dateRange.start;
      return List.generate(7, (i) {
        final dayDate = start.add(Duration(days: i));
        final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day);
        final dayEnd = DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59, 999);

        double inc = 0.0;
        double exp = 0.0;

        for (final tx in transactions) {
          if (!tx.date.isBefore(dayStart) && !tx.date.isAfter(dayEnd)) {
            if (tx.isIncome) inc += tx.amount;
            if (tx.isExpense) exp += tx.amount;
          }
        }

        return TrendPoint(
          label: days[i],
          startDate: dayStart,
          endDate: dayEnd,
          income: inc,
          expense: exp,
        );
      });

    case ReportPeriod.month:
      final start = dateRange.start;
      final totalDays = DateTime(start.year, start.month + 1, 0).day;
      final points = <TrendPoint>[];

      int dayCursor = 1;
      int weekIndex = 1;

      while (dayCursor <= totalDays) {
        final endDay = (dayCursor + 6) > totalDays ? totalDays : (dayCursor + 6);
        final intervalStart = DateTime(start.year, start.month, dayCursor);
        final intervalEnd = DateTime(start.year, start.month, endDay, 23, 59, 59, 999);

        double inc = 0.0;
        double exp = 0.0;

        for (final tx in transactions) {
          if (!tx.date.isBefore(intervalStart) && !tx.date.isAfter(intervalEnd)) {
            if (tx.isIncome) inc += tx.amount;
            if (tx.isExpense) exp += tx.amount;
          }
        }

        points.add(
          TrendPoint(
            label: 'W$weekIndex',
            startDate: intervalStart,
            endDate: intervalEnd,
            income: inc,
            expense: exp,
          ),
        );

        dayCursor += 7;
        weekIndex++;
      }
      return points;

    case ReportPeriod.year:
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final year = dateRange.start.year;

      return List.generate(12, (i) {
        final monthStart = DateTime(year, i + 1, 1);
        final monthEnd = DateTime(year, i + 2, 0, 23, 59, 59, 999);

        double inc = 0.0;
        double exp = 0.0;

        for (final tx in transactions) {
          if (!tx.date.isBefore(monthStart) && !tx.date.isAfter(monthEnd)) {
            if (tx.isIncome) inc += tx.amount;
            if (tx.isExpense) exp += tx.amount;
          }
        }

        return TrendPoint(
          label: months[i],
          startDate: monthStart,
          endDate: monthEnd,
          income: inc,
          expense: exp,
        );
      });
  }
}

List<FinancialInsight> _computeInsights({
  required ReportPeriod period,
  required ReportSummary summary,
  required List<CategorySpending> categories,
  required List<BudgetComparison> budgets,
}) {
  final list = <FinancialInsight>[];

  // 1. Cash flow & savings insight
  if (summary.totalIncome > 0 && summary.balance >= 0) {
    list.add(
      FinancialInsight(
        title: 'Net Savings On Track',
        message:
            'You saved ${summary.savingsRate.toStringAsFixed(1)}% of your income this ${period.label.toLowerCase()}.',
        icon: Icons.savings_outlined,
        iconColor: AppColors.income,
        backgroundColor: AppColors.primaryContainer,
      ),
    );
  } else if (summary.totalExpenses > summary.totalIncome && summary.totalIncome > 0) {
    list.add(
      FinancialInsight(
        title: 'Net Outflow Alert',
        message:
            'Expenses exceeded income by ${(summary.totalExpenses - summary.totalIncome).toStringAsFixed(0)} this ${period.label.toLowerCase()}.',
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warning,
        backgroundColor: const Color(0xFFFEF3C7),
      ),
    );
  }

  // 2. Top category spending insight
  if (categories.isNotEmpty && summary.totalExpenses > 0) {
    final top = categories.first;
    list.add(
      FinancialInsight(
        title: 'Highest Spending Category',
        message:
            '${top.category} is your top expense at ${top.percentage.toStringAsFixed(1)}% of all spending.',
        icon: top.icon,
        iconColor: top.color,
        backgroundColor: top.color.withValues(alpha: 0.12),
      ),
    );
  }

  // 3. Budget adherence insight
  final overBudgets = budgets.where((b) => b.isOverBudget).toList();
  final nearBudgets = budgets.where((b) => b.isNearLimit).toList();

  if (overBudgets.isNotEmpty) {
    final b = overBudgets.first;
    list.add(
      FinancialInsight(
        title: 'Budget Limit Exceeded',
        message: '${b.category} exceeded target limit by ${b.usagePercentage.toStringAsFixed(0)}%.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.darkExpense,
        backgroundColor: const Color(0xFFFEE2E2),
      ),
    );
  } else if (nearBudgets.isNotEmpty) {
    final b = nearBudgets.first;
    list.add(
      FinancialInsight(
        title: 'Approaching Budget Limit',
        message: '${b.category} has reached ${b.usagePercentage.toStringAsFixed(0)}% of its limit.',
        icon: Icons.hourglass_top_rounded,
        iconColor: AppColors.warning,
        backgroundColor: const Color(0xFFFEF3C7),
      ),
    );
  } else if (budgets.isNotEmpty) {
    list.add(
      FinancialInsight(
        title: 'All Budgets Controlled',
        message: 'All monitored categories are within spending thresholds.',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.primary,
        backgroundColor: AppColors.primaryContainer,
      ),
    );
  }

  return list;
}
