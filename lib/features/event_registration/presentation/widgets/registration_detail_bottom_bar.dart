import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/constants/registration_strings.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/design_system/design_system.dart';

class RegistrationDetailBottomBar extends StatelessWidget {
  const RegistrationDetailBottomBar({super.key, required this.params});

  final RegistrationDetailExtra params;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, math.max(16, bottomPadding)),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (params.onCancelRegistration != null)
              AppButton(
                label: RegistrationStrings.cancelRegistration,
                variant: AppButtonVariant.danger,
                onPressed: () async {
                  final ok = await params.onCancelRegistration!();
                  if (ok && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                isFullWidth: false,
              )
            else if (params.onReject != null && params.onApprove != null)
              Expanded(
                child: ApproveRejectBar(
                  rejectLabel: RegistrationStrings.reject,
                  approveLabel: RegistrationStrings.approve,
                  onReject: () => params.onReject!(context),
                  onApprove: () => params.onApprove!(context),
                ),
              )
            else ...[
              if (params.onReject != null)
                AppButton(
                  label: RegistrationStrings.reject,
                  variant: AppButtonVariant.danger,
                  icon: Icons.close_rounded,
                  onPressed: () => params.onReject!(context),
                  isFullWidth: false,
                ),
              if (params.onApprove != null)
                AppButton(
                  label: RegistrationStrings.approve,
                  variant: AppButtonVariant.primary,
                  icon: Icons.check_rounded,
                  onPressed: () => params.onApprove!(context),
                  isFullWidth: false,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
