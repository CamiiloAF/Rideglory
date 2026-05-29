import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

abstract final class AttendeeActionConfirmation {
  AttendeeActionConfirmation._();

  static Future<bool?> showApprove(
    BuildContext context, {
    required String participantName,
    required VoidCallback onConfirm,
  }) => ConfirmationDialog.show(
    context: context,
    title: context.l10n.event_approveRegistration,
    content: context.l10n.event_approveConfirmMessage(participantName),
    dialogType: DialogType.warning,
    confirmLabel: context.l10n.event_approveRegistration,
    onConfirm: onConfirm,
  );

  static Future<bool?> showReject(
    BuildContext context, {
    required String participantName,
    required VoidCallback onConfirm,
  }) => ConfirmationDialog.show(
    context: context,
    title: context.l10n.event_rejectRegistration,
    content: context.l10n.event_rejectConfirmMessage(participantName),
    confirmType: DialogActionType.danger,
    confirmLabel: context.l10n.event_rejectRegistration,
    onConfirm: onConfirm,
  );

  static Future<bool?> showRequestEdit(
    BuildContext context, {
    required String participantName,
    required VoidCallback onConfirm,
  }) => ConfirmationDialog.show(
    context: context,
    title: context.l10n.registration_requestEditConfirmTitle,
    content: context.l10n.registration_requestEditConfirmMessage(
      participantName,
    ),
    dialogType: DialogType.warning,
    confirmLabel: context.l10n.registration_requestEdit,
    onConfirm: onConfirm,
  );
}
