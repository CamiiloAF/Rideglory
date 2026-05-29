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
    final ownerSuppressed =
        params.eventOwnerId != null &&
        params.eventOwnerId == registration.userId;
    final showCancel = params.onCancelRegistration != null && !ownerSuppressed;
    final showApproveReject =
        params.onApprove != null || params.onReject != null;

    final actions = _buildActions(
      context,
      showApproveReject: showApproveReject,
      showCancel: showCancel,
    );
    if (actions.isEmpty) return const SizedBox.shrink();

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, math.max(16, bottomPadding)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions,
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context, {
    required bool showApproveReject,
    required bool showCancel,
  }) {
    // Vista organizador: aprobar destacado + (rechazar / solicitar edición).
    if (showApproveReject) {
      final secondaryButtons = <Widget>[
        if (params.onReject != null)
          Expanded(
            child: AppButton(
              label: context.l10n.registration_reject,
              icon: Icons.cancel_outlined,
              variant: AppButtonVariant.danger,
              style: AppButtonStyle.tonal,
              shape: AppButtonShape.pill,
              onPressed: () => params.onReject!(context),
              isFullWidth: true,
            ),
          ),
        if (params.onReject != null && params.onRequestEdit != null)
          AppSpacing.hGapSm,
        if (params.onRequestEdit != null)
          Expanded(
            child: AppButton(
              label: context.l10n.registration_requestEdit,
              icon: Icons.edit_outlined,
              variant: AppButtonVariant.secondary,
              style: AppButtonStyle.outlined,
              onPressed: () => params.onRequestEdit!(context),
              isFullWidth: true,
            ),
          ),
      ];

      return [
        if (params.onApprove != null)
          AppButton(
            label: context.l10n.registration_approve,
            icon: Icons.check_rounded,
            variant: AppButtonVariant.success,
            onPressed: () => params.onApprove!(context),
            isFullWidth: true,
          ),
        if (params.onApprove != null && secondaryButtons.isNotEmpty)
          AppSpacing.gapMd,
        if (secondaryButtons.isNotEmpty) Row(children: secondaryButtons),
      ];
    }

    // Vista piloto: editar + cancelar.
    return [
      if (params.onEditRegistration != null) ...[
        AppButton(
          label: context.l10n.registration_editRegistrationCta,
          icon: Icons.edit_outlined,
          variant: AppButtonVariant.primary,
          onPressed: () => params.onEditRegistration!(context),
          isFullWidth: true,
        ),
        if (showCancel) AppSpacing.gapMd,
      ],
      if (showCancel)
        AppButton(
          label: context.l10n.registration_cancelRegistration,
          variant: AppButtonVariant.danger,
          style: AppButtonStyle.tonal,
          shape: AppButtonShape.pill,
          onPressed: () async {
            final ok = await params.onCancelRegistration!();
            if (ok && context.mounted) {
              context.pop();
            }
          },
          isFullWidth: true,
        ),
    ];
  }
}
