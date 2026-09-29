import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/goal_model.dart';

/// Seed initial goals matching the user prompt.
final List<Goal> _initialGoals = [
  const Goal(
    id: 'goal-1',
    title: 'Emergency Flight Reserve',
    currentAmount: 120000,
    targetAmount: 200000,
    deadline: 'Dec 2026',
    icon: Icons.shield_rounded,
    color: Color(0xFF005C46),
  ),
  const Goal(
    id: 'goal-2',
    title: 'Japan Vacation',
    currentAmount: 350000,
    targetAmount: 600000,
    deadline: 'Apr 2027',
    icon: Icons.flight_takeoff_rounded,
    color: Color(0xFF6366F1),
  ),
];

/// Notifier managing goals state.
class GoalsNotifier extends Notifier<List<Goal>> {
  @override
  List<Goal> build() {
    return _initialGoals;
  }

  void addGoal(Goal goal) {
    state = [...state, goal];
  }

  void removeGoal(String id) {
    state = state.where((g) => g.id != id).toList();
  }
}

/// Provider for financial savings goals.
final goalsProvider = NotifierProvider<GoalsNotifier, List<Goal>>(() {
  return GoalsNotifier();
});
