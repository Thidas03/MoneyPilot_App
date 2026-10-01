import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/report_period.dart';

/// Navigation controls for cycling through historical reporting periods.
class ReportPeriodNavigator extends StatelessWidget {
  const ReportPeriodNavigator({
    super.key,
    required this.period,
    required this.referenceDate,
    required this.onPrevious,
    required this.onNext,
  });

  final ReportPeriod period;
  final DateTime referenceDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canNavigateNext = period.canNavigateNext(referenceDate);
    final periodLabel = period.formatPeriodLabel(referenceDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('report_previous_period_button'),
            icon: const Icon(Icons.chevron_left_rounded, size: 26),
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            tooltip: 'Previous ${period.label.toLowerCase()}',
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              periodLabel,
              key: const Key('report_period_label'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
              ),
            ),
          ),
          IconButton(
            key: const Key('report_next_period_button'),
            icon: const Icon(Icons.chevron_right_rounded, size: 26),
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            disabledColor: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            tooltip: 'Next ${period.label.toLowerCase()}',
            onPressed: canNavigateNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}
