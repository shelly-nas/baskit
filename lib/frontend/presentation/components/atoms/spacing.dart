import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';

/// Atomic spacing components for consistent layout spacing
class VerticalSpace extends StatelessWidget {
  final double height;

  const VerticalSpace(this.height, {super.key});

  const VerticalSpace.xSmall({super.key}) : height = DesignTokens.spaceXSmall;
  const VerticalSpace.small({super.key}) : height = DesignTokens.spaceSmall;
  const VerticalSpace.medium({super.key}) : height = DesignTokens.spaceMedium;
  const VerticalSpace.large({super.key}) : height = DesignTokens.spaceLarge;
  const VerticalSpace.xLarge({super.key}) : height = DesignTokens.spaceXLarge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

class HorizontalSpace extends StatelessWidget {
  final double width;

  const HorizontalSpace(this.width, {super.key});

  const HorizontalSpace.xSmall({super.key}) : width = DesignTokens.spaceXSmall;
  const HorizontalSpace.small({super.key}) : width = DesignTokens.spaceSmall;
  const HorizontalSpace.medium({super.key}) : width = DesignTokens.spaceMedium;
  const HorizontalSpace.large({super.key}) : width = DesignTokens.spaceLarge;
  const HorizontalSpace.xLarge({super.key}) : width = DesignTokens.spaceXLarge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width);
  }
}
