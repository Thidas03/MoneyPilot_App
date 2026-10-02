import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/app.dart';
import 'package:moneypilot/features/reports/domain/models/report_period.dart';
import 'package:moneypilot/features/reports/presentation/widgets/cash_flow_bar_chart.dart';
import 'package:moneypilot/features/reports/presentation/widgets/category_breakdown_card.dart';
import 'package:moneypilot/features/reports/presentation/widgets/period_selector.dart';
import 'package:moneypilot/features/reports/presentation/widgets/report_empty_state.dart';
import 'package:moneypilot/features/reports/presentation/widgets/report_period_navigator.dart';
import 'package:moneypilot/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:moneypilot/features/transactions/data/transactions_provider.dart';
import 'package:moneypilot/features/transactions/domain/transaction_model.dart';
import 'package:moneypilot/features/transactions/presentation/add_transaction_screen.dart';

class _EmptyTransactionsNotifier extends TransactionsNotifier {
  @override
  List<Transaction> build() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loadReportsTab(WidgetTester tester, {bool emptyTransactions = false}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    FlutterSecureStorage.setMockInitialValues({
      'moneypilot_has_seen_onboarding': 'true',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: emptyTransactions
            ? [transactionsProvider.overrideWith(() => _EmptyTransactionsNotifier())]
            : const [],
        child: const MoneyPilotApp(),
      ),
    );

    // Advance splash delay
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // Log in
    await tester.enterText(find.byType(TextFormField).at(0), 'pilot@moneypilot.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    // Switch to Reports tab via bottom nav
    await tester.tap(find.widgetWithText(AnimatedContainer, 'Reports'));
    await tester.pumpAndSettle();
  }

  group('Reports Screen Widget Tests', () {
    testWidgets('Renders Reports header, period selector, and cash flow cards', (WidgetTester tester) async {
      await loadReportsTab(tester);

      expect(find.text('Reports & Analytics'), findsOneWidget);
      expect(find.text('Understand where your money goes'), findsOneWidget);
      expect(find.byType(PeriodSelector), findsOneWidget);
      expect(find.byType(ReportSummaryCard), findsOneWidget);
      expect(find.text('Cash Flow Overview'), findsOneWidget);
      expect(find.text('Total Inflow'), findsWidgets);
      expect(find.text('Total Outflow'), findsWidgets);
      expect(find.text('Net Balance'), findsWidgets);
    });

    testWidgets('Period selector switches between Week, Month, and Year tabs', (WidgetTester tester) async {
      await loadReportsTab(tester);

      expect(find.byKey(const Key('period_tab_week')), findsOneWidget);
      expect(find.byKey(const Key('period_tab_month')), findsOneWidget);
      expect(find.byKey(const Key('period_tab_year')), findsOneWidget);

      // Tap Week tab
      await tester.tap(find.byKey(const Key('period_tab_week')));
      await tester.pumpAndSettle();
      expect(find.text('Reports & Analytics'), findsOneWidget);

      // Tap Year tab
      await tester.tap(find.byKey(const Key('period_tab_year')));
      await tester.pumpAndSettle();
      expect(find.text('Reports & Analytics'), findsOneWidget);

      // Tap Month tab
      await tester.tap(find.byKey(const Key('period_tab_month')));
      await tester.pumpAndSettle();
      expect(find.text('Reports & Analytics'), findsOneWidget);
    });

    testWidgets('Renders charts, breakdowns, and budgets sections when data exists', (WidgetTester tester) async {
      await loadReportsTab(tester);

      // Cash flow chart
      expect(find.byType(CashFlowBarChart), findsOneWidget);

      // Category breakdown
      expect(find.byType(CategoryBreakdownCard), findsOneWidget);
      expect(find.text('Category Proportions'), findsOneWidget);

      // Scroll down to see other sections
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Top spending & Budget vs actual
      expect(find.text('Top Spending Categories'), findsOneWidget);
      expect(find.text('Budget vs Actual Spending'), findsOneWidget);

      // Scroll further
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Savings Goals & Financial Insights
      expect(find.text('Financial Goals Progress'), findsOneWidget);
      expect(find.text('Financial Insights'), findsOneWidget);
    });

    testWidgets('Budget comparison card navigates to Budgets screen', (WidgetTester tester) async {
      await loadReportsTab(tester);

      // Scroll down to Budget vs Actual section
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(find.text('Budget vs Actual Spending'), findsOneWidget);
      final viewBudgetsBtn = find.widgetWithText(InkWell, 'View All').first;
      await tester.tap(viewBudgetsBtn);
      await tester.pumpAndSettle();

      // Should be on Budgets screen
      expect(find.text('Monthly Budget Target'), findsOneWidget);
    });

    testWidgets('Goals progress card navigates to Goals screen', (WidgetTester tester) async {
      await loadReportsTab(tester);

      // Scroll down to Goals section
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(find.text('Financial Goals Progress'), findsOneWidget);
      final viewGoalsBtn = find.widgetWithText(InkWell, 'View All').last;
      await tester.tap(viewGoalsBtn);
      await tester.pumpAndSettle();

      // Should be on Goals screen
      expect(find.text('Track Your Financial Dreams'), findsOneWidget);
    });

    testWidgets('Displays ReportEmptyState when no transactions exist and navigates to Add Transaction', (WidgetTester tester) async {
      await loadReportsTab(tester, emptyTransactions: true);

      expect(find.byType(ReportEmptyState), findsOneWidget);
      expect(find.text('No report data yet'), findsOneWidget);

      final addBtn = find.widgetWithText(ElevatedButton, 'Add Transaction');
      expect(addBtn, findsOneWidget);

      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Should navigate to Add Transaction screen
      expect(find.byType(AddTransactionScreen), findsOneWidget);
    });

    testWidgets('ReportPeriodNavigator renders with navigation buttons and label', (WidgetTester tester) async {
      await loadReportsTab(tester);

      expect(find.byType(ReportPeriodNavigator), findsOneWidget);
      expect(find.byKey(const Key('report_previous_period_button')), findsOneWidget);
      expect(find.byKey(const Key('report_period_label')), findsOneWidget);
      expect(find.byKey(const Key('report_next_period_button')), findsOneWidget);

      // On initial load (Month), Next button is disabled because it is the current period
      final nextButton = tester.widget<IconButton>(find.byKey(const Key('report_next_period_button')));
      expect(nextButton.onPressed, isNull);

      final currentLabel = ReportPeriod.month.formatPeriodLabel(DateTime.now());
      expect(find.text(currentLabel), findsWidgets);
    });

    testWidgets('Historical navigation: previous moves back, enables next button, and next returns to current', (WidgetTester tester) async {
      await loadReportsTab(tester);

      final currentMonthLabel = ReportPeriod.month.formatPeriodLabel(DateTime.now());
      final prevMonthDate = ReportPeriod.month.previousDate(DateTime.now());
      final prevMonthLabel = ReportPeriod.month.formatPeriodLabel(prevMonthDate);

      // Tap Previous button
      await tester.tap(find.byKey(const Key('report_previous_period_button')));
      await tester.pumpAndSettle();

      // Label should update to previous month
      expect(find.text(prevMonthLabel), findsWidgets);

      // Next button should now be enabled
      final enabledNextButton = tester.widget<IconButton>(find.byKey(const Key('report_next_period_button')));
      expect(enabledNextButton.onPressed, isNotNull);

      // Tap Next button to return toward current month
      await tester.tap(find.byKey(const Key('report_next_period_button')));
      await tester.pumpAndSettle();

      // Label should be current month again and Next button should be disabled
      expect(find.text(currentMonthLabel), findsWidgets);
      final disabledNextAgain = tester.widget<IconButton>(find.byKey(const Key('report_next_period_button')));
      expect(disabledNextAgain.onPressed, isNull);
    });

    testWidgets('Switching period type resets historical reference date to current period', (WidgetTester tester) async {
      await loadReportsTab(tester);

      // Navigate back in Month
      await tester.tap(find.byKey(const Key('report_previous_period_button')));
      await tester.pumpAndSettle();

      // Switch to Week tab
      await tester.tap(find.byKey(const Key('period_tab_week')));
      await tester.pumpAndSettle();

      // Label must be the current week, not a historical week
      final currentWeekLabel = ReportPeriod.week.formatPeriodLabel(DateTime.now());
      expect(find.text(currentWeekLabel), findsWidgets);

      // Next button must be disabled for current week
      final nextWeekBtn = tester.widget<IconButton>(find.byKey(const Key('report_next_period_button')));
      expect(nextWeekBtn.onPressed, isNull);

      // Navigate back in Week
      await tester.tap(find.byKey(const Key('report_previous_period_button')));
      await tester.pumpAndSettle();

      // Switch to Year tab
      await tester.tap(find.byKey(const Key('period_tab_year')));
      await tester.pumpAndSettle();

      // Label must be the current year
      final currentYearLabel = ReportPeriod.year.formatPeriodLabel(DateTime.now());
      expect(find.text(currentYearLabel), findsWidgets);
    });

    testWidgets('Export PDF button renders in AppBar and opens Export Options bottom sheet', (WidgetTester tester) async {
      await loadReportsTab(tester);

      final exportButton = find.byKey(const Key('report_export_pdf_button'));
      expect(exportButton, findsOneWidget);

      // Tap Export PDF button
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      // Modal bottom sheet should be presented
      expect(find.text('Export Financial Report'), findsOneWidget);
      expect(find.byKey(const Key('export_print_save_option')), findsOneWidget);
      expect(find.text('Print / Save as PDF'), findsOneWidget);
      expect(find.byKey(const Key('export_share_option')), findsOneWidget);
      expect(find.text('Share PDF Document'), findsOneWidget);

      // Dismiss bottom sheet by tapping barrier
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Export Financial Report'), findsNothing);
    });
  });
}

