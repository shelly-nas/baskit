import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../components/atoms/spacing.dart';
import '../components/atoms/app_text.dart';

/// Forgot Password Screen
/// Allows users to request a password reset email
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().forgotPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        setState(() => _submitted = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to send reset email'),
            backgroundColor: AppColors.destructive,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: AppColors.destructive,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          tooltip: 'Back to login',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const AppText(
          'Reset Password',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.foreground,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.space3XLarge),
            child: _submitted ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            CupertinoIcons.lock_rotation,
            size: 72,
            color: AppColors.primary,
          ),
          const VerticalSpace(DesignTokens.space3XLarge),

          const AppText(
            'Forgot your password?',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
            textAlign: TextAlign.center,
          ),
          const VerticalSpace(DesignTokens.spaceSmall),

          const AppText(
            'Enter your email address and we will send you a link to reset your password.',
            fontSize: 15,
            color: AppColors.mutedForeground,
            textAlign: TextAlign.center,
          ),
          const VerticalSpace(DesignTokens.space3XLarge),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              prefixIcon: const Icon(CupertinoIcons.mail),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const VerticalSpace(DesignTokens.spaceXLarge),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryForeground,
                        ),
                      ),
                    )
                  : const AppText(
                      'Send Reset Link',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryForeground,
                    ),
            ),
          ),
          const VerticalSpace(DesignTokens.spaceLarge),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText(
              'Back to Sign In',
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          CupertinoIcons.checkmark_circle,
          size: 72,
          color: AppColors.primary,
        ),
        const VerticalSpace(DesignTokens.space3XLarge),

        const AppText(
          'Check your inbox',
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.foreground,
          textAlign: TextAlign.center,
        ),
        const VerticalSpace(DesignTokens.spaceSmall),

        const AppText(
          'If an account exists with this email, you will receive a password reset link.',
          fontSize: 15,
          color: AppColors.mutedForeground,
          textAlign: TextAlign.center,
        ),
        const VerticalSpace(DesignTokens.space3XLarge),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
            ),
            child: const AppText(
              'Back to Sign In',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryForeground,
            ),
          ),
        ),
      ],
    );
  }
}
