import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/data/auth_repository.dart';
import '../models/reminder_model.dart';

/// Seed initial reminders for offline/test environments.
final List<Reminder> initialMockReminders = [
  Reminder(
    id: 'mock-rem-1',
    userId: 'mock-user-001',
    title: 'Electricity Bill',
    amount: 8500,
    dueDate: DateTime.now().add(const Duration(days: 3)),
    frequency: ReminderFrequency.monthly,
    isCompleted: false,
    categoryName: 'Utilities',
    note: 'CEB bill for home office studio',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
  Reminder(
    id: 'mock-rem-2',
    userId: 'mock-user-001',
    title: 'Internet & Cloud Services',
    amount: 4200,
    dueDate: DateTime.now().add(const Duration(days: 6)),
    frequency: ReminderFrequency.monthly,
    isCompleted: false,
    categoryName: 'Education',
    note: 'Fibre broadband subscription',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
  ),
  Reminder(
    id: 'mock-rem-3',
    userId: 'mock-user-001',
    title: 'Health & Accident Insurance',
    amount: 12500,
    dueDate: DateTime.now().add(const Duration(days: 15)),
    frequency: ReminderFrequency.monthly,
    isCompleted: false,
    categoryName: 'Health/Medical',
    note: 'Quarterly policy renewal',
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
  ),
  Reminder(
    id: 'mock-rem-4',
    userId: 'mock-user-001',
    title: 'Freelance Software License',
    amount: 6000,
    dueDate: DateTime.now().subtract(const Duration(days: 2)),
    frequency: ReminderFrequency.yearly,
    isCompleted: true,
    categoryName: 'Misc',
    note: 'Design tools annual license',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
];

/// Contract defining reminder repository operations.
abstract class ReminderRepository {
  /// Fetches all reminders for the authenticated user.
  Future<List<Reminder>> getReminders();

  /// Fetches upcoming uncompleted reminders, ordered by due date ascending.
  Future<List<Reminder>> getUpcomingReminders({int limit = 5});

  /// Fetches a single reminder by its unique identifier.
  Future<Reminder?> getReminderById(String id);

  /// Creates a new reminder for the authenticated user.
  Future<Reminder> createReminder(Reminder reminder);

  /// Updates an existing reminder belonging to the authenticated user.
  Future<Reminder> updateReminder(Reminder reminder);

  /// Toggles the completion status of a reminder.
  Future<Reminder> toggleReminderCompleted(String id, [bool? isCompleted]);

  /// Deletes a reminder by ID.
  Future<void> deleteReminder(String id);
}

/// Unified reminder repository supporting real Supabase PostgreSQL persistence
/// and graceful fallback for offline/test environments.
class SupabaseReminderRepository implements ReminderRepository {
  SupabaseReminderRepository({
    this.client,
    required this.authRepository,
    SecureStorageService? secureStorage,
  }) : secureStorage = secureStorage ?? SecureStorageService();

  final SupabaseClient? client;
  final AuthRepository authRepository;
  final SecureStorageService secureStorage;

  /// In-memory mock storage for testing and offline fallback.
  final List<Reminder> _mockReminders = List.from(initialMockReminders);

  bool get _isLive => client != null;

  String? get _currentUserId =>
      authRepository.getCurrentUser()?.id ?? client?.auth.currentUser?.id;

  Future<void> _saveLocalCache(String uid, List<Reminder> reminders) async {
    try {
      final jsonList = reminders.map((r) => r.toJson()).toList();
      await secureStorage.saveRemindersCache(uid, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<Reminder>> _loadLocalCache(String uid) async {
    try {
      final raw = await secureStorage.getRemindersCache(uid);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (_) {}
    return <Reminder>[];
  }

  @override
  Future<List<Reminder>> getReminders() async {
    final uid = _currentUserId;

    if (!_isLive) {
      final cacheKey = uid ?? 'mock-user-001';
      final cached = await _loadLocalCache(cacheKey);
      if (cached.isNotEmpty) {
        _mockReminders.clear();
        _mockReminders.addAll(cached);
        return cached;
      }
      return List.unmodifiable(_mockReminders);
    }

    try {
      final user = authRepository.getCurrentUser() ?? client?.auth.currentUser;
      final userId = user?.id ?? uid;

      var query = client!
          .from('reminders')
          .select('*, categories(id, name, icon, color_hex)');
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      List<dynamic> response;
      try {
        response = await query.order('due_date', ascending: true);
      } catch (_) {
        // Fallback without join if categories relation isn't available
        var fallbackQuery = client!.from('reminders').select('*');
        if (userId != null) {
          fallbackQuery = fallbackQuery.eq('user_id', userId);
        }
        response = await fallbackQuery.order('due_date', ascending: true);
      }

      final reminders = response
          .map((row) => Reminder.fromJson(row as Map<String, dynamic>))
          .toList();

      if (userId != null) {
        await _saveLocalCache(userId, reminders);
      }
      return reminders;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ReminderRepository] Error fetching reminders: $e');
        debugPrint(stackTrace.toString());
      }
      if (uid != null) {
        final cached = await _loadLocalCache(uid);
        if (cached.isNotEmpty) return cached;
      }
      return List.unmodifiable(_mockReminders);
    }
  }

  @override
  Future<List<Reminder>> getUpcomingReminders({int limit = 5}) async {
    final all = await getReminders();
    final pending = all.where((r) => !r.isCompleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.take(limit).toList();
  }

  @override
  Future<Reminder?> getReminderById(String id) async {
    final all = await getReminders();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Reminder> createReminder(Reminder reminder) async {
    final user = authRepository.getCurrentUser() ?? client?.auth.currentUser;
    final uid = user?.id ?? _currentUserId ?? 'mock-user-001';

    // Normalize reminder with current authenticated user
    final prepared = reminder.copyWith(userId: uid);

    if (!_isLive) {
      final newId = 'mock-rem-${DateTime.now().millisecondsSinceEpoch}';
      final created = prepared.copyWith(
        id: newId,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      _mockReminders.add(created);
      await _saveLocalCache(uid, _mockReminders);
      return created;
    }

    try {
      final payload = prepared.toSupabaseMap();
      payload['user_id'] = uid;

      Map<String, dynamic> row;
      try {
        row = await client!
            .from('reminders')
            .insert(payload)
            .select('*, categories(id, name, icon, color_hex)')
            .single();
      } catch (_) {
        row = await client!
            .from('reminders')
            .insert(payload)
            .select('*')
            .single();
      }

      var created = Reminder.fromJson(row);
      if (created.categoryName == null && prepared.categoryName != null) {
        created = created.copyWith(
          categoryName: prepared.categoryName,
          categoryIcon: prepared.categoryIcon,
          categoryColorHex: prepared.categoryColorHex,
        );
      }
      final currentList = await getReminders();
      final updatedList = List<Reminder>.from(currentList)..add(created);
      await _saveLocalCache(uid, updatedList);
      return created;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ReminderRepository] Error creating reminder: $e');
        debugPrint(stackTrace.toString());
      }
      rethrow;
    }
  }

  @override
  Future<Reminder> updateReminder(Reminder reminder) async {
    final user = authRepository.getCurrentUser() ?? client?.auth.currentUser;
    final uid = user?.id ?? _currentUserId ?? 'mock-user-001';
    final prepared = reminder.copyWith(userId: uid, updatedAt: DateTime.now().toUtc());

    if (!_isLive) {
      final index = _mockReminders.indexWhere((r) => r.id == reminder.id);
      if (index >= 0) {
        _mockReminders[index] = prepared;
      } else {
        _mockReminders.add(prepared);
      }
      await _saveLocalCache(uid, _mockReminders);
      return prepared;
    }

    try {
      final payload = prepared.toSupabaseMap();
      payload['user_id'] = uid;

      Map<String, dynamic> row;
      try {
        row = await client!
            .from('reminders')
            .update(payload)
            .eq('id', reminder.id)
            .select('*, categories(id, name, icon, color_hex)')
            .single();
      } catch (_) {
        row = await client!
            .from('reminders')
            .update(payload)
            .eq('id', reminder.id)
            .select('*')
            .single();
      }

      var updated = Reminder.fromJson(row);
      if (updated.categoryName == null && prepared.categoryName != null) {
        updated = updated.copyWith(
          categoryName: prepared.categoryName,
          categoryIcon: prepared.categoryIcon,
          categoryColorHex: prepared.categoryColorHex,
        );
      }
      final currentList = await getReminders();
      final updatedList = currentList.map((r) => r.id == updated.id ? updated : r).toList();
      await _saveLocalCache(uid, updatedList);
      return updated;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ReminderRepository] Error updating reminder: $e');
        debugPrint(stackTrace.toString());
      }
      rethrow;
    }
  }

  @override
  Future<Reminder> toggleReminderCompleted(String id, [bool? isCompleted]) async {
    final existing = await getReminderById(id);
    if (existing == null) {
      throw Exception('Reminder with id $id not found');
    }

    final newStatus = isCompleted ?? !existing.isCompleted;
    final user = authRepository.getCurrentUser() ?? client?.auth.currentUser;
    final uid = user?.id ?? _currentUserId ?? 'mock-user-001';

    if (!_isLive) {
      final updated = existing.copyWith(
        isCompleted: newStatus,
        updatedAt: DateTime.now().toUtc(),
      );
      final index = _mockReminders.indexWhere((r) => r.id == id);
      if (index >= 0) {
        _mockReminders[index] = updated;
      }
      await _saveLocalCache(uid, _mockReminders);
      return updated;
    }

    try {
      final payload = {
        'is_completed': newStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      Map<String, dynamic> row;
      try {
        row = await client!
            .from('reminders')
            .update(payload)
            .eq('id', id)
            .select('*, categories(id, name, icon, color_hex)')
            .single();
      } catch (_) {
        row = await client!
            .from('reminders')
            .update(payload)
            .eq('id', id)
            .select('*')
            .single();
      }

      var updated = Reminder.fromJson(row);
      if (updated.categoryName == null && existing.categoryName != null) {
        updated = updated.copyWith(
          categoryName: existing.categoryName,
          categoryIcon: existing.categoryIcon,
          categoryColorHex: existing.categoryColorHex,
        );
      }
      final currentList = await getReminders();
      final updatedList = currentList.map((r) => r.id == updated.id ? updated : r).toList();
      await _saveLocalCache(uid, updatedList);
      return updated;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ReminderRepository] Error toggling reminder completion: $e');
        debugPrint(stackTrace.toString());
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    final user = authRepository.getCurrentUser() ?? client?.auth.currentUser;
    final uid = user?.id ?? _currentUserId ?? 'mock-user-001';

    if (!_isLive) {
      _mockReminders.removeWhere((r) => r.id == id);
      await _saveLocalCache(uid, _mockReminders);
      return;
    }

    try {
      await client!.from('reminders').delete().eq('id', id);
      final currentList = await getReminders();
      final updatedList = currentList.where((r) => r.id != id).toList();
      await _saveLocalCache(uid, updatedList);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ReminderRepository] Error deleting reminder: $e');
        debugPrint(stackTrace.toString());
      }
      rethrow;
    }
  }
}

/// Riverpod provider for [ReminderRepository].
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  return SupabaseReminderRepository(
    client: client,
    authRepository: authRepository,
    secureStorage: secureStorage,
  );
});
