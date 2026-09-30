import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';

/// Type of financial category.
enum CategoryType {
  income,
  expense,
  both;

  static CategoryType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'income':
        return CategoryType.income;
      case 'expense':
        return CategoryType.expense;
      case 'both':
      default:
        return CategoryType.both;
    }
  }

  String get value {
    switch (this) {
      case CategoryType.income:
        return 'income';
      case CategoryType.expense:
        return 'expense';
      case CategoryType.both:
        return 'both';
    }
  }
}

/// Domain model representing a financial category from public.categories.
class Category {
  final String id;
  final String? userId;
  final String name;
  final CategoryType type;
  final String icon;
  final String colorHex;
  final bool isSystem;
  final DateTime? createdAt;

  const Category({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    this.icon = 'category_outlined',
    this.colorHex = '#64748B',
    this.isSystem = false,
    this.createdAt,
  });

  /// Factory creating [Category] from a PostgreSQL/Supabase row map.
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String?,
      name: map['name'] as String? ?? '',
      type: CategoryType.fromString(map['type'] as String? ?? 'expense'),
      icon: map['icon'] as String? ?? 'category_outlined',
      colorHex: map['color_hex'] as String? ?? '#64748B',
      isSystem: map['is_system'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  /// Converts this [Category] to a Supabase-compatible map.
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty && !id.startsWith('cat-sys-')) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'type': type.value,
      'icon': icon,
      'color_hex': colorHex,
      'is_system': isSystem,
    };
  }

  /// Resolve appropriate Material IconData for this category.
  IconData get iconData => AppCategories.getIcon(name);

  /// Resolve color from hex string or fallback to category name color.
  Color get color {
    try {
      final clean = colorHex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
    } catch (_) {}
    return AppCategories.getColor(name);
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    CategoryType? type,
    String? icon,
    String? colorHex,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Default 12 system categories pre-seeded in the database architecture.
  static const List<Category> systemCategories = [
    Category(
      id: 'cat-sys-1',
      name: 'Salary',
      type: CategoryType.income,
      icon: 'account_balance_wallet_outlined',
      colorHex: '#10B981',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-2',
      name: 'Investments',
      type: CategoryType.income,
      icon: 'trending_up_outlined',
      colorHex: '#06B6D4',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-3',
      name: 'Rent/Mortgage',
      type: CategoryType.expense,
      icon: 'home_outlined',
      colorHex: '#6366F1',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-4',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart_outlined',
      colorHex: '#F59E0B',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-5',
      name: 'Utilities',
      type: CategoryType.expense,
      icon: 'flash_on_outlined',
      colorHex: '#EAB308',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-6',
      name: 'Dining Out',
      type: CategoryType.expense,
      icon: 'restaurant_outlined',
      colorHex: '#F97316',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-7',
      name: 'Transportation',
      type: CategoryType.expense,
      icon: 'directions_car_outlined',
      colorHex: '#3B82F6',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-8',
      name: 'Entertainment',
      type: CategoryType.expense,
      icon: 'movie_outlined',
      colorHex: '#EC4899',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-9',
      name: 'Shopping',
      type: CategoryType.expense,
      icon: 'shopping_bag_outlined',
      colorHex: '#8B5CF6',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-10',
      name: 'Health/Medical',
      type: CategoryType.expense,
      icon: 'medical_services_outlined',
      colorHex: '#EF4444',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-11',
      name: 'Education',
      type: CategoryType.expense,
      icon: 'school_outlined',
      colorHex: '#14B8A6',
      isSystem: true,
    ),
    Category(
      id: 'cat-sys-12',
      name: 'Misc',
      type: CategoryType.both,
      icon: 'category_outlined',
      colorHex: '#64748B',
      isSystem: true,
    ),
  ];
}
