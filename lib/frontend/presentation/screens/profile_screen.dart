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
              child: auth.isSignedIn
                  ? _AccountView(auth: auth)
                  : _SignInForm(auth: auth),
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
        const VerticalSpace(32),
        const VersionDisplay(version: 'Version 1.0.0'),
      ],
    );
  }
}

class _SignInForm extends StatefulWidget {
  final AuthController auth;

  const _SignInForm({required this.auth});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    try {
      if (_register) {
        await widget.auth.register(
          _email.text.trim(),
          _password.text,
          _name.text.trim(),
        );
      } else {
        await widget.auth.signIn(_email.text.trim(), _password.text);
      }
    } on BaskitApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.auth.isBusy;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            _register ? 'Create an account' : 'Sign in',
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          const VerticalSpace(DesignTokens.spaceSmall),
          const AppText(
            'Sign in to keep your lists on all your devices and share them '
            'with your household. Without an account your lists stay on this '
            'device.',
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
          const VerticalSpace(DesignTokens.space2XLarge),
          if (_register) ...[
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const VerticalSpace(DesignTokens.spaceLarge),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const VerticalSpace(DesignTokens.spaceLarge),
          TextField(
            controller: _password,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: [
              _register ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onSubmitted: (_) => busy ? null : _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: _register ? 'At least 8 characters' : null,
            ),
          ),
          if (_error != null) ...[
            const VerticalSpace(DesignTokens.spaceLarge),
            AppText(_error!, fontSize: 13, color: AppColors.destructive),
          ],
          const VerticalSpace(DesignTokens.space2XLarge),
          ElevatedButton(
            onPressed: busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spaceXLarge,
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryForeground,
                    ),
                  )
                : Text(_register ? 'Create account' : 'Sign in'),
          ),
          const VerticalSpace(DesignTokens.spaceLarge),
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    _register = !_register;
                    _error = null;
                  }),
            child: Text(
              _register
                  ? 'I already have an account'
                  : 'New here? Create an account',
            ),
          ),
        ],
      ),
    );
  }
}
