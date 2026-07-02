import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_approve_button.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_reject_button.dart';

class ApproveRejectBar extends StatelessWidget {
  const ApproveRejectBar({
    super.key,
    required this.rejectLabel,
    required this.approveLabel,
    required this.onReject,
    required this.onApprove,
    this.showReject = true,
    this.showApprove = true,
    this.enabled = true,
    this.height = 44,
  });

  final String rejectLabel;
  final String approveLabel;
  final VoidCallback onReject;
  final VoidCallback onApprove;
  final bool showReject;
  final bool showApprove;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showReject)
          Expanded(
            child: RegistrationRejectButton(
              label: rejectLabel,
              onPressed: onReject,
              enabled: enabled,
              height: height,
            ),
          ),
        if (showReject && showApprove) AppSpacing.hGapSm,
        if (showApprove)
          Expanded(
            child: RegistrationApproveButton(
              label: approveLabel,
              onPressed: onApprove,
              enabled: enabled,
              height: height,
            ),
          ),
      ],
    );
  }
}
