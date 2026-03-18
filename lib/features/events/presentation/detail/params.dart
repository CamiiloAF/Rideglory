import 'package:flutter/foundation.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class EventDetailPageParams {
  final EventModel event;
  final ValueChanged<EventRegistrationModel>? onRegistrationChanged;
  final bool isFromEventDetailByIdPage;

  EventDetailPageParams({
    required this.event,
    this.onRegistrationChanged,
    this.isFromEventDetailByIdPage = false,
  });
}

class EventRegistrationParams {
  const EventRegistrationParams({
    required this.event,
    this.registration,
  });

  final EventModel event;
  final EventRegistrationModel? registration;
}
