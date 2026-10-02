import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/currency_formatter.dart';
import '../../../goals/domain/goal_model.dart';
import '../../domain/models/budget_comparison.dart';
import '../../domain/models/category_spending.dart';
import '../../domain/models/financial_insight.dart';
import '../../domain/models/report_data.dart';
import '../../domain/models/report_period.dart';
import '../../domain/models/report_summary.dart';

/// Provider exposing the [ReportPdfService] singleton.
final reportPdfServiceProvider = Provider<ReportPdfService>((ref) {
  return const ReportPdfService();
});

/// Dedicated service responsible for generating high-quality, professional
/// financial report PDF documents from existing [ReportData].
class ReportPdfService {
  const ReportPdfService();

  // MoneyPilot Brand Palette
  static final PdfColor _primaryEmerald = PdfColor.fromHex('#005C46');
  static final PdfColor _primaryDark = PdfColor.fromHex('#047857');
  static final PdfColor _primaryContainer = PdfColor.fromHex('#D1FAE5');
  static final PdfColor _incomeGreen = PdfColor.fromHex('#10B981');
  static final PdfColor _expenseRed = PdfColor.fromHex('#DC2626');
  static final PdfColor _warningAmber = PdfColor.fromHex('#F59E0B');
  static final PdfColor _textPrimary = PdfColor.fromHex('#0F172A');
  static final PdfColor _textSecondary = PdfColor.fromHex('#64748B');
  static final PdfColor _textMuted = PdfColor.fromHex('#94A3B8');
  static final PdfColor _bgLight = PdfColor.fromHex('#F8FAFC');
  static final PdfColor _borderLight = PdfColor.fromHex('#E2E8F0');
  static final PdfColor _white = PdfColor.fromHex('#FFFFFF');

  /// Generates the complete PDF document and returns the raw byte stream.
  Future<Uint8List> generateReportPdf({
    required ReportData reportData,
    String? periodLabel,
    DateTime? generatedAt,
  }) async {
    final pdf = pw.Document(
      title: 'MoneyPilot Financial Report',
      author: 'MoneyPilot',
      creator: 'MoneyPilot Personal Finance',
    );

    final genDate = generatedAt ?? DateTime.now();
    final rawPeriodLabel =
        periodLabel ?? reportData.period.formatPeriodLabel(reportData.dateRange.start);
    final effectivePeriodLabel = _cleanText(rawPeriodLabel);

    final periodTitle = _cleanText(_resolvePeriodTitle(reportData.period, effectivePeriodLabel));
    final dateRangeSubtitle =
        _cleanText(_resolveDateRangeSubtitle(reportData.dateRange.start, reportData.dateRange.end));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) => _buildPdfHeader(
          periodTitle: periodTitle,
          dateRangeSubtitle: dateRangeSubtitle,
          generatedAt: genDate,
        ),
        footer: (pw.Context context) => _buildPdfFooter(context),
        build: (pw.Context context) {
          if (reportData.isEmpty) {
            return [
              _buildSummarySection(reportData.summary),
              pw.SizedBox(height: 24),
              _buildEmptyNoticeCard(effectivePeriodLabel),
            ];
          }

          return [
            // 1. Executive Financial Summary
            _buildSummarySection(reportData.summary),
            pw.SizedBox(height: 20),

            // 2. Category Spending Distribution
            _buildCategorySpendingSection(reportData.categorySpendings),
            pw.SizedBox(height: 20),

            // 3. Budget vs Actual Comparison
            _buildBudgetComparisonSection(reportData.budgetComparisons),
            pw.SizedBox(height: 20),

            // 4. Savings Goals Progress
            _buildGoalsProgressSection(reportData.activeGoals),

            // 5. Financial Insights (omitted if empty)
            if (reportData.insights.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildFinancialInsightsSection(reportData.insights),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- Document Header & Footer ---

  pw.Widget _buildPdfHeader({
    required String periodTitle,
    required String dateRangeSubtitle,
    required DateTime generatedAt,
  }) {
    final dateFormatted = DateFormat('MMM d, yyyy - h:mm a').format(generatedAt);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _borderLight, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 26,
                    height: 26,
                    decoration: pw.BoxDecoration(
                      color: _primaryEmerald,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'M',
                      style: pw.TextStyle(
                        color: _white,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'MoneyPilot',
                    style: pw.TextStyle(
                      color: _primaryEmerald,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Personal Finance Report',
                style: pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _primaryContainer,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  periodTitle,
                  style: pw.TextStyle(
                    color: _primaryDark,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                dateRangeSubtitle,
                style: pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 8.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated on: $dateFormatted',
                style: pw.TextStyle(
                  color: _textMuted,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _borderLight, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'MoneyPilot - Personal Finance Report',
            style: pw.TextStyle(color: _textMuted, fontSize: 8),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(color: _textMuted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // --- Executive Financial Summary Cards ---

  pw.Widget _buildSummarySection(ReportSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FINANCIAL SUMMARY'),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildKpiCard(
                label: 'TOTAL INCOME',
                value: CurrencyFormatter.format(summary.totalIncome, forceDecimals: true),
                valueColor: _incomeGreen,
                caption: '${summary.transactionCount} transactions',
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildKpiCard(
                label: 'TOTAL EXPENSES',
                value: CurrencyFormatter.format(summary.totalExpenses, forceDecimals: true),
                valueColor: _expenseRed,
                caption: 'Avg ${CurrencyFormatter.format(summary.averageDailyExpense, forceDecimals: true)} / day',
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildKpiCard(
                label: 'NET BALANCE',
                value: CurrencyFormatter.format(summary.balance, forceDecimals: true),
                valueColor: summary.balance >= 0 ? _incomeGreen : _expenseRed,
                caption: summary.balance >= 0 ? 'Net Surplus' : 'Net Deficit',
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildKpiCard(
                label: 'SAVINGS RATE',
                value: '${summary.savingsRate.toStringAsFixed(1)}%',
                valueColor: summary.savingsRate >= 20
                    ? _primaryEmerald
                    : summary.savingsRate > 0
                        ? _warningAmber
                        : _expenseRed,
                caption: summary.savingsRate >= 20 ? 'Target Achieved' : 'Below 20% Target',
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildKpiCard({
    required String label,
    required String value,
    required PdfColor valueColor,
    required String caption,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderLight, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: _textSecondary,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: valueColor,
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            caption,
            style: pw.TextStyle(
              color: _textMuted,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // --- Category Spending Breakdown Section ---

  pw.Widget _buildCategorySpendingSection(List<CategorySpending> spendings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CATEGORY SPENDING ANALYSIS'),
        pw.SizedBox(height: 8),
        if (spendings.isEmpty)
          _buildEmptyPlaceholder('No category spending recorded for this period.')
        else
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderLight, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(3),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: _bgLight,
                    borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
                  ),
                  children: [
                    _buildTableHeaderCell('Category'),
                    _buildTableHeaderCell('Amount', align: pw.TextAlign.right),
                    _buildTableHeaderCell('Share', align: pw.TextAlign.right),
                    _buildTableHeaderCell('Proportion', align: pw.TextAlign.center),
                  ],
                ),
                // Table Data Rows
                for (int i = 0; i < spendings.length; i++)
                  _buildCategorySpendingRow(
                    spending: spendings[i],
                    isLast: i == spendings.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildCategorySpendingRow({
    required CategorySpending spending,
    required bool isLast,
  }) {
    final pdfCategoryColor = _pdfColorFromFlutterColor(spending.color);

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        border: isLast
            ? null
            : pw.Border(bottom: pw.BorderSide(color: _borderLight, width: 0.5)),
      ),
      children: [
        // Category Name with color indicator
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Row(
            children: [
              pw.Container(
                width: 7,
                height: 7,
                decoration: pw.BoxDecoration(
                  color: pdfCategoryColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Text(
                  _cleanText(spending.category),
                  style: pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Amount
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            CurrencyFormatter.format(spending.amount, forceDecimals: true),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        // Percentage
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            '${spending.percentage.toStringAsFixed(1)}%',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: _textSecondary,
              fontSize: 8.5,
            ),
          ),
        ),
        // Visual Bar
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: _buildProgressBar(
            ratio: spending.ratio,
            color: pdfCategoryColor,
          ),
        ),
      ],
    );
  }

  // --- Budget vs Actual Comparison Section ---

  pw.Widget _buildBudgetComparisonSection(List<BudgetComparison> budgets) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BUDGET COMPARISON'),
        pw.SizedBox(height: 8),
        if (budgets.isEmpty)
          _buildEmptyPlaceholder('No budget data available for this period.')
        else
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderLight, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(3.5),
                1: pw.FlexColumnWidth(2.5),
                2: pw.FlexColumnWidth(2.5),
                3: pw.FlexColumnWidth(2.5),
                4: pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: _bgLight,
                    borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
                  ),
                  children: [
                    _buildTableHeaderCell('Category'),
                    _buildTableHeaderCell('Budget', align: pw.TextAlign.right),
                    _buildTableHeaderCell('Spent', align: pw.TextAlign.right),
                    _buildTableHeaderCell('Remaining', align: pw.TextAlign.right),
                    _buildTableHeaderCell('Status', align: pw.TextAlign.center),
                  ],
                ),
                for (int i = 0; i < budgets.length; i++)
                  _buildBudgetRow(
                    budget: budgets[i],
                    isLast: i == budgets.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildBudgetRow({
    required BudgetComparison budget,
    required bool isLast,
  }) {
    final statusText = budget.isOverBudget
        ? 'Over Budget'
        : budget.isNearLimit
            ? 'Near Limit'
            : 'Within Budget';

    final statusBg = budget.isOverBudget
        ? PdfColor.fromHex('#FEE2E2')
        : budget.isNearLimit
            ? PdfColor.fromHex('#FEF3C7')
            : _primaryContainer;

    final statusTextColor = budget.isOverBudget
        ? _expenseRed
        : budget.isNearLimit
            ? _warningAmber
            : _primaryDark;

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        border: isLast
            ? null
            : pw.Border(bottom: pw.BorderSide(color: _borderLight, width: 0.5)),
      ),
      children: [
        // Category
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            _cleanText(budget.category),
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        // Budget
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            CurrencyFormatter.format(budget.budgetAmount, forceDecimals: true),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: _textSecondary,
              fontSize: 8.5,
            ),
          ),
        ),
        // Spent
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            CurrencyFormatter.format(budget.actualSpent, forceDecimals: true),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: budget.isOverBudget ? _expenseRed : _textPrimary,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        // Remaining
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            CurrencyFormatter.format(budget.remaining, forceDecimals: true),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: budget.isOverBudget ? _textMuted : _incomeGreen,
              fontSize: 8.5,
            ),
          ),
        ),
        // Status Badge
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: pw.BoxDecoration(
              color: statusBg,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              statusText,
              style: pw.TextStyle(
                color: statusTextColor,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Savings Goals Progress Section ---

  pw.Widget _buildGoalsProgressSection(List<Goal> goals) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SAVINGS GOALS PROGRESS'),
        pw.SizedBox(height: 8),
        if (goals.isEmpty)
          _buildEmptyPlaceholder('No savings goals available for this period.')
        else
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderLight, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(3.5),
                1: pw.FlexColumnWidth(2.5),
                2: pw.FlexColumnWidth(2.5),
                3: pw.FlexColumnWidth(2.5),
                4: pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: _bgLight,
                    borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
                  ),
                  children: [
                    _buildTableHeaderCell('Goal Name'),
                    _buildTableHeaderCell('Target Amount', align: pw.TextAlign.right),
                    _buildTableHeaderCell('Current Amount', align: pw.TextAlign.right),
                    _buildTableHeaderCell('Remaining', align: pw.TextAlign.right),
                    _buildTableHeaderCell('Progress', align: pw.TextAlign.center),
                  ],
                ),
                for (int i = 0; i < goals.length; i++)
                  _buildGoalRow(
                    goal: goals[i],
                    isLast: i == goals.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildGoalRow({
    required Goal goal,
    required bool isLast,
  }) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        border: isLast
            ? null
            : pw.Border(bottom: pw.BorderSide(color: _borderLight, width: 0.5)),
      ),
      children: [
        // Name
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            _cleanText(goal.title),
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        // Target
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            CurrencyFormatter.format(goal.targetAmount, forceDecimals: true),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: _textSecondary,
              fontSize: 8.5,
            ),
          ),
        ),
        // Current
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            CurrencyFormatter.format(goal.currentAmount, forceDecimals: true),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: _primaryEmerald,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        // Remaining
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            CurrencyFormatter.format(goal.remainingAmount, forceDecimals: true),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: _textMuted,
              fontSize: 8.5,
            ),
          ),
        ),
        // Progress %
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 38,
                child: _buildProgressBar(
                  ratio: goal.progressRatio,
                  color: _primaryEmerald,
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                '${goal.percent}%',
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Financial Insights Section ---

  pw.Widget _buildFinancialInsightsSection(List<FinancialInsight> insights) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FINANCIAL INSIGHTS'),
        pw.SizedBox(height: 8),
        for (final insight in insights) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.all(9),
            decoration: pw.BoxDecoration(
              color: _bgLight,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _borderLight, width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 5,
                  height: 5,
                  margin: const pw.EdgeInsets.only(top: 4, right: 8),
                  decoration: pw.BoxDecoration(
                    color: _primaryEmerald,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _cleanText(insight.title),
                        style: pw.TextStyle(
                          color: _textPrimary,
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _cleanText(insight.message),
                        style: pw.TextStyle(
                          color: _textSecondary,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Empty Report Notice Card ---

  pw.Widget _buildEmptyNoticeCard(String periodLabel) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _borderLight, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'No Financial Data Available',
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'There are no recorded transactions or spending activities for $periodLabel.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: _textSecondary,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  pw.Widget _buildSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _textSecondary,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.6,
      ),
    );
  }

  pw.Widget _buildTableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: _textSecondary,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildEmptyPlaceholder(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _borderLight, width: 0.8),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(
          color: _textSecondary,
          fontSize: 8.5,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  pw.Widget _buildProgressBar({
    required double ratio,
    required PdfColor color,
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    return pw.Container(
      height: 5,
      decoration: pw.BoxDecoration(
        color: _borderLight,
        borderRadius: pw.BorderRadius.circular(2.5),
      ),
      child: pw.Row(
        children: [
          if (clamped > 0)
            pw.Expanded(
              flex: (clamped * 100).round(),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(2.5),
                ),
              ),
            ),
          if (clamped < 1.0)
            pw.Expanded(
              flex: ((1.0 - clamped) * 100).round(),
              child: pw.Container(),
            ),
        ],
      ),
    );
  }

  static String _resolvePeriodTitle(ReportPeriod period, String label) {
    switch (period) {
      case ReportPeriod.week:
        return 'Weekly Report - $label';
      case ReportPeriod.month:
        return 'Monthly Report - $label';
      case ReportPeriod.year:
        return 'Annual Report - $label';
    }
  }

  static String _resolveDateRangeSubtitle(DateTime start, DateTime end) {
    final fmt = DateFormat('MMM d, yyyy');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  static PdfColor _pdfColorFromFlutterColor(Color color) {
    return PdfColor(
      color.r,
      color.g,
      color.b,
      color.a,
    );
  }

  static String _cleanText(String input) {
    final sanitized = input
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', ' - ')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2022', '-')
        .replaceAll('\u2026', '...')
        .replaceAll('\u00A0', ' ');

    final buffer = StringBuffer();
    for (final rune in sanitized.runes) {
      if (rune <= 255) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
