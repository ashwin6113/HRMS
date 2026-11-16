import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router_path.dart';
import '../constants/constant.dart';
import '../../screens/screens.dart';

GoRouter getRouterConfig() {
  return GoRouter(
    navigatorKey: globalNavigatorKey,
    initialLocation: RouterPath.home,

    routes: [
      GoRoute(path: RouterPath.splash, builder: (context, state) => const SplashScreen()),
      _shellRoute,
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Page not found: ${state.path}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.go(RouterPath.home), child: const Text('Go Home')),
          ],
        ),
      ),
    ),
  );
}

final _shellRoute = ShellRoute(
  builder: (context, state, child) {
    return MainShellScreen(child: child);
  },
  routes: [
    GoRoute(path: RouterPath.home, builder: (context, state) => const HomeScreen()),
    GoRoute(path: RouterPath.profile, builder: (context, state) => const ProfileScreen()),
  ],
);
