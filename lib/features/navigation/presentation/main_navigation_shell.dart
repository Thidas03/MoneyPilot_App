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

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SizedBox.expand(
        child: navigationShell,
      ),
      bottomNavigationBar: Container(
        height: 64 + bottomPadding,
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
        padding: EdgeInsets.only(
          left: 6,
          right: 6,
          top: 6,
          bottom: bottomPadding > 0 ? bottomPadding : 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final isSelected = currentIndex == index;
            final item = navItems[index];

            return Expanded(
              child: GestureDetector(
                key: Key('nav_tab_${item.label.toLowerCase()}'),
                onTap: () => _onDestinationSelected(index),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: isSelected
                        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                        : const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                        const SizedBox(height: 2),
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
