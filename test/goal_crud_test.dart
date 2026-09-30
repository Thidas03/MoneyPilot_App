import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneypilot/app.dart';
import 'package:moneypilot/features/dashboard/presentation/dashboard_screen.dart';
import 'package:moneypilot/features/goals/data/goals_provider.dart';
import 'package:moneypilot/features/goals/domain/goal_model.dart';
import 'package:moneypilot/features/goals/presentation/add_goal_screen.dart';
import 'package:moneypilot/features/goals/presentation/goals_screen.dart';
import 'package:moneypilot/features/goals/presentation/goal_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'moneypilot_jwt_token': 'dummy_jwt_token',
      'moneypilot_has_seen_onboarding': 'true',
    });
  });

  group('Goal Model Tests', () {
    test('remainingAmount calculates correctly and never goes negative', () {
      final goal1 = Goal(
        id: 'g1',
        title: 'Flight Training',
        targetAmount: 100000,
        currentAmount: 40000,
        deadlineDate: DateTime(2026, 12, 31),
      );
      expect(goal1.remainingAmount, 60000);
      expect(goal1.remaining, 60000);

      // Overfunded goal should clamp remainingAmount to 0.0
      final goal2 = Goal(
        id: 'g2',
        title: 'Emergency Fund',
        targetAmount: 50000,
        currentAmount: 70000,
        deadlineDate: DateTime(2026, 12, 31),
      );
      expect(goal2.remainingAmount, 0.0);
    });

    test('progressPercentage calculates ratio and clamps to 100%', () {
      final goal = Goal(
        id: 'g3',
        title: 'Japan Vacation',
        targetAmount: 200000,
        currentAmount: 100000,
        deadlineDate: DateTime(2026, 12, 31),
      );
      expect(goal.progressPercentage, 50.0);
      expect(goal.progressRatio, 0.5);
      expect(goal.percent, 50);

      // Overfunded goal should clamp to 100%
      final overfunded = goal.copyWith(currentAmount: 300000);
      expect(overfunded.progressPercentage, 100.0);
      expect(overfunded.progressRatio, 1.0);
      expect(overfunded.percent, 100);
    });

    test('progressPercentage safely handles targetAmount <= 0', () {
      final zeroTarget = Goal(
        id: 'g4',
        title: 'Zero Target',
        targetAmount: 0,
        currentAmount: 500,
        deadlineDate: DateTime(2026, 12, 31),
      );
      expect(zeroTarget.progressPercentage, 0.0);
      expect(zeroTarget.progressRatio, 0.0);

      final negTarget = Goal(
        id: 'g5',
        title: 'Negative Target',
        targetAmount: -100,
        currentAmount: 50,
        deadlineDate: DateTime(2026, 12, 31),
      );
      expect(negTarget.progressPercentage, 0.0);
    });

    test('isCompleted returns true when currentAmount >= targetAmount', () {
      final incomplete = Goal(
        id: 'g6',
        title: 'Drone',
        targetAmount: 80000,
        currentAmount: 79999,
        deadlineDate: DateTime(2026, 12, 31),
      );
      expect(incomplete.isCompleted, isFalse);

      final completed = incomplete.copyWith(currentAmount: 80000);
      expect(completed.isCompleted, isTrue);

      final overCompleted = incomplete.copyWith(currentAmount: 85000);
      expect(overCompleted.isCompleted, isTrue);
    });

    test('isNearCompletion returns true when 80%+ and not yet completed', () {
      final goal79 = Goal(
        id: 'g7',
        title: 'Headphones',
        targetAmount: 10000,
        currentAmount: 7900,
        deadlineDate: DateTime(2026, 12, 31),
      );
      expect(goal79.isNearCompletion, isFalse);

      final goal85 = goal79.copyWith(currentAmount: 8500);
      expect(goal85.isNearCompletion, isTrue);

      final goal100 = goal79.copyWith(currentAmount: 10000);
      expect(goal100.isNearCompletion, isFalse); // Completed, so not just 'near'
    });

    test('daysRemaining handles future, today, and past deadlines safely', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final futureGoal = Goal(
        id: 'g8',
        title: 'Future',
        targetAmount: 10000,
        deadlineDate: today.add(const Duration(days: 45)),
      );
      expect(futureGoal.daysRemaining, 45);

      final todayGoal = Goal(
        id: 'g9',
        title: 'Today',
        targetAmount: 10000,
        deadlineDate: today,
      );
      expect(todayGoal.daysRemaining, 0);

      final pastGoal = Goal(
        id: 'g10',
        title: 'Overdue',
        targetAmount: 10000,
        deadlineDate: today.subtract(const Duration(days: 10)),
      );
      expect(pastGoal.daysRemaining, -10);
    });

    test('fromMap and toMap serialize correctly for Supabase PostgreSQL', () {
      final now = DateTime(2026, 9, 15, 10, 30);
      final goal = Goal(
        id: 'goal-supabase-1',
        userId: 'usr-123',
        title: 'New Avionics',
        targetAmount: 500000,
        currentAmount: 150000,
        deadlineDate: DateTime(2027, 3, 31),
        note: 'Garmin GPS unit upgrade',
        iconName: 'flight_takeoff_rounded',
        colorHex: '#005C46',
        createdAt: now,
        updatedAt: now,
      );

      final map = goal.toMap(currentUserId: 'usr-123');
      expect(map['id'], 'goal-supabase-1');
      expect(map['user_id'], 'usr-123');
      expect(map['title'], 'New Avionics');
      expect(map['target_amount'], 500000.0);
      expect(map['current_amount'], 150000.0);
      expect(map['deadline'], '2027-03-31');
      expect(map['note'], 'Garmin GPS unit upgrade');
      expect(map['icon'], 'flight_takeoff_rounded');
      expect(map['color'], '#005C46');

      final reconstructed = Goal.fromMap(map);
      expect(reconstructed.id, goal.id);
      expect(reconstructed.userId, goal.userId);
      expect(reconstructed.title, goal.title);
      expect(reconstructed.targetAmount, goal.targetAmount);
      expect(reconstructed.currentAmount, goal.currentAmount);
      expect(reconstructed.note, goal.note);
      expect(reconstructed.iconName, goal.iconName);
      expect(reconstructed.colorHex, goal.colorHex);
    });

    test('Goal.legacy constructor parses string deadline and assigns defaults', () {
      final legacy = Goal.legacy(
        id: 'leg-1',
        title: 'Legacy Goal',
        currentAmount: 10000,
        targetAmount: 50000,
        deadline: 'Dec 2026',
        icon: Icons.shield_rounded,
        color: const Color(0xFF005C46),
      );
      expect(legacy.title, 'Legacy Goal');
      expect(legacy.targetAmount, 50000);
      expect(legacy.deadlineDate.year, 2026);
      expect(legacy.deadlineDate.month, 12);
      expect(legacy.iconName, 'shield_rounded');
      expect(legacy.colorHex, '#005c46');
    });
  });

  group('Goals Riverpod Notifier & CRUD Tests', () {
    test('Initial mock goals are seeded properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final goals = container.read(goalsProvider);
      expect(goals.length, 2);
      expect(goals.any((g) => g.title == 'Emergency Flight Reserve'), isTrue);
      expect(goals.any((g) => g.title == 'Japan Vacation'), isTrue);
    });

    test('createGoal adds a goal and updates state synchronously', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(goalsProvider);
      expect(initial.length, 2);

      final newGoal = Goal(
        id: 'goal-custom-1',
        title: 'Pilot License Examination',
        targetAmount: 75000,
        currentAmount: 15000,
        deadlineDate: DateTime(2027, 1, 15),
      );

      await container.read(goalsProvider.notifier).createGoal(newGoal);

      final updated = container.read(goalsProvider);
      expect(updated.length, 3);
      expect(updated.any((g) => g.id == 'goal-custom-1'), isTrue);
      expect(updated.firstWhere((g) => g.id == 'goal-custom-1').title, 'Pilot License Examination');
    });

    test('updateGoal modifies existing goal attributes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final goals = container.read(goalsProvider);
      final japan = goals.firstWhere((g) => g.title == 'Japan Vacation');

      final updatedJapan = japan.copyWith(
        targetAmount: 700000,
        note: 'Extended trip to include Osaka and Hokkaido',
      );

      await container.read(goalsProvider.notifier).updateGoal(updatedJapan);

      final after = container.read(goalsProvider);
      final refreshed = after.firstWhere((g) => g.id == japan.id);
      expect(refreshed.targetAmount, 700000);
      expect(refreshed.note, 'Extended trip to include Osaka and Hokkaido');
    });

    test('addSavings increments current amount properly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final goals = container.read(goalsProvider);
      final japan = goals.firstWhere((g) => g.title == 'Japan Vacation');
      final initialSaved = japan.currentAmount;

      await container.read(goalsProvider.notifier).addSavings(japan.id, 25000);

      final after = container.read(goalsProvider);
      final updated = after.firstWhere((g) => g.id == japan.id);
      expect(updated.currentAmount, initialSaved + 25000);
    });

    test('deleteGoal removes goal from state synchronously', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(goalsProvider);
      final toDelete = initial.first;

      await container.read(goalsProvider.notifier).deleteGoal(toDelete.id);

      final after = container.read(goalsProvider);
      expect(after.length, initial.length - 1);
      expect(after.any((g) => g.id == toDelete.id), isFalse);
    });

    test('derived providers calculate totals and active/completed filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final all = container.read(goalsProvider);
      final active = container.read(activeGoalsProvider);
      final completed = container.read(completedGoalsProvider);
      final totalTarget = container.read(totalGoalsTargetProvider);
      final totalSaved = container.read(totalGoalsSavedProvider);

      expect(active.length + completed.length, all.length);
      expect(totalTarget, 200000 + 600000);
      expect(totalSaved, 120000 + 350000);
    });
  });

  group('Goals UI & Navigation Widget Tests', () {
    testWidgets('GoalsScreen renders header, total progress, and seeded goals', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Navigate to Goals tab in bottom bar
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();

      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.text('Track Your Financial Dreams'), findsOneWidget);
      expect(find.text('Total Goals Progress'), findsOneWidget);
      expect(find.text('Emergency Flight Reserve'), findsOneWidget);
      expect(find.text('Japan Vacation'), findsOneWidget);
      expect(find.byKey(const Key('add_goal_button')), findsOneWidget);
      expect(find.byKey(const Key('goals_fab')), findsNothing);
    });

    testWidgets('Tapping New Goal button navigates to AddGoalScreen in Add mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Go to Goals tab
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();

      // Tap New Goal button
      await tester.tap(find.byKey(const Key('add_goal_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AddGoalScreen), findsOneWidget);
      expect(find.text('Add Goal'), findsOneWidget);
      expect(find.text('Save Goal'), findsOneWidget);
      expect(find.byKey(const Key('delete_goal_button')), findsNothing);
    });

    testWidgets('AddGoalScreen form validation prevents invalid submissions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Go to Goals -> Add Goal
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_goal_button')));
      await tester.pumpAndSettle();

      // 1. Submit empty form
      await tester.ensureVisible(find.byKey(const Key('save_goal_button')));
      await tester.tap(find.byKey(const Key('save_goal_button')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a goal name'), findsOneWidget);

      // 2. Fill name but leave target amount empty
      await tester.enterText(find.byKey(const Key('goal_title_field')), 'New Drone');
      await tester.ensureVisible(find.byKey(const Key('save_goal_button')));
      await tester.tap(find.byKey(const Key('save_goal_button')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a target amount'), findsOneWidget);

      // 3. Fill invalid target amount (0 or negative)
      await tester.enterText(find.byKey(const Key('goal_target_amount_field')), '0');
      await tester.ensureVisible(find.byKey(const Key('save_goal_button')));
      await tester.tap(find.byKey(const Key('save_goal_button')));
      await tester.pumpAndSettle();
      expect(find.text('Target amount must be greater than 0'), findsOneWidget);

      // 4. Fill current amount greater than target
      await tester.enterText(find.byKey(const Key('goal_target_amount_field')), '50000');
      await tester.enterText(find.byKey(const Key('goal_current_amount_field')), '80000');
      await tester.ensureVisible(find.byKey(const Key('save_goal_button')));
      await tester.tap(find.byKey(const Key('save_goal_button')));
      await tester.pumpAndSettle();
      expect(find.text('Current amount cannot exceed the target amount'), findsOneWidget);
    });

    testWidgets('Creating a valid goal adds it to GoalsScreen list and updates Dashboard', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Navigate to Goals -> Add Goal
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_goal_button')));
      await tester.pumpAndSettle();

      // Fill in valid details
      await tester.enterText(find.byKey(const Key('goal_title_field')), 'DJI Mini 4 Pro');
      await tester.enterText(find.byKey(const Key('goal_target_amount_field')), '280000');
      await tester.enterText(find.byKey(const Key('goal_current_amount_field')), '70000');
      await tester.enterText(find.byKey(const Key('goal_note_field')), 'Aerial photography gear');
      await tester.pumpAndSettle();

      // Tap Save Goal
      await tester.ensureVisible(find.byKey(const Key('save_goal_button')));
      await tester.tap(find.byKey(const Key('save_goal_button')));
      await tester.pumpAndSettle();

      // Should be back on GoalsScreen and new goal appears
      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.text('DJI Mini 4 Pro'), findsOneWidget);

      // Navigate back to Dashboard and verify the goal appears in Financial Goals preview
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Financial Goals'), findsOneWidget);
      expect(find.text('DJI Mini 4 Pro'), findsOneWidget);
    });

    testWidgets('Tapping existing goal card opens GoalDetailScreen and navigates to Edit mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Navigate to Goals tab
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();

      // Tap Japan Vacation card
      final japanCard = find.byKey(const Key('goal_card_goal-2'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(japanCard, findsOneWidget);
      await tester.tap(japanCard);
      await tester.pumpAndSettle();

      // Verify opened in GoalDetailScreen
      expect(find.byType(GoalDetailScreen), findsOneWidget);
      expect(find.text('Goal Details'), findsOneWidget);
      expect(find.byKey(const Key('edit_goal_action_button')), findsOneWidget);

      // Tap Edit Goal action button
      await tester.tap(find.byKey(const Key('edit_goal_action_button')));
      await tester.pumpAndSettle();

      // Verify opened in Edit mode
      expect(find.byType(AddGoalScreen), findsOneWidget);
      expect(find.text('Edit Goal'), findsOneWidget);
      expect(find.text('Update Goal'), findsOneWidget);

      // Update target amount
      await tester.enterText(find.byKey(const Key('goal_target_amount_field')), '650000');
      await tester.pumpAndSettle();

      // Tap Update Goal
      await tester.ensureVisible(find.byKey(const Key('save_goal_button')));
      await tester.tap(find.byKey(const Key('save_goal_button')));
      await tester.pumpAndSettle();

      // Return back to GoalsScreen
      if (find.byType(GoalDetailScreen).evaluate().isNotEmpty) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // Should be back on GoalsScreen
      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.textContaining('650,000'), findsWidgets);
    });

    testWidgets('Delete goal shows confirmation dialog and removes goal', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Navigate to Goals tab
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();

      // Tap Japan Vacation card to open GoalDetailScreen
      final japanCard = find.byKey(const Key('goal_card_goal-2'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(japanCard);
      await tester.pumpAndSettle();

      expect(find.byType(GoalDetailScreen), findsOneWidget);

      // Tap delete icon in header
      expect(find.byKey(const Key('delete_goal_action_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('delete_goal_action_button')));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Delete Goal?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.byKey(const Key('confirm_delete_goal_button')));
      await tester.pumpAndSettle();

      // Back on GoalsScreen, Japan Vacation should be removed
      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.byKey(const Key('goal_card_goal-2')), findsNothing);
    });

    testWidgets('Dashboard Financial Goals card navigates to /goals on tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // On Dashboard, scroll down until Financial Goals card is fully visible
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Financial Goals'), findsOneWidget);
      await tester.tap(find.text('Financial Goals'));
      await tester.pumpAndSettle();

      // Should navigate to GoalsScreen
      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.text('Track Your Financial Dreams'), findsOneWidget);
    });
  });
}
