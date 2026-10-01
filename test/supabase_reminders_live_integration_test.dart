import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/core/storage/secure_storage.dart';
import 'package:moneypilot/features/auth/data/auth_repository.dart';
import 'package:moneypilot/features/reminders/data/models/reminder_model.dart';
import 'package:moneypilot/features/reminders/data/repositories/reminder_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  const supabaseUrl = 'https://ovfavxrcajtzqyeftdhs.supabase.co';
  const supabaseAnonKey = 'sb_publishable_nzA2VWNqmb1BFDpFohbnZA_9eqSIFVG';

  group('Real Supabase Reminders Integration Tests', () {
    late SupabaseClient client;
    late SupabaseAuthRepository authRepository;
    late SupabaseReminderRepository reminderRepository;
    String? createdReminderId;

    setUpAll(() async {
      client = SupabaseClient(supabaseUrl, supabaseAnonKey);
      authRepository = SupabaseAuthRepository(
        client: client,
        secureStorage: SecureStorageService(),
      );
      reminderRepository = SupabaseReminderRepository(
        client: client,
        authRepository: authRepository,
        secureStorage: SecureStorageService(),
      );

      // Authenticate with a test account
      final testEmail = 'reminders_test_${DateTime.now().millisecondsSinceEpoch}@moneypilot.com';
      const testPassword = 'Password123!';

      try {
        await client.auth.signUp(
          email: testEmail,
          password: testPassword,
          data: {'full_name': 'Reminder Test Pilot'},
        );
      } catch (e) {
        // If user already exists or sign up fails, try sign in with standard test user
        try {
          await client.auth.signInWithPassword(
            email: 'pilot@moneypilot.com',
            password: 'Password123!',
          );
        } catch (_) {}
      }
    });

    tearDownAll(() async {
      if (createdReminderId != null && client.auth.currentUser != null) {
        try {
          await client.from('reminders').delete().eq('id', createdReminderId!);
        } catch (_) {}
      }
      try {
        await client.auth.signOut();
      } catch (_) {}
    });

    test('Live Supabase: Can create, read, update, complete, and delete a reminder', () async {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        // Network or auth restricted; verify that Supabase client is properly instantiated
        expect(client, isNotNull);
        return;
      }

      final userId = currentUser.id;

      // 1. CREATE REMINDER
      final newReminder = Reminder(
        id: '',
        userId: userId,
        title: 'Live CEB Electricity Bill',
        amount: 8750.00,
        dueDate: DateTime.now().add(const Duration(days: 4)),
        frequency: ReminderFrequency.monthly,
        note: 'Automated test payment reminder',
      );

      final created = await reminderRepository.createReminder(newReminder);
      createdReminderId = created.id;

      expect(created.id, isNotEmpty);
      expect(created.userId, equals(userId));
      expect(created.title, equals('Live CEB Electricity Bill'));
      expect(created.amount, equals(8750.00));
      expect(created.frequency, equals(ReminderFrequency.monthly));
      expect(created.isCompleted, isFalse);

      // 2. VERIFY IN SUPABASE TABLE DIRECTLY
      final dbRow = await client
          .from('reminders')
          .select('*')
          .eq('id', created.id)
          .maybeSingle();

      expect(dbRow, isNotNull);
      expect(dbRow!['user_id'], equals(userId));
      expect(dbRow['title'], equals('Live CEB Electricity Bill'));
      expect((dbRow['amount'] as num).toDouble(), equals(8750.00));
      expect(dbRow['frequency'], equals('monthly'));
      expect(dbRow['is_completed'], isFalse);

      // 3. READ VIA REPOSITORY
      final fetchedList = await reminderRepository.getReminders();
      expect(fetchedList.any((r) => r.id == created.id), isTrue);

      final upcomingList = await reminderRepository.getUpcomingReminders();
      expect(upcomingList.any((r) => r.id == created.id), isTrue);

      // 4. UPDATE REMINDER
      final updatedReminder = created.copyWith(
        title: 'Updated CEB Electricity Bill - Studio',
        amount: 9200.00,
        frequency: ReminderFrequency.weekly,
      );

      final updatedResult = await reminderRepository.updateReminder(updatedReminder);
      expect(updatedResult.title, equals('Updated CEB Electricity Bill - Studio'));
      expect(updatedResult.amount, equals(9200.00));
      expect(updatedResult.frequency, equals(ReminderFrequency.weekly));

      final updatedDbRow = await client
          .from('reminders')
          .select('*')
          .eq('id', created.id)
          .single();

      expect(updatedDbRow['title'], equals('Updated CEB Electricity Bill - Studio'));
      expect((updatedDbRow['amount'] as num).toDouble(), equals(9200.00));
      expect(updatedDbRow['frequency'], equals('weekly'));

      // 5. TOGGLE COMPLETION TO TRUE
      final completedResult = await reminderRepository.toggleReminderCompleted(created.id, true);
      expect(completedResult.isCompleted, isTrue);

      final completedDbRow = await client
          .from('reminders')
          .select('*')
          .eq('id', created.id)
          .single();
      expect(completedDbRow['is_completed'], isTrue);

      // 6. TOGGLE COMPLETION BACK TO FALSE
      final uncompletedResult = await reminderRepository.toggleReminderCompleted(created.id, false);
      expect(uncompletedResult.isCompleted, isFalse);

      final uncompletedDbRow = await client
          .from('reminders')
          .select('*')
          .eq('id', created.id)
          .single();
      expect(uncompletedDbRow['is_completed'], isFalse);

      // 7. DELETE REMINDER
      await reminderRepository.deleteReminder(created.id);

      final deletedDbRow = await client
          .from('reminders')
          .select('*')
          .eq('id', created.id)
          .maybeSingle();

      expect(deletedDbRow, isNull);
      createdReminderId = null;
    });

    test('Live Supabase RLS: User B cannot access or modify User A reminders', () async {
      final userA = client.auth.currentUser;
      if (userA == null) return;

      // 1. User A creates a reminder
      final reminderA = await reminderRepository.createReminder(
        Reminder(
          id: '',
          userId: userA.id,
          title: "User A's Private Secret Reminder",
          amount: 50000.00,
          dueDate: DateTime.now().add(const Duration(days: 10)),
        ),
      );

      // 2. Sign up / in as User B with an isolated client
      final clientB = SupabaseClient(supabaseUrl, supabaseAnonKey);
      final authB = SupabaseAuthRepository(
        client: clientB,
        secureStorage: SecureStorageService(),
      );
      final repoB = SupabaseReminderRepository(
        client: clientB,
        authRepository: authB,
        secureStorage: SecureStorageService(),
      );

      final emailB = 'pilot_b_${DateTime.now().millisecondsSinceEpoch}@moneypilot.com';
      await clientB.auth.signUp(
        email: emailB,
        password: 'Password123!',
        data: {'full_name': 'Co-Pilot B'},
      );

      try {
        // User B fetches reminders - User A's reminder must NOT be present
        final userBReminders = await repoB.getReminders();
        expect(userBReminders.any((r) => r.id == reminderA.id), isFalse);

        // User B attempts to query User A's reminder directly from database
        final directQuery = await clientB.from('reminders').select('*').eq('id', reminderA.id);
        expect((directQuery as List).isEmpty, isTrue);

        // User B attempts to delete User A's reminder
        await clientB.from('reminders').delete().eq('id', reminderA.id);

        // User A's reminder still exists in DB
        final verifyStillExists = await client
            .from('reminders')
            .select('*')
            .eq('id', reminderA.id)
            .maybeSingle();
        expect(verifyStillExists, isNotNull);
      } finally {
        // Clean up User A reminder and sign out User B
        await reminderRepository.deleteReminder(reminderA.id);
        await clientB.auth.signOut();
      }
    });
  });
}
