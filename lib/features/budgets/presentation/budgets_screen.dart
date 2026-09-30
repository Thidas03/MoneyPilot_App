import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/data/transactions_provider.dart';
import '../../transactions/domain/transaction_model.dart';
import '../data/budgets_provider.dart';
import '../domain/budget_model.dart';

/// Budgets Screen displaying overall monthly target and category budgets with real-time alerts.
/// Allows adding new budgets or tapping an existing budget to edit/delete it.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const brandGreen = Color(0xFF005C46);
    final budgetTarget = ref.watch(monthlyBudgetTargetProvider);
    final totalSpent = ref.watch(totalExpenseProvider);
    final remaining = (budgetTarget - totalSpent).clamp(0.0, budgetTarget);
    final progress = budgetTarget > 0 ? (totalSpent / budgetTarget).clamp(0.0, 1.0) : 0.0;

    // Category budgets backed by Supabase & transactions dynamic spending
    final budgets = ref.watch(budgetsProvider);
    final overBudgetList = ref.watch(overBudgetBudgetsProvider);
    final nearLimitList = ref.watch(nearLimitBudgetsProvider);

    // Compute category expenses from transactions
    final transactions = ref.watch(transactionsProvider);
    final expenseMap = <String, double>{};
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        expenseMap[tx.category] = (expenseMap[tx.category] ?? 0) + tx.amount;
      }
    }

    // Map budgets by category name
    final budgetMap = <String, Budget>{};
    for (final b in budgets) {
      budgetMap[b.category] = b;
    }

    // Merge categories from both budgets and actual expenses, keeping existing budgets first
    final Set<String> categoryOrder = {};
    for (final b in budgets) {
      categoryOrder.add(b.category);
    }
    for (final cat in expenseMap.keys) {
      categoryOrder.add(cat);
    }
    final allCategories = categoryOrder.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Budgets',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              key: const Key('add_budget_appbar_button'),
              onPressed: () => context.push('/budgets/add'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Add Budget',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Monthly Target Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                      const Expanded(
                        child: Text(
                          'Monthly Budget Target',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          context.push(
                            '/budgets/add',
                            extra: {
                              'isOverall': true,
                              'amount': budgetTarget,
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 13,
                                color: brandGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Edit Target',
                                style: TextStyle(
                                  color: brandGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(budgetTarget),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.85 ? const Color(0xFFDC2626) : brandGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Spent: ${CurrencyFormatter.format(totalSpent)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          totalSpent > budgetTarget
                              ? 'Over by: ${CurrencyFormatter.format(totalSpent - budgetTarget)}'
                              : 'Remaining: ${CurrencyFormatter.format(remaining)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: totalSpent > budgetTarget
                                ? const Color(0xFFDC2626)
                                : brandGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // PARTS 11 & 12: ACTIVE CATEGORY-SPECIFIC BUDGET ALERTS
            if (overBudgetList.isNotEmpty || nearLimitList.isNotEmpty) ...[
              const Text(
                'BUDGET ALERTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),

              // Over-Budget Category Alerts
              ...overBudgetList.map(
                (b) => Container(
                  key: Key('alert_over_budget_${b.category.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}'),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: InkWell(
                    onTap: () => context.push(
                      '/budgets/add',
                      extra: {
                        'existingBudget': b,
                        'category': b.category,
                        'amount': b.amount,
                      },
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔴', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You\'ve exceeded your monthly budget by ${CurrencyFormatter.format(b.overBudgetAmount)}.',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Budget: ${CurrencyFormatter.format(b.amount)}  •  Spent: ${CurrencyFormatter.format(b.spent)}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB91C1C), size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Near-Limit Category Alerts (80%+ threshold)
              ...nearLimitList.map(
                (b) => Container(
                  key: Key('alert_near_limit_${b.category.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}'),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: InkWell(
                    onTap: () => context.push(
                      '/budgets/add',
                      extra: {
                        'existingBudget': b,
                        'category': b.category,
                        'amount': b.amount,
                      },
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You\'ve used ${b.usagePercentage.toStringAsFixed(0)}% of your budget.',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${CurrencyFormatter.format(b.remaining)} remaining.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB45309), size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],

            // Category Budgets Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CATEGORY BUDGETS & SPENDING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${allCategories.length} categories',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (allCategories.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 40,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Budgets Set Yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Set category budgets to control your spending limits.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/budgets/add'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Budget'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allCategories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final category = allCategories[index];
                  final budget = budgetMap[category];
                  final spent = budget != null ? budget.spent : (expenseMap[category] ?? 0.0);
                  final budgetLimit = budget?.amount;
                  final hasLimit = budgetLimit != null && budgetLimit > 0;

                  final ratio = hasLimit
                      ? (spent / budgetLimit).clamp(0.0, 1.0)
                      : (totalSpent > 0 ? (spent / totalSpent) : 0.0);

                  final isOverBudget = hasLimit && spent > budgetLimit;
                  final categoryColor = AppCategories.getColor(category);
                  final categoryIcon = AppCategories.getIcon(category);

                  return GestureDetector(
                    key: Key('budget_category_${category.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}'),
                    onTap: () {
                      // If budget exists for this category, pass existingBudget to open Edit mode!
                      context.push(
                        '/budgets/add',
                        extra: {
                          'existingBudget': budget,
                          'category': category,
                          'amount': budgetLimit ?? (spent > 0 ? spent : 15000),
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOverBudget
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  categoryIcon,
                                  size: 18,
                                  color: categoryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            category,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (hasLimit) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.edit_outlined, size: 10, color: Color(0xFF64748B)),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      hasLimit
                                          ? 'Budget limit: ${CurrencyFormatter.format(budgetLimit)}'
                                          : 'No limit set (Tap to set)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: hasLimit
                                            ? const Color(0xFF64748B)
                                            : AppColors.primary,
                                        fontWeight: hasLimit
                                            ? FontWeight.w500
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(spent),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isOverBudget
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Text(
                                    'Spent',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 7,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverBudget
                                    ? const Color(0xFFDC2626)
                                    : ratio > 0.8
                                        ? const Color(0xFFF59E0B)
                                        : brandGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  hasLimit
                                      ? '${(ratio * 100).toStringAsFixed(0)}% used'
                                      : '${(ratio * 100).toStringAsFixed(0)}% of total',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasLimit) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isOverBudget
                                        ? 'Over by ${CurrencyFormatter.format(spent - budgetLimit)}'
                                        : '${CurrencyFormatter.format(budgetLimit - spent)} left',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isOverBudget
                                          ? const Color(0xFFDC2626)
                                          : brandGreen,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
