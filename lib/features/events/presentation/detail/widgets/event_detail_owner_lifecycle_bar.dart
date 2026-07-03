import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_owner_draft_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_owner_live_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_owner_start_bar.dart';

/// Owner CTA bar for the Event Detail screen.
///
/// Handles two states from Pencil page 6:
/// - OWNER — START EVENT: participant count (left) + green "Iniciar evento" btn (right)
/// - OWNER — EVENT LIVE: live badge + "Rodada en curso" + full-width red "Finalizar rodada" btn
class EventDetailOwnerLifecycleBar extends StatelessWidget {
  const EventDetailOwnerLifecycleBar({
    super.key,
    required this.event,
    required this.isLoading,
    required this.onStart,
    required this.onStop,
    required this.onOpenMap,
    this.onPublish,
  });

  final EventModel event;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onOpenMap;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, max(16.0, bottomPadding)),
      child: switch (event.state) {
        EventState.draft => EventDetailOwnerDraftBar(
          isLoading: isLoading,
          onPublish: onPublish ?? () {},
        ),
        EventState.scheduled => EventDetailOwnerStartBar(
          isLoading: isLoading,
          onStart: onStart,
        ),
        EventState.inProgress => EventDetailOwnerLiveBar(
          isLoading: isLoading,
          onStop: onStop,
          onOpenMap: onOpenMap,
        ),
        EventState.finished => const SizedBox.shrink(),
        EventState.cancelled => const SizedBox.shrink(),
      },
    );
  }
}
