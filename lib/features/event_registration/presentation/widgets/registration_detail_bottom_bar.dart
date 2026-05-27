import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class RegistrationDetailBottomBar extends StatelessWidget {
  const RegistrationDetailBottomBar({super.key, required this.params});

  final RegistrationDetailExtra params;

  @override
  Widget build(BuildContext context) {
    final registration = params.registration;
    final ownerSuppressed = params.eventOwnerId != null &&
        params.eventOwnerId == registration.userId;
    final showCancel =
        params.onCancelRegistration != null && !ownerSuppressed;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(
          top: BorderSide(color: AppColors.darkBorderPrimary),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, math.max(16, bottomPadding)),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showCancel)
              Expanded(
                child: AppButton(
                  label: context.l10n.registration_cancelRegistration,
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    final ok = await params.onCancelRegistration!();
                    if (ok && context.mounted) {
                      context.pop();
                    }
                  },
                  isFullWidth: true,
                ),
              )
            else if (params.onReject != null && params.onApprove != null)
              Expanded(
                child: ApproveRejectBar(
                  rejectLabel: context.l10n.registration_reject,
                  approveLabel: context.l10n.registration_approve,
                  onReject: () => params.onReject!(context),
                  onApprove: () => params.onApprove!(context),
                ),
              )
            else ...[
              if (params.onReject != null)
                Expanded(
                  child: AppButton(
                    label: context.l10n.registration_reject,
                    variant: AppButtonVariant.danger,
                    icon: Icons.close_rounded,
                    onPressed: () => params.onReject!(context),
                    isFullWidth: true,
                  ),
                ),
              if (params.onReject != null && params.onApprove != null)
                AppSpacing.hGapSm,
              if (params.onApprove != null)
                Expanded(
                  child: AppButton(
                    label: context.l10n.registration_approve,
                    variant: AppButtonVariant.primary,
                    icon: Icons.check_rounded,
                    onPressed: () => params.onApprove!(context),
                    isFullWidth: true,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
