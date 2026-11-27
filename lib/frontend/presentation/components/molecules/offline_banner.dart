import 'package:flutter/cupertino.dart';

import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// Tells the user the lists are used without a connection, and how many
/// changes are still waiting to be sent.
class OfflineBanner extends StatelessWidget {
  final int pending;

  const OfflineBanner({super.key, required this.pending});

  @override
  Widget build(BuildContext context) {
    final waiting = switch (pending) {
      0 => '',
      1 => ' 1 change waiting.',
      _ => ' $pending changes waiting.',
    };
    return Container(
      width: double.infinity,
      color: AppColors.warningBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceXLarge,
        vertical: DesignTokens.spaceSmall,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const AppIcon(
              CupertinoIcons.wifi_slash,
              size: DesignTokens.iconSmall,
              color: AppColors.warning,
            ),
            const SizedBox(width: DesignTokens.spaceSmall),
            Expanded(
              child: AppText(
                'Offline: changes are kept on this device and sent when you '
                'are back online.$waiting',
                fontSize: 13,
                color: AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
