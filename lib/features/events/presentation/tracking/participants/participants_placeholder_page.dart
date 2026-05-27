import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_empty_state.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_rider_list.dart';

/// Participants / Riders panel (Pencil page 34).
///
/// Shows an active-riders list sourced from [event]. When the full tracking
/// cubit is in scope this widget can be upgraded to a BlocBuilder; for now it
/// renders from whatever riders are passed in or shows a styled empty-state.
class ParticipantsPlaceholderPage extends StatelessWidget {
  const ParticipantsPlaceholderPage({
    super.key,
    required this.event,
    this.riders = const [],
  });

  final EventModel event;

  /// Active riders to display; defaults to empty list when not provided.
  final List<RiderTrackingModel> riders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.textOnDarkPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.map_participantsTitle,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              event.name,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.darkBorderPrimary),
        ),
      ),
      body: riders.isEmpty
          ? const ParticipantsEmptyState()
          : ParticipantsRiderList(riders: riders),
    );
  }
}
