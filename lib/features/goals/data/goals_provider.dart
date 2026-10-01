import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_service.dart';
import '../domain/goal_contribution_model.dart';
import '../domain/goal_model.dart';
import 'goal_repository.dart';

/// Notifier managing financial savings goals state.
class GoalsNotifier extends Notifier<List<Goal>> {
  GoalRepository get _repository => ref.read(goalRepositoryProvider);

  @override
  List<Goal> build() {
    final isLive = ref.watch(supabaseClientProvider) != null;

    if (isLive) {
      Future.microtask(() => _loadLiveGoals());
      return <Goal>[];
    }

    // Seed initial state only for offline testing and widget tests
    final initialList = List<Goal>.from(initialMockGoals);
    Future.microtask(() => _loadLiveGoals());
    return initialList;
  }

  Future<void> _loadLiveGoals() async {
    try {
      final fetched = await _repository.getGoals();
      final isLive = ref.read(supabaseClientProvider) != null;

      if (isLive) {
        state = fetched;
      } else if (fetched.isNotEmpty) {
        // Merge fetched with state to preserve any local additions
        final existingIds = state.map((g) => g.id).toSet();
        final merged = List<Goal>.from(state);
        for (final g in fetched) {
          if (!existingIds.contains(g.id)) {
            merged.add(g);
          }
        }
        state = merged;
      }
    } catch (e, st) {
      debugPrint('[GoalsNotifier] Error loading live goals: $e\n$st');
    }
  }

  /// Creates a new savings goal. Updates state synchronously for immediate UI feedback.
  Future<Goal> createGoal(Goal goal) async {
    final effectiveId = goal.id.isEmpty
        ? 'goal-${DateTime.now().millisecondsSinceEpoch}'
        : goal.id;
    final createdGoal = goal.copyWith(id: effectiveId);

    // Synchronous optimistic state update
    state = [...state, createdGoal];

    try {
      final persisted = await _repository.createGoal(createdGoal);
      state = state.map((g) => g.id == createdGoal.id ? persisted : g).toList();
      return persisted;
    } catch (e, st) {
      debugPrint('[GoalsNotifier] Failed to persist goal: $e\n$st');
      return createdGoal;
    }
  }

  /// Alias for backward compatibility with existing codebase.
  void addGoal(Goal goal) {
    createGoal(goal);
  }

  /// Updates an existing goal. Updates state synchronously.
  Future<Goal> updateGoal(Goal goal) async {
    state = state.map((g) => g.id == goal.id ? goal : g).toList();

    try {
      final updated = await _repository.updateGoal(goal);
      state = state.map((g) => g.id == goal.id ? updated : g).toList();
      return updated;
    } catch (e, st) {
      debugPrint('[GoalsNotifier] Failed to persist updated goal: $e\n$st');
      return goal;
    }
  }

  /// Deletes a goal by ID. Updates state synchronously.
  Future<void> deleteGoal(String id) async {
    state = state.where((g) => g.id != id).toList();

    try {
      await _repository.deleteGoal(id);
    } catch (e, st) {
      debugPrint('[GoalsNotifier] Failed to delete goal: $e\n$st');
    }
  }

  /// Alias for backward compatibility with existing codebase.
  void removeGoal(String id) {
    deleteGoal(id);
  }

  /// Records a new contribution toward a goal, persists it in the repository,
  /// synchronizes goal's current amount in goalsProvider, and invalidates contribution history.
  /// Returns whether this contribution completed the goal.
  Future<bool> addContribution({
    required String goalId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final contribution = GoalContribution(
      id: 'contrib-${DateTime.now().millisecondsSinceEpoch}',
      goalId: goalId,
      amount: amount,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );

    // 1. Persist contribution through repository
    await _repository.addContribution(contribution);

    // 2. Synchronize goal currentAmount in goalsProvider
    final index = state.indexWhere((g) => g.id == goalId);
    bool isNewlyCompleted = false;
    if (index != -1) {
      final existing = state[index];
      final wasCompleted = existing.isCompleted;
      final updated = existing.copyWith(
        currentAmount: existing.currentAmount + amount,
        updatedAt: DateTime.now(),
      );
      state = state.map((g) => g.id == goalId ? updated : g).toList();
      isNewlyCompleted = !wasCompleted && updated.isCompleted;
    }

    // 3. Invalidate goalContributionsProvider so history reloads immediately
    ref.invalidate(goalContributionsProvider(goalId));

    return isNewlyCompleted;
  }

  /// Deletes a contribution, synchronizes goal amount, and invalidates history.
  Future<void> deleteContribution({
    required String goalId,
    required String contributionId,
  }) async {
    await _repository.deleteContribution(
      goalId: goalId,
      contributionId: contributionId,
    );

    await syncGoalWithRepo(goalId);
    ref.invalidate(goalContributionsProvider(goalId));
  }

  /// Synchronizes a specific goal with the repository (e.g. after contribution deletion).
  Future<void> syncGoalWithRepo(String goalId) async {
    try {
      final synced = await _repository.getGoalById(goalId);
      if (synced != null) {
        state = state.map((g) => g.id == goalId ? synced : g).toList();
      }
    } catch (e, st) {
      debugPrint('[GoalsNotifier] Error syncing goal with repo: $e\n$st');
    }
  }

  /// Increments savings towards a goal with a contribution record.
  Future<Goal> addSavings(String id, double amount) async {
    await addContribution(
      goalId: id,
      amount: amount,
      date: DateTime.now(),
      note: 'Quick savings contribution',
    );

    return state.firstWhere((g) => g.id == id);
  }

  /// Manually refreshes goals from the repository.
  Future<void> refresh() async {
    try {
      final fetched = await _repository.getGoals();
      state = fetched;
    } catch (e, st) {
      debugPrint('[GoalsNotifier] Refresh error: $e\n$st');
    }
  }
}

/// Global provider for financial savings goals.
final goalsProvider = NotifierProvider<GoalsNotifier, List<Goal>>(() {
  return GoalsNotifier();
});

/// Single goal provider family by goal ID.
final singleGoalProvider = Provider.family<Goal?, String>((ref, goalId) {
  final all = ref.watch(goalsProvider);
  try {
    return all.firstWhere((g) => g.id == goalId);
  } catch (_) {
    return null;
  }
});

/// Future provider family for goal contribution history, supporting loading, data, error, and refresh.
final goalContributionsProvider = FutureProvider.family<List<GoalContribution>, String>((ref, goalId) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getContributions(goalId);
});

/// Active goals (goals not yet completed).
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  final all = ref.watch(goalsProvider);
  return all.where((g) => !g.isCompleted).toList();
});

/// Completed goals.
final completedGoalsProvider = Provider<List<Goal>>((ref) {
  final all = ref.watch(goalsProvider);
  return all.where((g) => g.isCompleted).toList();
});

/// Total target across all goals.
final totalGoalsTargetProvider = Provider<double>((ref) {
  final all = ref.watch(goalsProvider);
  return all.fold<double>(0.0, (sum, g) => sum + g.targetAmount);
});

/// Total saved across all goals.
final totalGoalsSavedProvider = Provider<double>((ref) {
  final all = ref.watch(goalsProvider);
  return all.fold<double>(0.0, (sum, g) => sum + g.currentAmount);
});
