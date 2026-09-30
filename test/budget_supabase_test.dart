import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moneypilot/core/storage/secure_storage.dart';
import 'package:moneypilot/features/auth/data/auth_repository.dart';
import 'package:moneypilot/features/budgets/data/budget_repository.dart';
import 'package:moneypilot/features/budgets/data/budgets_provider.dart';
import 'package:moneypilot/features/budgets/domain/budget_model.dart';
import 'package:moneypilot/features/transactions/data/transactions_provider.dart';
import 'package:moneypilot/features/transactions/domain/transaction_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  group('Part 3 & 17: Budget Domain Model Serialization', () {
    test('Budget.fromMap correctly parses standard Supabase row with joined categories', () {
      final map = {
        'id': 'b-uuid-1234',
        'user_id': 'user-uuid-5678',
        'category_id': 'cat-sys-6',
        'amount': 25000,
        'period': 'monthly',
        'start_date': '2026-09-01',
        'end_date': '2026-09-30',
        'note': 'Fine dining allowance',
        'created_at': '2026-09-01T00:00:00Z',
        'updated_at': '2026-09-15T12:00:00Z',
        'categories': {
          'name': 'Dining Out',
          'icon': 'restaurant_outlined',
          'color_hex': '#F97316',
        },
      };

      final budget = Budget.fromMap(map, calculatedSpent: 12500);

      expect(budget.id, 'b-uuid-1234');
      expect(budget.userId, 'user-uuid-5678');
      expect(budget.categoryId, 'cat-sys-6');
      expect(budget.category, 'Dining Out');
      expect(budget.categoryIcon, 'restaurant_outlined');
      expect(budget.categoryColor, '#F97316');
      expect(budget.amount, 25000.0);
      expect(budget.spent, 12500.0);
      expect(budget.month, 9);
      expect(budget.year, 2026);
      expect(budget.note, 'Fine dining allowance');
    });

    test('Budget.toMap formats data matching PostgreSQL public.budgets schema', () {
      final budget = Budget(
        id: 'b-uuid-1234',
        userId: 'user-uuid-5678',
        categoryId: 'cat-sys-6',
        category: 'Dining Out',
        amount: 30000,
        month: 10,
        year: 2026,
        period: 'Monthly',
        note: 'October food target',
        createdAt: DateTime(2026, 10, 1),
      );

      final map = budget.toMap();

      expect(map['id'], 'b-uuid-1234');
      expect(map['user_id'], 'user-uuid-5678');
      expect(map['category_id'], 'cat-sys-6');
      expect(map['amount'], 30000.0);
      expect(map['period'], 'monthly');
      expect(map['start_date'], '2026-10-01');
      expect(map['end_date'], '2026-10-31');
      expect(map['note'], 'October food target');
    });
  });

  group('Part 9, 10, 11, 12: Budget Spending & Alert Calculations', () {
    test('Calculates remaining, progress, and percentage correctly when under budget', () {
      final budget = Budget(
        id: 'b-1',
        category: 'Groceries',
        amount: 100,
        spent: 40,
        createdAt: DateTime(2026, 9, 1),
      );

      expect(budget.progress, 0.4);
      expect(budget.usagePercentage, 40.0);
      expect(budget.remaining, 60.0);
      expect(budget.isOverBudget, isFalse);
      expect(budget.isNearLimit, isFalse);
      expect(budget.overBudgetAmount, 0.0);
    });

    test('Detects near-limit warning threshold at 80% or more (Part 11)', () {
      final budget = Budget(
        id: 'b-2',
        category: 'Food & Dining',
        amount: 100,
        spent: 85,
        createdAt: DateTime(2026, 9, 1),
      );

      expect(budget.usagePercentage, 85.0);
      expect(budget.remaining, 15.0);
      expect(budget.isNearLimit, isTrue);
      expect(budget.isOverBudget, isFalse);
      expect(budget.category, 'Food & Dining'); // Clearly identifies category
    });

    test('Detects over-budget alert when spent > budget (Part 12)', () {
      final budget = Budget(
        id: 'b-3',
        category: 'Food & Dining',
        amount: 100,
        spent: 125,
        createdAt: DateTime(2026, 9, 1),
      );

      expect(budget.isOverBudget, isTrue);
      expect(budget.isNearLimit, isFalse); // Once over budget, near-limit flag transitions
      expect(budget.overBudgetAmount, 25.0);
      expect(budget.usagePercentage, 125.0);
      expect(budget.category, 'Food & Dining'); // Clearly identifies category
    });

    test('Safely handles zero budget values without division by zero', () {
      final budget = Budget(
        id: 'b-4',
        category: 'Misc',
        amount: 0,
        spent: 50,
        createdAt: DateTime(2026, 9, 1),
      );

      expect(budget.progress, 0.0);
      expect(budget.usagePercentage, 0.0);
      expect(budget.isOverBudget, isTrue);
    });
  });

  group('Part 4: BudgetRepository CRUD & Duplicate Prevention', () {
    test('createBudget, getBudgets, updateBudget, and deleteBudget in mock mode', () async {
      final authRepo = SupabaseAuthRepository(client: null, secureStorage: SecureStorageService());
      final repo = SupabaseBudgetRepository(authRepository: authRepo);

      // Create
      final created = await repo.createBudget(
        categoryId: 'cat-sys-4',
        categoryName: 'Groceries',
        amount: 40000,
        month: 9,
        year: 2026,
        note: 'Pantry essentials',
      );

      expect(created.category, 'Groceries');
      expect(created.amount, 40000);

      // Read
      final list = await repo.getBudgets(month: 9, year: 2026);
      expect(list.any((b) => b.category == 'Groceries'), isTrue);

      // Read by ID
      final fetched = await repo.getBudgetById(created.id);
      expect(fetched, isNotNull);
      expect(fetched?.amount, 40000);

      // Update
      final updated = created.copyWith(amount: 45000);
      await repo.updateBudget(updated);
      final afterUpdate = await repo.getBudgetById(created.id);
      expect(afterUpdate?.amount, 45000);

      // Delete
      await repo.deleteBudget(created.id);
      final afterDelete = await repo.getBudgetById(created.id);
      expect(afterDelete, isNull);
    });

    test('Prevents duplicate budget for the same category and period', () async {
      final authRepo = SupabaseAuthRepository(client: null, secureStorage: SecureStorageService());
      final repo = SupabaseBudgetRepository(authRepository: authRepo);

      // First creation succeeds
      await repo.createBudget(
        categoryId: 'cat-unique-1',
        categoryName: 'Health/Medical',
        amount: 12000,
        month: 11,
        year: 2026,
      );

      // Second creation for same category, month, and year throws BudgetDuplicateException
      expect(
        () => repo.createBudget(
          categoryId: 'cat-unique-1',
          categoryName: 'Health/Medical',
          amount: 15000,
          month: 11,
          year: 2026,
        ),
        throwsA(isA<BudgetDuplicateException>()),
      );
    });
  });

  group('Part 5 & 9: Dynamic Spending Recalculation via Riverpod', () {
    test('Adding a transaction dynamically updates budget spending and alerts', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify initial budgets
      final initialBudgets = container.read(budgetsProvider);
      final foodBudget = initialBudgets.firstWhere((b) => b.category == 'Food & Dining');
      final initialSpent = foodBudget.spent;

      // Add an expense transaction to Food & Dining
      await container.read(transactionsProvider.notifier).addTransaction(
            title: 'Dinner with colleagues',
            amount: 7500,
            type: TransactionType.expense,
            categoryId: 'cat-sys-6',
            categoryName: 'Food & Dining',
            date: DateTime(foodBudget.year, foodBudget.month, 15),
            note: 'Italian restaurant dinner',
          );

      // budgetsProvider should automatically recalculate spent
      final updatedBudgets = container.read(budgetsProvider);
      final updatedFoodBudget =
          updatedBudgets.firstWhere((b) => b.category == 'Food & Dining');

      expect(updatedFoodBudget.spent, initialSpent + 7500);
      expect(updatedFoodBudget.remaining, foodBudget.amount - (initialSpent + 7500));
    });

    test('activeBudgetAlertsProvider identifies near-limit and over-budget categories', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final budgetsNotifier = container.read(budgetsProvider.notifier);

      // Add a budget with limit 10,000
      final testBudget = Budget(
        id: 'budget-test-alert',
        categoryId: 'cat-test-dining',
        category: 'Test Dining',
        amount: 10000,
        month: 9,
        year: 2026,
        createdAt: DateTime(2026, 9, 1),
      );
      await budgetsNotifier.addOrUpdateBudget(testBudget);

      // 1. Add expense of 8,500 (85% -> Near Limit)
      await container.read(transactionsProvider.notifier).addTransaction(
            title: 'Fancy Dinner',
            amount: 8500,
            type: TransactionType.expense,
            categoryId: 'cat-test-dining',
            categoryName: 'Test Dining',
            date: DateTime(2026, 9, 10),
          );

      final nearLimitAlerts = container.read(nearLimitBudgetsProvider);
      expect(nearLimitAlerts.any((b) => b.category == 'Test Dining'), isTrue);

      final nearBudget = nearLimitAlerts.firstWhere((b) => b.category == 'Test Dining');
      expect(nearBudget.usagePercentage, 85.0);
      expect(nearBudget.remaining, 1500.0);

      // 2. Add another expense of 2,000 (total 10,500 -> Over Budget)
      await container.read(transactionsProvider.notifier).addTransaction(
            title: 'Dessert & drinks',
            amount: 2000,
            type: TransactionType.expense,
            categoryId: 'cat-test-dining',
            categoryName: 'Test Dining',
            date: DateTime(2026, 9, 12),
          );

      final overBudgetAlerts = container.read(overBudgetBudgetsProvider);
      expect(overBudgetAlerts.any((b) => b.category == 'Test Dining'), isTrue);

      final overBudget = overBudgetAlerts.firstWhere((b) => b.category == 'Test Dining');
      expect(overBudget.isOverBudget, isTrue);
      expect(overBudget.overBudgetAmount, 500.0);
      expect(overBudget.spent, 10500.0);
    });
  });
}
