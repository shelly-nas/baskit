import 'package:flutter/material.dart';
import 'login_page.dart';
import 'registration_page.dart';

/// Authentication Screen that hosts both login and registration pages
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegistration = true; // Default to registration as requested

  void _toggleAuthMode() {
    setState(() {
      _isRegistration = !_isRegistration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isRegistration
            ? RegistrationPage(
                key: const ValueKey('registration'),
                onSwitchToLogin: _toggleAuthMode,
              )
            : LoginPage(
                key: const ValueKey('login'),
                onSwitchToRegister: _toggleAuthMode,
              ),
      ),
    );
  }
}
