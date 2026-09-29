import 'package:flutter/material.dart';

/// Goal domain model representing a financial savings milestone.
class Goal {
  final String id;
  final String title;
  final double currentAmount;
  final double targetAmount;
  final String deadline;
  final IconData icon;
  final Color color;

  const Goal({
    required this.id,
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    required this.deadline,
    this.icon = Icons.flag_rounded,
    this.color = const Color(0xFF005C46),
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  int get percent => (progress * 100).round();
  double get remaining => (targetAmount - currentAmount).clamp(0.0, targetAmount);
}
