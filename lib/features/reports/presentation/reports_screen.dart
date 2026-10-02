import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_colors.dart';
import '../../budgets/data/budgets_provider.dart';
import '../../transactions/data/transactions_provider.dart';
import '../data/services/report_pdf_service.dart';
import '../domain/models/models.dart';
import 'providers/reports_provider.dart';
import 'widgets/budget_comparison_card.dart';
import 'widgets/cash_flow_bar_chart.dart';
import 'widgets/category_breakdown_card.dart';
import 'widgets/financial_insights_card.dart';
import 'widgets/goals_progress_card.dart';
import 'widgets/period_selector.dart';
import 'widgets/report_empty_state.dart';
import 'widgets/report_period_navigator.dart';
import 'widgets/report_summary_card.dart';
import 'widgets/top_spending_card.dart';

/// Reports & Analytics Screen providing comprehensive visualizations,
/// spending trends, category distributions, budget comparisons, and financial insights.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isExporting = false;

  Future<void> _exportPdf({required bool isPrint}) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Generating report...'),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      final reportData = ref.read(reportsProvider);
      final pdfService = ref.read(reportPdfServiceProvider);
      final dateRangeLabel = _formatDateRange(reportData.period, reportData.dateRange);

      final pdfBytes = await pdfService.generateReportPdf(
        reportData: reportData,
        periodLabel: dateRangeLabel,
      );

      final periodSlug = reportData.period.name;
      final dateSlug = DateFormat('yyyyMMdd').format(reportData.dateRange.start);
      final filename = 'MoneyPilot_${periodSlug}_report_$dateSlug.pdf';

      if (isPrint) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: filename,
        );
      } else {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Unable to generate the report. Please try again.'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showExportOptions(BuildContext context) {
    final reportData = ref.read(reportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateRangeLabel = _formatDateRange(reportData.period, reportData.dateRange);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Financial Report',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          dateRangeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                key: const Key('export_print_save_option'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                leading: const Icon(Icons.print_outlined, color: AppColors.primary),
                title: const Text(
                  'Print / Save as PDF',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Preview report, print, or save to device storage',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _exportPdf(isPrint: true);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                key: const Key('export_share_option'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                leading: const Icon(Icons.share_outlined, color: AppColors.primary),
                title: const Text(
                  'Share PDF Document',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Share via WhatsApp, Gmail, Drive, or messaging apps',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _exportPdf(isPrint: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportData = ref.watch(reportsProvider);
    final selectedPeriod = ref.watch(reportPeriodProvider);
    final referenceDate = ref.watch(reportReferenceDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateRangeLabel = _formatDateRange(reportData.period, reportData.dateRange);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports & Analytics',
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Understand where your money goes',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            )
          else
            IconButton(
              key: const Key('report_export_pdf_button'),
              tooltip: 'Export PDF',
              icon: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              onPressed: () => _showExportOptions(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait<void>([
            ref.read(transactionsProvider.notifier).refresh(),
            ref.read(budgetsProvider.notifier).refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Period Selector (Week, Month, Year)
              PeriodSelector(
                selectedPeriod: selectedPeriod,
                onPeriodChanged: (period) {
                  ref.read(reportPeriodProvider.notifier).setPeriod(period);
                },
              ),
              const SizedBox(height: 12),

              // Period Navigation (< September 2026 >)
              ReportPeriodNavigator(
                period: selectedPeriod,
                referenceDate: referenceDate,
                onPrevious: () {
                  ref.read(reportReferenceDateProvider.notifier).previous(selectedPeriod);
                },
                onNext: () {
                  ref.read(reportReferenceDateProvider.notifier).next(selectedPeriod);
                },
              ),
              const SizedBox(height: 16),

              // 2. Cash Flow Summary Overview Card
              ReportSummaryCard(
                summary: reportData.summary,
                dateRangeLabel: dateRangeLabel,
              ),
              const SizedBox(height: 20),

              // Empty State or Rich Analytics Visualizations
              if (reportData.isEmpty) ...[
                ReportEmptyState(
                  periodLabel: selectedPeriod.label.toLowerCase(),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // 3. Cash Flow Bar Chart (Income vs Expense)
                CashFlowBarChart(
                  trendPoints: reportData.trendPoints,
                  title: 'Cash Flow Trends (${selectedPeriod.label})',
                ),
                const SizedBox(height: 20),

                // 4. Expense Category Breakdown (Donut + Progress Bars)
                const Text(
                  'EXPENSE CATEGORY DISTRIBUTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                CategoryBreakdownCard(
                  categories: reportData.categorySpendings,
                  totalExpenses: reportData.summary.totalExpenses,
                ),
                const SizedBox(height: 20),

                // 5. Top Spending Categories Ranked
                if (reportData.topCategories.isNotEmpty) ...[
                  TopSpendingCard(
                    topCategories: reportData.topCategories,
                  ),
                  const SizedBox(height: 20),
                ],

                // 6. Budget vs Actual Comparison
                BudgetComparisonCard(
                  comparisons: reportData.budgetComparisons,
                ),
                const SizedBox(height: 20),

                // 7. Active Financial Goals Progress
                if (reportData.activeGoals.isNotEmpty) ...[
                  GoalsProgressCard(
                    goals: reportData.activeGoals,
                  ),
                  const SizedBox(height: 20),
                ],

                // 8. Financial Insights
                if (reportData.insights.isNotEmpty) ...[
                  FinancialInsightsCard(
                    insights: reportData.insights,
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(ReportPeriod period, DateTimeRange range) {
    return period.formatPeriodLabel(range.start);
  }
}
