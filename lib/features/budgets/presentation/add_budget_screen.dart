import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/budgets_provider.dart';
import '../domain/budget_model.dart';

enum BudgetScope { category, overall }

/// Screen for adding a new budget or editing an existing one.
class AddBudgetScreen extends ConsumerStatefulWidget {
  final Budget? existingBudget;
  final String? initialCategory;
  final double? initialAmount;
  final bool isOverallInitial;

  const AddBudgetScreen({
    super.key,
    this.existingBudget,
    this.initialCategory,
    this.initialAmount,
    this.isOverallInitial = false,
  });

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  late BudgetScope _selectedScope;
  late TextEditingController _amountController;
  final TextEditingController _noteController = TextEditingController();

  late String _selectedCategory;
  String _selectedPeriod = 'Monthly';

  bool get isEditing => widget.existingBudget != null;

  late final List<String> _categories;
  final List<String> _periods = ['Monthly', 'Weekly', 'Quarterly'];

  @override
  void initState() {
    super.initState();

    // Prepare category choices from AppCategories plus existing budget category if custom
    final catSet = <String>{
      'Food & Dining',
      'Transportation',
      'Entertainment',
      ...AppCategories.defaultCategories,
    };
    if (widget.existingBudget != null) {
      catSet.add(widget.existingBudget!.category);
    }
    if (widget.initialCategory != null) {
      catSet.add(widget.initialCategory!);
    }
    _categories = catSet.toList();

    if (widget.existingBudget != null) {
      final b = widget.existingBudget!;
      _selectedScope = BudgetScope.category;
      _selectedCategory = b.category;
      _selectedPeriod = b.period;
      _amountController = TextEditingController(
        text: b.amount % 1 == 0 ? b.amount.toInt().toString() : b.amount.toString(),
      );
      _noteController.text = b.note ?? '';
    } else {
      _selectedScope =
          widget.isOverallInitial ? BudgetScope.overall : BudgetScope.category;

      _selectedCategory = widget.initialCategory ?? _categories.first;
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = _categories.first;
      }

      final startAmount = widget.initialAmount != null
          ? widget.initialAmount!.toStringAsFixed(widget.initialAmount! % 1 == 0 ? 0 : 2)
          : (_selectedScope == BudgetScope.overall ? '50000' : '15000');
      _amountController = TextEditingController(text: startAmount);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addAmount(double add) {
    final current =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;
    final total = current + add;
    setState(() {
      _amountController.text = total.toStringAsFixed(0);
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete Budget?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete the budget limit for "$_selectedCategory"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_budget_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.existingBudget != null) {
      ref.read(budgetsProvider.notifier).removeBudget(widget.existingBudget!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Budget for "$_selectedCategory" deleted.'),
                ),
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

  void _saveBudget() {
    final rawAmount = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedScope == BudgetScope.overall) {
      ref.read(monthlyBudgetTargetProvider.notifier).setTarget(amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Overall monthly budget target updated to ${CurrencyFormatter.format(amount)}!',
          ),
          backgroundColor: const Color(0xFF005C46),
        ),
      );
    } else {
      if (isEditing) {
        final updated = widget.existingBudget!.copyWith(
          category: _selectedCategory,
          amount: amount,
          period: _selectedPeriod,
          note: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
        );
        ref.read(budgetsProvider.notifier).addOrUpdateBudget(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Budget for $_selectedCategory updated to ${CurrencyFormatter.format(amount)}!',
            ),
            backgroundColor: const Color(0xFF005C46),
          ),
        );
      } else {
        final newBudget = Budget(
          id: 'budget-${_selectedCategory.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}-${DateTime.now().millisecondsSinceEpoch}',
          category: _selectedCategory,
          amount: amount,
          period: _selectedPeriod,
          note: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
          createdAt: DateTime.now(),
        );

        ref.read(budgetsProvider.notifier).addOrUpdateBudget(newBudget);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Budget for $_selectedCategory set to ${CurrencyFormatter.format(amount)}!',
            ),
            backgroundColor: const Color(0xFF005C46),
          ),
        );
      }
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF005C46);
    const lightGreenBg = Color(0xFFE8F5E9);
    const borderColor = Color(0xFFE2E8F0);

    final title = isEditing
        ? 'Edit budget'
        : (_selectedScope == BudgetScope.overall
            ? 'Monthly target'
            : 'Add budget');

    final subtitle = isEditing
        ? 'Update spending limit for $_selectedCategory.'
        : (_selectedScope == BudgetScope.overall
            ? 'Set overall monthly target spending limit.'
            : 'Set spending guardrails to keep your flight plan on track.');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header: Back Button + Title + Delete action if editing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              key: const Key('add_budget_back_button'),
                              onTap: () => context.pop(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: lightGreenBg,
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
                              title,
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
                            key: const Key('delete_budget_button'),
                            onPressed: _confirmDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                            tooltip: 'Delete Budget',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Segmented Toggle: Category Budget vs Overall Target (hidden when editing a specific category)
                    if (!isEditing) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedScope = BudgetScope.category;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedScope == BudgetScope.category
                                        ? brandGreen
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Category Budget',
                                      style: TextStyle(
                                        color: _selectedScope == BudgetScope.category
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedScope = BudgetScope.overall;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedScope == BudgetScope.overall
                                        ? brandGreen
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Monthly Target',
                                      style: TextStyle(
                                        color: _selectedScope == BudgetScope.overall
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Category Picker (for Category Scope)
                    if (_selectedScope == BudgetScope.category) ...[
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(
                          color: isEditing ? const Color(0xFFF1F5F9) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            disabledHint: Text(_selectedCategory),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF0F172A),
                              size: 26,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            items: _categories.map((cat) {
                              final catColor = AppCategories.getColor(cat);
                              final catIcon = AppCategories.getIcon(cat);

                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        catIcon,
                                        size: 16,
                                        color: catColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(cat),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: isEditing
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedCategory = val;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Budget Limit Amount Label
                    Text(
                      _selectedScope == BudgetScope.overall
                          ? 'Overall Monthly Target Limit'
                          : 'Budget Limit Amount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Amount Input Field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Rs. ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              key: const Key('budget_amount_field'),
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                hintText: '0',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick increment suggestions
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickAmountChip('+2,000', 2000),
                          const SizedBox(width: 8),
                          _buildQuickAmountChip('+5,000', 5000),
                          const SizedBox(width: 8),
                          _buildQuickAmountChip('+10,000', 10000),
                          const SizedBox(width: 8),
                          _buildQuickAmountChip('+25,000', 25000),
                          const SizedBox(width: 8),
                          _buildQuickAmountChip('+50,000', 50000),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Frequency / Period Label
                    const Text(
                      'Budget Period',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Period Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF0F172A),
                            size: 26,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          items: _periods.map((period) {
                            return DropdownMenuItem<String>(
                              value: period,
                              child: Text(period),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPeriod = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Note (optional)
                    const Text(
                      'Note (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        key: const Key('budget_note_field'),
                        controller: _noteController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Add an optional note or purpose...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Save / Update Budget Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  key: const Key('save_budget_button'),
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing
                        ? 'Update budget'
                        : (_selectedScope == BudgetScope.overall
                            ? 'Update monthly target'
                            : 'Save budget'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double addAmount) {
    return ActionChip(
      onPressed: () => _addAmount(addAmount),
      label: Text(label),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF005C46),
      ),
      backgroundColor: const Color(0xFFE8F5E9),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
