import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../transactions/data/transactions_provider.dart';
import '../../transactions/domain/transaction_model.dart';
import '../domain/budget_model.dart';
import 'budget_repository.dart';

/// Helper function to calculate exact spending for a budget from transaction expenses.
double calculateBudgetSpent({
  required Budget budget,
  required List<Transaction> transactions,
}) {
  return transactions.where((tx) {
    if (tx.type != TransactionType.expense) return false;
    if (tx.date.month != budget.month || tx.date.year != budget.year) return false;

    final txCat = tx.category.trim().toLowerCase();
    final bCat = budget.category.trim().toLowerCase();

    // Match by category ID if both IDs exist
    if (tx.categoryId.isNotEmpty &&
        budget.categoryId.isNotEmpty &&
        tx.categoryId == budget.categoryId) {
      return true;
    }

    // Match by exact or normalized category name
    if (txCat == bCat) return true;

    // Harmonize common category naming variants (e.g. Food & Dining vs Dining Out)
    if ((bCat == 'food & dining' || bCat == 'food and dining' || bCat == 'food') &&
        (txCat == 'dining out' || txCat == 'food & dining' || txCat == 'food')) {
      return true;
    }

    return false;
  }).fold<double>(0.0, (sum, tx) => sum + tx.amount);
}

/// Notifier managing category budgets, backed by [BudgetRepository] and dynamically
/// recalculating spending from [transactionsProvider].
class BudgetsNotifier extends Notifier<List<Budget>> {
  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  List<Budget> _baseBudgets = [];
  bool _hasLoadedLive = false;

  @override
  List<Budget> build() {
    final isLive = ref.watch(supabaseClientProvider) != null;
    final transactions = ref.watch(transactionsProvider);

    if (isLive) {
      if (!_hasLoadedLive) {
        _baseBudgets = [];
        _loadLiveBudgets();
      }
      return _applySpending(_baseBudgets, transactions);
    }

    if (!_hasLoadedLive) {
      _baseBudgets = List<Budget>.from(initialMockBudgets);
      _loadLiveBudgets();
    }
    return _applySpending(_baseBudgets, transactions);
  }

  Future<void> _loadLiveBudgets() async {
    if (_hasLoadedLive) return;
    _hasLoadedLive = true;
    try {
      final list = await _repo.getCurrentMonthBudgets();
      final isLive = ref.read(supabaseClientProvider) != null;

      if (isLive) {
        _baseBudgets = list;
      } else if (list.isNotEmpty) {
        _baseBudgets = list;
      }
      final transactions = ref.read(transactionsProvider);
      state = _applySpending(_baseBudgets, transactions);
    } catch (_) {
      // Offline fallback remains active
    }
  }

  /// Calculates dynamic spending for all budgets given the current transactions.
  List<Budget> _applySpending(List<Budget> budgets, List<Transaction> transactions) {
    return budgets.map((b) {
      final calculatedSpent = calculateBudgetSpent(budget: b, transactions: transactions);
      return b.copyWith(spent: calculatedSpent);
    }).toList();
  }

  /// Reloads budgets from the repository and recalculates spending.
  Future<void> refresh() async {
    try {
      final list = await _repo.getCurrentMonthBudgets();
      if (list.isNotEmpty) {
        _baseBudgets = list;
      }
      final transactions = ref.read(transactionsProvider);
      state = _applySpending(_baseBudgets, transactions);
    } catch (_) {}
  }

  /// Adds a new budget or updates an existing one (instant synchronous UI update + async persist).
  Future<Budget> addOrUpdateBudget(Budget newBudget) async {
    final index = _baseBudgets.indexWhere(
      (b) =>
          b.id == newBudget.id ||
          b.category.toLowerCase() == newBudget.category.toLowerCase(),
    );

    Budget saved;
    if (index >= 0) {
      final updatedList = List<Budget>.from(_baseBudgets);
      updatedList[index] = newBudget;
      _baseBudgets = updatedList;

      // Update state synchronously for instant reactivity
      final transactions = ref.read(transactionsProvider);
      state = _applySpending(_baseBudgets, transactions);

      saved = await _repo.updateBudget(newBudget);
    } else {
      _baseBudgets = [..._baseBudgets, newBudget];

      // Update state synchronously for instant reactivity
      final transactions = ref.read(transactionsProvider);
      state = _applySpending(_baseBudgets, transactions);

      saved = await _repo.createBudget(
        categoryId: newBudget.categoryId,
        categoryName: newBudget.category,
        amount: newBudget.amount,
        period: newBudget.period,
        month: newBudget.month,
        year: newBudget.year,
        note: newBudget.note,
      );

      final idx = _baseBudgets.indexWhere(
        (b) => b.category.toLowerCase() == saved.category.toLowerCase(),
      );
      if (idx >= 0) {
        _baseBudgets[idx] = saved;
      }
    }

    return saved;
  }

  /// Creates a new budget in the repository and updates state.
  Future<Budget> createBudget({
    required String categoryId,
    required String categoryName,
    required double amount,
    String period = 'Monthly',
    int? month,
    int? year,
    String? note,
  }) async {
    final created = await _repo.createBudget(
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount,
      period: period,
      month: month,
      year: year,
      note: note,
    );

    // Replace if existing category or prepend
    final idx = _baseBudgets.indexWhere(
      (b) => b.category.toLowerCase() == categoryName.toLowerCase(),
    );
    if (idx >= 0) {
      final updated = List<Budget>.from(_baseBudgets);
      updated[idx] = created;
      _baseBudgets = updated;
    } else {
      _baseBudgets = [..._baseBudgets, created];
    }

    final transactions = ref.read(transactionsProvider);
    state = _applySpending(_baseBudgets, transactions);
    return created;
  }

  /// Updates an existing budget in repository and state.
  Future<Budget> updateBudget(Budget budget) async {
    final updated = await _repo.updateBudget(budget);
    final idx = _baseBudgets.indexWhere((b) => b.id == updated.id);
    if (idx >= 0) {
      final updatedList = List<Budget>.from(_baseBudgets);
      updatedList[idx] = updated;
      _baseBudgets = updatedList;
    }
    final transactions = ref.read(transactionsProvider);
    state = _applySpending(_baseBudgets, transactions);
    return updated;
  }

  /// Deletes a budget by ID from repository and state.
  Future<void> deleteBudget(String id) async {
    await _repo.deleteBudget(id);
    _baseBudgets = _baseBudgets.where((b) => b.id != id).toList();
    final transactions = ref.read(transactionsProvider);
    state = _applySpending(_baseBudgets, transactions);
  }

  /// Synchronous removal for test / legacy compatibility.
  void removeBudget(String id) {
    _baseBudgets = _baseBudgets.where((b) => b.id != id).toList();
    final transactions = ref.read(transactionsProvider);
    state = _applySpending(_baseBudgets, transactions);
    _repo.deleteBudget(id);
  }
}

/// Provider for reactive list of category budgets with dynamic spending calculation.
final budgetsProvider = NotifierProvider<BudgetsNotifier, List<Budget>>(() {
  return BudgetsNotifier();
});

/// Near-limit alert provider: returns budgets where spending has reached 80% or more (and not over).
final nearLimitBudgetsProvider = Provider<List<Budget>>((ref) {
  final budgets = ref.watch(budgetsProvider);
  return budgets.where((b) => b.isNearLimit).toList();
});

/// Over-budget alert provider: returns budgets where spending has exceeded the budget limit.
final overBudgetBudgetsProvider = Provider<List<Budget>>((ref) {
  final budgets = ref.watch(budgetsProvider);
  return budgets.where((b) => b.isOverBudget).toList();
});

/// Combined active alerts provider for dashboard and budget screens.
final activeBudgetAlertsProvider = Provider<List<Budget>>((ref) {
  final budgets = ref.watch(budgetsProvider);
  return budgets.where((b) => b.isOverBudget || b.isNearLimit).toList();
});

/// Overall monthly budget target limit.
class MonthlyBudgetTargetNotifier extends Notifier<double> {
  @override
  double build() => 50000.0;

  void setTarget(double newTarget) {
    if (newTarget > 0) {
      state = newTarget;
    }
  }
}

/// Provider for overall monthly budget target limit.
final monthlyBudgetTargetProvider =
    NotifierProvider<MonthlyBudgetTargetNotifier, double>(() {
  return MonthlyBudgetTargetNotifier();
});
