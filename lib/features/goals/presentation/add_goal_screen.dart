import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../data/goals_provider.dart';
import '../domain/goal_model.dart';

/// Available icon options for savings goals.
final List<Map<String, dynamic>> _goalIconOptions = [
  {'name': 'flag_rounded', 'icon': Icons.flag_rounded, 'label': 'Milestone'},
  {'name': 'shield_rounded', 'icon': Icons.shield_rounded, 'label': 'Reserve'},
  {'name': 'flight_takeoff_rounded', 'icon': Icons.flight_takeoff_rounded, 'label': 'Travel'},
  {'name': 'home_rounded', 'icon': Icons.home_rounded, 'label': 'Home'},
  {'name': 'directions_car_rounded', 'icon': Icons.directions_car_rounded, 'label': 'Vehicle'},
  {'name': 'school_rounded', 'icon': Icons.school_rounded, 'label': 'Education'},
  {'name': 'laptop_mac_rounded', 'icon': Icons.laptop_mac_rounded, 'label': 'Tech'},
  {'name': 'diamond_rounded', 'icon': Icons.diamond_rounded, 'label': 'Luxury'},
  {'name': 'beach_access_rounded', 'icon': Icons.beach_access_rounded, 'label': 'Vacation'},
  {'name': 'savings_rounded', 'icon': Icons.savings_rounded, 'label': 'Savings'},
];

/// Available color options for goals.
final List<Map<String, dynamic>> _goalColorOptions = [
  {'hex': '#005C46', 'color': const Color(0xFF005C46)},
  {'hex': '#047857', 'color': const Color(0xFF047857)},
  {'hex': '#6366F1', 'color': const Color(0xFF6366F1)},
  {'hex': '#3B82F6', 'color': const Color(0xFF3B82F6)},
  {'hex': '#F59E0B', 'color': const Color(0xFFF59E0B)},
  {'hex': '#EC4899', 'color': const Color(0xFFEC4899)},
  {'hex': '#8B5CF6', 'color': const Color(0xFF8B5CF6)},
  {'hex': '#10B981', 'color': const Color(0xFF10B981)},
];

/// Screen allowing users to create or edit a financial goal.
class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({
    super.key,
    this.existingGoal,
  });

  final Goal? existingGoal;

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentAmountController;
  late TextEditingController _noteController;

  DateTime? _selectedDeadline;
  String _selectedIconName = 'flag_rounded';
  String _selectedColorHex = '#005C46';
  bool _isSaving = false;

  bool get isEditing => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();

    final g = widget.existingGoal;
    if (g != null) {
      _titleController = TextEditingController(text: g.title);
      _targetAmountController = TextEditingController(
        text: g.targetAmount % 1 == 0
            ? g.targetAmount.toInt().toString()
            : g.targetAmount.toString(),
      );
      _currentAmountController = TextEditingController(
        text: g.currentAmount % 1 == 0
            ? g.currentAmount.toInt().toString()
            : g.currentAmount.toString(),
      );
      _noteController = TextEditingController(text: g.note ?? '');
      _selectedDeadline = g.deadlineDate;
      _selectedIconName = g.iconName;
      _selectedColorHex = g.colorHex;
    } else {
      _titleController = TextEditingController();
      _targetAmountController = TextEditingController();
      _currentAmountController = TextEditingController(text: '0');
      _noteController = TextEditingController();
      // Default to 1 year in the future
      final now = DateTime.now();
      _selectedDeadline = DateTime(now.year + 1, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2, 1, 1);
    final lastDate = DateTime(now.year + 20, 12, 31);
    final initial = _selectedDeadline ?? DateTime(now.year + 1, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : (initial.isAfter(lastDate) ? lastDate : initial),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF005C46),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _confirmDelete() async {
    if (!isEditing || widget.existingGoal == null) return;
    final goal = widget.existingGoal!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Goal?'),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_goal_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => ctx.pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Goal "${goal.title}" deleted successfully')),
              ],
            ),
            backgroundColor: const Color(0xFF334155),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target deadline'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final rawTarget = _targetAmountController.text.replaceAll(',', '').trim();
    final target = double.tryParse(rawTarget) ?? 0.0;

    final rawCurrent = _currentAmountController.text.replaceAll(',', '').trim();
    final current = double.tryParse(rawCurrent) ?? 0.0;

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        final updatedGoal = widget.existingGoal!.copyWith(
          title: _titleController.text.trim(),
          targetAmount: target,
          currentAmount: current,
          deadlineDate: _selectedDeadline!,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
          iconName: _selectedIconName,
          colorHex: _selectedColorHex,
          updatedAt: DateTime.now(),
        );

        await ref.read(goalsProvider.notifier).updateGoal(updatedGoal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal updated successfully'),
              backgroundColor: Color(0xFF005C46),
            ),
          );
          context.pop();
        }
      } else {
        final newGoal = Goal(
          id: '',
          title: _titleController.text.trim(),
          targetAmount: target,
          currentAmount: current,
          deadlineDate: _selectedDeadline!,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
          iconName: _selectedIconName,
          colorHex: _selectedColorHex,
        );

        await ref.read(goalsProvider.notifier).createGoal(newGoal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal created successfully'),
              backgroundColor: Color(0xFF005C46),
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF005C46);
    const borderColor = Color(0xFFE2E8F0);

    final titleText = isEditing ? 'Edit Goal' : 'Add Goal';
    final subtitleText = isEditing
        ? 'Update savings target and details for ${_titleController.text.isNotEmpty ? _titleController.text : "your goal"}.'
        : 'Set financial targets to keep your flight plan on track.';

    String formattedDeadline = 'Select Deadline';
    if (_selectedDeadline != null) {
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      formattedDeadline =
          '${monthNames[_selectedDeadline!.month - 1]} ${_selectedDeadline!.day}, ${_selectedDeadline!.year}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Back Button, Title, and Delete Icon if editing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          key: const Key('add_goal_back_button'),
                          onTap: () => context.pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.chevron_left_rounded,
                                color: brandGreen,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    if (isEditing)
                      IconButton(
                        key: const Key('delete_goal_button'),
                        onPressed: _confirmDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 24,
                        ),
                        tooltip: 'Delete Goal',
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    subtitleText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Goal Name Field
                _buildFieldLabel('GOAL NAME'),
                TextFormField(
                  key: const Key('goal_title_field'),
                  controller: _titleController,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. Japan Vacation or Emergency Fund',
                    prefixIcon: const Icon(Icons.flag_rounded, color: Color(0xFF64748B), size: 20),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a goal name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 2. Target Amount Field
                _buildFieldLabel('TARGET AMOUNT (Rs.)'),
                TextFormField(
                  key: const Key('goal_target_amount_field'),
                  controller: _targetAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _buildInputDecoration(
                    hintText: '0.00',
                    prefixIcon: Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: const Text(
                        'Rs.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a target amount';
                    }
                    final cleaned = value.replaceAll(',', '').trim();
                    final parsed = double.tryParse(cleaned);
                    if (parsed == null) {
                      return 'Please enter a valid amount';
                    }
                    if (parsed <= 0) {
                      return 'Target amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 3. Current Amount Field
                _buildFieldLabel('CURRENTLY SAVED (Rs.)'),
                TextFormField(
                  key: const Key('goal_current_amount_field'),
                  controller: _currentAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _buildInputDecoration(
                    hintText: '0.00',
                    prefixIcon: Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: const Text(
                        'Rs.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a valid current amount';
                    }
                    final cleaned = value.replaceAll(',', '').trim();
                    final parsed = double.tryParse(cleaned);
                    if (parsed == null) {
                      return 'Please enter a valid current amount';
                    }
                    if (parsed < 0) {
                      return 'Current amount cannot be negative';
                    }
                    final targetCleaned = _targetAmountController.text.replaceAll(',', '').trim();
                    final targetParsed = double.tryParse(targetCleaned);
                    if (targetParsed != null && targetParsed > 0 && parsed > targetParsed) {
                      return 'Current amount cannot exceed the target amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 4. Target Deadline
                _buildFieldLabel('TARGET DEADLINE'),
                GestureDetector(
                  key: const Key('goal_deadline_field'),
                  onTap: _pickDeadline,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formattedDeadline,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _selectedDeadline != null
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // 5. Visual Icon Selector
                _buildFieldLabel('SELECT ICON'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _goalIconOptions.map((opt) {
                      final isSelected = _selectedIconName == opt['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            opt['icon'] as IconData,
                            size: 18,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                          label: Text(opt['label'] as String),
                          selected: isSelected,
                          selectedColor: brandGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (sel) {
                            if (sel) {
                              setState(() => _selectedIconName = opt['name'] as String);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Color Theme Selector
                _buildFieldLabel('COLOR THEME'),
                Row(
                  children: _goalColorOptions.map((opt) {
                    final isSelected = _selectedColorHex.toLowerCase() ==
                        (opt['hex'] as String).toLowerCase();
                    final c = opt['color'] as Color;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColorHex = opt['hex'] as String);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // 7. Note Field (Optional)
                _buildFieldLabel('NOTE (OPTIONAL)'),
                TextFormField(
                  key: const Key('goal_note_field'),
                  controller: _noteController,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                    hintText: 'Add flight plans, milestones, or target descriptions...',
                  ),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 32),

                // Save Goal Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('save_goal_button'),
                    onPressed: _isSaving ? null : _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing ? 'Update Goal' : 'Save Goal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF005C46), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
