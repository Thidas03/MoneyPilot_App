import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// Pilot Profile screen presenting account details, preferences, and authentication management.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isLiveSupabase = ref.watch(isSupabaseActiveProvider);
    final profile = profileAsync.asData?.value ?? UserProfile.mock;

    final displayName = profile.fullName.isNotEmpty ? profile.fullName : 'Chief Pilot';
    final displayEmail = profile.email.isNotEmpty ? profile.email : 'pilot@moneypilot.com';
    final flightBadge = profile.flightBadge.isNotEmpty ? profile.flightBadge.toUpperCase() : 'FLIGHT CAPTAIN';
    final currencyText = 'Sri Lankan Rupee (${profile.currencySymbol})';
    final statusText = isLiveSupabase ? 'Active Supabase Session' : 'Active Prototype Session';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Pilot Profile',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar & Name Card
            GlassCard(
              borderRadius: 20,
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        flightBadge,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Details List Card
            GlassCard(
              borderRadius: 20,
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                children: [
                  _ProfileDetailTile(
                    icon: Icons.badge_outlined,
                    label: 'STATUS',
                    value: statusText,
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _ProfileDetailTile(
                    icon: Icons.currency_exchange_rounded,
                    label: 'DEFAULT CURRENCY',
                    value: currencyText,
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  const _ProfileDetailTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'SESSION SINCE',
                    value: 'September 2026',
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
            padding: const EdgeInsets.all(8),
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
