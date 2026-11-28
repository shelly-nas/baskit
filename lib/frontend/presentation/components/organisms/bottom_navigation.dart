import 'dart:ui';

import 'package:flutter/cupertino.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../molecules/bottom_nav_item.dart';

/// The tab bar in Apple's "Liquid Glass" style: a floating, translucent pill
/// over the blurred content, which scrolls on underneath it (the screen sets
/// `extendBody`).
class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: DesignTokens.spaceMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2XLarge,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.glassShadow,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: DesignTokens.glassBlur,
                    sigmaY: DesignTokens.glassBlur,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceSmall),
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusPill,
                      ),
                      border: Border.all(
                        color: AppColors.glassEdge,
                        width: DesignTokens.borderThin,
                      ),
                    ),
                    child: Row(
                      children: [
                        BottomNavItem(
                          icon: CupertinoIcons.search,
                          selectedIcon: CupertinoIcons.search,
                          label: 'Search',
                          isSelected: selectedIndex == 0,
                          onTap: () => onItemTapped(0),
                        ),
                        BottomNavItem(
                          icon: CupertinoIcons.list_bullet,
                          selectedIcon: CupertinoIcons.square_list_fill,
                          label: 'Lists',
                          isSelected: selectedIndex == 1,
                          onTap: () => onItemTapped(1),
                        ),
                        BottomNavItem(
                          icon: CupertinoIcons.person,
                          selectedIcon: CupertinoIcons.person_fill,
                          label: 'Profile',
                          isSelected: selectedIndex == 2,
                          onTap: () => onItemTapped(2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
