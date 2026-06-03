import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/data/cache/attendees_cache.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_empty_state.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_filter.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_rider_list.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/widgets/participants_filter_chips.dart';

/// Participants / Riders panel shown from the live map group icon.
///
/// Maintains local [_searchQuery] and [_filter] state.
/// Reads riders and SOS from [LiveTrackingCubit]; phone/vehicle data
/// from [AttendeesCache].
class ParticipantsPlaceholderPage extends StatefulWidget {
  const ParticipantsPlaceholderPage({super.key, required this.event});

  final EventModel event;

  @override
  State<ParticipantsPlaceholderPage> createState() =>
      _ParticipantsPlaceholderPageState();
}

class _ParticipantsPlaceholderPageState
    extends State<ParticipantsPlaceholderPage> {
  String _searchQuery = '';
  ParticipantsFilter _filter = ParticipantsFilter.all;

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
              widget.event.name,
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
        buildWhen: (prev, next) =>
            prev.ridersResult != next.ridersResult ||
            prev.sosAlertResult != next.sosAlertResult ||
            prev.currentUserLatitude != next.currentUserLatitude ||
            prev.currentUserLongitude != next.currentUserLongitude,
        builder: (context, state) {
          final riders = state.ridersResult.maybeWhen(
            data: (data) => data,
            orElse: () => <RiderTrackingModel>[],
          );

          final sosUserId = state.sosAlertResult.maybeWhen(
            data: (sos) => sos?.userId,
            orElse: () => null,
          );

          final registrations = _loadRegistrations();

          if (riders.isEmpty) {
            return const ParticipantsEmptyState();
          }

          return Column(
            children: [
              AppSearchBar(
                hintText: context.l10n.map_searchParticipants,
                onSearchChanged: (query) =>
                    setState(() => _searchQuery = query),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              ),
              ParticipantsFilterChips(
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              Expanded(
                child: ParticipantsRiderList(
                  riders: riders,
                  filter: _filter,
                  searchQuery: _searchQuery,
                  event: widget.event,
                  registrations: registrations,
                  sosUserId: sosUserId,
                  currentUserLat: state.currentUserLatitude,
                  currentUserLon: state.currentUserLongitude,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<EventRegistrationModel> _loadRegistrations() {
    final eventId = widget.event.id;
    if (eventId == null || eventId.isEmpty) return const [];
    return GetIt.instance<AttendeesCache>().read(eventId) ?? const [];
  }
}
