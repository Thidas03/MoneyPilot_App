import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/custom_button.dart';
import '../data/goals_provider.dart';
import '../domain/goal_contribution_model.dart';
import '../domain/goal_model.dart';

/// Dedicated read and management detail screen for a specific savings goal.
class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
  });

  /// The unique identifier of the target goal.
  final String goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  // --- Delete Goal Confirmation Flow ---
  Future<void> _showDeleteGoalDialog(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Goal?',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? All associated contribution records will also be removed.',
          style: const TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_goal_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal "${goal.title}" was removed'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  // --- Delete Contribution Confirmation Flow ---
  Future<void> _showDeleteContributionDialog(
    GoalContribution contribution,
    Goal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete this contribution?',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        content: Text(
          'Remove contribution of ${CurrencyFormatter.format(contribution.amount)} from ${contribution.formattedDate}?',
          style: const TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_contribution_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      await ref.read(goalsProvider.notifier).deleteContribution(
            goalId: goal.id,
            contributionId: contribution.id,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removed contribution of ${CurrencyFormatter.format(contribution.amount)}',
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // --- Add Contribution Dialog / BottomSheet ---
  Future<void> _showAddContributionSheet(Goal goal) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: goal.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(goal.icon, color: goal.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add Contribution',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                goal.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount Input Field
                    const Text(
                      'CONTRIBUTION AMOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('contribution_amount_field'),
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: const Text(
                            'Rs.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF005C46),
                            ),
                          ),
                        ),
                        errorText: errorText,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF005C46), width: 1.8),
                        ),
                      ),
                      onChanged: (val) {
                        if (errorText != null) {
                          setSheetState(() => errorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Row
                    const Text(
                      'CONTRIBUTION DATE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      key: const Key('contribution_date_picker'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: Color(0xFF005C46),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${selectedDate.day} / ${selectedDate.month} / ${selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF005C46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Optional Note Field
                    const Text(
                      'NOTE (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('contribution_note_field'),
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Monthly salary savings',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF005C46), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    CustomButton(
                      key: const Key('save_contribution_button'),
                      text: 'Save Contribution',
                      backgroundColor: const Color(0xFF005C46),
                      onPressed: () async {
                        final raw = amountController.text.trim();
                        final parsed = CurrencyFormatter.parse(raw);
                        if (parsed == null || parsed <= 0) {
                          setSheetState(() {
                            errorText = 'Enter an amount greater than 0';
                          });
                          return;
                        }

                        Navigator.of(sheetCtx).pop();

                        final isNewlyCompleted = await ref
                            .read(goalsProvider.notifier)
                            .addContribution(
                              goalId: goal.id,
                              amount: parsed,
                              date: selectedDate,
                              note: noteController.text.trim().isNotEmpty
                                  ? noteController.text.trim()
                                  : null,
                            );

                        if (!mounted) return;
                        if (isNewlyCompleted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Text('🎉 ', style: TextStyle(fontSize: 18)),
                                  Expanded(
                                    child: Text(
                                      'Goal Achieved! You reached your savings target for "${goal.title}"!',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF059669),
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Saved ${CurrencyFormatter.format(parsed)} to "${goal.title}"!',
                              ),
                              backgroundColor: const Color(0xFF005C46),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF005C46);
    final goal = ref.watch(singleGoalProvider(widget.goalId));
    final contributionsAsync = ref.watch(goalContributionsProvider(widget.goalId));

    if (goal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Goal Details'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_outlined, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              const Text(
                'Goal not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This savings goal may have been deleted.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Goals'),
              ),
            ],
          ),
        ),
      );
    }

    final isCompleted = goal.isCompleted;
    final isNear = goal.isNearCompletion;
    final days = goal.daysRemaining;

    String deadlineText;
    if (isCompleted) {
      deadlineText = 'Target Achieved!';
    } else if (days < 0) {
      deadlineText = 'Past deadline by ${-days} days';
    } else if (days == 0) {
      deadlineText = 'Due today!';
    } else if (days <= 30) {
      deadlineText = '$days days left';
    } else {
      deadlineText = '$days days remaining';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Goal Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            key: const Key('edit_goal_action_button'),
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569)),
            tooltip: 'Edit Goal',
            onPressed: () => context.push('/goals/add', extra: goal),
          ),
          IconButton(
            key: const Key('delete_goal_action_button'),
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Delete Goal',
            onPressed: () => _showDeleteGoalDialog(goal),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(goalsProvider.notifier).refresh();
          ref.invalidate(goalContributionsProvider(goal.id));
        },
        color: brandGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HERO GOAL SUMMARY CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : const Color(0xFFE2E8F0),
                    width: isCompleted ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Title + Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: goal.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(goal.icon, color: goal.color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (goal.note != null && goal.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  goal.note!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Badge
                        _buildStatusBadge(isCompleted, isNear),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount Highlights
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CURRENT SAVED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(goal.currentAmount),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF005C46),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TARGET GOAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(goal.targetAmount),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Progress Bar & Percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${goal.percent}% Saved',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isCompleted ? const Color(0xFF059669) : brandGreen,
                          ),
                        ),
                        Text(
                          isCompleted
                              ? 'Goal Achieved! 🎉'
                              : '${CurrencyFormatter.format(goal.remainingAmount)} remaining',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? const Color(0xFF059669) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 10,
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
                    const SizedBox(height: 16),

                    // Deadline Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : days < 0
                                    ? const Color(0xFFF43F5E)
                                    : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target Date: ${goal.deadline}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            deadlineText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? const Color(0xFF059669)
                                  : days < 0
                                      ? const Color(0xFFF43F5E)
                                      : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. PRIMARY ACTION: ADD CONTRIBUTION
              CustomButton(
                key: const Key('add_contribution_button'),
                text: '+ Add Contribution',
                backgroundColor: brandGreen,
                onPressed: () => _showAddContributionSheet(goal),
              ),
              const SizedBox(height: 28),

              // 3. CONTRIBUTION HISTORY SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CONTRIBUTION HISTORY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF475569),
                    ),
                  ),
                  contributionsAsync.maybeWhen(
                    data: (list) => Text(
                      '${list.length} ${list.length == 1 ? "entry" : "entries"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              contributionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Error loading contributions: $err',
                    style: const TextStyle(color: Color(0xFFDC2626)),
                  ),
                ),
                data: (contributions) {
                  if (contributions.isEmpty) {
                    return _buildEmptyHistoryState();
                  }

                  return Column(
                    children: contributions.map((c) {
                      return _buildContributionTile(c, goal);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Status Badge Helper ---
  Widget _buildStatusBadge(bool isCompleted, bool isNear) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉 ', style: TextStyle(fontSize: 12)),
            Text(
              'Goal Achieved',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
      );
    }

    if (isNear) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Near completion',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFFD97706),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Active',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  // --- Contribution Item Tile ---
  Widget _buildContributionTile(
    GoalContribution contribution,
    Goal goal,
  ) {
    return Container(
      key: Key('contribution_item_${contribution.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              color: Color(0xFF005C46),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+ ${CurrencyFormatter.format(contribution.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF005C46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contribution.formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (contribution.note != null && contribution.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    contribution.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            key: Key('delete_contribution_btn_${contribution.id}'),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
            tooltip: 'Delete Contribution',
            onPressed: () => _showDeleteContributionDialog(contribution, goal),
          ),
        ],
      ),
    );
  }

  // --- Empty History Component ---
  Widget _buildEmptyHistoryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'No contributions yet.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Start saving toward this goal.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
