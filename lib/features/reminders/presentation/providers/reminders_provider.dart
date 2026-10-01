import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/models/reminder_model.dart';
import '../../data/repositories/reminder_repository.dart';

/// Loading indicator notifier for reminder background operations.
class RemindersLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) => state = val;
}

final remindersLoadingProvider =
    NotifierProvider<RemindersLoadingNotifier, bool>(() => RemindersLoadingNotifier());

/// Error state notifier for reminder operations.
class RemindersErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? val) => state = val;
}

final remindersErrorProvider =
    NotifierProvider<RemindersErrorNotifier, String?>(() => RemindersErrorNotifier());

/// Filter selection for the Reminders screen.
enum ReminderFilter { all, upcoming, completed, overdue }

/// Active filter notifier for the reminders screen.
class ReminderFilterNotifier extends Notifier<ReminderFilter> {
  @override
  ReminderFilter build() => ReminderFilter.upcoming;

  void setFilter(ReminderFilter filter) => state = filter;
}

final reminderFilterProvider =
    NotifierProvider<ReminderFilterNotifier, ReminderFilter>(() => ReminderFilterNotifier());

/// Strongly typed summary model for reminders.
class ReminderSummary {
  final int totalCount;
  final int upcomingCount;
  final int completedCount;
  final int overdueCount;

  const ReminderSummary({
    this.totalCount = 0,
    this.upcomingCount = 0,
    this.completedCount = 0,
    this.overdueCount = 0,
  });

  int? operator [](String key) {
    switch (key) {
      case 'total':
        return totalCount;
      case 'pending':
      case 'upcoming':
        return upcomingCount;
      case 'completed':
        return completedCount;
      case 'overdue':
        return overdueCount;
      default:
        return null;
    }
  }
}

/// Reactive notifier managing the list of reminders.
class RemindersNotifier extends Notifier<List<Reminder>> {
  ReminderRepository get _repository => ref.read(reminderRepositoryProvider);

  @override
  List<Reminder> build() {
    final isLive = ref.watch(supabaseClientProvider) != null;
    final currentUser = ref.watch(currentUserProvider);

    if (isLive) {
      if (currentUser != null) {
        Future.microtask(() => loadReminders());
      }
      return <Reminder>[];
    }

    // Seed mock initial reminders for offline/widget testing
    return List<Reminder>.from(initialMockReminders);
  }

  /// Reloads reminders from the repository.
  Future<void> loadReminders() async {
    ref.read(remindersLoadingProvider.notifier).setLoading(true);
    ref.read(remindersErrorProvider.notifier).setError(null);

    try {
      final fetched = await _repository.getReminders();
      state = fetched;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[RemindersNotifier] Error loading reminders: $e\n$st');
      }
      ref.read(remindersErrorProvider.notifier).setError(e.toString());
    } finally {
      ref.read(remindersLoadingProvider.notifier).setLoading(false);
    }
  }

  /// Creates a reminder and updates state immediately.
  Future<Reminder> createReminder(Reminder reminder) async {
    ref.read(remindersLoadingProvider.notifier).setLoading(true);
    ref.read(remindersErrorProvider.notifier).setError(null);

    final tempId = reminder.id.isEmpty
        ? 'rem-${DateTime.now().millisecondsSinceEpoch}'
        : reminder.id;
    final optimistic = reminder.copyWith(id: tempId);

    // Optimistic UI update
    state = [...state, optimistic];

    try {
      final created = await _repository.createReminder(reminder);
      // Replace optimistic reminder with the server-returned record
      state = state.map((r) => r.id == tempId ? created : r).toList();
      return created;
    } catch (e) {
      // Revert optimistic update on failure
      state = state.where((r) => r.id != tempId).toList();
      ref.read(remindersErrorProvider.notifier).setError(e.toString());
      rethrow;
    } finally {
      ref.read(remindersLoadingProvider.notifier).setLoading(false);
    }
  }

  /// Updates an existing reminder and reactively refreshes state.
  Future<Reminder> updateReminder(Reminder reminder) async {
    ref.read(remindersLoadingProvider.notifier).setLoading(true);
    ref.read(remindersErrorProvider.notifier).setError(null);

    final previousList = state;
    // Optimistic local update
    state = state.map((r) => r.id == reminder.id ? reminder : r).toList();

    try {
      final updated = await _repository.updateReminder(reminder);
      state = state.map((r) => r.id == reminder.id ? updated : r).toList();
      return updated;
    } catch (e) {
      // Revert on failure
      state = previousList;
      ref.read(remindersErrorProvider.notifier).setError(e.toString());
      rethrow;
    } finally {
      ref.read(remindersLoadingProvider.notifier).setLoading(false);
    }
  }

  /// Toggles the completion state of a reminder.
  Future<Reminder> toggleReminderCompleted(String id) async {
    final existingIndex = state.indexWhere((r) => r.id == id);
    if (existingIndex < 0) {
      throw Exception('Reminder with id $id not found in state');
    }

    final existing = state[existingIndex];
    final toggled = existing.copyWith(isCompleted: !existing.isCompleted);

    // Optimistic local update
    final previousList = state;
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == existingIndex) toggled else state[i],
    ];

    try {
      final serverUpdated = await _repository.toggleReminderCompleted(id);
      state = [
        for (final r in state)
          if (r.id == id) serverUpdated else r,
      ];
      return serverUpdated;
    } catch (e) {
      // Revert on failure
      state = previousList;
      ref.read(remindersErrorProvider.notifier).setError(e.toString());
      rethrow;
    }
  }

  /// Convenient alias for toggleReminderCompleted.
  Future<Reminder> toggleComplete(Reminder reminder) {
    return toggleReminderCompleted(reminder.id);
  }

  /// Deletes a reminder by ID with instant state update.
  Future<void> deleteReminder(String id) async {
    final previousList = state;
    // Optimistic local deletion
    state = state.where((r) => r.id != id).toList();

    try {
      await _repository.deleteReminder(id);
    } catch (e) {
      // Revert on failure
      state = previousList;
      ref.read(remindersErrorProvider.notifier).setError(e.toString());
      rethrow;
    }
  }
}

/// Provider for managing reminders state.
final remindersProvider =
    NotifierProvider<RemindersNotifier, List<Reminder>>(() {
  return RemindersNotifier();
});

/// Provider for uncompleted upcoming reminders, sorted by due date ascending.
final upcomingRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final uncompleted = reminders.where((r) => !r.isCompleted).toList();
  uncompleted.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return uncompleted;
});

/// Provider for completed reminders.
final completedRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final completed = reminders.where((r) => r.isCompleted).toList();
  completed.sort((a, b) => b.dueDate.compareTo(a.dueDate));
  return completed;
});

/// Provider for pending reminders (uncompleted).
final pendingRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  return reminders.where((r) => !r.isCompleted).toList();
});

/// Provider for overdue uncompleted reminders.
final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  return reminders.where((r) => r.isOverdue).toList();
});

/// Provider for filtered reminders based on current [reminderFilterProvider].
final filteredRemindersProvider = Provider<List<Reminder>>((ref) {
  final filter = ref.watch(reminderFilterProvider);
  switch (filter) {
    case ReminderFilter.upcoming:
      return ref.watch(upcomingRemindersProvider);
    case ReminderFilter.completed:
      return ref.watch(completedRemindersProvider);
    case ReminderFilter.overdue:
      return ref.watch(overdueRemindersProvider);
    case ReminderFilter.all:
      final all = List<Reminder>.from(ref.watch(remindersProvider));
      all.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return all;
  }
});

/// Provider supplying reminder summary counts.
final remindersSummaryProvider = Provider<ReminderSummary>((ref) {
  final all = ref.watch(remindersProvider);
  final pending = all.where((r) => !r.isCompleted).length;
  final completed = all.where((r) => r.isCompleted).length;
  final overdue = all.where((r) => r.isOverdue).length;

  return ReminderSummary(
    totalCount: all.length,
    upcomingCount: pending,
    completedCount: completed,
    overdueCount: overdue,
  );
});
