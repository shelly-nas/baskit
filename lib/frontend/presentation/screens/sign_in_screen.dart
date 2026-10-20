import 'package:flutter/material.dart';
import '../../../database/data_sources/baskit_api_client.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../components/atoms/app_text.dart';
import '../components/atoms/spacing.dart';
import '../controllers/auth_controller.dart';

/// First screen without a stored sign-in: sign in or create an account.
class SignInScreen extends StatelessWidget {
  final AuthController auth;

  const SignInScreen({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
              child: ListenableBuilder(
                listenable: auth,
                builder: (context, _) => _SignInForm(auth: auth),
              ),
            ),
          ),
        ),
      ),
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
          const AppText('Baskit', fontSize: 32, fontWeight: FontWeight.w700),
          const VerticalSpace(DesignTokens.spaceLarge),
          AppText(
            _register ? 'Create an account' : 'Sign in',
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          const VerticalSpace(DesignTokens.spaceSmall),
          const AppText(
            'Your lists are kept in your account, on all your devices, and '
            'can be shared with your household. You stay signed in on this '
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
