import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

abstract final class AttendeeActionConfirmation {
  AttendeeActionConfirmation._();

  static Future<bool?> showApprove(
    BuildContext context, {
    required String firstName,
    required VoidCallback onConfirm,
  }) =>
      ConfirmationDialog.show(
        context: context,
        title: EventStrings.approveRegistration,
        content: EventStrings.approveConfirmMessage(firstName),
        dialogType: DialogType.warning,
        confirmLabel: EventStrings.approveRegistration,
        onConfirm: onConfirm,
      );

  static Future<bool?> showReject(
    BuildContext context, {
    required String firstName,
    required VoidCallback onConfirm,
  }) =>
      ConfirmationDialog.show(
        context: context,
        title: EventStrings.rejectRegistration,
        content: EventStrings.rejectConfirmMessage(firstName),
        dialogType: DialogType.warning,
        confirmLabel: EventStrings.rejectRegistration,
        onConfirm: onConfirm,
      );
}
