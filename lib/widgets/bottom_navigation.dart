import 'package:flutter/material.dart';
import '../common/constants/constant.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const CustomBottomNavigation({super.key, required this.currentIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    final bottomBarTheme = Theme.of(context).bottomNavigationBarTheme;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(color: bottomBarTheme.backgroundColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;
          final iconColor = isSelected ? bottomBarTheme.selectedItemColor : bottomBarTheme.unselectedItemColor;
          final labelStyle = isSelected ? bottomBarTheme.selectedLabelStyle : bottomBarTheme.unselectedLabelStyle;
          final iconSize = 28.0;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: iconColor, size: iconSize),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle?.copyWith(color: iconColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

class BottomNavItems {
  static const BottomNavItem home = BottomNavItem(icon: Icons.home_outlined, label: 'Home');

  static const BottomNavItem network = BottomNavItem(icon: Icons.person, label: 'Profile');

  static List<BottomNavItem> get defaultItems => [home,network];
}

class BadgedBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BadgedBottomNavItem> items;

  const BadgedBottomNavigation({super.key, required this.currentIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                              child: Icon(item.icon, color: isSelected ? AppColors.primary : (isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiaryLight), size: 24),
                            ),
                            if (item.badgeCount != null && item.badgeCount! > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected ? AppColors.primary : (isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class BadgedBottomNavItem extends BottomNavItem {
  final int? badgeCount;

  const BadgedBottomNavItem({required super.icon, required super.label, this.badgeCount});
}