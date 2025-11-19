import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_text.dart';
import '../atoms/spacing.dart';

/// Molecular component for profile header with avatar and info
class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String badgeText;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppAvatar(
          icon: CupertinoIcons.person,
          backgroundColor: Color(0xFFF1F1EF),
          iconColor: Color(0xFF787774),
        ),
        const HorizontalSpace.xLarge(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                name,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF37352F),
              ),
              const VerticalSpace(4),
              AppText(email, fontSize: 14, color: const Color(0xFF787774)),
              const VerticalSpace(8),
              AppBadge(
                text: badgeText,
                backgroundColor: const Color(0xFF37352F),
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
