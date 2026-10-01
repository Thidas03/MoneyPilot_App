import 'package:flutter/material.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/utils/date_formatter.dart';

/// Supported frequency recurrence intervals for reminders matching the PostgreSQL constraint:
/// CHECK (frequency IN ('once', 'daily', 'weekly', 'monthly', 'yearly'))
enum ReminderFrequency {
  once,
  daily,
  weekly,
  monthly,
  yearly;

  /// Human-readable label for UI display.
  String get label => displayName;

  /// Human-readable label for UI display.
  String get displayName {
    switch (this) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
      case ReminderFrequency.yearly:
        return 'Yearly';
    }
  }

  /// PostgreSQL string value.
  String get value => name;

  /// Converts a database string into a typed [ReminderFrequency].
  static ReminderFrequency fromString(String? value) {
    if (value == null) return ReminderFrequency.monthly;
    switch (value.trim().toLowerCase()) {
      case 'daily':
        return ReminderFrequency.daily;
      case 'weekly':
        return ReminderFrequency.weekly;
      case 'monthly':
        return ReminderFrequency.monthly;
      case 'yearly':
        return ReminderFrequency.yearly;
      case 'once':
        return ReminderFrequency.once;
      default:
        return ReminderFrequency.monthly;
    }
  }

  /// PostgreSQL string value.
  String toDbString() => name;
}

/// Compatibility extension for ReminderFrequency.fromString.
extension ReminderFrequencyExtension on ReminderFrequency {
  static ReminderFrequency fromString(String? value) =>
      ReminderFrequency.fromString(value);
}

/// Strongly typed entity representing a record from public.reminders.
class Reminder {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final double? amount;
  final DateTime dueDate;
  final ReminderFrequency frequency;
  final bool isCompleted;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined category metadata (if resolved via foreign key)
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColorHex;

  /// Category name alias
  String? get category => categoryName;

  Reminder({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.amount,
    required this.dueDate,
    this.frequency = ReminderFrequency.once,
    this.isCompleted = false,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? category,
    this.categoryIcon,
    this.categoryColorHex,
  })  : categoryName = categoryName ?? category,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Deserializes a database row or JSON map from Supabase into a strongly typed [Reminder].
  factory Reminder.fromJson(Map<String, dynamic> json) {
    // Check for joined category object: categories(id, name, icon, color_hex)
    String? catName;
    String? catIcon;
    String? catColor;

    if (json['categories'] is Map<String, dynamic>) {
      final catMap = json['categories'] as Map<String, dynamic>;
      catName = catMap['name'] as String?;
      catIcon = catMap['icon'] as String?;
      catColor = catMap['color_hex'] as String?;
    } else {
      catName = json['category_name'] as String?;
      catIcon = json['category_icon'] as String?;
      catColor = json['category_color'] as String?;
    }

    final rawDueDate = json['due_date'];
    DateTime parsedDueDate;
    if (rawDueDate is DateTime) {
      parsedDueDate = rawDueDate;
    } else if (rawDueDate != null) {
      parsedDueDate = DateTime.tryParse(rawDueDate.toString()) ?? DateTime.now();
    } else {
      parsedDueDate = DateTime.now();
    }

    final rawCreatedAt = json['created_at'];
    DateTime parsedCreatedAt;
    if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt != null) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    final rawUpdatedAt = json['updated_at'];
    DateTime parsedUpdatedAt;
    if (rawUpdatedAt is DateTime) {
      parsedUpdatedAt = rawUpdatedAt;
    } else if (rawUpdatedAt != null) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt.toString()) ?? DateTime.now();
    } else {
      parsedUpdatedAt = DateTime.now();
    }

    return Reminder(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      dueDate: parsedDueDate,
      frequency: ReminderFrequency.fromString(json['frequency'] as String?),
      isCompleted: json['is_completed'] as bool? ?? false,
      note: json['note'] as String?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      categoryName: catName,
      categoryIcon: catIcon,
      categoryColorHex: catColor,
    );
  }

  /// Serializes into a JSON map or cache payload.
  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'frequency': frequency.toDbString(),
      'is_completed': isCompleted,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (categoryName != null) 'category_name': categoryName,
      if (categoryIcon != null) 'category_icon': categoryIcon,
      if (categoryColorHex != null) 'category_color': categoryColorHex,
    };

    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  /// Prepares a payload strictly formatted for Supabase insert/update.
  Map<String, dynamic> toSupabaseMap() {
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);

    return {
      if (isUuid) 'id': id,
      'user_id': userId,
      'category_id': (categoryId != null && categoryId!.isNotEmpty) ? categoryId : null,
      'title': title.trim(),
      'amount': amount,
      'due_date': dueDate.toUtc().toIso8601String(),
      'frequency': frequency.toDbString(),
      'is_completed': isCompleted,
      'note': (note != null && note!.trim().isNotEmpty) ? note!.trim() : null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Reminder copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    double? amount,
    DateTime? dueDate,
    ReminderFrequency? frequency,
    bool? isCompleted,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? category,
    String? categoryIcon,
    String? categoryColorHex,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? category ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
    );
  }

  // --- Convenience Getters ---

  /// Effective category name, falling back to 'General' if unassigned.
  String get displayCategory => categoryName ?? 'General';

  /// Icon associated with the category.
  IconData get iconData => AppCategories.getIcon(displayCategory);

  /// Color associated with the category.
  Color get color => AppCategories.getColor(displayCategory);

  /// Formatted due date string (e.g., "Oct 5, 2026").
  String get formattedDueDate => DateFormatter.formatDate(dueDate);

  /// Number of calendar days until this reminder is due (negative if overdue).
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.difference(today).inDays;
  }

  /// Whether this reminder is overdue and uncompleted.
  bool get isOverdue {
    if (isCompleted) return false;
    return daysUntilDue < 0;
  }

  /// Whether this reminder is due today.
  bool get isDueToday {
    return daysUntilDue == 0;
  }

  /// Human-friendly relative due description (e.g. "Due today", "Due in 3 days", "Overdue by 2 days").
  String get relativeDueDescription {
    if (isCompleted) return 'Completed';
    final days = daysUntilDue;
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days > 1) return 'Due in $days days';
    if (days == -1) return 'Overdue by 1 day';
    return 'Overdue by ${days.abs()} days';
  }
}
