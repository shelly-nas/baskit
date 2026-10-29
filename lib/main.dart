import 'package:flutter/material.dart';

import 'di/dependency_injection.dart';
import 'frontend/presentation/screens/auth_gate.dart';
import 'frontend/theme/theme.dart';

void main() {
  final dependencies = AppDependencies.create();
  // Signed in before? The stored token is checked while a loader shows.
  dependencies.authController.restore();
  runApp(BaskitApp(dependencies: dependencies));
}

class BaskitApp extends StatelessWidget {
  final AppDependencies dependencies;

  const BaskitApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baskit - Smart Shopping Lists',
      theme: AppTheme.lightTheme,
      home: AuthGate(dependencies: dependencies),
      debugShowCheckedModeBanner: false,
    );
  }
}
