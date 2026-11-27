import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../backend/models/favorite.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// Favorites that are not open on the list yet; tapping one puts it on.
class FavoritesBar extends StatelessWidget {
  final List<Favorite> favorites;
  final ValueChanged<Favorite> onAdd;

  const FavoritesBar({super.key, required this.favorites, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Favorites',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(height: DesignTokens.spaceSmall),
          Wrap(
            spacing: DesignTokens.spaceSmall,
            runSpacing: DesignTokens.spaceSmall,
            children: [
              for (final favorite in favorites)
                // A chip reads as a checkbox to screen readers; this is a
                // button that puts the favorite on the list.
                Semantics(
                  // Its own node, not merged with the title or other chips.
                  container: true,
                  button: true,
                  label: 'Add ${favorite.name}',
                  onTap: () => onAdd(favorite),
                  excludeSemantics: true,
                  child: ActionChip(
                    avatar: const AppIcon(
                      CupertinoIcons.add,
                      size: DesignTokens.iconSmall,
                      color: AppColors.mutedForeground,
                    ),
                    label: Text(favorite.name),
                    backgroundColor: AppColors.secondary,
                    side: BorderSide.none,
                    onPressed: () => onAdd(favorite),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
