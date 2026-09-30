import 'package:flutter/material.dart';

/// Aggregated expense data for a single category within a report period.
class CategorySpending {
  final String category;
  final double amount;
  final double percentage; // 0.0 to 100.0%
  final int transactionCount;
  final Color color;
  final IconData icon;

  const CategorySpending({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required this.color,
    required this.icon,
  });

  /// Ratio (0.0 to 1.0) for progress bars and charts.
  double get ratio => (percentage / 100.0).clamp(0.0, 1.0);

  CategorySpending copyWith({
    String? category,
    double? amount,
    double? percentage,
    int? transactionCount,
    Color? color,
    IconData? icon,
  }) {
    return CategorySpending(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      transactionCount: transactionCount ?? this.transactionCount,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
