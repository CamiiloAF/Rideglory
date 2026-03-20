import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class ApproveRejectBar extends StatelessWidget {
  const ApproveRejectBar({
    super.key,
    required this.rejectLabel,
    required this.approveLabel,
    required this.onReject,
    required this.onApprove,
  });

  final String rejectLabel;
  final String approveLabel;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: rejectLabel,
            icon: Icons.close_rounded,
            onPressed: onReject,
            variant: AppButtonVariant.danger,
            style: AppButtonStyle.outlined,
            isFullWidth: true,
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: AppButton(
            label: approveLabel,
            icon: Icons.check_rounded,
            onPressed: onApprove,
            variant: AppButtonVariant.success,
            style: AppButtonStyle.outlined,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}
