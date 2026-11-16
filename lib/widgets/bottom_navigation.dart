import 'package:flutter/material.dart';
import '../common/constants/constant.dart';

class FloatingBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onAddPressed;
  final Color? activeColor;
  final Color? backgroundColor;

  const FloatingBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAddPressed,
    this.activeColor,
    this.backgroundColor,
  });

  static const List<IconData> defaultIcons = [
    Icons.home_outlined,
    Icons.people_alt_outlined,
    Icons.calendar_month_outlined,
    Icons.chat_bubble_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final pillBg = backgroundColor ??
        (isDarkMode ? AppColors.cardDark : Colors.white);
    final effectiveActiveColor = activeColor ?? const Color(0xFF6C5CE7);
    final unselectedColor =
        isDarkMode ? AppColors.textTertiaryDark : const Color(0xFF9E9E9E);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              // 1. Separate White Pill Navigation Bar on the left
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDarkMode ? 0.3 : 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(defaultIcons.length, (index) {
                      final isSelected = index == currentIndex;
                      final icon = defaultIcons[index];

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(index),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 26,
                                  color: isSelected
                                      ? effectiveActiveColor
                                      : unselectedColor,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? effectiveActiveColor
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 2. Separate Floating Action Button (+) on the right
              GestureDetector(
                onTap: onAddPressed,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: effectiveActiveColor,
                    boxShadow: [
                      BoxShadow(
                        color: effectiveActiveColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep standard bottom nav item model for compatibility
class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

class BottomNavItems {
  static const BottomNavItem home =
      BottomNavItem(icon: Icons.home_outlined, label: 'Home');
  static const BottomNavItem team =
      BottomNavItem(icon: Icons.people_alt_outlined, label: 'Team');
  static const BottomNavItem calendar =
      BottomNavItem(icon: Icons.calendar_month_outlined, label: 'Calendar');
  static const BottomNavItem chat =
      BottomNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat');

  static List<BottomNavItem> get defaultItems => [home, team, calendar, chat];
}

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onAddPressed;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAddPressed,
    List<BottomNavItem>? items,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingBottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      onAddPressed: onAddPressed,
    );
  }
}
