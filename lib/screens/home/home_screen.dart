import 'package:flutter/material.dart';
import 'package:hrms/common/constants/constant.dart';
import 'package:hrms/common/router/router_path.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../api/api.dart';
import '../../../common/utils/location_service.dart';

import '../../../data/providers/theme_provider.dart';
import '../../../data/providers/employee_provider.dart';
import '../../../data/providers/attendance_provider.dart';
import '../../../data/providers/leave_provider.dart';
import '../../../data/providers/sync_provider.dart';
import '../../../data/model/models.dart';
import '../../widgets/loading_shimmer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBgColor = isDark ? AppColors.surfaceDark : AppColors.primary;
    final sheetBgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    final employeeProvider = context.watch<EmployeeProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final leaveProvider = context.watch<LeaveProvider>();
    final syncProvider = context.watch<SyncProvider>();

    final employee = employeeProvider.employee;

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
                // ================= Header Area =================
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Menu, Connectivity Status, Sync Button, Theme Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu_rounded,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              _showReviewerDrawer(context);
                            },
                          ),
                          Row(
                            children: [
                              // Connectivity & Sync Status Pill
                              _buildSyncStatusBadge(
                                context,
                                syncProvider,
                                attendanceProvider,
                              ),
                              const SizedBox(width: 8),

                              // Theme Switcher
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

                              // Notification Bell
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('No new notifications')),
                                      );
                                    },
                                  ),
                                  if (attendanceProvider.pendingEvents.isNotEmpty)
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.warning,
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
                      const SizedBox(height: 8),

                      // Employee Greeting & Department
                      Text(
                        'Hi ${employee?.name ?? 'Alex Smith'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _getTimeBasedGreeting(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${employee?.employeeId ?? 'EMP-878'} • ${employee?.department ?? 'Engineering'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),

                // ================= Main Sheet Body =================
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: sheetBgColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          employeeProvider.loadEmployee(forceRefresh: true),
                          attendanceProvider.loadDashboardAttendance(
                              forceRefresh: true),
                          leaveProvider.loadLeaveData(forceRefresh: true),
                        ]);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Offline Warning Banner
                            if (syncProvider.isOffline)
                              _buildOfflineBanner(context),

                            // Today's Attendance Status Card
                            _buildTodayAttendanceCard(
                              context,
                              attendanceProvider,
                              isDark,
                            ),
                            const SizedBox(height: 24),

                            // Section 1: Todays Attendance Stats (Moved from bottom to replace services row)
                            const Text(
                              'Todays Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildAttendanceSummaryRow(isDark),
                            const SizedBox(height: 24),

                            // Section 2: Latest Attendance Records (Latest 5)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Attendance',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.go(RouterPath.calendar),
                                  child: Text(
                                    'View All',
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
                            const SizedBox(height: 12),
                            _buildLatestAttendanceList(
                              context,
                              attendanceProvider,
                              isDark,
                            ),
                            const SizedBox(height: 24),

                            // Section 3: Recent Leave Application
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
                                  onTap: () =>
                                      context.go(RouterPath.calendar),
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
                            const SizedBox(height: 12),
                            _buildRecentLeaveCard(
                              context,
                              leaveProvider,
                              isDark,
                            ),

                            // Bottom spacing for floating navigation bar
                            const SizedBox(height: 110),
                          ],
                        ),
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

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // ================= Sync Status Badge =================

  Widget _buildSyncStatusBadge(
    BuildContext context,
    SyncProvider syncProvider,
    AttendanceProvider attendanceProvider,
  ) {
    if (syncProvider.isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Syncing...',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (syncProvider.isOffline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 14),
            SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Online state with pending count
    final pendingCount = attendanceProvider.pendingEvents.length;

    return GestureDetector(
      onTap: () async {
        final result = await syncProvider.syncNow(attendanceProvider);
        if (context.mounted && result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(syncProvider.lastSyncMessage ?? 'Synced!'),
              backgroundColor: result.hasErrors
                  ? AppColors.warning
                  : AppColors.success,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              pendingCount > 0 ? 'Sync ($pendingCount)' : 'Synced',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Offline Banner =================

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Color(0xFFE67E22), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are offline. Attendance check-in/out actions will be safely queued locally and synced when connection returns.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFD35400),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= Today's Attendance Live Status Card =================

  Widget _buildTodayAttendanceCard(
    BuildContext context,
    AttendanceProvider provider,
    bool isDark,
  ) {
    final record = provider.todayRecord;
    final status = provider.todayStatus;
    final cardBgColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (provider.isCheckedIn) {
      statusColor = AppColors.success;
      statusBgColor = AppColors.success.withValues(alpha: 0.12);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (provider.isCheckedOut) {
      statusColor = const Color(0xFF4A80F0);
      statusBgColor = const Color(0xFF4A80F0).withValues(alpha: 0.12);
      statusIcon = Icons.task_alt_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      statusIcon = Icons.access_time_rounded;
    }

    final checkInStr = record?.checkInTime != null
        ? DateFormat('hh:mm a').format(record!.checkInTime!)
        : '--:--';
    final checkOutStr = record?.checkOutTime != null
        ? DateFormat('hh:mm a').format(record!.checkOutTime!)
        : '--:--';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today, ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Columns: Check-in, Check-out, Working Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAttendanceMetricItem(
                label: 'Check-In',
                value: checkInStr,
                icon: Icons.login_rounded,
                color: AppColors.success,
              ),
              Container(
                width: 1,
                height: 38,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              _buildAttendanceMetricItem(
                label: 'Check-Out',
                value: checkOutStr,
                icon: Icons.logout_rounded,
                color: AppColors.error,
              ),
              Container(
                width: 1,
                height: 38,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              _buildAttendanceMetricItem(
                label: 'Working Duration',
                value: provider.isCheckedIn
                    ? provider.formattedElapsedDuration
                    : (record?.durationMinutes != null &&
                            record!.durationMinutes! > 0
                        ? '${record.durationMinutes! ~/ 60}h ${record.durationMinutes! % 60}m'
                        : '--:--'),
                icon: Icons.timer_outlined,
                color: const Color(0xFF4A80F0),
                isLiveTicker: provider.isCheckedIn,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Check-In / Check-Out Action Button
          if (provider.isNotCheckedIn)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: provider.isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.touch_app_rounded, size: 20),
                label: Text(
                  provider.isProcessing
                      ? 'Validating Location...'
                      : 'Check In (Geofenced)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: provider.isProcessing
                    ? null
                    : () async {
                        final employee =
                            context.read<EmployeeProvider>().employee!;
                        final isOnline = context.read<SyncProvider>().isOnline;
                        final result = await provider.performCheckIn(
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
                              action: result.geofenceResult?.canOpenSettings ==
                                      true
                                  ? SnackBarAction(
                                      label: 'Settings',
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        final opened = await LocationService.instance
                                            .openSettings();
                                        if (!opened && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not open settings automatically. Please check device settings manually.'),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        }
                      },
              ),
            )
          else if (provider.isCheckedIn)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: provider.isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  provider.isProcessing ? 'Processing...' : 'Check Out Now',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: provider.isProcessing
                    ? null
                    : () async {
                        final employee =
                            context.read<EmployeeProvider>().employee!;
                        final isOnline = context.read<SyncProvider>().isOnline;
                        final result = await provider.performCheckOut(
                          employee: employee,
                          isOnline: isOnline,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor: result.success
                                  ? const Color(0xFF4A80F0)
                                  : AppColors.error,
                              action: result.geofenceResult?.canOpenSettings ==
                                      true
                                  ? SnackBarAction(
                                      label: 'Settings',
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        final opened = await LocationService.instance
                                            .openSettings();
                                        if (!opened && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not open settings automatically. Please check device settings manually.'),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        }
                      },
              ),
            )
          else if (provider.isCheckedOut)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFF141414))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: isDark ? Colors.white : const Color(0xFF141414),
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attendance session completed for today.',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF141414),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildAttendanceMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isLiveTicker = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isLiveTicker ? color : null,
          ),
        ),
      ],
    );
  }

  // ================= Services Row =================

  Widget _buildServicesRow(
    BuildContext context,
    LeaveProvider leaveProvider,
    AttendanceProvider attendanceProvider,
    bool isDark,
  ) {
    final totalLeaveDays =
        leaveProvider.balance.totalAvailable.toInt().toString();

    final services = [
      _ServiceItemData(
        title: 'Requests',
        count: leaveProvider.requests.length.toString(),
        icon: Icons.mark_email_unread_outlined,
        color: AppColors.success,
        onTap: () => context.go(RouterPath.calendar),
      ),
      _ServiceItemData(
        title: 'Leaves',
        count: '$totalLeaveDays Days',
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
            const SnackBar(content: Text('Viewing available Pay Slips...')),
          );
        },
      ),
      _ServiceItemData(
        title: 'Attendance',
        count: attendanceProvider.todayStatus,
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

  // ================= Latest 5 Attendance Records =================

  Widget _buildLatestAttendanceList(
    BuildContext context,
    AttendanceProvider provider,
    bool isDark,
  ) {
    if (provider.isLoading && provider.latestRecords.isEmpty) {
      return const LoadingCard(isPortrait: false, titleHeight: 18);
    }

    if (provider.latestRecords.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No attendance records found.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: provider.latestRecords.map((record) {
        return _buildAttendanceHistoryTile(record, isDark);
      }).toList(),
    );
  }

  Widget _buildAttendanceHistoryTile(AttendanceRecord record, bool isDark) {
    final checkIn = record.checkInTime != null
        ? DateFormat('hh:mm a').format(record.checkInTime!)
        : '--';
    final checkOut = record.checkOutTime != null
        ? DateFormat('hh:mm a').format(record.checkOutTime!)
        : '--';
    final duration = record.durationMinutes != null && record.durationMinutes! > 0
        ? '${record.durationMinutes! ~/ 60}h ${record.durationMinutes! % 60}m'
        : '0h';

    Color syncColor;
    String syncLabel;
    IconData syncIcon;

    if (record.syncStatus == 'synced') {
      syncColor = AppColors.success;
      syncLabel = 'Synced';
      syncIcon = Icons.done_all_rounded;
    } else if (record.syncStatus == 'rejected') {
      syncColor = AppColors.error;
      syncLabel = 'Rejected';
      syncIcon = Icons.error_outline_rounded;
    } else {
      syncColor = const Color(0xFFF59E0B);
      syncLabel = 'Pending';
      syncIcon = Icons.sync_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A80F0).withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Color(0xFF4A80F0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'In: $checkIn  •  Out: $checkOut ($duration)',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: syncColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(syncIcon, color: syncColor, size: 12),
                const SizedBox(width: 4),
                Text(
                  syncLabel,
                  style: TextStyle(
                    color: syncColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= Recent Leave Application =================

  Widget _buildRecentLeaveCard(
    BuildContext context,
    LeaveProvider provider,
    bool isDark,
  ) {
    final cardBgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final requests = provider.requests;

    if (requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No recent leave applications.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final latest = requests.first;
    final dateRange =
        '${DateFormat('dd MMM').format(latest.startDate)} - ${DateFormat('dd MMM, yyyy').format(latest.endDate)} (${latest.daysCount} days)';

    return GestureDetector(
      onTap: () => context.go(RouterPath.calendar),
      child: Container(
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.3)
                    : const Color(0xFFF0F4F8),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 28,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User Info & Request details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${latest.leaveType.toUpperCase()} LEAVE',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusPill(latest.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateRange,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF141414),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    latest.reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = AppColors.success;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= Attendance Summary Row =================

  Widget _buildAttendanceSummaryRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _AttendanceStatCard(
            label: 'Presents',
            value: '54',
            circleColor: AppColors.success,
            circleBgColor: AppColors.success.withValues(alpha: 0.12),
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

  // ================= Reviewer Drawer / Debug Modal =================

  void _showReviewerDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final scenarioManager = MockScenarioManager.instance;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Material(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reviewer Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Network Offline Simulation Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Simulate Network Offline'),
                        subtitle: const Text(
                          'Cuts off connectivity to verify offline queueing and persistence.',
                        ),
                        value: scenarioManager.isSimulateOffline,
                        onChanged: (val) {
                          scenarioManager.setSimulateOffline(val);
                          setModalState(() {});
                        },
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Mock Scenarios:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<MockApiScenario>(
                        isExpanded: true,
                        initialValue: scenarioManager.currentScenario,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: MockApiScenario.success,
                            child: Text(
                              'Success (Normal 200/201)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: MockApiScenario.slowResponse,
                            child: Text(
                              'Slow Response / Timeout (10s)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: MockApiScenario.serverError,
                            child: Text(
                              'Server 500 Error',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: MockApiScenario.duplicateAttendanceConflict,
                            child: Text(
                              '409 Duplicate Attendance Conflict',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: MockApiScenario.leaveValidationRejection,
                            child: Text(
                              '422 Leave Validation Rejection',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            scenarioManager.setScenario(val);
                            setModalState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Location Simulation (Geofence):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<LocationSimulationMode>(
                        isExpanded: true,
                        initialValue: LocationService.instance.simulationMode,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: LocationSimulationMode.atOffice,
                            child: Text(
                              'At Office Desk (0m — Geofence Valid)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: LocationSimulationMode.outsideOffice,
                            child: Text(
                              'Outside Office (~550m — Geofence Blocked)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: LocationSimulationMode.permissionDenied,
                            child: Text(
                              'Permission Denied',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                LocationSimulationMode.permissionPermanentlyDenied,
                            child: Text(
                              'Permission Permanently Denied',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: LocationSimulationMode.servicesDisabled,
                            child: Text(
                              'GPS Services Disabled',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: LocationSimulationMode.realGps,
                            child: Text(
                              'Real Device GPS',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            LocationService.instance.setSimulationMode(val);
                            setModalState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Scenarios to Success'),
                        onPressed: () {
                          scenarioManager.resetToSuccess();
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ================= Auxiliary Widgets =================

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
        width: 108,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withValues(alpha: 0.14),
              ),
              child: Icon(data.icon, color: data.color, size: 24),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            width: 52,
            height: 52,
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
