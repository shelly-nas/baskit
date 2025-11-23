import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// Molecular component for shopping list header
class ListHeader extends StatelessWidget {
  final String title;
  final bool showAddButton;
  final VoidCallback? onAddPressed;

  const ListHeader({
    super.key,
    required this.title,
    this.showAddButton = true,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          title,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.foreground,
        ),
        if (showAddButton)
          IconButton(
            icon: const AppIcon(
              CupertinoIcons.add_circled_solid,
              size: DesignTokens.iconXLarge,
              color: AppColors.foreground,
            ),
            onPressed: onAddPressed ?? () {},
          ),
      ],
    );
  }
}
