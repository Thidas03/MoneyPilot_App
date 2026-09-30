/// A single data point on the cash flow trend timeline (Income vs Expense).
class TrendPoint {
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final double income;
  final double expense;

  const TrendPoint({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.income,
    required this.expense,
  });

  double get netBalance => income - expense;

  /// Max of income or expense for chart scaling.
  double get maxVal => income > expense ? income : expense;
}
