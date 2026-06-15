import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

String _label(BuildContext context, EventModel event) {
  return switch (event.state) {
    EventState.draft => context.l10n.event_draftBadge,
    EventState.scheduled => context.l10n.event_comingSoonPill,
    EventState.inProgress => context.l10n.event_eventLiveNow,
    EventState.finished => context.l10n.event_eventFinished.toUpperCase(),
    EventState.cancelled => event.state.label.toUpperCase(),
  };
}

Color _color(EventModel event) {
  return switch (event.state) {
    EventState.draft => AppColors.primary,
    EventState.scheduled => AppColors.info,
    EventState.inProgress => AppColors.success,
    EventState.finished => AppColors.tabInactive,
    EventState.cancelled => AppColors.tabInactive,
  };
}

class EventDetailStatusBadge extends StatelessWidget {
  const EventDetailStatusBadge({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _color(event),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(context, event),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Space Grotesk',
          height: 1.0,
        ),
      ),
    );
  }
}
