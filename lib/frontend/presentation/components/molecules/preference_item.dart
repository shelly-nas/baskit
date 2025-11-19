import 'package:flutter/material.dart';
import '../atoms/app_text.dart';

/// Molecular component for preference items with label and value
class PreferenceItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const PreferenceItem({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(label, fontSize: 14, color: const Color(0xFF37352F)),
              AppText(value, fontSize: 14, color: const Color(0xFF787774)),
            ],
          ),
        ),
      ),
    );
  }
}
