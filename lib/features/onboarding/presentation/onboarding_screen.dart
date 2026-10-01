import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/glass_card.dart';

/// Data model representing an individual onboarding slide.
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.tag,
    required this.title,
    required this.description,
    required this.badgeIcon,
    required this.badgeColor,
    required this.illustrationWidget,
  });

  final String tag;
  final String title;
  final String description;
  final IconData badgeIcon;
  final Color badgeColor;
  final Widget illustrationWidget;
}

/// Interactive onboarding walkthrough presented to new users before auth.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding({required String targetRoute}) async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.completeOnboarding();
    if (mounted) {
      context.go(targetRoute);
    }
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding(targetRoute: '/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final slides = [
      OnboardingSlideData(
        tag: 'REAL-TIME TRACKING',
        title: 'Take Command of Every Rupee',
        description:
            'Log income and categorize daily expenses in seconds. Gain complete clarity and master your personal finances.',
        badgeIcon: Icons.insights_rounded,
        badgeColor: AppColors.primary,
        illustrationWidget: _buildTrackingIllustration(context, isDark),
      ),
      OnboardingSlideData(
        tag: 'SMART BUDGET RADAR',
        title: 'Navigate Clear of Overspending',
        description:
            'Set flexible monthly spending limits for every category. Receive intelligent proactive alerts before turbulence hits.',
        badgeIcon: Icons.shield_rounded,
        badgeColor: AppColors.teal,
        illustrationWidget: _buildBudgetIllustration(context, isDark),
      ),
      OnboardingSlideData(
        tag: 'FINANCIAL FREEDOM',
        title: 'Soar Towards Your Life Goals',
        description:
            'Chart your savings targets for emergency reserves, dream investments, and travel. Reach new heights on your schedule.',
        badgeIcon: Icons.rocket_launch_rounded,
        badgeColor: AppColors.indigo,
        illustrationWidget: _buildGoalsIllustration(context, isDark),
      ),
    ];

    final isLastPage = _currentPage == slides.length - 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Brand Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Logo mark with rounded container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MoneyPilot',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (!isLastPage)
                    TextButton(
                      onPressed: () => _finishOnboarding(targetRoute: '/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondaryLight,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // Rich Interactive Illustration
                        slide.illustrationWidget,
                        const SizedBox(height: 28),

                        // Pill Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: slide.badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: slide.badgeColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                slide.badgeIcon,
                                size: 14,
                                color: slide.badgeColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                slide.tag,
                                style: TextStyle(
                                  color: slide.badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14.5,
                                  height: 1.5,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions & Page Indicators
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth Animated Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: isActive ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (!isLastPage) ...[
                    CustomButton(
                      text: 'Continue',
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      onPressed: _onNext,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _finishOnboarding(targetRoute: '/login'),
                      child: const Text(
                        'Already have an account? Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ] else ...[
                    CustomButton(
                      text: 'Get Started with MoneyPilot',
                      icon: const Icon(Icons.flight_takeoff_rounded, size: 20),
                      onPressed: () => _finishOnboarding(targetRoute: '/register'),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: 'Sign In to Existing Account',
                      isOutlined: true,
                      onPressed: () => _finishOnboarding(targetRoute: '/login'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 1 ILLUSTRATION: Cashflow & Expense Radar Card
  // --------------------------------------------------------------------------
  Widget _buildTrackingIllustration(BuildContext context, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      backgroundColor: isDark ? const Color(0xFF131D2E) : Colors.white,
      borderColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
      child: Column(
        children: [
          // Header Row with Balance & Flight Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL BALANCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondaryLight,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rs. 182,500.00',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primaryDark),
                    SizedBox(width: 4),
                    Text(
                      '+52.8%',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mini Metric Badges
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF047857)),
                      SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('INCOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                          Text('Rs. 250,000', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFFBE123C)),
                      SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EXPENSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFBE123C))),
                          Text('Rs. 67,500', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF881337))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sample Transaction Pills
          _buildTransactionMiniRow(
            icon: Icons.work_outline_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF15803D),
            title: 'Monthly Salary Deposit',
            subtitle: 'Direct Transfer • Today',
            amount: '+Rs. 250,000',
            isIncome: true,
          ),
          const SizedBox(height: 8),
          _buildTransactionMiniRow(
            icon: Icons.shopping_bag_outlined,
            iconBg: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFB91C1C),
            title: 'Keells Supermarket',
            subtitle: 'Groceries • Yesterday',
            amount: '-Rs. 8,450',
            isIncome: false,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 2 ILLUSTRATION: Precision Budget Controls
  // --------------------------------------------------------------------------
  Widget _buildBudgetIllustration(BuildContext context, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      backgroundColor: isDark ? const Color(0xFF131D2E) : Colors.white,
      borderColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded, color: AppColors.teal, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Monthly Budget Radar',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SAFE ALTITUDE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget Progress Bars
          _buildBudgetMeter(
            label: 'Dining & Restaurants',
            spent: 'Rs. 14,200',
            total: 'Rs. 25,000',
            progress: 0.57,
            progressColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildBudgetMeter(
            label: 'Fuel & Transportation',
            spent: 'Rs. 18,900',
            total: 'Rs. 22,000',
            progress: 0.86,
            progressColor: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildBudgetMeter(
            label: 'Utilities & Bills',
            spent: 'Rs. 12,000',
            total: 'Rs. 30,000',
            progress: 0.40,
            progressColor: AppColors.teal,
          ),
          const SizedBox(height: 14),

          // Status Alert Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryDark, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are 28% below your monthly projected spending cap.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 3 ILLUSTRATION: Financial Goals & Wealth Milestones
  // --------------------------------------------------------------------------
  Widget _buildGoalsIllustration(BuildContext context, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      backgroundColor: isDark ? const Color(0xFF131D2E) : Colors.white,
      borderColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: AppColors.indigo, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Savings Milestones',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '3 ACTIVE GOALS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal Card 1: Emergency Reserve
          _buildGoalItem(
            icon: Icons.shield_moon_rounded,
            iconColor: AppColors.teal,
            title: 'Emergency Flight Reserve',
            current: 'Rs. 250,000',
            target: 'Rs. 300,000',
            percent: 83,
            eta: 'Achieved in 4 weeks',
          ),
          const SizedBox(height: 12),

          // Goal Card 2: Dream Travel Fund
          _buildGoalItem(
            icon: Icons.flight_takeoff_rounded,
            iconColor: AppColors.indigo,
            title: 'Japan Vacation Odyssey',
            current: 'Rs. 480,000',
            target: 'Rs. 600,000',
            percent: 80,
            eta: 'Achieved in 2 months',
          ),
        ],
      ),
    );
  }

  // Mini Helpers
  Widget _buildTransactionMiniRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required bool isIncome,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Text(
                'Direct Transfer • Today',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isIncome ? AppColors.income : AppColors.expense,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetMeter({
    required String label,
    required String spent,
    required String total,
    required double progress,
    required Color progressColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('$spent / $total', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: progressColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String current,
    required String target,
    required int percent,
    required String eta,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(fontWeight: FontWeight.w800, color: iconColor, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100.0,
              minHeight: 6,
              backgroundColor: iconColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$current of $target',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                eta,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: iconColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
