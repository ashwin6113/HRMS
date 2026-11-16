import 'package:flutter/material.dart';
import 'package:hrms/common/constants/constant.dart';
import 'package:hrms/common/router/router_path.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBgColor = isDark ? AppColors.surfaceDark : AppColors.primary;
    final sheetBgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: headerBgColor,
      body: Stack(
        children: [
          // Decorative background circles in the header
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 70,
            right: 40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Menu icon, Theme Switcher & Notification Bell
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu_rounded,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Menu drawer opened')),
                              );
                            },
                          ),
                          Row(
                            children: [
                              Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return IconButton(
                                    icon: Icon(
                                      themeProvider.isDarkMode
                                          ? Icons.dark_mode_rounded
                                          : Icons.light_mode_rounded,
                                      color: Colors.white70,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      themeProvider.toggleTheme(
                                          !themeProvider.isDarkMode);
                                    },
                                  );
                                },
                              ),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'No new notifications')),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Greeting texts
                      Text(
                        'Hi Alex Smith',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Good Morning',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Main Content Sheet with rounded top
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: sheetBgColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Choose Services
                          const Text(
                            'Please Choose Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildServicesRow(context, isDark),

                          const SizedBox(height: 28),

                          // Section 2: Recent Leave Application
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Leave Application',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go(RouterPath.calendar),
                                child: Text(
                                  'See All',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildLeaveApplicationCard(context, isDark),

                          const SizedBox(height: 28),

                          // Section 3: Todays Attendance
                          const Text(
                            'Todays Attendance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildAttendanceRow(isDark),

                          // Bottom spacing for floating navigation bar
                          const SizedBox(height: 110),
                        ],
                      ),
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

  Widget _buildServicesRow(BuildContext context, bool isDark) {
    final services = [
      _ServiceItemData(
        title: 'Requests',
        count: '100',
        icon: Icons.mark_email_unread_outlined,
        color: AppColors.success,
        onTap: () => context.go(RouterPath.search),
      ),
      _ServiceItemData(
        title: 'Leaves',
        count: '12',
        icon: Icons.calendar_month_outlined,
        color: AppColors.error,
        onTap: () => context.go(RouterPath.calendar),
      ),
      _ServiceItemData(
        title: 'Pay Slip',
        count: '15',
        icon: Icons.receipt_long_outlined,
        color: AppColors.warning,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Pay Slips...')),
          );
        },
      ),
      _ServiceItemData(
        title: 'Attendance',
        count: '98%',
        icon: Icons.how_to_reg_outlined,
        color: AppColors.info,
        onTap: () => context.go(RouterPath.calendar),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: services.map((service) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ServiceCard(data: service, isDark: isDark),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaveApplicationCard(BuildContext context, bool isDark) {
    final cardBgColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.primaryLight.withValues(alpha: 0.3)
                  : const Color(0xFFF0F4F8),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 32,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // User Info & Request details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alexa Smith',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '27 Aug- 28 Aug, 2021',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A80F0),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sick Leave Request',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons: Cancel & Approve
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ActionPillButton(
                text: 'Cancel',
                textColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFF8E7),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Leave application cancelled')),
                  );
                },
              ),
              const SizedBox(height: 8),
              _ActionPillButton(
                text: 'Approve',
                textColor: AppColors.success,
                bgColor: const Color(0xFFE8F8EE),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Leave application approved!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _AttendanceStatCard(
            label: 'Presents',
            value: '54',
            circleColor: const Color(0xFF4A80F0),
            circleBgColor: const Color(0xFF4A80F0).withValues(alpha: 0.12),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AttendanceStatCard(
            label: 'Late',
            value: '15',
            circleColor: const Color(0xFFF59E0B),
            circleBgColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AttendanceStatCard(
            label: 'Absent',
            value: '20',
            circleColor: AppColors.error,
            circleBgColor: AppColors.error.withValues(alpha: 0.12),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _ServiceItemData {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItemData({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceItemData data;
  final bool isDark;

  const _ServiceCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBgColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withValues(alpha: 0.14),
              ),
              child: Icon(data.icon, color: data.color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              data.count,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionPillButton({
    required this.text,
    required this.textColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color circleColor;
  final Color circleBgColor;
  final bool isDark;

  const _AttendanceStatCard({
    required this.label,
    required this.value,
    required this.circleColor,
    required this.circleBgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBgColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleBgColor,
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: circleColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
