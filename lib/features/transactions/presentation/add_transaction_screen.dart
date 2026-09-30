import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../categories/data/category_repository.dart';
import '../data/transactions_provider.dart';
import '../domain/transaction_model.dart';

/// Screen for creating a new transaction or editing an existing one.
/// Addresses HCI usability testing feedback by providing explicit success confirmation.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.existingTransaction,
  });

  final Transaction? existingTransaction;

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isSaving = false;

  bool get isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    if (tx != null) {
      _type = tx.type;
      _titleController = TextEditingController(text: tx.title);
      _amountController = TextEditingController(
        text: tx.amount % 1 == 0 ? tx.amount.toInt().toString() : tx.amount.toString(),
      );
      _noteController = TextEditingController(text: tx.note ?? '');
      _selectedDate = tx.transactionDate;
      _selectedCategoryId = tx.categoryId;
      _selectedCategoryName = tx.category;
    } else {
      _type = TransactionType.expense;
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategoryId == null || _selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category for this transaction.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final parsedAmount = CurrencyFormatter.parse(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(transactionsProvider.notifier);

      if (isEditing) {
        final updatedTx = widget.existingTransaction!.copyWith(
          title: _titleController.text.trim(),
          amount: parsedAmount,
          type: _type,
          categoryId: _selectedCategoryId!,
          category: _selectedCategoryName!,
          transactionDate: _selectedDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
        await notifier.updateTransaction(updatedTx);
      } else {
        await notifier.addTransaction(
          title: _titleController.text.trim(),
          amount: parsedAmount,
          type: _type,
          categoryId: _selectedCategoryId!,
          categoryName: _selectedCategoryName!,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
      }

      if (!mounted) return;

      // HCI Usability requirement: Explicit confirmation feedback after saving
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('transaction_success_snackbar'),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing
                      ? 'Transaction updated successfully!'
                      : 'Transaction saved successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/transactions');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save transaction: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = _type == TransactionType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    // Auto-select first category if unassigned
    if (_selectedCategoryId == null && availableCategories.isNotEmpty) {
      _selectedCategoryId = availableCategories.first.id;
      _selectedCategoryName = availableCategories.first.name;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(
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
              context.go('/transactions');
            }
          },
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
                // 1. Transaction Type Toggle (Expense / Income)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = TransactionType.expense;
                              _selectedCategoryId = null;
                              _selectedCategoryName = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == TransactionType.expense
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _type == TransactionType.expense
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 18,
                                  color: _type == TransactionType.expense
                                      ? AppColors.expense
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Expense',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _type == TransactionType.expense
                                      ? AppColors.expense
                                      : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = TransactionType.income;
                              _selectedCategoryId = null;
                              _selectedCategoryName = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == TransactionType.income
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _type == TransactionType.income
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 18,
                                  color: _type == TransactionType.income
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Income',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _type == TransactionType.income
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Form Fields Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Field
                      CustomTextField(
                        controller: _amountController,
                        label: 'AMOUNT (${CurrencyFormatter.currencySymbol})',
                        hintText: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final parsed = CurrencyFormatter.parse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter an amount greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Title Field
                      CustomTextField(
                        controller: _titleController,
                        label: 'TITLE / PAYEE',
                        hintText: _type == TransactionType.expense
                            ? 'e.g. Keells Supermarket'
                            : 'e.g. Monthly Salary',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Category Selector
                      const Text(
                        'CATEGORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: const Key('transaction_category_dropdown'),
                            isExpanded: true,
                            value: availableCategories.any((c) => c.id == _selectedCategoryId)
                                ? _selectedCategoryId
                                : (availableCategories.isNotEmpty ? availableCategories.first.id : null),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                            items: availableCategories.map<DropdownMenuItem<String>>((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: cat.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(cat.iconData, size: 16, color: cat.color),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newCatId) {
                              if (newCatId != null) {
                                final selected = availableCategories.firstWhere((c) => c.id == newCatId);
                                setState(() {
                                  _selectedCategoryId = selected.id;
                                  _selectedCategoryName = selected.name;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Date Picker Field
                      const Text(
                        'TRANSACTION DATE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const Key('transaction_date_picker_button'),
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                DateFormatter.formatDate(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.edit_calendar_outlined, size: 18, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Optional Note Field
                      CustomTextField(
                        controller: _noteController,
                        label: 'NOTE (OPTIONAL)',
                        hintText: 'Add flight logs or receipts description...',
                        maxLines: 2,
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Action Button
                CustomButton(
                  key: const Key('save_transaction_button'),
                  text: isEditing ? 'Update Transaction' : 'Save Transaction',
                  isLoading: _isSaving,
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
