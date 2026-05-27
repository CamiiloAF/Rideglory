import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailCopyButton extends StatelessWidget {
  const VehicleDetailCopyButton({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: text)),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.content_copy, size: 14, color: AppColors.textOnDarkSecondary),
      ),
    );
  }
}
