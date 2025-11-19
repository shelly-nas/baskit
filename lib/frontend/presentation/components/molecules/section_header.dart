import 'package:flutter/material.dart';
import '../atoms/app_text.dart';

/// Molecular component for section headers
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppText(
      title,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF787774),
    );
  }
}
