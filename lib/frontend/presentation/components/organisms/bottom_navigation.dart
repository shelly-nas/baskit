import 'package:flutter/cupertino.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../molecules/bottom_nav_item.dart';

/// Organism component for bottom navigation bar
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: DesignTokens.borderThin,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              BottomNavItem(
                icon: CupertinoIcons.search,
                label: 'Search',
                isSelected: selectedIndex == 0,
                onTap: () => onItemTapped(0),
              ),
              BottomNavItem(
                icon: CupertinoIcons.list_bullet,
                label: 'Lists',
                isSelected: selectedIndex == 1,
                onTap: () => onItemTapped(1),
              ),
              BottomNavItem(
                icon: CupertinoIcons.person,
                label: 'Profile',
                isSelected: selectedIndex == 2,
                onTap: () => onItemTapped(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
