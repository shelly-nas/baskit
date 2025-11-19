import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../atoms/app_text.dart';

/// Molecular component for preference toggle items with switch
class PreferenceToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PreferenceToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(label, fontSize: 14, color: const Color(0xFF37352F)),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF37352F),
          ),
        ],
      ),
    );
  }
}
