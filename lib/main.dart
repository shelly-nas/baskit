import 'package:flutter/material.dart';
import 'frontend/theme/app_theme.dart';
import 'frontend/presentation/screens/list_overview_screen.dart';
import 'di/dependency_injection.dart';

void main() {
  // Initialize dependency injection
  DependencyInjection().initialize();

  runApp(const BaskitApp());
}

class BaskitApp extends StatelessWidget {
  const BaskitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baskit - Smart Shopping Lists',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const ListOverviewScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
