import 'package:flutter/material.dart';
import '../atoms/app_text.dart';
import '../atoms/spacing.dart';

/// Organism component for savings summary section
class SavingsSummary extends StatelessWidget {
  final String totalSavings;
  final String membershipDuration;

  const SavingsSummary({
    super.key,
    required this.totalSavings,
    required this.membershipDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Your Total Savings',
            fontSize: 14,
            color: Color(0xFF787774),
          ),
          const VerticalSpace(12),
          AppText(
            totalSavings,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF37352F),
          ),
          const VerticalSpace(8),
          AppText(
            membershipDuration,
            fontSize: 12,
            color: const Color(0xFF787774),
          ),
        ],
      ),
    );
  }
}
