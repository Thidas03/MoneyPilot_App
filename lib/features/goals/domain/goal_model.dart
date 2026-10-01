import 'package:flutter/material.dart';

/// Goal domain model representing a financial savings milestone.
class Goal {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadlineDate;
  final String? note;
  final String iconName;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.id,
    this.userId = '',
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadlineDate,
    this.note,
    this.iconName = 'flag_rounded',
    this.colorHex = '#005C46',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Legacy convenience constructor supporting existing string deadlines (e.g. 'Dec 2026', 'Apr 2027')
  factory Goal.legacy({
    required String id,
    required String title,
    required double currentAmount,
    required double targetAmount,
    required String deadline,
    IconData icon = Icons.flag_rounded,
    Color color = const Color(0xFF005C46),
    String? note,
  }) {
    DateTime parsedDate;
    try {
      final parts = deadline.trim().split(' ');
      if (parts.length == 2) {
        final monthStr = parts[0].toLowerCase();
        final year = int.tryParse(parts[1]) ?? DateTime.now().year + 1;
        const months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        };
        final m = months[monthStr.substring(0, 3)] ?? 12;
        parsedDate = DateTime(year, m, 28);
      } else {
        parsedDate = DateTime.tryParse(deadline) ?? DateTime.now().add(const Duration(days: 365));
      }
    } catch (_) {
      parsedDate = DateTime.now().add(const Duration(days: 365));
    }

    return Goal(
      id: id,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadlineDate: parsedDate,
      note: note,
      iconName: _iconDataToName(icon),
      colorHex: '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    );
  }

  // --- Computed Business Logic Properties ---

  /// Remaining amount: targetAmount - currentAmount, never negative.
  double get remainingAmount {
    final rem = targetAmount - currentAmount;
    return rem < 0 ? 0.0 : rem;
  }

  /// Alias for compatibility with existing dashboard code.
  double get remaining => remainingAmount;

  /// Progress percentage: 0 to 100%. Safely handles targetAmount <= 0.
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final pct = (currentAmount / targetAmount) * 100;
    return pct.clamp(0.0, 100.0);
  }

  /// Progress ratio: 0.0 to 1.0 for progress indicators.
  double get progressRatio => progressPercentage / 100.0;

  /// Alias for compatibility with existing dashboard code.
  double get progress => progressRatio;

  /// Integer percentage (0 to 100).
  int get percent => progressPercentage.round();

  /// Whether the goal is completed.
  bool get isCompleted => targetAmount > 0 && currentAmount >= targetAmount;

  /// Whether the goal is near completion (80%+ progress and not yet completed).
  bool get isNearCompletion => progressPercentage >= 80.0 && !isCompleted;

  /// Number of calendar days between today and the deadline.
  /// Handles past deadlines safely (returns negative integer if overdue).
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadlineDate.year, deadlineDate.month, deadlineDate.day);
    return target.difference(today).inDays;
  }

  /// Human-friendly deadline string (e.g. 'Dec 31, 2026').
  String get deadline {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = monthNames[deadlineDate.month - 1];
    return '$m ${deadlineDate.day}, ${deadlineDate.year}';
  }

  /// Human-friendly ETA string (e.g. 'Dec 2026').
  String get etaText {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monthNames[deadlineDate.month - 1]} ${deadlineDate.year}';
  }

  /// Visual IconData resolution from iconName.
  IconData get icon => _nameToIconData(iconName);

  /// Visual Color resolution from colorHex.
  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF005C46);
    }
  }

  // --- Serialization for Supabase PostgreSQL Table ---

  /// Parses a Supabase row map into a Goal domain model.
  factory Goal.fromMap(Map<String, dynamic> map) {
    DateTime parsedDeadline;
    final rawDeadline = map['target_date'] ?? map['deadline'];
    if (rawDeadline is DateTime) {
      parsedDeadline = rawDeadline;
    } else if (rawDeadline != null) {
      parsedDeadline = DateTime.tryParse(rawDeadline.toString()) ?? DateTime.now().add(const Duration(days: 180));
    } else {
      parsedDeadline = DateTime.now().add(const Duration(days: 180));
    }

    return Goal(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      deadlineDate: parsedDeadline,
      note: map['note']?.toString(),
      iconName: map['icon']?.toString() ?? map['icon_name']?.toString() ?? 'flag_rounded',
      colorHex: map['color_hex']?.toString() ?? map['color']?.toString() ?? '#005C46',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  /// Formats the Goal model into a map for Supabase insertion or update.
  Map<String, dynamic> toMap({String? currentUserId}) {
    return {
      if (id.isNotEmpty) 'id': id,
      if ((currentUserId ?? userId).isNotEmpty) 'user_id': currentUserId ?? userId,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadlineDate.toIso8601String().split('T').first,
      if (note != null) 'note': note,
      'icon': iconName,
      'color': colorHex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Formats the Goal model into a clean map matching the Supabase `savings_goals` table schema.
  Map<String, dynamic> toSavingsGoalsMap({String? currentUserId, bool includeNote = true}) {
    final effectiveUserId = (currentUserId != null && currentUserId.isNotEmpty)
        ? currentUserId
        : (userId.isNotEmpty ? userId : null);
    final targetDateStr = deadlineDate.toIso8601String().split('T').first;
    final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    return {
      if (id.isNotEmpty && isUuid.hasMatch(id)) 'id': id,
      if (effectiveUserId != null && effectiveUserId.isNotEmpty) 'user_id': effectiveUserId,
      'title': title.trim(),
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDateStr,
      'icon': iconName,
      'color_hex': colorHex,
      'status': isCompleted ? 'completed' : 'in_progress',
      if (includeNote && note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Immutability copyWith helper.
  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadlineDate,
    String? note,
    String? iconName,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      note: note ?? this.note,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // --- Icon mapping helpers ---

  static IconData _nameToIconData(String name) {
    switch (name.toLowerCase()) {
      case 'shield_rounded':
      case 'shield':
        return Icons.shield_rounded;
      case 'flight_takeoff_rounded':
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'home_rounded':
      case 'home':
        return Icons.home_rounded;
      case 'directions_car_rounded':
      case 'car':
        return Icons.directions_car_rounded;
      case 'school_rounded':
      case 'education':
        return Icons.school_rounded;
      case 'laptop_mac_rounded':
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'beach_access_rounded':
      case 'vacation':
        return Icons.beach_access_rounded;
      case 'diamond_rounded':
      case 'diamond':
        return Icons.diamond_rounded;
      case 'savings_rounded':
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  static String _iconDataToName(IconData icon) {
    if (icon == Icons.shield_rounded) return 'shield_rounded';
    if (icon == Icons.flight_takeoff_rounded) return 'flight_takeoff_rounded';
    if (icon == Icons.home_rounded) return 'home_rounded';
    if (icon == Icons.directions_car_rounded) return 'directions_car_rounded';
    if (icon == Icons.school_rounded) return 'school_rounded';
    if (icon == Icons.laptop_mac_rounded) return 'laptop_mac_rounded';
    if (icon == Icons.beach_access_rounded) return 'beach_access_rounded';
    if (icon == Icons.diamond_rounded) return 'diamond_rounded';
    if (icon == Icons.savings_rounded) return 'savings_rounded';
    return 'flag_rounded';
  }
}
