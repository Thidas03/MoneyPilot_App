import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction_model.dart';

/// Seed mock transactions for high-fidelity demonstration.
final List<Transaction> _initialTransactions = [
  Transaction(
    id: 'tx-1',
    title: 'Salary',
    category: 'Salary',
    amount: 250000,
    type: TransactionType.income,
    date: DateTime(2026, 9, 28),
    note: 'Monthly Flight Captain Salary',
  ),
  Transaction(
    id: 'tx-2',
    title: 'Keells Supermarket',
    category: 'Groceries',
    amount: 8450,
    type: TransactionType.expense,
    date: DateTime(2026, 9, 27),
    note: 'Weekly groceries and essentials',
  ),
  Transaction(
    id: 'tx-3',
    title: 'Uber',
    category: 'Transportation',
    amount: 2500,
    type: TransactionType.expense,
    date: DateTime(2026, 9, 26),
    note: 'Airport taxi transfer',
  ),
  Transaction(
    id: 'tx-4',
    title: 'Dialog',
    category: 'Utilities',
    amount: 1850,
    type: TransactionType.expense,
    date: DateTime(2026, 9, 25),
    note: 'Broadband & mobile postpaid bill',
  ),
  Transaction(
    id: 'tx-5',
    title: 'Coffee Shop',
    category: 'Dining Out',
    amount: 1200,
    type: TransactionType.expense,
    date: DateTime(2026, 9, 24),
    note: 'Artisan roast coffee & snacks',
  ),
];

/// Notifier managing transactions in-memory state.
class TransactionsNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() {
    return _initialTransactions;
  }

  void addTransaction(Transaction tx) {
    state = [tx, ...state];
  }

  void deleteTransaction(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

/// Provider for transactions list.
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

/// Total Income computed from transactions
final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0, (sum, item) => sum + item.amount);
});

/// Total Expense computed from transactions
final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (sum, item) => sum + item.amount);
});

/// Net Savings computed from transactions
final netSavingsProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseProvider);
  return income - expense;
});

/// Savings Rate percentage (0 to 100)
final savingsRateProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final savings = ref.watch(netSavingsProvider);
  if (income <= 0) return 0.0;
  final rate = (savings / income) * 100;
  return rate < 0 ? 0.0 : (rate > 100 ? 100.0 : rate);
});

/// Top most recent transactions for dashboard preview
final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.take(5).toList();
});
