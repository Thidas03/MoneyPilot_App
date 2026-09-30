/// Budget data model for category and overall targets.
/// Compatible with Supabase public.budgets schema while supporting dynamic transaction-based spending.
class Budget {
  final String id;
  final String? userId;
  final String categoryId;
  final String category;
  final String? categoryIcon;
  final String? categoryColor;
  final double amount;
  final double spent;
  final String period;
  final int month;
  final int year;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Budget({
    required this.id,
    this.userId,
    this.categoryId = '',
    required this.category,
    this.categoryIcon,
    this.categoryColor,
    required this.amount,
    this.spent = 0.0,
    this.period = 'Monthly',
    int? month,
    int? year,
    this.startDate,
    this.endDate,
    this.note,
    required this.createdAt,
    this.updatedAt,
  })  : month = month ?? (startDate != null ? startDate.month : 9),
        year = year ?? (startDate != null ? startDate.year : 2026);

  /// Safe calculation of percentage progress (clamped between 0.0 and 1.0 for meters).
  double get progress => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;

  /// Remaining allowance before exceeding budget limit.
  double get remaining => (amount - spent).clamp(0.0, amount);

  /// True if spending strictly exceeds budget limit.
  bool get isOverBudget => spent > amount;

  /// Usage percentage from 0 to 100+ %.
  double get usagePercentage => amount > 0 ? (spent / amount * 100) : 0.0;

  /// Amount by which spending exceeds budget limit (0.0 if within limit).
  double get overBudgetAmount => isOverBudget ? spent - amount : 0.0;

  /// Near-limit warning threshold (80% or more, but not yet over budget).
  /// Directly satisfies Milestone 2 usability requirement.
  bool get isNearLimit => !isOverBudget && usagePercentage >= 80.0;

  /// Factory creating [Budget] from Supabase PostgreSQL row or analytical view.
  factory Budget.fromMap(
    Map<String, dynamic> map, {
    String? resolvedCategoryName,
    String? resolvedCategoryIcon,
    String? resolvedCategoryColor,
    double? calculatedSpent,
  }) {
    // If joined with categories table: categories: {name: '...', icon: '...', color_hex: '...'}
    final catData = map['categories'] as Map<String, dynamic>?;
    final catName = resolvedCategoryName ??
        catData?['name'] as String? ??
        map['category_name'] as String? ??
        map['category'] as String? ??
        '';

    final catIcon = resolvedCategoryIcon ??
        catData?['icon'] as String? ??
        map['category_icon'] as String?;

    final catColor = resolvedCategoryColor ??
        catData?['color_hex'] as String? ??
        map['category_color'] as String?;

    final amountNum = map['amount'] ?? map['budget_limit'] ?? 0;
    final parsedAmount = amountNum is num
        ? amountNum.toDouble()
        : (double.tryParse(amountNum.toString()) ?? 0.0);

    DateTime? start;
    if (map['start_date'] != null) {
      start = DateTime.tryParse(map['start_date'].toString());
    }
    DateTime? end;
    if (map['end_date'] != null) {
      end = DateTime.tryParse(map['end_date'].toString());
    }

    final now = DateTime.now();
    final parsedMonth = map['month'] is int
        ? map['month'] as int
        : (start?.month ?? (map['month'] != null ? int.tryParse(map['month'].toString()) : null) ?? now.month);

    final parsedYear = map['year'] is int
        ? map['year'] as int
        : (start?.year ?? (map['year'] != null ? int.tryParse(map['year'].toString()) : null) ?? now.year);

    final spentNum = calculatedSpent ?? map['spent'] ?? 0;
    final parsedSpent = spentNum is num
        ? spentNum.toDouble()
        : (double.tryParse(spentNum.toString()) ?? 0.0);

    return Budget(
      id: map['id']?.toString() ?? map['budget_id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      categoryId: map['category_id']?.toString() ?? '',
      category: catName,
      categoryIcon: catIcon,
      categoryColor: catColor,
      amount: parsedAmount,
      spent: parsedSpent,
      period: (map['period'] as String? ?? 'Monthly'),
      month: parsedMonth,
      year: parsedYear,
      startDate: start,
      endDate: end,
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? now)
          : now,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Converts this [Budget] to a Supabase-compatible map for public.budgets table.
  Map<String, dynamic> toMap({String? userId}) {
    final effectiveUserId = userId ?? this.userId;
    final sDate = startDate ?? DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0).day;
    final eDate = endDate ?? DateTime(year, month, lastDay);

    final sDateStr =
        '${sDate.year.toString().padLeft(4, '0')}-${sDate.month.toString().padLeft(2, '0')}-${sDate.day.toString().padLeft(2, '0')}';
    final eDateStr =
        '${eDate.year.toString().padLeft(4, '0')}-${eDate.month.toString().padLeft(2, '0')}-${eDate.day.toString().padLeft(2, '0')}';

    return {
      if (id.isNotEmpty && !id.startsWith('budget-')) 'id': id,
      if (effectiveUserId != null && effectiveUserId.isNotEmpty) 'user_id': effectiveUserId,
      'category_id': categoryId,
      'amount': amount,
      'period': period.toLowerCase(),
      'start_date': sDateStr,
      'end_date': eDateStr,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? category,
    String? categoryIcon,
    String? categoryColor,
    double? amount,
    double? spent,
    String? period,
    int? month,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      month: month ?? this.month,
      year: year ?? this.year,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
