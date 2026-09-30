import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneypilot/app.dart';
import 'package:moneypilot/features/budgets/data/budgets_provider.dart';
import 'package:moneypilot/features/budgets/presentation/add_budget_screen.dart';
import 'package:moneypilot/features/budgets/presentation/budgets_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'moneypilot_jwt_token': 'dummy_jwt_token',
      'moneypilot_has_seen_onboarding': 'true',
    });
  });

  group('Budgets Provider & Logic', () {
    test('Initial category budgets are seeded properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final budgets = container.read(budgetsProvider);
      expect(budgets.length, 3);
      expect(budgets.any((b) => b.category == 'Food & Dining'), isTrue);
      expect(budgets.any((b) => b.category == 'Transportation'), isTrue);
      expect(budgets.any((b) => b.category == 'Entertainment'), isTrue);
    });

    test('addOrUpdateBudget updates existing budget without duplicating', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(budgetsProvider);
      final foodBudget = initial.firstWhere((b) => b.category == 'Food & Dining');

      final updated = foodBudget.copyWith(amount: 30000);
      container.read(budgetsProvider.notifier).addOrUpdateBudget(updated);

      final after = container.read(budgetsProvider);
      expect(after.length, 3);
      expect(after.firstWhere((b) => b.category == 'Food & Dining').amount, 30000);
    });

    test('removeBudget deletes budget by id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(budgetsProvider);
      final foodBudget = initial.firstWhere((b) => b.category == 'Food & Dining');

      container.read(budgetsProvider.notifier).removeBudget(foodBudget.id);

      final after = container.read(budgetsProvider);
      expect(after.length, 2);
      expect(after.any((b) => b.id == foodBudget.id), isFalse);
    });
  });

  group('Budget UI & Navigation', () {
    testWidgets('Tapping Add Budget opens AddBudgetScreen in Add mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Go to Budget tab
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      expect(find.byType(BudgetsScreen), findsOneWidget);

      // Tap "Add Budget" button in app bar
      final addBtn = find.byKey(const Key('add_budget_appbar_button'));
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Should be in Add mode
      expect(find.byType(AddBudgetScreen), findsOneWidget);
      expect(find.text('Add budget'), findsOneWidget);
      expect(find.text('Save budget'), findsOneWidget);
      expect(find.byKey(const Key('delete_budget_button')), findsNothing);
    });

    testWidgets('Tapping already added budget category opens Edit mode with prefilled data and delete option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Go to Budget tab
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      // Tap existing "Food & Dining" budget item
      final foodTile = find.byKey(const Key('budget_category_food_&_dining'));
      expect(foodTile, findsOneWidget);
      await tester.tap(foodTile);
      await tester.pumpAndSettle();

      // Verify that it opens in EDIT mode, NOT "Add budget"
      expect(find.byType(AddBudgetScreen), findsOneWidget);
      expect(find.text('Edit budget'), findsOneWidget);
      expect(find.text('Update budget'), findsOneWidget);
      expect(find.byKey(const Key('delete_budget_button')), findsOneWidget);

      // Verify amount is prefilled with 25000
      final amountField = find.byKey(const Key('budget_amount_field'));
      expect(amountField, findsOneWidget);
      expect(find.text('25000'), findsOneWidget);

      // Update amount to 28000
      await tester.enterText(amountField, '28000');
      await tester.pumpAndSettle();

      // Tap "Update budget"
      await tester.tap(find.byKey(const Key('save_budget_button')));
      await tester.pumpAndSettle();

      // Should return to BudgetsScreen
      expect(find.byType(BudgetsScreen), findsOneWidget);
      expect(find.text('Budget limit: Rs. 28,000'), findsOneWidget);
    });
  });
}
