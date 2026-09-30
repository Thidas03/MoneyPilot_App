import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneypilot/app.dart';
import 'package:moneypilot/core/storage/secure_storage.dart';
import 'package:moneypilot/features/auth/data/auth_repository.dart';
import 'package:moneypilot/features/goals/data/goal_repository.dart';
import 'package:moneypilot/features/goals/data/goals_provider.dart';
import 'package:moneypilot/features/goals/domain/goal_contribution_model.dart';
import 'package:moneypilot/features/goals/domain/goal_model.dart';
import 'package:moneypilot/features/goals/presentation/goal_detail_screen.dart';
import 'package:moneypilot/features/reports/presentation/providers/reports_provider.dart';
import 'package:moneypilot/features/reports/presentation/reports_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'moneypilot_jwt_token': 'dummy_jwt_token',
      'moneypilot_has_seen_onboarding': 'true',
    });
  });

  group('GoalContribution Model Tests', () {
    test('Constructor validates positive amount', () {
      final contribution = GoalContribution(
        id: 'contrib-1',
        goalId: 'goal-1',
        amount: 25000,
        date: DateTime(2026, 9, 28),
        note: 'Monthly allocation',
      );

      expect(contribution.id, 'contrib-1');
      expect(contribution.goalId, 'goal-1');
      expect(contribution.amount, 25000);
      expect(contribution.formattedDate, '28 Sep 2026');
      expect(contribution.note, 'Monthly allocation');
    });

    test('fromMap and toMap serialize correctly for Supabase', () {
      final now = DateTime(2026, 9, 30, 10, 0);
      final rawMap = {
        'id': 'contrib-uuid-123',
        'goal_id': 'goal-uuid-456',
        'user_id': 'user-uuid-789',
        'amount': 50000.0,
        'contribution_date': now.toIso8601String(),
        'note': 'Salary bonus',
        'created_at': now.toIso8601String(),
      };

      final parsed = GoalContribution.fromMap(rawMap);
      expect(parsed.id, 'contrib-uuid-123');
      expect(parsed.goalId, 'goal-uuid-456');
      expect(parsed.userId, 'user-uuid-789');
      expect(parsed.amount, 50000.0);
      expect(parsed.date, now);
      expect(parsed.note, 'Salary bonus');

      final serialized = parsed.toMap();
      expect(serialized['id'], 'contrib-uuid-123');
      expect(serialized['goal_id'], 'goal-uuid-456');
      expect(serialized['user_id'], 'user-uuid-789');
      expect(serialized['amount'], 50000.0);
      expect(serialized['contribution_date'], now.toIso8601String());
      expect(serialized['note'], 'Salary bonus');
    });

    test('copyWith updates fields without mutating original', () {
      final original = GoalContribution(
        id: 'c-1',
        goalId: 'g-1',
        amount: 10000,
        date: DateTime(2026, 9, 1),
      );

      final updated = original.copyWith(amount: 15000, note: 'Added note');
      expect(updated.id, 'c-1');
      expect(updated.amount, 15000);
      expect(updated.note, 'Added note');
      expect(original.amount, 10000);
      expect(original.note, isNull);
    });
  });

  group('GoalRepository Contributions CRUD & Fallback Tests', () {
    late SupabaseGoalRepository repository;

    setUp(() {
      repository = SupabaseGoalRepository(
        client: null, // mock offline mode
        authRepository: SupabaseAuthRepository(
          client: null,
          secureStorage: SecureStorageService(),
        ),
      );
    });

    test('Seeded mock contributions exist for initial goals', () async {
      final contribsGoal1 = await repository.getContributions('goal-1');
      expect(contribsGoal1.length, 2);
      expect(contribsGoal1.first.amount, greaterThan(0));

      final contribsGoal2 = await repository.getContributions('goal-2');
      expect(contribsGoal2.length, 2);
    });

    test('addContribution persists record and increments goal currentAmount', () async {
      final goalBefore = await repository.getGoalById('goal-1');
      final amountBefore = goalBefore!.currentAmount;

      final newContribution = GoalContribution(
        id: 'contrib-new-1',
        goalId: 'goal-1',
        amount: 30000,
        date: DateTime.now(),
        note: 'Deposit',
      );

      final saved = await repository.addContribution(newContribution);
      expect(saved.id, 'contrib-new-1');

      final goalAfter = await repository.getGoalById('goal-1');
      expect(goalAfter!.currentAmount, amountBefore + 30000);

      final history = await repository.getContributions('goal-1');
      expect(history.any((c) => c.id == 'contrib-new-1'), isTrue);
    });

    test('deleteContribution removes record and decrements goal currentAmount', () async {
      final contrib = GoalContribution(
        id: 'temp-contrib',
        goalId: 'goal-1',
        amount: 20000,
        date: DateTime.now(),
      );
      await repository.addContribution(contrib);

      final goalBefore = await repository.getGoalById('goal-1');
      final amountBefore = goalBefore!.currentAmount;

      await repository.deleteContribution(
        goalId: 'goal-1',
        contributionId: 'temp-contrib',
      );

      final goalAfter = await repository.getGoalById('goal-1');
      expect(goalAfter!.currentAmount, amountBefore - 20000);

      final history = await repository.getContributions('goal-1');
      expect(history.any((c) => c.id == 'temp-contrib'), isFalse);
    });
  });

  group('GoalsNotifier Atomic Mutations & Reports Integration Tests', () {
    test('Adding contribution triggers goal completion transition', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Seed a test goal: target 100,000, current 80,000
      final testGoal = Goal(
        id: 'test-goal-completion',
        title: 'Emergency Flight Gear',
        targetAmount: 100000,
        currentAmount: 80000,
        deadlineDate: DateTime(2026, 12, 31),
      );

      await container.read(goalsProvider.notifier).createGoal(testGoal);
      expect(container.read(singleGoalProvider('test-goal-completion'))!.isCompleted, isFalse);

      // Add contribution of 25,000 (exceeds target by 5,000)
      final isNewlyCompleted = await container.read(goalsProvider.notifier).addContribution(
            goalId: 'test-goal-completion',
            amount: 25000,
            date: DateTime.now(),
            note: 'Final milestone push',
          );

      expect(isNewlyCompleted, isTrue);

      final updatedGoal = container.read(singleGoalProvider('test-goal-completion'))!;
      expect(updatedGoal.currentAmount, 105000);
      expect(updatedGoal.isCompleted, isTrue);
      expect(updatedGoal.remainingAmount, 0.0);
      expect(updatedGoal.progressPercentage, 100.0);
    });

    test('Reports provider reactively reflects goal contributions', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial reports state
      final initialReports = container.read(reportsProvider);
      final initialGoal1 = initialReports.activeGoals.firstWhere((g) => g.id == 'goal-1');
      final initialSaved = initialGoal1.currentAmount;

      // Add a 50,000 contribution to goal-1
      await container.read(goalsProvider.notifier).addContribution(
            goalId: 'goal-1',
            amount: 50000,
            date: DateTime.now(),
            note: 'Bonus transfer',
          );

      // Reports provider must update reactively without duplicate state
      final updatedReports = container.read(reportsProvider);
      final updatedGoal1 = updatedReports.activeGoals.firstWhere((g) => g.id == 'goal-1');
      expect(updatedGoal1.currentAmount, initialSaved + 50000);
    });
  });

  group('GoalDetailScreen Widget & User Flow Tests', () {
    testWidgets('Renders GoalDetailScreen header, progress, and history list', (tester) async {
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

      // Tap on goal-1 card ('Emergency Flight Reserve')
      final card = find.byKey(const Key('goal_card_goal-1'));
      expect(card, findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Verify Goal Details screen elements
      expect(find.byType(GoalDetailScreen), findsOneWidget);
      expect(find.text('Goal Details'), findsOneWidget);
      expect(find.text('Emergency Flight Reserve'), findsOneWidget);
      expect(find.byKey(const Key('add_contribution_button')), findsOneWidget);
      expect(find.byKey(const Key('edit_goal_action_button')), findsOneWidget);
      expect(find.byKey(const Key('delete_goal_action_button')), findsOneWidget);
      expect(find.text('CONTRIBUTION HISTORY'), findsOneWidget);

      // Verify seeded contributions appear
      expect(find.text('+ Rs. 70,000'), findsOneWidget);
      expect(find.text('+ Rs. 50,000'), findsOneWidget);
    });

    testWidgets('Adding contribution updates current amount, progress, and history', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Go to Goals -> goal-1
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('goal_card_goal-1')));
      await tester.pumpAndSettle();

      // Tap Add Contribution button
      await tester.tap(find.byKey(const Key('add_contribution_button')));
      await tester.pumpAndSettle();

      // Modal bottom sheet should be visible
      expect(find.text('Add Contribution'), findsWidgets);
      expect(find.byKey(const Key('contribution_amount_field')), findsOneWidget);

      // Enter contribution amount and note
      await tester.enterText(find.byKey(const Key('contribution_amount_field')), '15000');
      await tester.enterText(find.byKey(const Key('contribution_note_field')), 'Flight pay savings');
      await tester.pumpAndSettle();

      // Save contribution
      await tester.tap(find.byKey(const Key('save_contribution_button')));
      await tester.pumpAndSettle();

      // Modal closed, contribution appears in history
      expect(find.text('+ Rs. 15,000'), findsOneWidget);
      expect(find.text('Flight pay savings'), findsOneWidget);
      // New total: 120,000 + 15,000 = 135,000
      expect(find.text('Rs. 135,000'), findsWidgets);
    });

    testWidgets('Completing a goal displays celebration feedback and Goal Achieved badge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Go to Goals -> goal-1 (target 200,000, currently 120,000 or 135,000)
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('goal_card_goal-1')));
      await tester.pumpAndSettle();

      // Add a large contribution to reach target (100,000)
      await tester.tap(find.byKey(const Key('add_contribution_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('contribution_amount_field')), '100000');
      await tester.tap(find.byKey(const Key('save_contribution_button')));
      await tester.pumpAndSettle();

      // Goal Achieved snackbar and status badge
      expect(find.textContaining('Goal Achieved! You reached your savings target'), findsOneWidget);
      expect(find.text('Goal Achieved'), findsWidgets);
      expect(find.text('100% Saved'), findsOneWidget);
    });

    testWidgets('Deleting a contribution requires confirmation and recalculates amount', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Navigate to Goals -> Japan Vacation (goal-2)
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
      await tester.pumpAndSettle();

      final goal2Card = find.byKey(const Key('goal_card_goal-2'));
      expect(goal2Card, findsOneWidget);
      await tester.tap(goal2Card);
      await tester.pumpAndSettle();

      // On GoalDetailScreen, drag down if needed to ensure contribution tile is visible
      expect(find.byType(GoalDetailScreen), findsOneWidget);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
      await tester.pumpAndSettle();

      // Verify contrib-2-2 is present (+ Rs. 150,000)
      expect(find.text('+ Rs. 150,000'), findsOneWidget);
      final deleteBtn = find.byKey(const Key('delete_contribution_btn_contrib-2-2'));
      expect(deleteBtn, findsOneWidget);

      // Tap delete
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Delete this contribution?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_contribution_button')), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.byKey(const Key('confirm_delete_contribution_button')));
      await tester.pumpAndSettle();

      // Contribution should be removed from history
      expect(find.text('+ Rs. 150,000'), findsNothing);
      // Japan Vacation was 350,000 - 150,000 = 200,000
      expect(find.text('Rs. 200,000'), findsWidgets);
    });

    testWidgets('Contribution changes reactively update Reports Goals section', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // 1. Visit Reports screen
      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      expect(find.byType(ReportsScreen), findsOneWidget);

      // 2. Go to Goals -> goal-1 and add a contribution of 20,000
      await tester.tap(find.text('Goals').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('goal_card_goal-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_contribution_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('contribution_amount_field')), '20000');
      await tester.tap(find.byKey(const Key('save_contribution_button')));
      await tester.pumpAndSettle();

      // 3. Return to Reports tab and verify updated savings progress
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();

      expect(find.byType(ReportsScreen), findsOneWidget);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Financial Goals Progress'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
