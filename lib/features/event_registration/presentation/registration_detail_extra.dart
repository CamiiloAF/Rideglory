import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class RegistrationDetailExtra {
  const RegistrationDetailExtra({
    required this.registration,
    this.eventOwnerId,
    this.isOrganizerView = false,
    this.eventState,
    this.eventSosTriggeredAt,
    this.onCancelRegistration,
    this.onApprove,
    this.onReject,
    this.onRequestEdit,
    this.onEditRegistration,
  });

  final EventRegistrationModel registration;
  final String? eventOwnerId;

  /// Cuando es `true`, el detalle se abre desde la perspectiva del organizador
  /// (lista de inscritos o detalle del evento). Por defecto `false` para que
  /// los puntos de navegación del piloto (Mis inscripciones) no cambien.
  final bool isOrganizerView;

  /// Estado del evento en el momento de abrir el detalle (para la vista
  /// organizador: relevante para la ofuscación condicional de datos).
  final EventState? eventState;

  /// Marca de tiempo del SOS activo del evento, si lo hay.
  final DateTime? eventSosTriggeredAt;
  final Future<bool> Function()? onCancelRegistration;
  final void Function(BuildContext context)? onApprove;
  final void Function(BuildContext context)? onReject;

  /// Organizador: habilita la edición de la inscripción del piloto
  /// (estado READY_FOR_EDIT).
  final void Function(BuildContext context)? onRequestEdit;

  /// Piloto: abre el formulario para editar su propia inscripción.
  final void Function(BuildContext context)? onEditRegistration;
}
