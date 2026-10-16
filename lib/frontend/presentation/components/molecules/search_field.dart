import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';

/// Molecular component for a Notion style search input
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;
  final bool autofocus;

  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 15, color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.mutedForeground),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceLarge,
              vertical: DesignTokens.spaceLarge,
            ),
            prefixIcon: const AppIcon(
              CupertinoIcons.search,
              size: DesignTokens.iconMedium,
              color: AppColors.mutedForeground,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const AppIcon(
                      CupertinoIcons.clear_circled_solid,
                      size: DesignTokens.iconMedium,
                      color: AppColors.mutedForeground,
                    ),
                    onPressed: onClear,
                  ),
          ),
        );
      },
    );
  }
}
