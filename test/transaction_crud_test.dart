import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/app.dart';
import 'package:moneypilot/core/storage/secure_storage.dart';
import 'package:moneypilot/features/auth/data/auth_repository.dart';
import 'package:moneypilot/features/transactions/data/transaction_repository.dart';
import 'package:moneypilot/features/transactions/data/transactions_provider.dart';
import 'package:moneypilot/features/transactions/domain/transaction_model.dart';
import 'package:moneypilot/features/transactions/presentation/add_transaction_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageService secureStorage;
  late SupabaseAuthRepository authRepository;
  late SupabaseTransactionRepository transactionRepository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    secureStorage = SecureStorageService();
    authRepository = SupabaseAuthRepository(
      client: null,
      secureStorage: secureStorage,
    );
    transactionRepository = SupabaseTransactionRepository(
      client: null,
      authRepository: authRepository,
    );
  });

  group('Transaction Model serialization tests', () {
    test('Transaction.fromMap parses Supabase joined row map', () {
      final map = {
        'id': 'tx-1234',
        'user_id': 'u100',
        'category_id': 'cat-1',
        'title': 'Flight Equipment',
        'amount': 45000.50,
        'type': 'expense',
        'transaction_date': '2026-09-29T12:00:00Z',
        'note': 'Aviation headset',
        'categories': {
          'name': 'Shopping',
          'icon': 'shopping_bag_outlined',
          'color_hex': '#8B5CF6',
        },
      };

      final tx = Transaction.fromMap(map);

      expect(tx.id, equals('tx-1234'));
      expect(tx.userId, equals('u100'));
      expect(tx.categoryId, equals('cat-1'));
      expect(tx.category, equals('Shopping'));
      expect(tx.title, equals('Flight Equipment'));
      expect(tx.amount, equals(45000.50));
      expect(tx.type, equals(TransactionType.expense));
      expect(tx.isExpense, isTrue);
      expect(tx.isIncome, isFalse);
      expect(tx.note, equals('Aviation headset'));
    });

    test('Transaction.toMap prepares valid PostgreSQL payload', () {
      final tx = Transaction(
        id: 'tx-real-uuid-001',
        userId: 'u100',
        categoryId: 'cat-sys-1',
        category: 'Salary',
        title: 'Monthly Pay',
        amount: 250000,
        type: TransactionType.income,
        date: DateTime.utc(2026, 9, 28),
        note: 'Flight captain paycheck',
      );

      final map = tx.toMap();

      expect(map['id'], equals('tx-real-uuid-001'));
      expect(map['user_id'], equals('u100'));
      expect(map['category_id'], equals('cat-sys-1'));
      expect(map['title'], equals('Monthly Pay'));
      expect(map['amount'], equals(250000.0));
      expect(map['type'], equals('income'));
      expect(map['note'], equals('Flight captain paycheck'));
    });
  });

  group('TransactionRepository CRUD unit tests', () {
    test('Initial getTransactions returns 5 seeded mock transactions', () async {
      final list = await transactionRepository.getTransactions();
      expect(list.length, equals(5));
      expect(list.any((t) => t.title == 'Salary'), isTrue);
    });

    test('createTransaction inserts new transaction and updates list', () async {
      final created = await transactionRepository.createTransaction(
        title: 'Hotel Stay',
        amount: 15000,
        type: TransactionType.expense,
        categoryId: 'cat-sys-3',
        categoryName: 'Rent/Mortgage',
        date: DateTime(2026, 9, 29),
        note: 'Crew layover in Singapore',
      );

      expect(created.title, equals('Hotel Stay'));
      expect(created.amount, equals(15000.0));
      expect(created.type, equals(TransactionType.expense));

      final all = await transactionRepository.getTransactions();
      expect(all.length, equals(6));
      expect(all.first.title, equals('Hotel Stay'));
    });

    test('getTransactions with search filter', () async {
      final searchResults = await transactionRepository.getTransactions(search: 'Keells');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.title, equals('Keells Supermarket'));
    });

    test('getTransactions with type filter', () async {
      final incomeList = await transactionRepository.getTransactions(type: TransactionType.income);
      expect(incomeList.every((t) => t.isIncome), isTrue);

      final expenseList = await transactionRepository.getTransactions(type: TransactionType.expense);
      expect(expenseList.every((t) => t.isExpense), isTrue);
    });

    test('updateTransaction modifies record', () async {
      final original = await transactionRepository.getTransactionById('tx-2');
      expect(original, isNotNull);

      final updated = original!.copyWith(amount: 9999.0, title: 'Keells Premium');
      final res = await transactionRepository.updateTransaction(updated);

      expect(res.amount, equals(9999.0));
      expect(res.title, equals('Keells Premium'));

      final retrieved = await transactionRepository.getTransactionById('tx-2');
      expect(retrieved?.amount, equals(9999.0));
    });

    test('deleteTransaction removes transaction from repository', () async {
      await transactionRepository.deleteTransaction('tx-5');
      final all = await transactionRepository.getTransactions();
      expect(all.any((t) => t.id == 'tx-5'), isFalse);
    });
  });

  group('Reactive Provider and Dashboard Calculations tests', () {
    test('Dashboard calculation providers accurately reflect transactions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final income = container.read(totalIncomeProvider);
      final expense = container.read(totalExpenseProvider);
      final netSavings = container.read(netSavingsProvider);
      final savingsRate = container.read(savingsRateProvider);

      expect(income, equals(250000.0));
      expect(expense, equals(8450 + 2500 + 1850 + 1200));
      expect(netSavings, equals(income - expense));
      expect(savingsRate, greaterThan(0));
    });

    test('addTransaction through provider updates totals immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(transactionsProvider.notifier);
      await notifier.addTransaction(
        title: 'Freelance Flight Instruction',
        amount: 50000,
        type: TransactionType.income,
        categoryId: 'cat-sys-1',
        categoryName: 'Salary',
        date: DateTime.now(),
      );

      final updatedIncome = container.read(totalIncomeProvider);
      expect(updatedIncome, equals(300000.0));
    });

    test('deleteTransaction through provider recalculates expenses', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final expenseBefore = container.read(totalExpenseProvider);
      final notifier = container.read(transactionsProvider.notifier);

      // Delete Keells (8450)
      await notifier.deleteTransaction('tx-2');

      final expenseAfter = container.read(totalExpenseProvider);
      expect(expenseAfter, equals(expenseBefore - 8450));
    });
  });

  group('UI Flow & Usability Feedback widget tests', () {
    Future<void> loadDashboard(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({
        'moneypilot_has_seen_onboarding': 'true',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MoneyPilotApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'pilot@moneypilot.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome aboard!'), findsOneWidget);
    }

    testWidgets('Add Transaction: validates required fields', (WidgetTester tester) async {
      await loadDashboard(tester);

      // Open Add Entry from dashboard quick action
      final addEntryButton = find.byKey(const Key('quick_action_add_entry'));
      final inkWell = find.descendant(of: addEntryButton, matching: find.byType(InkWell));
      (tester.widget(inkWell) as InkWell).onTap!();
      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionScreen), findsOneWidget);

      // Tap Save with empty fields
      await tester.tap(find.byKey(const Key('save_transaction_button')));
      await tester.pumpAndSettle();

      expect(find.text('Amount is required'), findsOneWidget);
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('Add Transaction: successful submission displays explicit confirmation feedback (HCI fix)', (WidgetTester tester) async {
      await loadDashboard(tester);

      // Open Add Entry
      final addEntryButton = find.byKey(const Key('quick_action_add_entry'));
      final inkWell = find.descendant(of: addEntryButton, matching: find.byType(InkWell));
      (tester.widget(inkWell) as InkWell).onTap!();
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(find.byType(TextFormField).at(0), '4500');
      // Enter title
      await tester.enterText(find.byType(TextFormField).at(1), 'Airport Duty Free');

      // Tap Save Transaction
      await tester.tap(find.byKey(const Key('save_transaction_button')));
      await tester.pumpAndSettle();

      // Verify HCI usability confirmation SnackBar is displayed
      expect(find.byKey(const Key('transaction_success_snackbar')), findsOneWidget);
      expect(find.text('Transaction saved successfully!'), findsOneWidget);

      // Returned to dashboard
      expect(find.text('Welcome aboard!'), findsOneWidget);
    });

    testWidgets('Transactions screen: Delete action requires explicit confirmation dialog', (WidgetTester tester) async {
      await loadDashboard(tester);

      // Switch to Transactions tab via bottom nav
      final navTab = find.byKey(const Key('nav_tab_transactions'));
      expect(navTab, findsOneWidget);
      await tester.tap(navTab);
      await tester.pumpAndSettle();

      // Verify transaction list is rendered
      expect(find.text('Keells Supermarket'), findsOneWidget);

      // Tap delete on Keells Supermarket (tx-2)
      final deleteIcon = find.byKey(const Key('delete_tx_tx-2'));
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Verify Delete Confirmation Dialog is shown
      expect(find.text('Delete Transaction?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_button')), findsOneWidget);

      // Cancel delete
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Keells Supermarket'), findsOneWidget);

      // Tap delete again and confirm
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_button')));
      await tester.pumpAndSettle();

      // Item should be removed from the UI
      expect(find.text('Keells Supermarket'), findsNothing);
      expect(find.text('Deleted "Keells Supermarket" successfully.'), findsOneWidget);
    });
  });
}
