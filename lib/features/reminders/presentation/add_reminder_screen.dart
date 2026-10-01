import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category_model.dart';
import '../data/models/reminder_model.dart';
import 'providers/reminders_provider.dart';

/// Screen supporting creating a new reminder or editing an existing reminder.
class AddReminderScreen extends ConsumerStatefulWidget {
  const AddReminderScreen({
    super.key,
    this.existingReminder,
  });

  final Reminder? existingReminder;

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late DateTime _selectedDueDate;
  late ReminderFrequency _selectedFrequency;
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  bool _isSaving = false;

  bool get isEditing => widget.existingReminder != null;

  @override
  void initState() {
    super.initState();
    final rem = widget.existingReminder;
    _titleController = TextEditingController(text: rem?.title ?? '');
    _amountController = TextEditingController(
      text: rem?.amount != null && rem!.amount! > 0
          ? rem.amount!.toStringAsFixed(rem.amount! % 1 == 0 ? 0 : 2)
          : '',
    );
    _noteController = TextEditingController(text: rem?.note ?? '');
    _selectedDueDate = rem?.dueDate ?? DateTime.now().add(const Duration(days: 3));
    _selectedFrequency = rem?.frequency ?? ReminderFrequency.monthly;
    _selectedCategoryId = rem?.categoryId;
    _selectedCategoryName = rem?.categoryName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDueDate.isBefore(now.subtract(const Duration(days: 365)))
        ? now
        : _selectedDueDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDueDate.hour,
          _selectedDueDate.minute,
        );
      });
    }
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    double? parsedAmount;
    if (_amountController.text.trim().isNotEmpty) {
      parsedAmount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));
    }

    try {
      if (isEditing) {
        final existing = widget.existingReminder!;
        final updated = existing.copyWith(
          title: _titleController.text.trim(),
          amount: parsedAmount,
          dueDate: _selectedDueDate,
          frequency: _selectedFrequency,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
          updatedAt: DateTime.now().toUtc(),
        );

        await ref.read(remindersProvider.notifier).updateReminder(updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Reminder updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final newReminder = Reminder(
          id: '',
          userId: '',
          title: _titleController.text.trim(),
          amount: parsedAmount,
          dueDate: _selectedDueDate,
          frequency: _selectedFrequency,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await ref.read(remindersProvider.notifier).createReminder(newReminder);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Reminder created successfully!'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/reminders');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reminder: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.asData?.value ?? <Category>[];

    final dateFormatted = DateFormat('EEE, MMM d, yyyy').format(_selectedDueDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isEditing ? 'Edit Reminder' : 'Add Reminder',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Update Reminder' : 'New Payment Reminder',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Never miss an important bill, loan installment, or subscription.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Container Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Title (Required)
                      CustomTextField(
                        controller: _titleController,
                        label: 'TITLE *',
                        hintText: 'e.g. Electricity Bill, Rent, Cloud Hosting',
                        prefixIcon: const Icon(Icons.title_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Reminder title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Amount (Optional)
                      CustomTextField(
                        controller: _amountController,
                        label: 'AMOUNT (OPTIONAL)',
                        hintText: 'e.g. 8500',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final clean = value.trim().replaceAll(',', '');
                          final parsed = double.tryParse(clean);
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter a valid positive amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 3. Category Selector (Optional)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CATEGORY (OPTIONAL)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryName,
                            decoration: InputDecoration(
                              hintText: 'Select category',
                              prefixIcon: Icon(
                                _selectedCategoryName != null
                                    ? AppCategories.getIcon(_selectedCategoryName!)
                                    : Icons.category_outlined,
                                color: _selectedCategoryName != null
                                    ? AppCategories.getColor(_selectedCategoryName!)
                                    : const Color(0xFF64748B),
                                size: 20,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('No Category', style: TextStyle(color: Color(0xFF94A3B8))),
                              ),
                              if (categories.isNotEmpty)
                                ...categories.map((c) => DropdownMenuItem<String>(
                                      value: c.name,
                                      child: Row(
                                        children: [
                                          Icon(
                                            AppCategories.getIcon(c.name),
                                            color: AppCategories.getColor(c.name),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            c.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                              else
                                ...AppCategories.defaultCategories.map((name) => DropdownMenuItem<String>(
                                      value: name,
                                      child: Row(
                                        children: [
                                          Icon(
                                            AppCategories.getIcon(name),
                                            color: AppCategories.getColor(name),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                            ],
                            onChanged: (catName) {
                              setState(() {
                                _selectedCategoryName = catName;
                                if (catName != null && categories.isNotEmpty) {
                                  try {
                                    _selectedCategoryId = categories.firstWhere((c) => c.name == catName).id;
                                  } catch (_) {
                                    _selectedCategoryId = null;
                                  }
                                } else {
                                  _selectedCategoryId = null;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 4. Due Date Picker (Required)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DUE DATE *',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            key: const Key('pick_due_date_button'),
                            onTap: _pickDueDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      dateFormatted,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 5. Frequency Recurrence (Required)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FREQUENCY *',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ReminderFrequency>(
                            initialValue: _selectedFrequency,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.repeat_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            items: ReminderFrequency.values.map((freq) {
                              return DropdownMenuItem<ReminderFrequency>(
                                value: freq,
                                child: Text(
                                  freq.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (freq) {
                              if (freq != null) {
                                setState(() => _selectedFrequency = freq);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 6. Note (Optional)
                      CustomTextField(
                        controller: _noteController,
                        label: 'NOTE (OPTIONAL)',
                        hintText: 'Add account number, reference, or payment note...',
                        maxLines: 3,
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save Action Button
                CustomButton(
                  key: const Key('save_reminder_button'),
                  text: isEditing ? 'Save Changes' : 'Create Reminder',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 12),

                // Cancel Button
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
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
}
