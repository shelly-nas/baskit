import 'package:flutter/cupertino.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
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
          backgroundColor: AppColors.secondary,
          iconColor: AppColors.mutedForeground,
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
                color: AppColors.foreground,
              ),
              const VerticalSpace(DesignTokens.spaceSmall),
              AppText(email, fontSize: 14, color: AppColors.mutedForeground),
              const VerticalSpace(DesignTokens.spaceMedium),
              AppBadge(
                text: badgeText,
                backgroundColor: AppColors.primary,
                textColor: AppColors.primaryForeground,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
