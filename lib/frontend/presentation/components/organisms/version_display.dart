import 'package:flutter/material.dart';
import '../atoms/app_text.dart';

/// Organism component for version display
class VersionDisplay extends StatelessWidget {
  final String version;

  const VersionDisplay({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppText(version, fontSize: 12, color: const Color(0xFF787774)),
    );
  }
}
