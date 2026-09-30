import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/budget_model.dart';

/// Exception thrown when attempting to create a duplicate budget for the same category and period.
class BudgetDuplicateException implements Exception {
  final String message;
  const BudgetDuplicateException(this.message);

  @override
  String toString() => message;
}

/// Seed initial category budgets matching requested design specifications.
final List<Budget> initialMockBudgets = [
  Budget(
    id: 'budget-1',
    categoryId: 'cat-sys-6',
    category: 'Food & Dining',
    categoryIcon: 'restaurant_outlined',
    categoryColor: '#F97316',
    amount: 25000,
    spent: 0,
    period: 'Monthly',
    month: 9,
    year: 2026,
    note: 'Dining out, cafes and takeout allowance',
    createdAt: DateTime(2026, 9, 1),
  ),
  Budget(
    id: 'budget-2',
    categoryId: 'cat-sys-7',
    category: 'Transportation',
    categoryIcon: 'directions_car_outlined',
    categoryColor: '#3B82F6',
    amount: 15000,
    spent: 0,
    period: 'Monthly',
    month: 9,
    year: 2026,
    note: 'Fuel, tolls, ride-shares and taxi transfers',
    createdAt: DateTime(2026, 9, 1),
  ),
  Budget(
    id: 'budget-3',
    categoryId: 'cat-sys-8',
    category: 'Entertainment',
    categoryIcon: 'movie_outlined',
    categoryColor: '#EC4899',
    amount: 10000,
    spent: 0,
    period: 'Monthly',
    month: 9,
    year: 2026,
    note: 'Movies, streaming subscriptions, events',
    createdAt: DateTime(2026, 9, 1),
  ),
];

/// Contract defining budget repository operations.
abstract class BudgetRepository {
  /// Fetches budgets for the authenticated user, optionally filtered by month and year.
  Future<List<Budget>> getBudgets({int? month, int? year});

  /// Fetches budgets for the current calendar month.
  Future<List<Budget>> getCurrentMonthBudgets();

  /// Fetches a single budget by ID.
  Future<Budget?> getBudgetById(String id);

  /// Creates a new category budget.
  Future<Budget> createBudget({
    required String categoryId,
    required String categoryName,
    required double amount,
    String period = 'Monthly',
    int? month,
    int? year,
    String? note,
  });

  /// Updates an existing budget.
  Future<Budget> updateBudget(Budget budget);

  /// Deletes a budget by ID.
  Future<void> deleteBudget(String id);
}

/// Unified Supabase repository supporting real PostgreSQL tables and offline mock fallback.
class SupabaseBudgetRepository implements BudgetRepository {
  SupabaseBudgetRepository({
    this.client,
    required this.authRepository,
  });

  final SupabaseClient? client;
  final AuthRepository authRepository;

  bool get isLiveSupabase => client != null;

  // In-memory mock storage for test and offline environments
  final List<Budget> _mockBudgets = List<Budget>.from(initialMockBudgets);

  @override
  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    if (!isLiveSupabase) {
      return _filterMockBudgets(month: month, year: year);
    }

    try {
      var query = client!
          .from('budgets')
          .select('*, categories(name, icon, color_hex)');

      if (month != null && year != null) {
        final startDateStr =
            '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
        query = query.eq('start_date', startDateStr);
      }

      final data = await query.order('created_at', ascending: true);
      final list = (data as List)
          .map((item) => Budget.fromMap(item as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return _filterMockBudgets(month: month, year: year);
      }
      return list;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[BudgetRepository] Error fetching live budgets: $e\n$st');
      }
      return _filterMockBudgets(month: month, year: year);
    }
  }

  @override
  Future<List<Budget>> getCurrentMonthBudgets() {
    final now = DateTime.now();
    return getBudgets(month: now.month, year: now.year);
  }

  @override
  Future<Budget?> getBudgetById(String id) async {
    if (!isLiveSupabase) {
      try {
        return _mockBudgets.firstWhere((b) => b.id == id);
      } catch (_) {
        return null;
      }
    }

    try {
      final res = await client!
          .from('budgets')
          .select('*, categories(name, icon, color_hex)')
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return Budget.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Budget> createBudget({
    required String categoryId,
    required String categoryName,
    required double amount,
    String period = 'Monthly',
    int? month,
    int? year,
    String? note,
  }) async {
    final now = DateTime.now();
    final effectiveMonth = month ?? now.month;
    final effectiveYear = year ?? now.year;
    final user = authRepository.getCurrentUser();

    final lastDay = DateTime(effectiveYear, effectiveMonth + 1, 0).day;
    final startDateStr =
        '${effectiveYear.toString().padLeft(4, '0')}-${effectiveMonth.toString().padLeft(2, '0')}-01';
    final endDateStr =
        '${effectiveYear.toString().padLeft(4, '0')}-${effectiveMonth.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final newBudget = Budget(
      id: 'budget-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id,
      categoryId: categoryId,
      category: categoryName,
      amount: amount,
      spent: 0.0,
      period: period,
      month: effectiveMonth,
      year: effectiveYear,
      startDate: DateTime(effectiveYear, effectiveMonth, 1),
      endDate: DateTime(effectiveYear, effectiveMonth, lastDay),
      note: note?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Duplicate check in mock mode
    if (!isLiveSupabase) {
      final duplicate = _mockBudgets.any((b) =>
          (b.categoryId == categoryId ||
              b.category.toLowerCase() == categoryName.toLowerCase()) &&
          b.month == effectiveMonth &&
          b.year == effectiveYear);
      if (duplicate) {
        throw BudgetDuplicateException(
          'A budget for "$categoryName" already exists for this period.',
        );
      }

      _mockBudgets.add(newBudget);
      return newBudget;
    }

    try {
      final insertData = {
        'user_id': user?.id,
        'category_id': categoryId,
        'amount': amount,
        'period': period.toLowerCase(),
        'start_date': startDateStr,
        'end_date': endDateStr,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final res = await client!
          .from('budgets')
          .insert(insertData)
          .select('*, categories(name, icon, color_hex)')
          .single();

      return Budget.fromMap(res, resolvedCategoryName: categoryName);
    } on PostgrestException catch (pe) {
      if (pe.code == '23505') {
        throw BudgetDuplicateException(
          'A budget for "$categoryName" already exists for this period.',
        );
      }
      if (kDebugMode) {
        debugPrint('[BudgetRepository] Supabase PostgrestException: ${pe.message}');
      }
      _mockBudgets.add(newBudget);
      return newBudget;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[BudgetRepository] Create error, using fallback: $e\n$st');
      }
      _mockBudgets.add(newBudget);
      return newBudget;
    }
  }

  @override
  Future<Budget> updateBudget(Budget budget) async {
    if (!isLiveSupabase) {
      final idx = _mockBudgets.indexWhere((b) => b.id == budget.id);
      if (idx != -1) {
        _mockBudgets[idx] = budget;
      } else {
        _mockBudgets.add(budget);
      }
      return budget;
    }

    try {
      final lastDay = DateTime(budget.year, budget.month + 1, 0).day;
      final startDateStr =
          '${budget.year.toString().padLeft(4, '0')}-${budget.month.toString().padLeft(2, '0')}-01';
      final endDateStr =
          '${budget.year.toString().padLeft(4, '0')}-${budget.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final updateData = {
        'amount': budget.amount,
        'period': budget.period.toLowerCase(),
        'start_date': startDateStr,
        'end_date': endDateStr,
        'note': budget.note?.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final res = await client!
          .from('budgets')
          .update(updateData)
          .eq('id', budget.id)
          .select('*, categories(name, icon, color_hex)')
          .single();

      return Budget.fromMap(res, resolvedCategoryName: budget.category);
    } catch (e) {
      final idx = _mockBudgets.indexWhere((b) => b.id == budget.id);
      if (idx != -1) {
        _mockBudgets[idx] = budget;
      }
      return budget;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    if (!isLiveSupabase) {
      _mockBudgets.removeWhere((b) => b.id == id);
      return;
    }

    try {
      await client!.from('budgets').delete().eq('id', id);
    } catch (e) {
      _mockBudgets.removeWhere((b) => b.id == id);
    }
  }

  List<Budget> _filterMockBudgets({int? month, int? year}) {
    if (month == null && year == null) {
      return List.unmodifiable(_mockBudgets);
    }
    return _mockBudgets.where((b) {
      if (month != null && b.month != month) return false;
      if (year != null && b.year != year) return false;
      return true;
    }).toList();
  }
}

/// Provider exposing [BudgetRepository] configured with live or mock dependencies.
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return SupabaseBudgetRepository(
    client: client,
    authRepository: authRepo,
  );
});
