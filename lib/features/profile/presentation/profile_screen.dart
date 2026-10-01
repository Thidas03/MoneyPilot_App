import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// User Profile screen presenting account details, preferences, and profile editing.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openEditProfileModal(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileBottomSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isLiveSupabase = ref.watch(isSupabaseActiveProvider);
    final profile = profileAsync.asData?.value ?? UserProfile.mock;

    final displayName = profile.fullName.isNotEmpty ? profile.fullName : 'MoneyPilot User';
    final displayEmail = profile.email.isNotEmpty ? profile.email : 'user@moneypilot.com';
    final memberBadge = profile.memberBadge;
    final currencyText = profile.currencyCode == 'LKR'
        ? 'Sri Lankan Rupee (${profile.currencySymbol})'
        : '${profile.currencyCode} (${profile.currencySymbol})';
    final statusText = isLiveSupabase ? 'Active Supabase Session' : 'Active Session';
    final memberSinceText = profile.createdAt != null
        ? DateFormatter.formatMonthYear(profile.createdAt)
        : DateFormatter.formatMonthYear(DateTime.now());

    final initialLetter = displayName.trim().isNotEmpty
        ? displayName.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'User Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            key: const Key('appbar_edit_profile_button'),
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined, size: 22, color: Color(0xFF0F172A)),
            onPressed: () => _openEditProfileModal(context, profile),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar, Identity & Quick Edit Card
            GlassCard(
              borderRadius: 20,
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initialLetter,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openEditProfileModal(context, profile),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        memberBadge,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const Key('edit_profile_button'),
                      onPressed: () => _openEditProfileModal(context, profile),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Details List Card (Displaying details entered during registration)
            GlassCard(
              borderRadius: 20,
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 10, top: 4),
                    child: Text(
                      'USER PROFILE DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  _ProfileDetailTile(
                    icon: Icons.person_outline_rounded,
                    label: 'FULL NAME',
                    value: displayName,
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _ProfileDetailTile(
                    icon: Icons.mail_outline_rounded,
                    label: 'EMAIL ADDRESS',
                    value: displayEmail,
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _ProfileDetailTile(
                    icon: Icons.verified_user_outlined,
                    label: 'ACCOUNT STATUS',
                    value: statusText,
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _ProfileDetailTile(
                    icon: Icons.currency_exchange_rounded,
                    label: 'DEFAULT CURRENCY',
                    value: currencyText,
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _ProfileDetailTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'MEMBER SINCE',
                    value: memberSinceText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Return to Dashboard Action
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to Dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Logout Action
            OutlinedButton.icon(
              key: const Key('profile_logout_button'),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  const _ProfileDetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet modal enabling user profile editing with instant persistence.
class _EditProfileBottomSheet extends ConsumerStatefulWidget {
  const _EditProfileBottomSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends ConsumerState<_EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedCurrencyCode;
  late String _selectedCurrencySymbol;
  bool _isSaving = false;

  final List<Map<String, String>> _currencyOptions = const [
    {'code': 'LKR', 'symbol': 'Rs.', 'label': 'Sri Lankan Rupee (Rs.)'},
    {'code': 'USD', 'symbol': '\$', 'label': 'US Dollar (\$)'},
    {'code': 'EUR', 'symbol': '€', 'label': 'Euro (€)'},
    {'code': 'GBP', 'symbol': '£', 'label': 'British Pound (£)'},
    {'code': 'INR', 'symbol': '₹', 'label': 'Indian Rupee (₹)'},
    {'code': 'AUD', 'symbol': 'A\$', 'label': 'Australian Dollar (A\$)'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _selectedCurrencyCode = widget.profile.currencyCode.isNotEmpty
        ? widget.profile.currencyCode
        : 'LKR';
    _selectedCurrencySymbol = widget.profile.currencySymbol.isNotEmpty
        ? widget.profile.currencySymbol
        : 'Rs.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final success = await ref.read(profileNotifierProvider.notifier).updateProfile(
      fullName: _nameController.text.trim(),
      currencyCode: _selectedCurrencyCode,
      currencySymbol: _selectedCurrencySymbol,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Update your personal profile details',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Full Name field
              CustomTextField(
                controller: _nameController,
                label: 'FULL NAME',
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Full name cannot be empty';
                  }
                  if (val.trim().length < 2) {
                    return 'Full name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Address (read only)
              CustomTextField(
                initialValue: widget.profile.email.isNotEmpty
                    ? widget.profile.email
                    : 'user@moneypilot.com',
                label: 'EMAIL ADDRESS',
                hintText: 'Email address',
                enabled: false,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
              const SizedBox(height: 4),
              const Text(
                'Email is linked to your authentication account',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),

              // Default Currency Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEFAULT CURRENCY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrencyCode,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.currency_exchange_rounded,
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
                    items: _currencyOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt['code'],
                        child: Text(
                          opt['label']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (code) {
                      if (code == null) return;
                      final match = _currencyOptions.firstWhere(
                        (o) => o['code'] == code,
                        orElse: () => _currencyOptions.first,
                      );
                      setState(() {
                        _selectedCurrencyCode = code;
                        _selectedCurrencySymbol = match['symbol']!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: _handleSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
