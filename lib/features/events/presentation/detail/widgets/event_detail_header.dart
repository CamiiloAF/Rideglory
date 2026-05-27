import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_background.dart';

class EventDetailHeader extends StatelessWidget {
  const EventDetailHeader({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      width: double.infinity,
      child: EventDetailHeaderBackground(event: event),
    );
  }
}
