import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms/widgets/bottom_navigation.dart';
import 'package:hrms/common/router/router_path.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: BottomNavItems.defaultItems,
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RouterPath.home)) {
      return 0;
    }
    if (location.startsWith(RouterPath.profile)) {
      return 1;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouterPath.home);
        break;
      case 1:
        context.go(RouterPath.profile);
        break;
    }
  }
}
