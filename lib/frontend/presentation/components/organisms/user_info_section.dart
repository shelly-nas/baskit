import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../molecules/profile_header.dart';

/// Organism component for user info section
class UserInfoSection extends StatelessWidget {
  final String name;
  final String email;
  final String badgeText;

  const UserInfoSection({
    super.key,
    required this.name,
    required this.email,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2XLarge),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: DesignTokens.borderThin,
          ),
        ),
      ),
      child: ProfileHeader(name: name, email: email, badgeText: badgeText),
    );
  }
}
