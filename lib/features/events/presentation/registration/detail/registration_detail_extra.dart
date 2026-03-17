import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';

/// Extra data for [RegistrationDetailPage] navigation.
class RegistrationDetailExtra {
  const RegistrationDetailExtra({
    required this.registration,
    this.onCancelRegistration,
    this.onApprove,
    this.onReject,
  });

  final EventRegistrationModel registration;
  final Future<bool> Function()? onCancelRegistration;
  /// Called when user taps Aprobar. Receives [BuildContext] to show confirmation and pop.
  final void Function(BuildContext context)? onApprove;
  /// Called when user taps Rechazar. Receives [BuildContext] to show confirmation and pop.
  final void Function(BuildContext context)? onReject;
}
