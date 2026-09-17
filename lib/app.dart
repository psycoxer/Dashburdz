import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

/// Root MaterialApp with theme switching and the dashboard as home.
class DashburdzApp extends ConsumerWidget {
  const DashburdzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Dashburdz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeInOutCubic,
      home: const DashboardScreen(),
    );
  }
}
