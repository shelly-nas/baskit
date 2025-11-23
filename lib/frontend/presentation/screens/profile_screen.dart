import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components/atoms/spacing.dart';
import '../components/molecules/section_header.dart';
import '../components/molecules/menu_item.dart';
import '../components/organisms/user_info_section.dart';
import '../components/organisms/savings_summary.dart';
import '../components/organisms/preferences_section.dart';
import '../components/organisms/logout_button.dart';
import '../components/organisms/version_display.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UserInfoSection(name: '', email: '', badgeText: ''),
            const VerticalSpace(24),
            const SavingsSummary(
              totalSavings: '\$0.00',
              membershipDuration: '',
            ),
            const VerticalSpace(32),
            const SectionHeader(title: 'ACCOUNT'),
            const VerticalSpace(12),
            MenuItem(
              icon: CupertinoIcons.settings,
              label: 'Account Settings',
              onTap: () {},
            ),
            const VerticalSpace(8),
            MenuItem(
              icon: CupertinoIcons.bell,
              label: 'Notifications',
              onTap: () {},
            ),
            const VerticalSpace(8),
            MenuItem(
              icon: CupertinoIcons.creditcard,
              label: 'Payment & Subscription',
              onTap: () {},
            ),
            const VerticalSpace(8),
            MenuItem(
              icon: CupertinoIcons.person_2,
              label: 'Household Members',
              onTap: () {},
            ),
            const VerticalSpace(32),
            const SectionHeader(title: 'PREFERENCES'),
            const VerticalSpace(12),
            PreferencesSection(
              defaultStoreValue: '',
              priceAlertValue: '',
              shoppingReminderValue: false,
              onDefaultStoreTap: () {},
              onPriceAlertTap: () {},
              onShoppingReminderChanged: (value) {},
            ),
            const VerticalSpace(32),
            const SectionHeader(title: 'SUPPORT'),
            const VerticalSpace(12),
            MenuItem(
              icon: CupertinoIcons.question_circle,
              label: 'Help Center',
              onTap: () {},
            ),
            const VerticalSpace(32),
            LogoutButton(onTap: () {}),
            const VerticalSpace(32),
            const VersionDisplay(version: 'Version 1.0.0'),
            const VerticalSpace(16),
          ],
        ),
      ),
    );
  }
}
