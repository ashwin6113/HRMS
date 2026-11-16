import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hrms/common/constants/constant.dart';
import 'package:hrms/widgets/bottom_navigation.dart';
import 'package:hrms/common/router/router_path.dart';
import 'package:hrms/data/providers/attendance_provider.dart';
import 'package:hrms/data/providers/employee_provider.dart';
import 'package:hrms/data/providers/sync_provider.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: FloatingBottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        onAddPressed: () => _showQuickActionModal(context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RouterPath.home)) {
      return 0;
    }
    if (location.startsWith(RouterPath.search)) {
      return 1;
    }
    if (location.startsWith(RouterPath.calendar)) {
      return 2;
    }
    if (location.startsWith(RouterPath.profile)) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouterPath.home);
        break;
      case 1:
        context.go(RouterPath.search);
        break;
      case 2:
        context.go(RouterPath.calendar);
        break;
      case 3:
        context.go(RouterPath.profile);
        break;
    }
  }

  void _showQuickActionModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickActionButton(
                        icon: Icons.calendar_month_outlined,
                        label: 'Apply Leave',
                        color: AppColors.error,
                        onTap: () {
                          Navigator.pop(ctx);
                          context.go(RouterPath.calendar);
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.how_to_reg_outlined,
                        label: 'Check In',
                        color: AppColors.success,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final employee =
                              context.read<EmployeeProvider>().employee!;
                          final isOnline =
                              context.read<SyncProvider>().isOnline;
                          final result = await context
                              .read<AttendanceProvider>()
                              .performCheckIn(
                                employee: employee,
                                isOnline: isOnline,
                              );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.message),
                                backgroundColor: result.success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'New Request',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.pop(ctx);
                          context.go(RouterPath.search);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
