import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/features/goals/domain/goal_model.dart';
import 'package:moneypilot/features/reports/data/services/report_pdf_service.dart';
import 'package:moneypilot/features/reports/domain/models/models.dart';
import 'package:moneypilot/features/transactions/domain/transaction_model.dart';

void main() {
  const service = ReportPdfService();

  group('ReportPdfService Unit Tests', () {
    test('1. PDF generation succeeds with valid ReportData and returns non-empty bytes', () async {
      final reportData = ReportData(
        period: ReportPeriod.month,
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30, 23, 59, 59),
        ),
        summary: const ReportSummary(
          totalIncome: 150000.0,
          totalExpenses: 75000.0,
          balance: 75000.0,
          transactionCount: 12,
          averageDailyExpense: 2500.0,
        ),
        categorySpendings: const [
          CategorySpending(
            category: 'Groceries',
            amount: 40000.0,
            percentage: 53.3,
            transactionCount: 6,
            color: Color(0xFF10B981),
            icon: Icons.shopping_basket,
          ),
          CategorySpending(
            category: 'Transport',
            amount: 35000.0,
            percentage: 46.7,
            transactionCount: 6,
            color: Color(0xFF3B82F6),
            icon: Icons.directions_car,
          ),
        ],
        trendPoints: const [],
        budgetComparisons: const [
          BudgetComparison(
            budgetId: 'b1',
            category: 'Groceries',
            budgetAmount: 50000.0,
            actualSpent: 40000.0,
            color: Color(0xFF10B981),
            icon: Icons.shopping_basket,
          ),
        ],
        activeGoals: [
          Goal(
            id: 'g1',
            title: 'Emergency Fund',
            targetAmount: 200000.0,
            currentAmount: 120000.0,
            deadlineDate: DateTime(2027, 12, 31),
          ),
        ],
        insights: const [
          FinancialInsight(
            title: 'Savings On Track',
            message: 'You saved 50% of your income this month.',
            icon: Icons.savings,
            iconColor: Color(0xFF10B981),
            backgroundColor: Color(0xFFD1FAE5),
          ),
        ],
        periodTransactions: [
          Transaction(
            id: 't1',
            title: 'Monthly Salary',
            amount: 150000.0,
            type: TransactionType.income,
            category: 'Salary',
            date: DateTime(2026, 9, 5),
          ),
          Transaction(
            id: 't2',
            title: 'Weekly Groceries',
            amount: 75000.0,
            type: TransactionType.expense,
            category: 'Groceries',
            date: DateTime(2026, 9, 10),
          ),
        ],
      );

      final bytes = await service.generateReportPdf(
        reportData: reportData,
        periodLabel: 'September 2026',
        generatedAt: DateTime(2026, 9, 30, 18, 30),
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      // PDF documents start with '%PDF-' header bytes: 0x25, 0x50, 0x44, 0x46, 0x2D
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('2. PDF generation succeeds across all periods: Week, Month, Year', () async {
      for (final period in ReportPeriod.values) {
        final range = period.getDateRange(DateTime(2026, 9, 15));
        final reportData = ReportData(
          period: period,
          dateRange: range,
          summary: const ReportSummary(
            totalIncome: 100000.0,
            totalExpenses: 50000.0,
            balance: 50000.0,
            transactionCount: 4,
            averageDailyExpense: 1500.0,
          ),
          categorySpendings: const [],
          trendPoints: const [],
          budgetComparisons: const [],
          activeGoals: const [],
          insights: const [],
          periodTransactions: [
            Transaction(
              id: 't1',
              title: 'General Expense',
              amount: 50000.0,
              type: TransactionType.expense,
              category: 'General',
              date: range.start,
            ),
          ],
        );

        final bytes = await service.generateReportPdf(
          reportData: reportData,
          periodLabel: period.formatPeriodLabel(range.start),
        );

        expect(bytes.isNotEmpty, isTrue);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      }
    });

    test('3. Empty data is handled safely without crashing and produces a valid PDF', () async {
      final emptyReport = ReportData.empty(period: ReportPeriod.month);

      final bytes = await service.generateReportPdf(
        reportData: emptyReport,
        periodLabel: 'September 2026',
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('4. Missing optional sections (no budgets, no goals, no insights) do not crash generation', () async {
      final minimalReport = ReportData(
        period: ReportPeriod.month,
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
        summary: const ReportSummary(
          totalIncome: 50000.0,
          totalExpenses: 20000.0,
          balance: 30000.0,
          transactionCount: 2,
          averageDailyExpense: 666.6,
        ),
        categorySpendings: const [
          CategorySpending(
            category: 'Food',
            amount: 20000.0,
            percentage: 100.0,
            transactionCount: 2,
            color: Color(0xFFF59E0B),
            icon: Icons.fastfood,
          ),
        ],
        trendPoints: const [],
        budgetComparisons: const [], // Empty budgets
        activeGoals: const [], // Empty goals
        insights: const [], // Empty insights
        periodTransactions: [
          Transaction(
            id: 't1',
            title: 'Food Purchase',
            amount: 20000.0,
            type: TransactionType.expense,
            category: 'Food',
            date: DateTime(2026, 9, 12),
          ),
        ],
      );

      final bytes = await service.generateReportPdf(
        reportData: minimalReport,
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('5. Budget statuses (Over Budget, Near Limit, Within Budget) are handled correctly', () async {
      final budgetReport = ReportData(
        period: ReportPeriod.month,
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
        summary: const ReportSummary(
          totalIncome: 100000.0,
          totalExpenses: 95000.0,
          balance: 5000.0,
          transactionCount: 5,
          averageDailyExpense: 3166.6,
        ),
        categorySpendings: const [],
        trendPoints: const [],
        budgetComparisons: const [
          // Over budget
          BudgetComparison(
            budgetId: 'b1',
            category: 'Dining',
            budgetAmount: 20000.0,
            actualSpent: 25000.0,
            color: Color(0xFFEF4444),
            icon: Icons.restaurant,
          ),
          // Near limit (85% usage)
          BudgetComparison(
            budgetId: 'b2',
            category: 'Shopping',
            budgetAmount: 20000.0,
            actualSpent: 17000.0,
            color: Color(0xFFF59E0B),
            icon: Icons.shopping_bag,
          ),
          // Within budget (50% usage)
          BudgetComparison(
            budgetId: 'b3',
            category: 'Utilities',
            budgetAmount: 30000.0,
            actualSpent: 15000.0,
            color: Color(0xFF10B981),
            icon: Icons.bolt,
          ),
        ],
        activeGoals: const [],
        insights: const [],
        periodTransactions: [
          Transaction(
            id: 't1',
            title: 'Various Expenses',
            amount: 57000.0,
            type: TransactionType.expense,
            category: 'Expenses',
            date: DateTime(2026, 9, 10),
          ),
        ],
      );

      final bytes = await service.generateReportPdf(
        reportData: budgetReport,
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('6. Savings goals progress is generated cleanly with target, current and percent values', () async {
      final goalReport = ReportData(
        period: ReportPeriod.month,
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
        summary: const ReportSummary(
          totalIncome: 80000.0,
          totalExpenses: 40000.0,
          balance: 40000.0,
          transactionCount: 3,
          averageDailyExpense: 1333.3,
        ),
        categorySpendings: const [],
        trendPoints: const [],
        budgetComparisons: const [],
        activeGoals: [
          Goal(
            id: 'g1',
            title: 'New Laptop',
            targetAmount: 350000.0,
            currentAmount: 175000.0,
            deadlineDate: DateTime(2027, 6, 30),
          ),
          Goal(
            id: 'g2',
            title: 'Vacation Fund',
            targetAmount: 100000.0,
            currentAmount: 10000.0,
            deadlineDate: DateTime(2026, 12, 31),
          ),
        ],
        insights: const [],
        periodTransactions: [],
      );

      final bytes = await service.generateReportPdf(
        reportData: goalReport,
        periodLabel: 'September 2026',
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('7. Special characters, quotes, em-dashes, and unicode symbols are sanitized without crashing', () async {
      final unicodeReport = ReportData(
        period: ReportPeriod.month,
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
        summary: const ReportSummary(
          totalIncome: 120000.0,
          totalExpenses: 60000.0,
          balance: 60000.0,
          transactionCount: 4,
          averageDailyExpense: 2000.0,
        ),
        categorySpendings: const [
          CategorySpending(
            category: '“Groceries” & Café—Special',
            amount: 30000.0,
            percentage: 50.0,
            transactionCount: 2,
            color: Color(0xFF10B981),
            icon: Icons.shopping_basket,
          ),
        ],
        trendPoints: const [],
        budgetComparisons: const [
          BudgetComparison(
            budgetId: 'b1',
            category: 'Dining • Out & ‘Takeaway’',
            budgetAmount: 40000.0,
            actualSpent: 30000.0,
            color: Color(0xFFF59E0B),
            icon: Icons.restaurant,
          ),
        ],
        activeGoals: [
          Goal(
            id: 'g1',
            title: 'Dream House 🏡 & Car 🚗',
            targetAmount: 500000.0,
            currentAmount: 250000.0,
            deadlineDate: DateTime(2028, 1, 1),
          ),
        ],
        insights: const [
          FinancialInsight(
            title: 'Insight • Summary — "Great job!"',
            message: 'You’re saving 50%… Keep it up!',
            icon: Icons.check,
            iconColor: Color(0xFF10B981),
            backgroundColor: Color(0xFFD1FAE5),
          ),
        ],
        periodTransactions: [],
      );

      final bytes = await service.generateReportPdf(
        reportData: unicodeReport,
        periodLabel: 'September 2026 — Monthly Report',
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
