import 'package:flutter/material.dart';
import 'frontend/presentation/screens/auth_screen.dart';
import 'frontend/presentation/screens/lists_screen.dart';
import 'frontend/services/token_storage_service.dart';
import 'frontend/theme/theme.dart';

void main() {
  runApp(const BaskitApp());
}

class BaskitApp extends StatelessWidget {
  const BaskitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baskit - Smart Shopping Lists',
      theme: AppTheme.lightTheme,
      home: const _StartupRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Checks stored session on startup and routes to the appropriate screen
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final hasSession = await TokenStorageService().hasValidSession();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            hasSession ? const ListsScreen() : const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a blank loading screen while the token check runs
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
