import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class RegistrationDetailExtra {
  const RegistrationDetailExtra({
    required this.registration,
    this.eventOwnerId,
    this.onCancelRegistration,
    this.onApprove,
    this.onReject,
  });

  final EventRegistrationModel registration;
  final String? eventOwnerId;
  final Future<bool> Function()? onCancelRegistration;
  final void Function(BuildContext context)? onApprove;
  final void Function(BuildContext context)? onReject;
}
