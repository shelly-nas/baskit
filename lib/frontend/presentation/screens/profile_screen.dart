import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../services/token_storage_service.dart';
import '../components/atoms/app_text.dart';
import '../components/atoms/spacing.dart';
import '../components/molecules/section_header.dart';
import '../components/molecules/menu_item.dart';
import '../components/organisms/user_info_section.dart';
import '../components/organisms/savings_summary.dart';
import '../components/organisms/preferences_section.dart';
import '../components/organisms/logout_button.dart';
import '../components/organisms/version_display.dart';
import 'auth_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _displayName = '';
  String _email = '';
  String _subscriptionTier = 'free';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tokenStorage = TokenStorageService();
      final accessToken = await tokenStorage.getAccessToken();

      if (accessToken == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please log in again.';
        });
        return;
      }

      // Try loading cached user info first for a fast initial render
      final cachedInfo = await tokenStorage.getUserInfo();
      if (mounted) {
        setState(() {
          _displayName = cachedInfo['displayName'] ?? '';
          _email = cachedInfo['email'] ?? '';
        });
      }

      // Then fetch the full profile from the backend
      final result = await AuthService().getProfile(accessToken: accessToken);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final user = data?['user'] as Map<String, dynamic>?;
        setState(() {
          _isLoading = false;
          _displayName = user?['displayName'] as String? ?? _displayName;
          _email = user?['email'] as String? ?? _email;
          _subscriptionTier = user?['subscriptionTier'] as String? ?? 'free';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] as String?;
        });
        if (_errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: AppColors.destructive,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: ${e.toString()}'),
          backgroundColor: AppColors.destructive,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AppText(
          'Log Out',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        content: const AppText(
          'Are you sure you want to log out?',
          fontSize: 15,
          color: AppColors.mutedForeground,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const AppText(
              'Cancel',
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const AppText(
              'Log Out',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.destructive,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final tokenStorage = TokenStorageService();
      final accessToken = await tokenStorage.getAccessToken();
      final refreshToken = await tokenStorage.getRefreshToken();

      if (accessToken != null) {
        await AuthService().logout(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      await tokenStorage.clearAll();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: AppColors.destructive,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spaceLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserInfoSection(
                    name: _displayName,
                    email: _email,
                    badgeText: _subscriptionTier,
                  ),
                  const VerticalSpace(DesignTokens.spaceXLarge),
                  const SavingsSummary(
                    totalSavings: '\$0.00',
                    membershipDuration: '',
                  ),
                  const VerticalSpace(DesignTokens.space3XLarge),
                  const SectionHeader(title: 'ACCOUNT'),
                  const VerticalSpace(DesignTokens.spaceMedium),
                  MenuItem(
                    icon: CupertinoIcons.settings,
                    label: 'Account Settings',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _StubScreen(
                          title: 'Account Settings',
                        ),
                      ),
                    ),
                  ),
                  const VerticalSpace(DesignTokens.spaceSmall),
                  MenuItem(
                    icon: CupertinoIcons.bell,
                    label: 'Notifications',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _StubScreen(
                          title: 'Notifications',
                        ),
                      ),
                    ),
                  ),
                  const VerticalSpace(DesignTokens.spaceSmall),
                  MenuItem(
                    icon: CupertinoIcons.creditcard,
                    label: 'Payment & Subscription',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _StubScreen(
                          title: 'Payment & Subscription',
                        ),
                      ),
                    ),
                  ),
                  const VerticalSpace(DesignTokens.spaceSmall),
                  MenuItem(
                    icon: CupertinoIcons.lock,
                    label: 'Change Password',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                  const VerticalSpace(DesignTokens.spaceSmall),
                  MenuItem(
                    icon: CupertinoIcons.person_2,
                    label: 'Household Members',
                    onTap: () {},
                  ),
                  const VerticalSpace(DesignTokens.space3XLarge),
                  const SectionHeader(title: 'PREFERENCES'),
                  const VerticalSpace(DesignTokens.spaceMedium),
                  PreferencesSection(
                    defaultStoreValue: '',
                    priceAlertValue: '',
                    shoppingReminderValue: false,
                    onDefaultStoreTap: () {},
                    onPriceAlertTap: () {},
                    onShoppingReminderChanged: (value) {},
                  ),
                  const VerticalSpace(DesignTokens.space3XLarge),
                  const SectionHeader(title: 'SUPPORT'),
                  const VerticalSpace(DesignTokens.spaceMedium),
                  MenuItem(
                    icon: CupertinoIcons.question_circle,
                    label: 'Help Center',
                    onTap: () {},
                  ),
                  const VerticalSpace(DesignTokens.space3XLarge),
                  LogoutButton(onTap: _handleLogout),
                  const VerticalSpace(DesignTokens.space3XLarge),
                  const VersionDisplay(version: 'Version 1.0.0'),
                  const VerticalSpace(DesignTokens.spaceLarge),
                ],
              ),
            ),
    );
  }
}

/// Stub screen used as placeholder for unimplemented sections
class _StubScreen extends StatelessWidget {
  final String title;

  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          title,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.foreground,
      ),
      backgroundColor: AppColors.background,
      body: const Center(
        child: AppText(
          'Coming soon',
          fontSize: 16,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }
}
