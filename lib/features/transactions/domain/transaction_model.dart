/// Transaction type distinguishing income from expense.
enum TransactionType {
  expense,
  income;

  static TransactionType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }

  String get value => this == TransactionType.income ? 'income' : 'expense';
}

/// Domain model representing a financial transaction from public.transactions.
class Transaction {
  final String id;
  final String? userId;
  final String categoryId;
  final String category;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime transactionDate;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Transaction({
    required this.id,
    this.userId,
    String? categoryId,
    required this.category,
    required this.title,
    required this.amount,
    required this.type,
    DateTime? transactionDate,
    DateTime? date,
    this.note,
    this.createdAt,
    this.updatedAt,
  })  : categoryId = categoryId ?? id,
        transactionDate = transactionDate ?? (date ?? const _DefaultDate()),
        assert(amount >= 0, 'Amount must be non-negative');

  /// Getter for backward compatibility with existing tests and UI widgets.
  DateTime get date => transactionDate;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  /// Factory creating [Transaction] from a Supabase row map.
  factory Transaction.fromMap(
    Map<String, dynamic> map, {
    String? resolvedCategoryName,
  }) {
    // Nested category join support
    String catName = resolvedCategoryName ?? '';
    if (catName.isEmpty && map['categories'] != null && map['categories'] is Map) {
      catName = (map['categories'] as Map)['name']?.toString() ?? '';
    }
    if (catName.isEmpty) {
      catName = map['category_name']?.toString() ??
          map['category']?.toString() ??
          'General';
    }

    final rawAmount = map['amount'];
    final double parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : (double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0);

    return Transaction(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      categoryId: map['category_id']?.toString() ?? '',
      category: catName,
      title: map['title']?.toString() ?? '',
      amount: parsedAmount,
      type: TransactionType.fromString(map['type']?.toString() ?? 'expense'),
      transactionDate: map['transaction_date'] != null
          ? (DateTime.tryParse(map['transaction_date'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      note: map['note']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Converts this [Transaction] to a Supabase-compatible PostgreSQL map.
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (userId != null) 'user_id': userId,
      'category_id': categoryId,
      'title': title.trim(),
      'amount': amount,
      'type': type.value,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      'note': note?.trim(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? category,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? transactionDate,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      transactionDate: transactionDate ?? (date ?? this.transactionDate),
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class _DefaultDate implements DateTime {
  const _DefaultDate();

  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}
