import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../atoms/app_text.dart';

/// Molecular component for list card info text
class ListCardInfo extends StatelessWidget {
  final int completedItems;
  final int totalItems;

  const ListCardInfo({
    super.key,
    required this.completedItems,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    return AppText(
      '$completedItems/$totalItems items completed',
      fontSize: 12,
      color: AppColors.mutedForeground,
    );
  }
}
