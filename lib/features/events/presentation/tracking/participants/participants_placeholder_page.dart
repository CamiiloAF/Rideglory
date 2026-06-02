import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_empty_state.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_rider_list.dart';

/// Participants / Riders panel (Pencil page 34).
///
/// Shows the live active-riders list from the [LiveTrackingCubit] in scope.
class ParticipantsPlaceholderPage extends StatelessWidget {
  const ParticipantsPlaceholderPage({super.key, required this.event});

  final EventModel event;

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
      body: BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
        buildWhen: (prev, next) => prev.ridersResult != next.ridersResult,
        builder: (context, state) {
          final riders = state.ridersResult.maybeWhen(
            data: (data) => data,
            orElse: () => <RiderTrackingModel>[],
          );
          if (riders.isEmpty) {
            return const ParticipantsEmptyState();
          }
          return ParticipantsRiderList(riders: riders);
        },
      ),
    );
  }
}
