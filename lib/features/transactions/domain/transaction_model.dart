/// Transaction type distinguishing income from expense.
enum TransactionType {
  expense,
  income,
}

/// Domain model representing a financial transaction.
class Transaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;

  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  Transaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
