import 'package:flutter/foundation.dart';

/// Domain entity representing an individual savings contribution toward a financial goal.
@immutable
class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.userId,
    this.note,
    this.createdAt,
  }) : assert(amount > 0, 'Contribution amount must be greater than zero');

  /// Unique identifier of the contribution.
  final String id;

  /// Foreign key referencing the parent Savings Goal.
  final String goalId;

  /// Foreign key referencing the authenticated user profile.
  final String? userId;

  /// Numeric monetary amount contributed (must be positive).
  final double amount;

  /// Date when the contribution was made.
  final DateTime date;

  /// Optional personal note or allocation memo.
  final String? note;

  /// Timestamp when this record was persisted.
  final DateTime? createdAt;

  /// Formatted date string for UI display (e.g. '28 Sep 2026').
  String get formattedDate {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = monthNames[date.month - 1];
    return '${date.day} $m ${date.year}';
  }

  /// Parses a Map row (from Supabase PostgreSQL or local cache) into a GoalContribution.
  factory GoalContribution.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final rawDate = map['contribution_date'] ?? map['date'];
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedCreatedAt;
    final rawCreated = map['created_at'] ?? map['createdAt'];
    if (rawCreated is DateTime) {
      parsedCreatedAt = rawCreated;
    } else if (rawCreated != null) {
      parsedCreatedAt = DateTime.tryParse(rawCreated.toString());
    }

    final rawAmount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    // Ensure amount is validated > 0
    final validatedAmount = rawAmount <= 0 ? 0.01 : rawAmount;

    return GoalContribution(
      id: map['id']?.toString() ?? '',
      goalId: map['goal_id']?.toString() ?? map['goalId']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString(),
      amount: validatedAmount,
      date: parsedDate,
      note: map['note']?.toString(),
      createdAt: parsedCreatedAt,
    );
  }

  /// Converts this model to a Map matching the Supabase `goal_contributions` table schema.
  Map<String, dynamic> toMap({String? currentUserId}) {
    return {
      if (id.isNotEmpty) 'id': id,
      'goal_id': goalId,
      if ((currentUserId ?? userId) != null && (currentUserId ?? userId)!.isNotEmpty)
        'user_id': currentUserId ?? userId,
      'amount': amount,
      'contribution_date': date.toIso8601String(),
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Immutability copyWith helper.
  GoalContribution copyWith({
    String? id,
    String? goalId,
    String? userId,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return GoalContribution(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalContribution &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          userId == other.userId &&
          amount == other.amount &&
          date == other.date &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      goalId.hashCode ^
      userId.hashCode ^
      amount.hashCode ^
      date.hashCode ^
      note.hashCode;

  @override
  String toString() {
    return 'GoalContribution(id: $id, goalId: $goalId, amount: $amount, date: $date, note: $note)';
  }
}
