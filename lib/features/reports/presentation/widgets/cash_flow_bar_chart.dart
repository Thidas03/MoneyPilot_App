import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/cash_flow_trend.dart';

/// Interactive BarChart visualizing Income vs Expense cash flow across time intervals.
class CashFlowBarChart extends StatelessWidget {
  const CashFlowBarChart({
    super.key,
    required this.trendPoints,
    required this.title,
  });

  final List<TrendPoint> trendPoints;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const incomeColor = Color(0xFF10B981);
    const expenseColor = Color(0xFFF43F5E);

    final maxVal = trendPoints.fold<double>(
      0.0,
      (max, p) => p.maxVal > max ? p.maxVal : max,
    );
    final safeMaxY = maxVal > 0 ? (maxVal * 1.25) : 1000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Chart Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendIndicator(
                    color: incomeColor,
                    label: 'Income',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _LegendIndicator(
                    color: expenseColor,
                    label: 'Expense',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: trendPoints.isEmpty
                ? Center(
                    child: Text(
                      'No trend data available',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: safeMaxY,
                      minY: 0,
                      barGroups: _buildBarGroups(trendPoints, isDark),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: safeMaxY / 4 > 0 ? safeMaxY / 4 : 250,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: safeMaxY / 4 > 0 ? safeMaxY / 4 : 250,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  CurrencyFormatter.formatCompact(value),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : const Color(0xFF94A3B8),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= trendPoints.length) {
                                return const SizedBox.shrink();
                              }
                              // For year view (12 months), show every other label on small screens
                              if (trendPoints.length > 8 && index % 2 != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  trendPoints[index].label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF1E293B),
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final point = trendPoints[groupIndex];
                            final isIncomeRod = rodIndex == 0;
                            final label = isIncomeRod ? 'Inflow' : 'Outflow';
                            final val = isIncomeRod ? point.income : point.expense;
                            return BarTooltipItem(
                              '${point.label}\n$label: ${CurrencyFormatter.format(val)}',
                              TextStyle(
                                color: isIncomeRod ? incomeColor : expenseColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<TrendPoint> points,
    bool isDark,
  ) {
    const incomeColor = Color(0xFF10B981);
    const expenseColor = Color(0xFFF43F5E);
    final rodWidth = points.length > 8 ? 6.0 : (points.length > 5 ? 8.0 : 12.0);

    return List.generate(points.length, (index) {
      final p = points[index];
      return BarChartGroupData(
        x: index,
        barsSpace: 3,
        barRods: [
          BarChartRodData(
            toY: p.income,
            color: incomeColor,
            width: rodWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
          BarChartRodData(
            toY: p.expense,
            color: expenseColor,
            width: rodWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    });
  }
}

class _LegendIndicator extends StatelessWidget {
  const _LegendIndicator({
    required this.color,
    required this.label,
    required this.isDark,
  });

  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
