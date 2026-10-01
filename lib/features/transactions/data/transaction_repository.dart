import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/transaction_model.dart';

/// Seed mock transactions for high-fidelity demonstration and test consistency.
final List<Transaction> initialMockTransactions = [
  Transaction(
    id: 'tx-1',
    title: 'Salary',
    category: 'Salary',
    categoryId: 'cat-sys-1',
    amount: 250000,
    type: TransactionType.income,
    date: DateTime.now(),
    note: 'Monthly Flight Captain Salary',
  ),
  Transaction(
    id: 'tx-2',
    title: 'Keells Supermarket',
    category: 'Groceries',
    categoryId: 'cat-sys-4',
    amount: 8450,
    type: TransactionType.expense,
    date: DateTime.now(),
    note: 'Weekly groceries and essentials',
  ),
  Transaction(
    id: 'tx-3',
    title: 'Uber',
    category: 'Transportation',
    categoryId: 'cat-sys-7',
    amount: 2500,
    type: TransactionType.expense,
    date: DateTime.now(),
    note: 'Airport taxi transfer',
  ),
  Transaction(
    id: 'tx-4',
    title: 'Dialog',
    category: 'Utilities',
    categoryId: 'cat-sys-5',
    amount: 1850,
    type: TransactionType.expense,
    date: DateTime.now(),
    note: 'Broadband & mobile postpaid bill',
  ),
  Transaction(
    id: 'tx-5',
    title: 'Coffee Shop',
    category: 'Dining Out',
    categoryId: 'cat-sys-6',
    amount: 1200,
    type: TransactionType.expense,
    date: DateTime.now(),
    note: 'Artisan roast coffee & snacks',
  ),
];

/// Contract defining transaction database operations.
abstract class TransactionRepository {
  /// Fetches transactions scoped to authenticated user with optional filtering.
  Future<List<Transaction>> getTransactions({
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  });

  /// Fetches the top recent transactions.
  Future<List<Transaction>> getRecentTransactions({int limit = 5});

  /// Fetches a single transaction by ID.
  Future<Transaction?> getTransactionById(String id);

  /// Saves a new transaction record.
  Future<Transaction> createTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String categoryName,
    required DateTime date,
    String? note,
  });

  /// Updates an existing transaction.
  Future<Transaction> updateTransaction(Transaction transaction);

  /// Deletes a transaction by ID.
  Future<void> deleteTransaction(String id);
}

/// Unified transaction repository implementation.
class SupabaseTransactionRepository implements TransactionRepository {
  SupabaseTransactionRepository({
    this.client,
    required this.authRepository,
  });

  final SupabaseClient? client;
  final AuthRepository authRepository;

  bool get isLiveSupabase => client != null;

  // In-memory mock storage for test and offline environments
  final List<Transaction> _mockTransactions = List<Transaction>.from(initialMockTransactions);

  @override
  Future<List<Transaction>> getTransactions({
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    if (!isLiveSupabase) {
      return _filterMockTransactions(
        type: type,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        search: search,
      );
    }

    try {
      final uid = authRepository.getCurrentUser()?.id;
      var query = client!
          .from('transactions')
          .select('*, categories(name, icon, color_hex)');

      if (uid != null) {
        query = query.eq('user_id', uid);
      }

      if (type != null) {
        query = query.eq('type', type.value);
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toUtc().toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toUtc().toIso8601String());
      }
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('title', '%${search.trim()}%');
      }

      final data = await query.order('transaction_date', ascending: false);
      final list = (data as List)
          .map((item) => Transaction.fromMap(item as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[TransactionRepository] Error fetching transactions: $e\n$st');
      }
      return <Transaction>[];
    }
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 5}) async {
    final list = await getTransactions();
    return list.take(limit).toList();
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    if (!isLiveSupabase) {
      try {
        return _mockTransactions.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }

    try {
      final res = await client!
          .from('transactions')
          .select('*, categories(name, icon, color_hex)')
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return Transaction.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Transaction> createTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String categoryName,
    required DateTime date,
    String? note,
  }) async {
    final user = authRepository.getCurrentUser();
    final newTx = Transaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id,
      categoryId: categoryId,
      category: categoryName,
      title: title.trim(),
      amount: amount,
      type: type,
      transactionDate: date,
      note: note?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (!isLiveSupabase) {
      _mockTransactions.insert(0, newTx);
      return newTx;
    }

    try {
      final insertData = {
        'user_id': user?.id,
        'category_id': categoryId,
        'title': title.trim(),
        'amount': amount,
        'type': type.value,
        'transaction_date': date.toUtc().toIso8601String(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final res = await client!
          .from('transactions')
          .insert(insertData)
          .select('*, categories(name, icon, color_hex)')
          .single();

      return Transaction.fromMap(res, resolvedCategoryName: categoryName);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[TransactionRepository] Create error, using local fallback: $e\n$st');
      }
      _mockTransactions.insert(0, newTx);
      return newTx;
    }
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    if (!isLiveSupabase) {
      final idx = _mockTransactions.indexWhere((t) => t.id == transaction.id);
      if (idx != -1) {
        _mockTransactions[idx] = transaction;
      }
      return transaction;
    }

    try {
      final updateData = {
        'title': transaction.title.trim(),
        'amount': transaction.amount,
        'type': transaction.type.value,
        'category_id': transaction.categoryId,
        'transaction_date': transaction.transactionDate.toUtc().toIso8601String(),
        'note': transaction.note?.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final res = await client!
          .from('transactions')
          .update(updateData)
          .eq('id', transaction.id)
          .select('*, categories(name, icon, color_hex)')
          .single();

      return Transaction.fromMap(res, resolvedCategoryName: transaction.category);
    } catch (e) {
      final idx = _mockTransactions.indexWhere((t) => t.id == transaction.id);
      if (idx != -1) {
        _mockTransactions[idx] = transaction;
      }
      return transaction;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (!isLiveSupabase) {
      _mockTransactions.removeWhere((t) => t.id == id);
      return;
    }

    try {
      await client!.from('transactions').delete().eq('id', id);
    } catch (e) {
      _mockTransactions.removeWhere((t) => t.id == id);
    }
  }

  List<Transaction> _filterMockTransactions({
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) {
    return _mockTransactions.where((t) {
      if (type != null && t.type != type) return false;
      if (categoryId != null && categoryId.isNotEmpty && t.categoryId != categoryId) return false;
      if (startDate != null && t.transactionDate.isBefore(startDate)) return false;
      if (endDate != null && t.transactionDate.isAfter(endDate)) return false;
      if (search != null && search.trim().isNotEmpty) {
        final query = search.trim().toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesCategory = t.category.toLowerCase().contains(query);
        final matchesNote = (t.note ?? '').toLowerCase().contains(query);
        if (!matchesTitle && !matchesCategory && !matchesNote) return false;
      }
      return true;
    }).toList();
  }
}

/// Provider injecting the [TransactionRepository].
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return SupabaseTransactionRepository(
    client: client,
    authRepository: authRepo,
  );
});
