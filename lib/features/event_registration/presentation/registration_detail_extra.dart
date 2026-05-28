import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class RegistrationDetailExtra {
  const RegistrationDetailExtra({
    required this.registration,
    this.eventOwnerId,
    this.onCancelRegistration,
    this.onApprove,
    this.onReject,
    this.onRequestEdit,
    this.onEditRegistration,
  });

  final EventRegistrationModel registration;
  final String? eventOwnerId;
  final Future<bool> Function()? onCancelRegistration;
  final void Function(BuildContext context)? onApprove;
  final void Function(BuildContext context)? onReject;

  /// Organizador: habilita la edición de la inscripción del piloto
  /// (estado READY_FOR_EDIT).
  final void Function(BuildContext context)? onRequestEdit;

  /// Piloto: abre el formulario para editar su propia inscripción.
  final void Function(BuildContext context)? onEditRegistration;
}
