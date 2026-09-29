import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Custom mobile bottom navigation bar matching the MoneyPilot design specifications.
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = AppColors.primary;
    const activePillBg = Color(0xFFE8F5E9);
    const inactiveColor = Color(0xFF64748B);

    final currentIndex = navigationShell.currentIndex;

    final navItems = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavItem(
        icon: Icons.swap_horiz_rounded,
        activeIcon: Icons.swap_horiz_rounded,
        label: 'Transactions',
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Budget',
      ),
      _NavItem(
        icon: Icons.diamond_outlined,
        activeIcon: Icons.diamond_rounded,
        label: 'Goals',
      ),
      _NavItem(
        icon: Icons.pie_chart_outline_rounded,
        activeIcon: Icons.pie_chart_rounded,
        label: 'Reports',
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = currentIndex == index;
              final item = navItems[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onDestinationSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: isSelected
                          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                          : const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? activePillBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? brandGreen : inactiveColor,
                            size: 22,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? brandGreen : inactiveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
