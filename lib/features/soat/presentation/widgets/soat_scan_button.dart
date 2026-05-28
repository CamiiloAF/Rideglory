import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class SoatScanButton extends StatelessWidget {
  const SoatScanButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: context.l10n.soat_scan_button,
      icon: Icons.auto_fix_high_rounded,
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      variant: AppButtonVariant.primary,
      style: AppButtonStyle.outlined,
    );
  }
}
