import 'package:flutter/material.dart';

import '../../../goals/domain/goal_model.dart';
import '../../../transactions/domain/transaction_model.dart';
import 'budget_comparison.dart';
import 'cash_flow_trend.dart';
import 'category_spending.dart';
import 'financial_insight.dart';
import 'report_period.dart';
import 'report_summary.dart';

/// Aggregated, fully resolved reporting state for the active time period.
class ReportData {
  final ReportPeriod period;
  final DateTimeRange dateRange;
  final ReportSummary summary;
  final List<CategorySpending> categorySpendings;
  final List<TrendPoint> trendPoints;
  final List<BudgetComparison> budgetComparisons;
  final List<Goal> activeGoals;
  final List<FinancialInsight> insights;
  final List<Transaction> periodTransactions;

  const ReportData({
    required this.period,
    required this.dateRange,
    required this.summary,
    required this.categorySpendings,
    required this.trendPoints,
    required this.budgetComparisons,
    required this.activeGoals,
    required this.insights,
    required this.periodTransactions,
  });

  /// Empty report state when no data exists.
  factory ReportData.empty({
    ReportPeriod period = ReportPeriod.month,
    DateTimeRange? dateRange,
  }) {
    final range = dateRange ?? period.getDateRange();
    return ReportData(
      period: period,
      dateRange: range,
      summary: ReportSummary.empty(),
      categorySpendings: const [],
      trendPoints: const [],
      budgetComparisons: const [],
      activeGoals: const [],
      insights: const [],
      periodTransactions: const [],
    );
  }

  /// Whether the dataset contains zero transactions in this period.
  bool get isEmpty => periodTransactions.isEmpty;

  /// Whether any expenses exist in this period.
  bool get hasExpenses => summary.totalExpenses > 0;

  /// Top 3 categories ranked by spending amount.
  List<CategorySpending> get topCategories =>
      categorySpendings.take(3).toList();

  /// Highest spending category in this period.
  CategorySpending? get highestSpendingCategory =>
      categorySpendings.isNotEmpty ? categorySpendings.first : null;
}
