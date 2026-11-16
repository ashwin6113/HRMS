import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/constants/constant.dart';
import 'common/router/router.dart';
import 'data/providers/theme_provider.dart';
import 'data/providers/employee_provider.dart';
import 'data/providers/attendance_provider.dart';
import 'data/providers/leave_provider.dart';
import 'data/providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _router = getRouterConfig();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => EmployeeProvider()..loadEmployee(),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider()..loadDashboardAttendance(),
        ),
        ChangeNotifierProvider(
          create: (_) => LeaveProvider()..loadLeaveData(),
        ),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'HRMS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
