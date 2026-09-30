import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';
import '../data/goals_provider.dart';
import '../domain/goal_model.dart';

/// Main screen displaying the user's savings milestones and progress.
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  // --- Quick Add Savings Dialog ---
  Future<void> _showAddSavingsDialog(BuildContext context, Goal goal) async {
    final amountController = TextEditingController();
    String? errorText;
    double addedAmount = 0.0;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final newTotal = goal.currentAmount + addedAmount;
            final isNowCompleted = newTotal >= goal.targetAmount;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: goal.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(goal.icon, color: goal.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Savings',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current: ${CurrencyFormatter.format(goal.currentAmount)}  •  Target: ${CurrencyFormatter.format(goal.targetAmount)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('add_savings_amount_field'),
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'ADD SAVINGS AMOUNT',
                        hintText: 'e.g. 25000',
                        prefixIcon: Container(
                          width: 44,
                          alignment: Alignment.center,
                          child: const Text(
                            'Rs.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        errorText: errorText,
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          final parsed = CurrencyFormatter.parse(val);
                          if (parsed == null || parsed <= 0) {
                            addedAmount = 0.0;
                            errorText = 'Enter an amount greater than 0';
                          } else {
                            addedAmount = parsed;
                            errorText = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    if (addedAmount > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'New Total:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(newTotal),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isNowCompleted ? const Color(0xFF005C46) : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  key: const Key('confirm_add_savings_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005C46),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final raw = amountController.text.trim();
                    final parsed = CurrencyFormatter.parse(raw);
                    if (parsed == null || parsed <= 0) {
                      setDialogState(() {
                        errorText = 'Please enter a valid amount';
                      });
                      return;
                    }

                    Navigator.of(dialogCtx).pop();

                    await ref.read(goalsProvider.notifier).addSavings(goal.id, parsed);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added ${CurrencyFormatter.format(parsed)} to "${goal.title}"!',
                          ),
                          backgroundColor: const Color(0xFF005C46),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  child: const Text('Add Savings'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF005C46);
    final allGoals = ref.watch(goalsProvider);
    final activeGoals = allGoals.where((g) => !g.isCompleted).toList();
    final completedGoals = allGoals.where((g) => g.isCompleted).toList();
    final totalTarget = ref.watch(totalGoalsTargetProvider);
    final totalSaved = ref.watch(totalGoalsSavedProvider);
    final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Savings Goals',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              key: const Key('add_goal_button'),
              onPressed: () => context.push('/goals/add'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(goalsProvider.notifier).refresh(),
        color: brandGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Reference Design Header Dream Card
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: brandGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Track Your Financial Dreams',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Automate and monitor your savings milestones.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Aggregate Savings Progress Overview Card
              if (allGoals.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Goals Progress',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Text(
                            '${(overallProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: brandGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 8,
                          backgroundColor: brandGreen.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(brandGreen),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved: ${CurrencyFormatter.format(totalSaved)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Text(
                            'Target: ${CurrencyFormatter.format(totalTarget)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 3. Goals List or Empty State
              if (allGoals.isEmpty)
                _buildEmptyState(context)
              else ...[
                // ACTIVE GOALS SECTION
                if (activeGoals.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACTIVE GOALS (${activeGoals.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...activeGoals.map((goal) => _buildGoalCard(context, goal)),
                ],

                // COMPLETED GOALS SECTION
                if (completedGoals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COMPLETED MILESTONES (${completedGoals.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF005C46),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...completedGoals.map((goal) => _buildGoalCard(context, goal)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Goal Card Component ---
  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final isCompleted = goal.isCompleted;
    final isNear = goal.isNearCompletion;
    final days = goal.daysRemaining;

    String deadlineSubtitle;
    if (isCompleted) {
      deadlineSubtitle = 'Goal Achieved! 🎉';
    } else if (days < 0) {
      deadlineSubtitle = 'Past deadline by ${-days} days';
    } else if (days == 0) {
      deadlineSubtitle = 'Due today!';
    } else if (days <= 30) {
      deadlineSubtitle = '$days days left • ${goal.deadline}';
    } else {
      deadlineSubtitle = 'Deadline: ${goal.deadline}';
    }

    final cardBorderColor = isCompleted
        ? const Color(0xFF10B981).withValues(alpha: 0.4)
        : isNear
            ? const Color(0xFF005C46).withValues(alpha: 0.35)
            : const Color(0xFFE2E8F0);

    return Container(
      key: Key('goal_card_${goal.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: isCompleted || isNear ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Tapping card opens Goal Details
            context.push('/goals/detail?id=${goal.id}', extra: goal.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon, Title, Status / Edit button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: goal.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        goal.icon,
                        color: goal.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.calendar_today_rounded,
                                size: 12,
                                color: isCompleted
                                    ? const Color(0xFF10B981)
                                    : days < 0
                                        ? const Color(0xFFF43F5E)
                                        : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  deadlineSubtitle,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isCompleted || days < 0 ? FontWeight.w600 : FontWeight.w500,
                                    color: isCompleted
                                        ? const Color(0xFF059669)
                                        : days < 0
                                            ? const Color(0xFFF43F5E)
                                            : const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Progress Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFD1FAE5)
                            : isNear
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${goal.percent}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isCompleted
                              ? const Color(0xFF059669)
                              : isNear
                                  ? const Color(0xFF005C46)
                                  : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Amount Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCompleted
                          ? 'Goal Completed'
                          : '${CurrencyFormatter.format(goal.remainingAmount)} remaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500,
                        color: isCompleted ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    backgroundColor: (isCompleted
                            ? const Color(0xFF10B981)
                            : goal.color)
                        .withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? const Color(0xFF10B981)
                          : isNear
                              ? const Color(0xFF059669)
                              : goal.color,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Actions Row: Quick Add Savings & Edit Goal
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isCompleted) ...[
                      OutlinedButton.icon(
                        key: Key('add_savings_btn_${goal.id}'),
                        onPressed: () => _showAddSavingsDialog(context, goal),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Add Savings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF005C46),
                          side: const BorderSide(color: Color(0xFF005C46)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton.icon(
                      key: Key('edit_goal_btn_${goal.id}'),
                      onPressed: () => context.push('/goals/add', extra: goal),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Empty State Component ---
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_outlined,
                size: 44,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No financial goals yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start planning your next financial milestone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('empty_create_goal_button'),
              onPressed: () => context.push('/goals/add'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('+ Create Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005C46),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
