import 'package:flutter/foundation.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';

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
