import 'package:flutter/material.dart';

/// Predefined categories and icon/color helpers for MoneyPilot.
/// Matches existing categories on the web platform while supporting custom user categories.
class AppCategories {
  AppCategories._();

  static const List<String> defaultCategories = [
    'Salary',
    'Investments',
    'Rent/Mortgage',
    'Groceries',
    'Utilities',
    'Dining Out',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Health/Medical',
    'Education',
    'Misc',
  ];

  /// Categorize an icon based on category name.
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.account_balance_wallet_outlined;
      case 'investments':
        return Icons.trending_up_outlined;
      case 'rent/mortgage':
      case 'rent':
      case 'mortgage':
        return Icons.home_outlined;
      case 'groceries':
        return Icons.shopping_cart_outlined;
      case 'utilities':
        return Icons.flash_on_outlined;
      case 'dining out':
      case 'food':
        return Icons.restaurant_outlined;
      case 'transportation':
      case 'travel':
        return Icons.directions_car_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'health/medical':
      case 'health':
      case 'medical':
        return Icons.medical_services_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'misc':
      default:
        return Icons.category_outlined;
    }
  }

  /// Categorize color based on category name.
  static Color getColor(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return const Color(0xFF10B981); // Emerald
      case 'investments':
        return const Color(0xFF06B6D4); // Cyan
      case 'rent/mortgage':
        return const Color(0xFF6366F1); // Indigo
      case 'groceries':
        return const Color(0xFFF59E0B); // Amber
      case 'utilities':
        return const Color(0xFFEAB308); // Yellow
      case 'dining out':
        return const Color(0xFFF97316); // Orange
      case 'transportation':
        return const Color(0xFF3B82F6); // Blue
      case 'entertainment':
        return const Color(0xFFEC4899); // Pink
      case 'shopping':
        return const Color(0xFF8B5CF6); // Purple
      case 'health/medical':
        return const Color(0xFFEF4444); // Red
      case 'education':
        return const Color(0xFF14B8A6); // Teal
      case 'misc':
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}
