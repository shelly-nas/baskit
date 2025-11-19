import 'package:flutter/material.dart';

/// Atomic progress bar component
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color backgroundColor;
  final Color valueColor;
  final double height;
  final double borderRadius;

  const AppProgressBar({
    super.key,
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
    this.height = 6,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(valueColor),
      ),
    );
  }
}
