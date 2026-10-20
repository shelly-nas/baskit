import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../database/data_sources/baskit_api_client.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../components/atoms/app_text.dart';
import '../components/atoms/spacing.dart';
import '../components/molecules/menu_item.dart';
import '../components/molecules/section_header.dart';
import '../components/organisms/logout_button.dart';
import '../components/organisms/user_info_section.dart';
import '../components/organisms/version_display.dart';
import '../controllers/auth_controller.dart';
import '../dialogs/text_input_dialog.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AuthController auth;

  const ProfileScreen({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: auth,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
              // Signing out swaps this screen for the sign-in screen.
              child: auth.isSignedIn
                  ? _AccountView(auth: auth)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountView extends StatelessWidget {
  final AuthController auth;

  const _AccountView({required this.auth});

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeName(BuildContext context) async {
    final name = await showTextInputDialog(
      context,
      title: 'Your name',
      confirmLabel: 'Save',
      initialValue: auth.user!.displayName,
    );
    if (name == null) return;
    try {
      await auth.updateProfile(displayName: name);
    } on BaskitApiException catch (e) {
      if (context.mounted) _show(context, e.message);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = await showTextInputDialog(
      context,
      title: 'Current password',
      confirmLabel: 'Next',
      obscureText: true,
    );
    if (current == null || !context.mounted) return;
    final next = await showTextInputDialog(
      context,
      title: 'New password',
      confirmLabel: 'Save',
      hintText: 'At least 8 characters',
      obscureText: true,
    );
    if (next == null) return;
    try {
      await auth.updateProfile(currentPassword: current, newPassword: next);
      if (context.mounted) _show(context, 'Password changed');
    } on BaskitApiException catch (e) {
      if (context.mounted) _show(context, e.message);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = await showTextInputDialog(
      context,
      title: 'Delete account',
      confirmLabel: 'Delete',
      hintText: 'Your password, to confirm',
      obscureText: true,
    );
    if (password == null) return;
    try {
      // On success the app returns to the sign-in screen.
      await auth.deleteAccount(password);
    } on BaskitApiException catch (e) {
      if (context.mounted) _show(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserInfoSection(
          name: user.displayName,
          email: user.email,
          badgeText: user.isAdmin ? 'Admin' : 'Member',
        ),
        const VerticalSpace(DesignTokens.spaceSmall),
        const AppText(
          'Your lists are saved to your account and can be shared.',
          fontSize: 13,
          color: AppColors.mutedForeground,
        ),
        const VerticalSpace(32),
        const SectionHeader(title: 'ACCOUNT'),
        const VerticalSpace(12),
        MenuItem(
          icon: CupertinoIcons.person,
          label: 'Change name',
          onTap: () => _changeName(context),
        ),
        const VerticalSpace(8),
        MenuItem(
          icon: CupertinoIcons.lock,
          label: 'Change password',
          onTap: () => _changePassword(context),
        ),
        if (user.isAdmin) ...[
          const VerticalSpace(32),
          const SectionHeader(title: 'ADMIN'),
          const VerticalSpace(12),
          MenuItem(
            icon: CupertinoIcons.person_3,
            label: 'Users and usage',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => AdminScreen(auth: auth)),
            ),
          ),
        ],
        const VerticalSpace(32),
        LogoutButton(onTap: auth.signOut),
        const VerticalSpace(DesignTokens.spaceLarge),
        Center(
          child: TextButton(
            onPressed: () => _deleteAccount(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: const Text('Delete account'),
          ),
        ),
        const AppText(
          'Deletes your account and your own lists. Lists others shared with '
          'you stay with them.',
          fontSize: 12,
          color: AppColors.mutedForeground,
          textAlign: TextAlign.center,
        ),
        const VerticalSpace(32),
        const VersionDisplay(version: 'Version 1.0.0'),
      ],
    );
  }
}
