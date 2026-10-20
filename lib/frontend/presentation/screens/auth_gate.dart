import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../di/dependency_injection.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../components/atoms/app_text.dart';
import '../components/atoms/spacing.dart';
import '../controllers/auth_controller.dart';
import 'main_screen.dart';
import 'sign_in_screen.dart';

/// Shows the sign-in screen until there is an account, then the app.
class AuthGate extends StatelessWidget {
  final AppDependencies dependencies;

  const AuthGate({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    final auth = dependencies.authController;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => switch (auth.status) {
        AuthStatus.restoring => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthStatus.unreachable => _Unreachable(auth: auth),
        AuthStatus.signedOut => SignInScreen(auth: auth),
        // Keyed by account, so a different account starts on fresh tabs.
        AuthStatus.signedIn => MainScreen(
          key: ValueKey(auth.user?.id),
          dependencies: dependencies,
        ),
      },
    );
  }
}

/// The stored sign-in could not be checked; it is kept for the next try.
class _Unreachable extends StatelessWidget {
  final AuthController auth;

  const _Unreachable({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.wifi_slash,
                size: 40,
                color: AppColors.mutedForeground,
              ),
              const VerticalSpace(DesignTokens.spaceLarge),
              AppText(
                auth.restoreError ?? 'Could not reach Baskit.',
                fontSize: 14,
                color: AppColors.mutedForeground,
                textAlign: TextAlign.center,
              ),
              const VerticalSpace(DesignTokens.spaceXLarge),
              ElevatedButton(
                onPressed: auth.restore,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
