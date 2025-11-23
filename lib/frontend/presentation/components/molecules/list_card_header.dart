import 'package:flutter/cupertino.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';
import '../atoms/spacing.dart';

/// Molecular component for list card header
class ListCardHeader extends StatelessWidget {
  final String name;
  final bool isShared;

  const ListCardHeader({super.key, required this.name, required this.isShared});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              AppText(
                name,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
              if (isShared) ...[
                const HorizontalSpace.medium(),
                const AppIcon(
                  CupertinoIcons.person_2,
                  size: DesignTokens.iconSmall,
                  color: AppColors.mutedForeground,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
