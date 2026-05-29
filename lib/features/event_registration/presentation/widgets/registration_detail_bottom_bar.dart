import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_approve_button.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_reject_button.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_request_edit_button.dart';
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

    // Regla READY_FOR_EDIT: mientras la inscripción esté en este estado, el
    // organizador SOLO puede rechazarla; no puede aprobar ni volver a solicitar
    // edición. En PENDING dispone de las tres acciones. Solo el piloto (al
    // editar su inscripción) la regresa a PENDING.
    final isReadyForEdit =
        registration.status == RegistrationStatus.readyForEdit;
    final showOwnerActions =
        params.onApprove != null || params.onReject != null;
    final showApprove = !isReadyForEdit && params.onApprove != null;
    final showRequestEdit = !isReadyForEdit && params.onRequestEdit != null;

    final actions = _buildActions(
      context,
      showOwnerActions: showOwnerActions,
      showApprove: showApprove,
      showRequestEdit: showRequestEdit,
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
    required bool showOwnerActions,
    required bool showApprove,
    required bool showRequestEdit,
    required bool showCancel,
  }) {
    // Vista organizador: aprobar destacado + (rechazar / solicitar edición).
    // En READY_FOR_EDIT solo queda rechazar, que entonces ocupa todo el ancho.
    if (showOwnerActions) {
      final secondaryButtons = <Widget>[
        if (params.onReject != null)
          Expanded(
            child: RegistrationRejectButton(
              label: context.l10n.registration_reject,
              onPressed: () => params.onReject!(context),
            ),
          ),
        if (params.onReject != null && showRequestEdit) AppSpacing.hGapSm,
        if (showRequestEdit)
          Expanded(
            child: RegistrationRequestEditButton(
              label: context.l10n.registration_requestEdit,
              onPressed: () => params.onRequestEdit!(context),
            ),
          ),
      ];

      return [
        if (showApprove)
          RegistrationApproveButton(
            label: context.l10n.registration_approve,
            onPressed: () => params.onApprove!(context),
          ),
        if (showApprove && secondaryButtons.isNotEmpty) AppSpacing.gapMd,
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
