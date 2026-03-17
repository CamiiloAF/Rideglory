import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';

class RegistrationWithEvent {
  const RegistrationWithEvent({
    required this.registration,
    this.event,
  });

  final EventRegistrationModel registration;
  final EventModel? event;
}
