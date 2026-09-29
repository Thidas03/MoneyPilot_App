/// Budget data model for category and overall targets.
class Budget {
  final String id;
  final String category;
  final double amount;
  final double spent;
  final String period;
  final String? note;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.category,
    required this.amount,
    this.spent = 0.0,
    this.period = 'Monthly',
    this.note,
    required this.createdAt,
  });

  double get progress => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (amount - spent).clamp(0.0, amount);
  bool get isOverBudget => spent > amount;

  Budget copyWith({
    String? id,
    String? category,
    double? amount,
    double? spent,
    String? period,
    String? note,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
