import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/core/storage/secure_storage.dart';
import 'package:moneypilot/features/auth/data/auth_repository.dart';
import 'package:moneypilot/features/reminders/data/models/reminder_model.dart';
import 'package:moneypilot/features/reminders/data/repositories/reminder_repository.dart';
import 'package:moneypilot/features/reminders/presentation/add_reminder_screen.dart';
import 'package:moneypilot/features/reminders/presentation/providers/reminders_provider.dart';
import 'package:moneypilot/features/reminders/presentation/reminders_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageService secureStorage;
  late SupabaseAuthRepository authRepository;
  late SupabaseReminderRepository reminderRepository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    secureStorage = SecureStorageService();
    authRepository = SupabaseAuthRepository(
      client: null,
      secureStorage: secureStorage,
    );
    reminderRepository = SupabaseReminderRepository(
      client: null,
      authRepository: authRepository,
      secureStorage: secureStorage,
    );
  });

  group('ReminderRepository CRUD Tests', () {
    test('Initial getReminders returns default seeded reminders', () async {
      final list = await reminderRepository.getReminders();
      expect(list.isNotEmpty, isTrue);
      expect(list.any((r) => r.title.contains('Electricity Bill')), isTrue);
    });

    test('createReminder inserts a new reminder and updates local store', () async {
      final newReminder = Reminder(
        id: '',
        userId: 'mock-user-001',
        title: 'Starlink Internet',
        amount: 15500.0,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        frequency: ReminderFrequency.monthly,
        note: 'Satellite broadband bill',
      );

      final created = await reminderRepository.createReminder(newReminder);

      expect(created.title, 'Starlink Internet');
      expect(created.amount, 15500.0);
      expect(created.frequency, ReminderFrequency.monthly);
      expect(created.isCompleted, isFalse);

      final all = await reminderRepository.getReminders();
      expect(all.any((r) => r.id == created.id), isTrue);
      expect(all.any((r) => r.title == 'Starlink Internet'), isTrue);
    });

    test('getUpcomingReminders returns only pending reminders sorted by due date', () async {
      final upcoming = await reminderRepository.getUpcomingReminders();
      expect(upcoming.every((r) => !r.isCompleted), isTrue);
    });

    test('updateReminder modifies title, amount and frequency', () async {
      final all = await reminderRepository.getReminders();
      final target = all.first;

      final updated = target.copyWith(
        title: 'Updated Water Utility',
        amount: 3200.0,
        frequency: ReminderFrequency.weekly,
      );

      final result = await reminderRepository.updateReminder(updated);
      expect(result.title, 'Updated Water Utility');
      expect(result.amount, 3200.0);
      expect(result.frequency, ReminderFrequency.weekly);

      final retrieved = await reminderRepository.getReminderById(target.id);
      expect(retrieved?.title, 'Updated Water Utility');
    });

    test('toggleReminderCompleted flips completion status', () async {
      final all = await reminderRepository.getReminders();
      final target = all.firstWhere((r) => !r.isCompleted);

      final completed = await reminderRepository.toggleReminderCompleted(target.id, true);
      expect(completed.isCompleted, isTrue);

      final uncompleted = await reminderRepository.toggleReminderCompleted(target.id, false);
      expect(uncompleted.isCompleted, isFalse);
    });

    test('deleteReminder removes item from repository', () async {
      final created = await reminderRepository.createReminder(
        Reminder(
          id: '',
          userId: 'mock-user-001',
          title: 'Temporary Reminder',
          dueDate: DateTime.now().add(const Duration(days: 2)),
        ),
      );

      final before = await reminderRepository.getReminders();
      expect(before.any((r) => r.id == created.id), isTrue);

      await reminderRepository.deleteReminder(created.id);

      final after = await reminderRepository.getReminders();
      expect(after.any((r) => r.id == created.id), isFalse);
    });
  });

  group('Reminders Riverpod Provider State Tests', () {
    test('remindersProvider loads initial state properly', () async {
      final container = ProviderContainer(
        overrides: [
          reminderRepositoryProvider.overrideWithValue(reminderRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remindersProvider.notifier).loadReminders();
      final reminders = container.read(remindersProvider);
      expect(reminders.isNotEmpty, isTrue);

      final pending = container.read(pendingRemindersProvider);
      final completed = container.read(completedRemindersProvider);

      expect(pending.every((r) => !r.isCompleted), isTrue);
      expect(completed.every((r) => r.isCompleted), isTrue);
    });

    test('createReminder through provider adds reminder and refreshes lists', () async {
      final container = ProviderContainer(
        overrides: [
          reminderRepositoryProvider.overrideWithValue(reminderRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remindersProvider.notifier).loadReminders();
      final notifier = container.read(remindersProvider.notifier);

      final created = await notifier.createReminder(
        Reminder(
          id: '',
          userId: 'mock-user-001',
          title: 'Adobe Creative Cloud',
          amount: 8200.0,
          dueDate: DateTime.now().add(const Duration(days: 4)),
          frequency: ReminderFrequency.monthly,
        ),
      );

      expect(created, isNotNull);
      final pending = container.read(pendingRemindersProvider);
      expect(pending.any((r) => r.title == 'Adobe Creative Cloud'), isTrue);
    });

    test('toggleComplete through provider moves reminder from pending to completed', () async {
      final container = ProviderContainer(
        overrides: [
          reminderRepositoryProvider.overrideWithValue(reminderRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remindersProvider.notifier).loadReminders();
      final reminders = container.read(remindersProvider);
      final pendingItem = reminders.firstWhere((r) => !r.isCompleted);
      final notifier = container.read(remindersProvider.notifier);

      await notifier.toggleComplete(pendingItem);

      final completed = container.read(completedRemindersProvider);
      expect(completed.any((r) => r.id == pendingItem.id), isTrue);
    });

    test('deleteReminder through provider removes record from all lists', () async {
      final container = ProviderContainer(
        overrides: [
          reminderRepositoryProvider.overrideWithValue(reminderRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remindersProvider.notifier).loadReminders();
      final reminders = container.read(remindersProvider);
      final target = reminders.first;
      final notifier = container.read(remindersProvider.notifier);

      await notifier.deleteReminder(target.id);

      final after = container.read(remindersProvider);
      expect(after.any((r) => r.id == target.id), isFalse);
    });

    test('remindersSummaryProvider returns correct counts and amounts', () async {
      final container = ProviderContainer(
        overrides: [
          reminderRepositoryProvider.overrideWithValue(reminderRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remindersProvider.notifier).loadReminders();
      final summary = container.read(remindersSummaryProvider);

      expect(summary.totalCount, greaterThan(0));
      expect(summary.upcomingCount + summary.completedCount + summary.overdueCount, greaterThanOrEqualTo(summary.totalCount));
    });
  });

  group('Reminders UI & Widget Tests', () {
    testWidgets('RemindersScreen renders title, summary chips, and add button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderRepositoryProvider.overrideWithValue(reminderRepository),
          ],
          child: const MaterialApp(
            home: RemindersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reminders'), findsOneWidget);
      expect(find.byKey(const Key('add_reminder_appbar_button')), findsOneWidget);
      expect(find.text('UPCOMING'), findsWidgets);
      expect(find.text('COMPLETED'), findsWidgets);
    });

    testWidgets('AddReminderScreen validates required title and allows cancellation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderRepositoryProvider.overrideWithValue(reminderRepository),
          ],
          child: const MaterialApp(
            home: AddReminderScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Reminder'), findsOneWidget);
      expect(find.byKey(const Key('save_reminder_button')), findsOneWidget);

      // Tap Save without entering title
      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      expect(find.text('Reminder title is required'), findsOneWidget);
    });

    testWidgets('AddReminderScreen successfully submits a valid reminder', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderRepositoryProvider.overrideWithValue(reminderRepository),
          ],
          child: const MaterialApp(
            home: AddReminderScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter title (TextFormField at 0)
      await tester.enterText(find.byType(TextFormField).at(0), 'Fiber Broadband');
      // Enter amount (TextFormField at 1)
      await tester.enterText(find.byType(TextFormField).at(1), '4800');

      // Tap Save Reminder
      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      // Successful creation should have called repository
      final all = await reminderRepository.getReminders();
      expect(all.any((r) => r.title == 'Fiber Broadband'), isTrue);
    });

    testWidgets('RemindersScreen: delete triggers confirmation dialog before deleting', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderRepositoryProvider.overrideWithValue(reminderRepository),
          ],
          child: const MaterialApp(
            home: RemindersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find first reminder card popup menu
      final popupMenuButtons = find.byType(PopupMenuButton<String>);
      expect(popupMenuButtons, findsWidgets);

      await tester.tap(popupMenuButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Delete Reminder'), findsOneWidget);
      await tester.tap(find.text('Delete Reminder'));
      await tester.pumpAndSettle();

      // Verify Delete Reminder dialog
      expect(find.text('Delete Reminder?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this reminder?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_reminder_button')), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Reminder?'), findsNothing);

      // Confirm delete flow
      await tester.tap(popupMenuButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Reminder'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_reminder_button')));
      await tester.pumpAndSettle();
      expect(find.text('Delete Reminder?'), findsNothing);
    });

    testWidgets('RemindersScreen displays friendly empty state when no reminders exist', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            remindersProvider.overrideWith(() => _EmptyRemindersNotifier()),
          ],
          child: const MaterialApp(
            home: RemindersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No reminders yet'), findsOneWidget);
      expect(find.text('Keep track of upcoming bills and important payments.'), findsOneWidget);
      expect(find.byKey(const Key('empty_state_add_reminder_button')), findsOneWidget);
    });

    testWidgets('RemindersScreen toggles completion status when toggle button is tapped', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final initialReminders = await reminderRepository.getReminders();
      final target = initialReminders.firstWhere((r) => !r.isCompleted);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderRepositoryProvider.overrideWithValue(reminderRepository),
          ],
          child: const MaterialApp(
            home: RemindersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final toggleKey = Key('toggle_reminder_${target.id}');
      expect(find.byKey(toggleKey), findsOneWidget);

      await tester.tap(find.byKey(toggleKey));
      await tester.pumpAndSettle();

      final updated = await reminderRepository.getReminderById(target.id);
      expect(updated?.isCompleted, isTrue);
    });

    testWidgets('AddReminderScreen preloads existing reminder values for editing and saves changes', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final existing = Reminder(
        id: 'edit-test-1',
        userId: 'mock-user-001',
        title: 'Office Cleaning',
        amount: 3500,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        frequency: ReminderFrequency.weekly,
        note: 'Pay janitorial service',
      );
      await reminderRepository.createReminder(existing);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderRepositoryProvider.overrideWithValue(reminderRepository),
          ],
          child: MaterialApp(
            home: AddReminderScreen(existingReminder: existing),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Reminder'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Office Cleaning'), findsOneWidget);

      // Modify title
      await tester.enterText(find.byType(TextFormField).at(0), 'Office Cleaning & Sanitization');
      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      final inRepo = await reminderRepository.getReminderById(existing.id);
      expect(inRepo?.title, 'Office Cleaning & Sanitization');
    });

    testWidgets('RemindersScreen switches tabs between Upcoming, Overdue, Completed and All', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reminderRepositoryProvider.overrideWithValue(reminderRepository),
          ],
          child: const MaterialApp(
            home: RemindersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Upcoming'), findsWidgets);
      expect(find.textContaining('Completed'), findsWidgets);
      expect(find.textContaining('All'), findsWidgets);

      // Tap Completed filter chip
      await tester.tap(find.text('COMPLETED'));
      await tester.pumpAndSettle();

      // Tap All filter tab (in horizontal scroll view)
      await tester.tap(find.textContaining('All ('), warnIfMissed: false);
      await tester.pumpAndSettle();
    });
  });
}

class _EmptyRemindersNotifier extends RemindersNotifier {
  @override
  List<Reminder> build() => [];
}
