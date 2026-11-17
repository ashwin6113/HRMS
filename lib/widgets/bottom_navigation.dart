import 'package:flutter/material.dart';
import '../common/constants/constant.dart';

class BottomNavPillItem {
  final IconData icon;
  final String label;

  const BottomNavPillItem({required this.icon, required this.label});
}

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

  static const List<BottomNavPillItem> defaultItems = [
    BottomNavPillItem(icon: Icons.home_rounded, label: 'Home'),
    BottomNavPillItem(icon: Icons.calendar_month_rounded, label: 'Calendar'),
    BottomNavPillItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Theme adaptive colors:
    // Light Mode: Pill is white, active items & button are black, button icon is white.
    // Dark Mode:  Pill is dark, active items & button are white, button icon is black.
    final pillBg = backgroundColor ??
        (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);

    final effectiveActiveColor = activeColor ??
        (isDarkMode ? Colors.white : const Color(0xFF141414));

    final buttonBgColor =
        isDarkMode ? Colors.white : const Color(0xFF141414);

    final buttonIconColor =
        isDarkMode ? const Color(0xFF141414) : Colors.white;

    final unselectedColor =
        isDarkMode ? const Color(0xFF71717A) : const Color(0xFF8E8E93);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              // 1. Separate Pill Navigation Bar with Icons & Text Labels
              Expanded(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDarkMode ? 0.4 : 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(defaultItems.length, (index) {
                      final isSelected = index == currentIndex;
                      final item = defaultItems[index];

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(index),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 22,
                                  color: isSelected
                                      ? effectiveActiveColor
                                      : unselectedColor,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? effectiveActiveColor
                                        : unselectedColor,
                                    letterSpacing: -0.2,
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

              const SizedBox(width: 14),

              // 2. Separate Floating Action Button (+) on the right
              GestureDetector(
                onTap: onAddPressed,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: buttonBgColor,
                    boxShadow: [
                      BoxShadow(
                        color: (isDarkMode ? Colors.white : Colors.black)
                            .withValues(alpha: isDarkMode ? 0.2 : 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: buttonIconColor,
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
