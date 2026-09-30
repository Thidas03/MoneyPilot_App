import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/goal_contribution_model.dart';
import '../domain/goal_model.dart';

/// Seed initial financial goals matching the MoneyPilot flight theme and specifications.
final List<Goal> initialMockGoals = [
  Goal(
    id: 'goal-1',
    title: 'Emergency Flight Reserve',
    currentAmount: 120000,
    targetAmount: 200000,
    deadlineDate: DateTime(2026, 12, 31),
    iconName: 'shield_rounded',
    colorHex: '#005C46',
    note: '6-month emergency buffer for flight operations and living expenses',
    createdAt: DateTime(2026, 1, 1),
  ),
  Goal(
    id: 'goal-2',
    title: 'Japan Vacation',
    currentAmount: 350000,
    targetAmount: 600000,
    deadlineDate: DateTime(2027, 4, 30),
    iconName: 'flight_takeoff_rounded',
    colorHex: '#6366F1',
    note: 'Flights, accommodations, and dining across Tokyo and Kyoto',
    createdAt: DateTime(2026, 2, 1),
  ),
];

/// Seed initial mock contributions mirroring the seeded amounts of initialMockGoals.
final List<GoalContribution> initialMockContributions = [
  GoalContribution(
    id: 'contrib-1-1',
    goalId: 'goal-1',
    amount: 70000,
    date: DateTime(2026, 1, 15),
    note: 'Initial emergency buffer allocation',
    createdAt: DateTime(2026, 1, 15),
  ),
  GoalContribution(
    id: 'contrib-1-2',
    goalId: 'goal-1',
    amount: 50000,
    date: DateTime(2026, 2, 20),
    note: 'Monthly savings transfer',
    createdAt: DateTime(2026, 2, 20),
  ),
  GoalContribution(
    id: 'contrib-2-1',
    goalId: 'goal-2',
    amount: 200000,
    date: DateTime(2026, 2, 10),
    note: 'Flight tickets savings bonus',
    createdAt: DateTime(2026, 2, 10),
  ),
  GoalContribution(
    id: 'contrib-2-2',
    goalId: 'goal-2',
    amount: 150000,
    date: DateTime(2026, 3, 5),
    note: 'Accommodations reserve',
    createdAt: DateTime(2026, 3, 5),
  ),
];

/// Contract defining goal and contribution repository operations.
abstract class GoalRepository {
  /// Fetches all savings goals for the authenticated user.
  Future<List<Goal>> getGoals();

  /// Fetches a single goal by its unique identifier.
  Future<Goal?> getGoalById(String id);

  /// Creates a new financial goal.
  Future<Goal> createGoal(Goal goal);

  /// Updates an existing financial goal.
  Future<Goal> updateGoal(Goal goal);

  /// Deletes a financial goal by ID.
  Future<void> deleteGoal(String id);

  /// Conveniently increments savings towards an existing goal.
  Future<Goal> addSavings(String id, double amount);

  // --- Goal Contributions Operations ---

  /// Records a new contribution towards a savings goal.
  Future<GoalContribution> addContribution(GoalContribution contribution);

  /// Fetches all contributions made toward a specific goal, sorted newest first.
  Future<List<GoalContribution>> getContributions(String goalId);

  /// Fetches a specific contribution by ID.
  Future<GoalContribution?> getContributionById(String id);

  /// Deletes a contribution record and synchronizes the goal's current amount.
  Future<void> deleteContribution({
    required String goalId,
    required String contributionId,
  });

  /// Updates an existing contribution record.
  Future<GoalContribution> updateContribution(GoalContribution contribution);
}

/// Production Supabase goal repository with seamless in-memory fallback.
class SupabaseGoalRepository implements GoalRepository {
  SupabaseGoalRepository({
    this.client,
    required this.authRepository,
  });

  final SupabaseClient? client;
  final AuthRepository authRepository;

  /// In-memory mock storage seeded for offline testing and graceful fallback.
  final List<Goal> _mockGoals = List.from(initialMockGoals);

  /// In-memory contributions storage seeded for offline testing and graceful fallback.
  final List<GoalContribution> _mockContributions = List.from(initialMockContributions);

  bool get _isLive => client != null;

  String? get _currentUserId => authRepository.getCurrentUser()?.id;

  // --- Goal Operations ---

  @override
  Future<List<Goal>> getGoals() async {
    if (!_isLive) {
      return List.unmodifiable(_mockGoals);
    }

    try {
      final uid = _currentUserId;
      if (uid == null) return List.unmodifiable(_mockGoals);

      // Attempt querying 'savings_goals' (schema table name) with fallback to 'goals'
      try {
        final response = await client!
            .from('savings_goals')
            .select()
            .eq('user_id', uid)
            .order('target_date', ascending: true);
        final rows = response as List<dynamic>;
        return rows.map((r) => Goal.fromMap(r as Map<String, dynamic>)).toList();
      } catch (_) {
        final response = await client!
            .from('goals')
            .select()
            .eq('user_id', uid)
            .order('deadline', ascending: true);
        final rows = response as List<dynamic>;
        return rows.map((r) => Goal.fromMap(r as Map<String, dynamic>)).toList();
      }
    } catch (e, st) {
      debugPrint('[GoalRepository] Live fetch error, fallback to mock: $e\n$st');
      return List.unmodifiable(_mockGoals);
    }
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    if (!_isLive) {
      try {
        return _mockGoals.firstWhere((g) => g.id == id);
      } catch (_) {
        return null;
      }
    }

    try {
      final uid = _currentUserId;
      try {
        var query = client!.from('savings_goals').select().eq('id', id);
        if (uid != null) query = query.eq('user_id', uid);
        final response = await query.maybeSingle();
        if (response != null) return Goal.fromMap(response);
      } catch (_) {
        var query = client!.from('goals').select().eq('id', id);
        if (uid != null) query = query.eq('user_id', uid);
        final response = await query.maybeSingle();
        if (response != null) return Goal.fromMap(response);
      }
      return _mockGoals.cast<Goal?>().firstWhere((g) => g?.id == id, orElse: () => null);
    } catch (e, st) {
      debugPrint('[GoalRepository] Get by ID error: $e\n$st');
      return _mockGoals.cast<Goal?>().firstWhere((g) => g?.id == id, orElse: () => null);
    }
  }

  @override
  Future<Goal> createGoal(Goal goal) async {
    final effectiveId = goal.id.isEmpty
        ? 'goal-${DateTime.now().millisecondsSinceEpoch}'
        : goal.id;
    final preparedGoal = goal.copyWith(
      id: effectiveId,
      userId: _currentUserId ?? goal.userId,
    );

    if (!_isLive) {
      _mockGoals.add(preparedGoal);
      return preparedGoal;
    }

    try {
      final payload = preparedGoal.toMap(currentUserId: _currentUserId);
      Map<String, dynamic> response;
      try {
        response = await client!
            .from('savings_goals')
            .insert(payload)
            .select()
            .single();
      } catch (_) {
        response = await client!
            .from('goals')
            .insert(payload)
            .select()
            .single();
      }

      final created = Goal.fromMap(response);
      _mockGoals.add(created);
      return created;
    } catch (e, st) {
      debugPrint('[GoalRepository] Live create error, saving locally: $e\n$st');
      _mockGoals.add(preparedGoal);
      return preparedGoal;
    }
  }

  @override
  Future<Goal> updateGoal(Goal goal) async {
    final updatedGoal = goal.copyWith(updatedAt: DateTime.now());

    if (!_isLive) {
      final idx = _mockGoals.indexWhere((g) => g.id == goal.id);
      if (idx != -1) {
        _mockGoals[idx] = updatedGoal;
      } else {
        _mockGoals.add(updatedGoal);
      }
      return updatedGoal;
    }

    try {
      final payload = updatedGoal.toMap(currentUserId: _currentUserId);
      Map<String, dynamic> response;
      try {
        response = await client!
            .from('savings_goals')
            .update(payload)
            .eq('id', goal.id)
            .select()
            .single();
      } catch (_) {
        response = await client!
            .from('goals')
            .update(payload)
            .eq('id', goal.id)
            .select()
            .single();
      }

      final result = Goal.fromMap(response);
      final idx = _mockGoals.indexWhere((g) => g.id == goal.id);
      if (idx != -1) {
        _mockGoals[idx] = result;
      }
      return result;
    } catch (e, st) {
      debugPrint('[GoalRepository] Live update error, updating locally: $e\n$st');
      final idx = _mockGoals.indexWhere((g) => g.id == goal.id);
      if (idx != -1) {
        _mockGoals[idx] = updatedGoal;
      }
      return updatedGoal;
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    _mockGoals.removeWhere((g) => g.id == id);
    _mockContributions.removeWhere((c) => c.goalId == id);

    if (!_isLive) return;

    try {
      try {
        await client!.from('savings_goals').delete().eq('id', id);
      } catch (_) {
        await client!.from('goals').delete().eq('id', id);
      }
    } catch (e, st) {
      debugPrint('[GoalRepository] Live delete error: $e\n$st');
    }
  }

  @override
  Future<Goal> addSavings(String id, double amount) async {
    if (amount <= 0) {
      throw ArgumentError('Added savings amount must be greater than zero');
    }

    // Persist as a formal contribution record
    final contribution = GoalContribution(
      id: 'contrib-${DateTime.now().millisecondsSinceEpoch}',
      goalId: id,
      amount: amount,
      date: DateTime.now(),
      note: 'Quick savings contribution',
      createdAt: DateTime.now(),
    );

    await addContribution(contribution);

    final goal = await getGoalById(id);
    if (goal == null) {
      throw StateError('Goal with ID "$id" not found after adding contribution');
    }
    return goal;
  }

  // --- Goal Contribution Operations ---

  @override
  Future<GoalContribution> addContribution(GoalContribution contribution) async {
    if (contribution.amount <= 0) {
      throw ArgumentError('Contribution amount must be greater than zero');
    }

    final effectiveId = contribution.id.isEmpty
        ? 'contrib-${DateTime.now().millisecondsSinceEpoch}'
        : contribution.id;
    final prepared = contribution.copyWith(
      id: effectiveId,
      userId: _currentUserId ?? contribution.userId,
      createdAt: contribution.createdAt ?? DateTime.now(),
    );

    // Update in-memory cache and parent goal amount
    _mockContributions.add(prepared);
    final goalIdx = _mockGoals.indexWhere((g) => g.id == prepared.goalId);
    if (goalIdx != -1) {
      final existingGoal = _mockGoals[goalIdx];
      _mockGoals[goalIdx] = existingGoal.copyWith(
        currentAmount: existingGoal.currentAmount + prepared.amount,
        updatedAt: DateTime.now(),
      );
    }

    if (!_isLive) {
      return prepared;
    }

    try {
      final payload = prepared.toMap(currentUserId: _currentUserId);
      final response = await client!
          .from('goal_contributions')
          .insert(payload)
          .select()
          .single();

      final created = GoalContribution.fromMap(response);

      // Replace with server-persisted instance in local cache
      final cIdx = _mockContributions.indexWhere((c) => c.id == prepared.id);
      if (cIdx != -1) {
        _mockContributions[cIdx] = created;
      }

      // Note: Supabase database trigger `on_goal_contribution_change` automatically
      // synchronizes `savings_goals.current_amount` upon insertion.
      // Fetch latest goal from Supabase to ensure synchronization
      try {
        final updatedGoal = await getGoalById(prepared.goalId);
        if (updatedGoal != null && goalIdx != -1) {
          _mockGoals[goalIdx] = updatedGoal;
        }
      } catch (_) {}

      return created;
    } catch (e, st) {
      debugPrint('[GoalRepository] Live contribution error, saved locally: $e\n$st');
      return prepared;
    }
  }

  @override
  Future<List<GoalContribution>> getContributions(String goalId) async {
    if (!_isLive) {
      final list = _mockContributions.where((c) => c.goalId == goalId).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return List.unmodifiable(list);
    }

    try {
      final uid = _currentUserId;
      var query = client!
          .from('goal_contributions')
          .select()
          .eq('goal_id', goalId);
      if (uid != null) {
        query = query.eq('user_id', uid);
      }
      final response = await query.order('contribution_date', ascending: false);
      final rows = response as List<dynamic>;
      final list = rows.map((r) => GoalContribution.fromMap(r as Map<String, dynamic>)).toList();
      return list;
    } catch (e, st) {
      debugPrint('[GoalRepository] Live getContributions error, fallback to mock: $e\n$st');
      final list = _mockContributions.where((c) => c.goalId == goalId).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return List.unmodifiable(list);
    }
  }

  @override
  Future<GoalContribution?> getContributionById(String id) async {
    if (!_isLive) {
      try {
        return _mockContributions.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    try {
      final response = await client!
          .from('goal_contributions')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) {
        return _mockContributions.cast<GoalContribution?>().firstWhere(
              (c) => c?.id == id,
              orElse: () => null,
            );
      }
      return GoalContribution.fromMap(response);
    } catch (e, st) {
      debugPrint('[GoalRepository] Live getContributionById error: $e\n$st');
      return _mockContributions.cast<GoalContribution?>().firstWhere(
            (c) => c?.id == id,
            orElse: () => null,
          );
    }
  }

  @override
  Future<void> deleteContribution({
    required String goalId,
    required String contributionId,
  }) async {
    // Find contribution to know its amount
    final idx = _mockContributions.indexWhere((c) => c.id == contributionId);
    double amountToDeduct = 0.0;
    if (idx != -1) {
      amountToDeduct = _mockContributions[idx].amount;
      _mockContributions.removeAt(idx);
    }

    // Synchronize parent goal in mock storage
    final goalIdx = _mockGoals.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      final existingGoal = _mockGoals[goalIdx];
      final newCurrent = (existingGoal.currentAmount - amountToDeduct).clamp(0.0, double.infinity);
      _mockGoals[goalIdx] = existingGoal.copyWith(
        currentAmount: newCurrent,
        updatedAt: DateTime.now(),
      );
    }

    if (!_isLive) return;

    try {
      // The Supabase trigger `on_goal_contribution_change` automatically decrements
      // `savings_goals.current_amount` upon deletion in PostgreSQL.
      await client!.from('goal_contributions').delete().eq('id', contributionId);

      // Re-fetch parent goal to ensure sync
      try {
        final synced = await getGoalById(goalId);
        if (synced != null && goalIdx != -1) {
          _mockGoals[goalIdx] = synced;
        }
      } catch (_) {}
    } catch (e, st) {
      debugPrint('[GoalRepository] Live delete contribution error: $e\n$st');
    }
  }

  @override
  Future<GoalContribution> updateContribution(GoalContribution contribution) async {
    final idx = _mockContributions.indexWhere((c) => c.id == contribution.id);
    double amountDiff = 0.0;
    if (idx != -1) {
      amountDiff = contribution.amount - _mockContributions[idx].amount;
      _mockContributions[idx] = contribution;
    } else {
      _mockContributions.add(contribution);
      amountDiff = contribution.amount;
    }

    final goalIdx = _mockGoals.indexWhere((g) => g.id == contribution.goalId);
    if (goalIdx != -1) {
      final existingGoal = _mockGoals[goalIdx];
      final newCurrent = (existingGoal.currentAmount + amountDiff).clamp(0.0, double.infinity);
      _mockGoals[goalIdx] = existingGoal.copyWith(
        currentAmount: newCurrent,
        updatedAt: DateTime.now(),
      );
    }

    if (!_isLive) return contribution;

    try {
      final payload = contribution.toMap(currentUserId: _currentUserId);
      final response = await client!
          .from('goal_contributions')
          .update(payload)
          .eq('id', contribution.id)
          .select()
          .single();

      final updated = GoalContribution.fromMap(response);
      return updated;
    } catch (e, st) {
      debugPrint('[GoalRepository] Live update contribution error: $e\n$st');
      return contribution;
    }
  }
}

/// Global Riverpod provider for GoalRepository.
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return SupabaseGoalRepository(
    client: client,
    authRepository: authRepo,
  );
});
