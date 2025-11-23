import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_divider.dart';
import '../molecules/preference_item.dart';
import '../molecules/preference_toggle.dart';

/// Organism component for preferences section
class PreferencesSection extends StatelessWidget {
  final String defaultStoreValue;
  final String priceAlertValue;
  final bool shoppingReminderValue;
  final VoidCallback onDefaultStoreTap;
  final VoidCallback onPriceAlertTap;
  final ValueChanged<bool> onShoppingReminderChanged;

  const PreferencesSection({
    super.key,
    required this.defaultStoreValue,
    required this.priceAlertValue,
    required this.shoppingReminderValue,
    required this.onDefaultStoreTap,
    required this.onPriceAlertTap,
    required this.onShoppingReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: AppColors.border,
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        children: [
          PreferenceItem(
            label: 'Default Store Layout',
            value: defaultStoreValue,
            onTap: onDefaultStoreTap,
          ),
          const AppDivider(height: 1, color: AppColors.border),
          PreferenceItem(
            label: 'Price Alert Threshold',
            value: priceAlertValue,
            onTap: onPriceAlertTap,
          ),
          const AppDivider(height: 1, color: AppColors.border),
          PreferenceToggle(
            label: 'Shopping Reminder',
            value: shoppingReminderValue,
            onChanged: onShoppingReminderChanged,
          ),
        ],
      ),
    );
  }
}
