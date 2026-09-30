import 'package:flutter/material.dart';

/// Factual, data-driven analytical insight derived from current user metrics.
class FinancialInsight {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const FinancialInsight({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}
