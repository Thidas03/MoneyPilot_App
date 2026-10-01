import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../data/models/reminder_model.dart';
import 'providers/reminders_provider.dart';

/// Screen presenting the full list of financial reminders with filtering,
/// completion toggling, creation, editing, and deletion.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Reminder reminder) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete Reminder?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to delete this reminder?',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            key: const Key('confirm_delete_reminder_button'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text('Deleted "${reminder.title}"'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF0F172A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete reminder: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(filteredRemindersProvider);
    final summary = ref.watch(remindersSummaryProvider);
    final currentFilter = ref.watch(reminderFilterProvider);
    final isLoading = ref.watch(remindersLoadingProvider);
    final errorMessage = ref.watch(remindersErrorProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Reminders',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton.icon(
              key: const Key('add_reminder_appbar_button'),
              onPressed: () => context.push('/reminders/add'),
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Add Reminder',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(remindersProvider.notifier).loadReminders(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // Error banner if any operation failed
            if (errorMessage != null)
              ErrorBanner(
                message: errorMessage,
                onRetry: () => ref.read(remindersProvider.notifier).loadReminders(),
              ),

            // Summary Overview Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryMetricChip(
                    label: 'UPCOMING',
                    count: summary['pending'] ?? 0,
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    bgColor: const Color(0xFFE8F5E9),
                    isSelected: currentFilter == ReminderFilter.upcoming,
                    onTap: () => ref.read(reminderFilterProvider.notifier).setFilter(
                        ReminderFilter.upcoming),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryMetricChip(
                    label: 'OVERDUE',
                    count: summary['overdue'] ?? 0,
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                    isSelected: currentFilter == ReminderFilter.overdue,
                    onTap: () => ref.read(reminderFilterProvider.notifier).setFilter(
                        ReminderFilter.overdue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryMetricChip(
                    label: 'COMPLETED',
                    count: summary['completed'] ?? 0,
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                    isSelected: currentFilter == ReminderFilter.completed,
                    onTap: () => ref.read(reminderFilterProvider.notifier).setFilter(
                        ReminderFilter.completed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter Tabs Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterTab(
                    label: 'Upcoming (${summary['pending'] ?? 0})',
                    isSelected: currentFilter == ReminderFilter.upcoming,
                    onTap: () => ref.read(reminderFilterProvider.notifier).setFilter(
                        ReminderFilter.upcoming),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Overdue (${summary['overdue'] ?? 0})',
                    isSelected: currentFilter == ReminderFilter.overdue,
                    onTap: () => ref.read(reminderFilterProvider.notifier).setFilter(
                        ReminderFilter.overdue),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Completed (${summary['completed'] ?? 0})',
                    isSelected: currentFilter == ReminderFilter.completed,
                    onTap: () => ref.read(reminderFilterProvider.notifier).setFilter(
                        ReminderFilter.completed),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'All (${summary['total'] ?? 0})',
                    isSelected: currentFilter == ReminderFilter.all,
                    onTap: () => ref.read(reminderFilterProvider.notifier).setFilter(
                        ReminderFilter.all),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reminders List / Empty State / Loading
            if (isLoading && reminders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingIndicator(message: 'Loading reminders...'),
              )
            else if (reminders.isEmpty)
              _EmptyRemindersView(
                filter: currentFilter,
                onAddReminder: () => context.push('/reminders/add'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return _ReminderCard(
                    reminder: reminder,
                    onToggleComplete: () async {
                      try {
                        await ref
                            .read(remindersProvider.notifier)
                            .toggleReminderCompleted(reminder.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    onEdit: () => context.push('/reminders/edit', extra: reminder),
                    onDelete: () => _showDeleteDialog(context, ref, reminder),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetricChip extends StatelessWidget {
  const _SummaryMetricChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isSelected ? color : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: count > 0 && label == 'OVERDUE' ? color : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final Reminder reminder;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _getBadgeColor() {
    if (reminder.isCompleted) return const Color(0xFF0284C7);
    if (reminder.isOverdue) return const Color(0xFFDC2626);
    if (reminder.isDueToday) return const Color(0xFFD97706);
    return AppColors.primary;
  }

  Color _getBadgeBgColor() {
    if (reminder.isCompleted) return const Color(0xFFE0F2FE);
    if (reminder.isOverdue) return const Color(0xFFFEF2F2);
    if (reminder.isDueToday) return const Color(0xFFFFFBEB);
    return const Color(0xFFE8F5E9);
  }

  @override
  Widget build(BuildContext context) {
    final catColor = reminder.color;
    final catIcon = reminder.iconData;
    final badgeColor = _getBadgeColor();
    final badgeBgColor = _getBadgeBgColor();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: Colors.white,
      borderColor: reminder.isCompleted
          ? const Color(0xFFE2E8F0)
          : (reminder.isOverdue ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox Toggle Button
              GestureDetector(
                key: Key('toggle_reminder_${reminder.id}'),
                onTap: onToggleComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    color: reminder.isCompleted ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: reminder.isCompleted ? AppColors.primary : const Color(0xFF94A3B8),
                      width: 2,
                    ),
                  ),
                  child: reminder.isCompleted
                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                      : null,
                ),
              ),

              // Category Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Title & Category Row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: reminder.isCompleted
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A),
                        decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            reminder.displayCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            reminder.frequency.label,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Popup Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (reminder.amount != null && reminder.amount! > 0)
                    Text(
                      CurrencyFormatter.format(reminder.amount),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: reminder.isCompleted
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  PopupMenuButton<String>(
                    key: Key('reminder_menu_${reminder.id}'),
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: Color(0xFF334155)),
                            SizedBox(width: 8),
                            Text('Edit Reminder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text(
                              'Delete Reminder',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Footer: Due Date, Relative Status Badge, and Note
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${reminder.formattedDueDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reminder.relativeDueDescription,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

          if (reminder.note != null && reminder.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reminder.note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyRemindersView extends StatelessWidget {
  const _EmptyRemindersView({
    required this.filter,
    required this.onAddReminder,
  });

  final ReminderFilter filter;
  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    String message = 'Keep track of upcoming bills and important payments.';
    if (filter == ReminderFilter.completed) {
      message = 'Completed reminders will appear here.';
    } else if (filter == ReminderFilter.overdue) {
      message = 'Great job! You have no overdue payments.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 36,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            key: const Key('empty_state_add_reminder_button'),
            onPressed: onAddReminder,
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text(
              '+ Add Reminder',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
