import 'package:flutter/material.dart';

/// Budget comparison item representing target vs actual spending for reports.
class BudgetComparison {
  final String budgetId;
  final String category;
  final double budgetAmount;
  final double actualSpent;
  final Color color;
  final IconData icon;

  const BudgetComparison({
    required this.budgetId,
    required this.category,
    required this.budgetAmount,
    required this.actualSpent,
    required this.color,
    required this.icon,
  });

  /// Remaining allowance before exceeding target.
  double get remaining => (budgetAmount - actualSpent).clamp(0.0, budgetAmount);

  /// Amount by which spending exceeds budget target.
  double get overBudgetAmount => actualSpent > budgetAmount ? actualSpent - budgetAmount : 0.0;

  /// Usage percentage from 0 to 100+ %.
  double get usagePercentage {
    if (budgetAmount <= 0) return 0.0;
    return (actualSpent / budgetAmount) * 100.0;
  }

  /// Progress ratio clamped 0.0 to 1.0 for progress bars.
  double get progressRatio => (usagePercentage / 100.0).clamp(0.0, 1.0);

  bool get isOverBudget => actualSpent > budgetAmount;
  bool get isNearLimit => !isOverBudget && usagePercentage >= 80.0;
}
