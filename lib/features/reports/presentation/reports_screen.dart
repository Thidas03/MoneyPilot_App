import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../budgets/data/budgets_provider.dart';
import '../../transactions/data/transactions_provider.dart';
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
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
