import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
            // User Info
            Container(
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE9E9E7), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1EF),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      CupertinoIcons.person,
                      size: 32,
                      color: Color(0xFF787774),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sarah Johnson',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF37352F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'sarah.j@email.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF787774),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF37352F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Premium Member',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Savings Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Total Savings',
                    style: TextStyle(fontSize: 14, color: Color(0xFF787774)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '\$1,247.50',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF37352F),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Since joining 3 months ago',
                    style: TextStyle(fontSize: 12, color: Color(0xFF787774)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Account Settings Section
            const Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF787774),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: CupertinoIcons.settings,
              label: 'Account Settings',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: CupertinoIcons.bell,
              label: 'Notifications',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: CupertinoIcons.creditcard,
              label: 'Payment & Subscription',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: CupertinoIcons.person_2,
              label: 'Household Members',
              onTap: () {},
            ),
            const SizedBox(height: 32),

            // Preferences Section
            const Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF787774),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE9E9E7), width: 1),
              ),
              child: Column(
                children: [
                  _buildPreferenceItem(
                    label: 'Default Store Layout',
                    value: 'Whole Foods',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Color(0xFFE9E9E7)),
                  _buildPreferenceItem(
                    label: 'Price Alert Threshold',
                    value: '10%',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Color(0xFFE9E9E7)),
                  _buildPreferenceToggle(
                    label: 'Shopping Reminder',
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Support Section
            const Text(
              'SUPPORT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF787774),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: CupertinoIcons.question_circle,
              label: 'Help Center',
              onTap: () {},
            ),
            const SizedBox(height: 32),

            // Logout Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCCCC), width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.square_arrow_right,
                          size: 20,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Version
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Color(0xFF787774)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9E9E7), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF787774)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF37352F),
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: Color(0xFF787774),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF37352F)),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF787774)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF37352F)),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF37352F),
          ),
        ],
      ),
    );
  }
}
