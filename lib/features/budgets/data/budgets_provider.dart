import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/budget_model.dart';

/// Seed initial category budgets matching requested design specifications.
final List<Budget> _initialBudgets = [
  Budget(
    id: 'budget-1',
    category: 'Food & Dining',
    amount: 25000,
    spent: 18500,
    period: 'Monthly',
    note: 'Dining out, cafes and takeout allowance',
    createdAt: DateTime(2026, 9, 1),
  ),
  Budget(
    id: 'budget-2',
    category: 'Transportation',
    amount: 15000,
    spent: 9200,
    period: 'Monthly',
    note: 'Fuel, tolls, ride-shares and taxi transfers',
    createdAt: DateTime(2026, 9, 1),
  ),
  Budget(
    id: 'budget-3',
    category: 'Entertainment',
    amount: 10000,
    spent: 6500,
    period: 'Monthly',
    note: 'Movies, streaming subscriptions, events',
    createdAt: DateTime(2026, 9, 1),
  ),
];

/// Notifier managing category budgets.
class BudgetsNotifier extends Notifier<List<Budget>> {
  @override
  List<Budget> build() {
    return _initialBudgets;
  }

  void addOrUpdateBudget(Budget newBudget) {
    final index = state.indexWhere(
      (b) => b.category.toLowerCase() == newBudget.category.toLowerCase(),
    );

    if (index >= 0) {
      final updated = List<Budget>.from(state);
      updated[index] = newBudget;
      state = updated;
    } else {
      state = [...state, newBudget];
    }
  }

  void removeBudget(String id) {
    state = state.where((b) => b.id != id).toList();
  }
}

/// Provider for list of category budgets.
final budgetsProvider = NotifierProvider<BudgetsNotifier, List<Budget>>(() {
  return BudgetsNotifier();
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
