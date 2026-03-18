import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

abstract final class AttendeeActionConfirmation {
  AttendeeActionConfirmation._();

  static Future<bool?> showApprove(
    BuildContext context, {
    required String firstName,
    required VoidCallback onConfirm,
  }) =>
      ConfirmationDialog.show(
        context: context,
        title: context.l10n.event_approveRegistration,
        content: context.l10n.event_approveConfirmMessage(firstName),
        dialogType: DialogType.warning,
        confirmLabel: context.l10n.event_approveRegistration,
        onConfirm: onConfirm,
      );

  static Future<bool?> showReject(
    BuildContext context, {
    required String firstName,
    required VoidCallback onConfirm,
  }) =>
      ConfirmationDialog.show(
        context: context,
        title: context.l10n.event_rejectRegistration,
        content: context.l10n.event_rejectConfirmMessage(firstName),
        dialogType: DialogType.warning,
        confirmLabel: context.l10n.event_rejectRegistration,
        onConfirm: onConfirm,
      );
}
