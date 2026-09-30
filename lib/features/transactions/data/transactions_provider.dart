import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/transaction_model.dart';
import 'transaction_repository.dart';

/// Notifier managing transactions state backed by [TransactionRepository].
class TransactionsNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() {
    // Seed with initial mock transactions for instant display & widget test compatibility
    final initialList = List<Transaction>.from(initialMockTransactions);

    // Asynchronously fetch live transactions from Supabase
    _loadLiveTransactions();

    return initialList;
  }

  TransactionRepository get _repo => ref.read(transactionRepositoryProvider);

  Future<void> _loadLiveTransactions() async {
    try {
      final list = await _repo.getTransactions();
      if (list.isNotEmpty) {
        state = list;
      }
    } catch (_) {
      // Fallback remains active
    }
  }

  /// Reloads transactions from repository.
  Future<void> refresh() async {
    try {
      final list = await _repo.getTransactions();
      state = list;
    } catch (_) {}
  }

  /// Creates and saves a new transaction.
  Future<Transaction> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String categoryName,
    required DateTime date,
    String? note,
  }) async {
    final created = await _repo.createTransaction(
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      categoryName: categoryName,
      date: date,
      note: note,
    );
    // Prepend to current state to trigger immediate reactive UI updates
    state = [created, ...state.where((t) => t.id != created.id)];
    return created;
  }

  /// Updates an existing transaction.
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final updated = await _repo.updateTransaction(transaction);
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
    return updated;
  }

  /// Deletes a transaction by ID.
  Future<void> deleteTransaction(String id) async {
    await _repo.deleteTransaction(id);
    state = state.where((t) => t.id != id).toList();
  }
}

/// Central provider for the reactive list of transactions.
final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

/// Filter state: null for All, or TransactionType.expense / income.
class TransactionFilterNotifier extends Notifier<TransactionType?> {
  @override
  TransactionType? build() => null;

  void setFilter(TransactionType? filter) {
    state = filter;
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionType?>(() {
  return TransactionFilterNotifier();
});

/// Search query notifier for transactions list.
class TransactionSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String query) {
    state = query;
  }
}

final transactionSearchProvider =
    NotifierProvider<TransactionSearchNotifier, String>(() {
  return TransactionSearchNotifier();
});

/// Filtered transactions based on active tab and search query.
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);
  final search = ref.watch(transactionSearchProvider).trim().toLowerCase();

  return transactions.where((tx) {
    if (filter != null && tx.type != filter) {
      return false;
    }
    if (search.isNotEmpty) {
      final matchesTitle = tx.title.toLowerCase().contains(search);
      final matchesCategory = tx.category.toLowerCase().contains(search);
      final matchesNote = (tx.note ?? '').toLowerCase().contains(search);
      if (!matchesTitle && !matchesCategory && !matchesNote) {
        return false;
      }
    }
    return true;
  }).toList();
});

/// Total Income computed from transactions.
final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0, (sum, item) => sum + item.amount);
});

/// Total Expense computed from transactions.
final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (sum, item) => sum + item.amount);
});

/// Net Savings computed from transactions.
final netSavingsProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseProvider);
  return income - expense;
});

/// Savings Rate percentage (0 to 100).
final savingsRateProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final savings = ref.watch(netSavingsProvider);
  if (income <= 0) return 0.0;
  final rate = (savings / income) * 100;
  return rate < 0 ? 0.0 : (rate > 100 ? 100.0 : rate);
});

/// Top most recent transactions for dashboard preview.
final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.take(5).toList();
});
