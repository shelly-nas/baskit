import 'package:flutter/material.dart';
import '../../models/shopping_list.dart';
import '../atoms/app_progress_bar.dart';
import '../atoms/spacing.dart';
import '../molecules/list_card_header.dart';
import '../molecules/list_card_info.dart';

/// Organism component for shopping list card
class ShoppingListCardComponent extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback? onTap;

  const ShoppingListCardComponent({super.key, required this.list, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9E9E7), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListCardHeader(name: list.name, isShared: list.isShared),
                const VerticalSpace(4),
                ListCardInfo(
                  completedItems: list.completedItems,
                  totalItems: list.itemCount,
                ),
                const VerticalSpace(12),
                AppProgressBar(
                  value: list.completionPercentage,
                  backgroundColor: const Color(0xFFF1F1EF),
                  valueColor: const Color(0xFF37352F),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
