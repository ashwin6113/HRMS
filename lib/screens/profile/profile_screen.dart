import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/mock_api_scenario.dart';
import '../../api/mock_http_client.dart';
import '../../common/constants/constant.dart';
import '../../data/local/database_helper.dart';
import '../../data/providers/attendance_provider.dart';
import '../../data/providers/employee_provider.dart';
import '../../data/providers/leave_provider.dart';
import '../../data/providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? AppColors.cardDark : Colors.white;

    final employeeProvider = context.watch<EmployeeProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final leaveProvider = context.watch<LeaveProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final employee = employeeProvider.employee;
    final name = employee?.name ?? 'Ashwin Kumar';
    final empId = employee?.employeeId ?? 'EMP-001';
    final dept = employee?.department ?? 'Mobile Engineering';
    final balance = leaveProvider.balance;

    // In light theme: primary is black (0xFF141414). In dark theme: primary is white.
    final primaryColor = isDark ? Colors.white : const Color(0xFF141414);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            // 1. Employee Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      border: Border.all(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.3 : 0.2,
                        ),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 42,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dept,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: $empId',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Work & Location Information Card
            _buildSectionCard(
              context: context,
              title: 'Workplace & Geofence',
              cardBgColor: cardBgColor,
              isDark: isDark,
              children: [
                _buildInfoRow(
                  icon: Icons.business_rounded,
                  label: 'Office Base',
                  value: 'REBS HQ (Bangalore)',
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  icon: Icons.radar_rounded,
                  label: 'Geofence Radius',
                  value:
                      '${employee?.geofenceRadiusMeters.toInt() ?? 200} Meters',
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Timezone',
                  value: employee?.timezone ?? 'Asia/Kolkata',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Quick Stats Card
            _buildSectionCard(
              context: context,
              title: 'Attendance & Leave Summary',
              cardBgColor: cardBgColor,
              isDark: isDark,
              children: [
                _buildInfoRow(
                  icon: Icons.how_to_reg_rounded,
                  label: "Today's Status",
                  value: attendanceProvider.todayStatus,
                  isDark: isDark,
                  valueColor: attendanceProvider.isCheckedIn
                      ? AppColors.success
                      : null,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  icon: Icons.beach_access_rounded,
                  label: 'Casual Leaves Available',
                  value:
                      '${balance.casualLeaveAvailable.toInt()} / ${balance.casualLeaveTotal.toInt()} days',
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Sick Leaves Available',
                  value:
                      '${balance.sickLeaveAvailable.toInt()} / ${balance.sickLeaveTotal.toInt()} days',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. App Preferences & Tools
            _buildSectionCard(
              context: context,
              title: 'Preferences & Tools',
              cardBgColor: cardBgColor,
              isDark: isDark,
              children: [
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      Icons.dark_mode_outlined,
                      color: primaryColor,
                    ),
                    activeTrackColor: isDark
                        ? Colors.white70
                        : const Color(0xFF141414),
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(val),
                  ),
                ),
                _buildDivider(isDark),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.restart_alt_rounded,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Reset Local Database & Cache',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: const Text(
                      'Clears offline SQLite tables and reloads initial mock data',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark
                              ? AppColors.surfaceDark
                              : Colors.white,
                          title: Text(
                            'Reset Database?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          content: Text(
                            'This will clear local attendance and leave records and restore defaults.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await DatabaseHelper.instance.clearAllData();
                        MockScenarioManager.instance.reset();
                        MockHttpClient.resetServerData();
                        if (context.mounted) {
                          await employeeProvider.loadEmployee(
                            forceRefresh: true,
                          );
                          await attendanceProvider.loadDashboardAttendance(
                            forceRefresh: true,
                          );
                          await leaveProvider.loadLeaveData(forceRefresh: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Database reset to defaults successfully.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Version info footer
            const Text(
              'REBS HRMS Mobile • Version 1.0.0\nOffline-Capable Employee Workspace',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required Color cardBgColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Material(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(18),
      elevation: isDark ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    final iconColor = isDark ? Colors.white70 : const Color(0xFF141414);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  valueColor ??
                  (isDark ? Colors.white : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white12 : Colors.grey.shade100,
    );
  }
}
