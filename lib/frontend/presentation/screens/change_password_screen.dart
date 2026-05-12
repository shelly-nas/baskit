import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../services/token_storage_service.dart';
import '../components/atoms/spacing.dart';
import '../components/atoms/app_text.dart';

/// Change Password Screen
/// Allows authenticated users to change their password
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final accessToken = await TokenStorageService().getAccessToken();

      if (accessToken == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: AppColors.destructive,
          ),
        );
        return;
      }

      final result = await AuthService().changePassword(
        accessToken: accessToken,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Password changed successfully'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to change password'),
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

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
      return r'Password must contain at least one special character (@$!%*?&)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const AppText(
          'Change Password',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space3XLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppText(
                  'Choose a new password',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
                const VerticalSpace(DesignTokens.spaceSmall),
                const AppText(
                  'Your new password must be at least 8 characters and include uppercase, lowercase, a number, and a special character.',
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
                const VerticalSpace(DesignTokens.space3XLarge),

                // Current Password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !_isCurrentPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    hintText: 'Enter your current password',
                    prefixIcon: const Icon(CupertinoIcons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isCurrentPasswordVisible
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                      ),
                      tooltip: _isCurrentPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () => setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const VerticalSpace(DesignTokens.spaceLarge),

                // New Password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter your new password',
                    prefixIcon: const Icon(CupertinoIcons.lock_shield),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                      ),
                      tooltip: _isNewPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () => setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                  ),
                  validator: _validateNewPassword,
                ),
                const VerticalSpace(DesignTokens.spaceLarge),

                // Confirm New Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    hintText: 'Re-enter your new password',
                    prefixIcon: const Icon(CupertinoIcons.lock_shield),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                      ),
                      tooltip: _isConfirmPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () => setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      }),
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const VerticalSpace(DesignTokens.spaceXLarge),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMedium),
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
                            'Change Password',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryForeground,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
