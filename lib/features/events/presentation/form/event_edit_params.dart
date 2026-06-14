import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventEditParams {
  const EventEditParams({required this.event, this.onSaved});

  final EventModel event;
  final void Function(EventModel)? onSaved;
}
