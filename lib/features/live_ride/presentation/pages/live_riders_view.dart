import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/live_rider_card.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../../../events/domain/registration_status.dart';
import '../../../events/presentation/cubit/registrants_cubit.dart';
import '../../../events/presentation/cubit/registrants_state.dart';
import '../../domain/live_rider.dart';
import '../cubit/live_ride_cubit.dart';
import '../cubit/live_ride_state.dart';
import '../live_ride_external_actions.dart';
import '../live_ride_formatters.dart';
import '../live_ride_labels.dart';
import '../live_ride_rider_row.dart';
import '../live_ride_route_args.dart';

/// LV6: lista completa de riders para el organizador — estado y botón de
/// llamar por cada uno. Fusiona `event_registrations_for_organizer`
/// (teléfono) con `live_riders` (posición en vivo), por eso necesita su
/// propio [RegistrantsCubit] (provisto por `LiveRidersPage`) además del
/// [LiveRideCubit] de la sesión.
///
/// Pencil: UGgbU
class LiveRidersView extends StatelessWidget {
  const LiveRidersView({required this.eventId, required this.args, super.key});

  final String eventId;
  final LiveRideRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageHeader(title: context.l10n.live_riders_page_header),
      body: SafeArea(
        top: false,
        child: BlocBuilder<RegistrantsCubit, RegistrantsState>(
          builder: (context, registrantsState) {
            return registrantsState.registrants.when(
              initial: () => const SkeletonList(),
              loading: () => const SkeletonList(),
              empty: () => EmptyStateView(
                title: context.l10n.events_registrants_empty_title,
              ),
              error: (_) => ErrorStateView(
                title: context.l10n.events_registrants_error_title,
                onRetry: () => context.read<RegistrantsCubit>().retry(),
              ),
              data: (registrants) {
                final approved = registrants
                    .where(
                      (registrant) =>
                          registrant.status == RegistrationStatus.approved,
                    )
                    .toList();
                return BlocBuilder<LiveRideCubit, LiveRideState>(
                  builder: (context, liveState) {
                    final liveRiders =
                        liveState.riders.whenOrNull(data: (data) => data) ??
                        const <LiveRider>[];
                    final rows = mergeLiveRiderRows(
                      registrants: approved,
                      liveRiders: liveRiders,
                      ownerId: args.ownerId,
                    );
                    final leader = rows.where((row) => row.isLeader);
                    final leaderPosition = leader.isNotEmpty
                        ? leader.first.liveRider
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Text(
                            context.l10n.live_riders_page_subtitle(
                              rows.length,
                              liveRiders.length,
                            ),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                context,
                              ).extension<AppColors>()!.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: rows.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              final meta = !row.isSharing
                                  ? context.l10n.live_ride_not_sharing_status
                                  : (leaderPosition == null
                                        ? liveRideFreshnessLabel(
                                            context,
                                            row.liveRider!.recordedAt,
                                          )
                                        : '${liveRideDistanceLabel(context, liveRideDistanceMeters(lat1: row.liveRider!.lat, lng1: row.liveRider!.lng, lat2: leaderPosition.lat, lng2: leaderPosition.lng))} ${context.l10n.live_ride_leader_distance_suffix}');
                              return LiveRiderCard(
                                initials: liveRideInitials(row.fullName),
                                name: row.isLeader
                                    ? '${row.fullName} · ${context.l10n.live_ride_leader_suffix}'
                                    : row.fullName,
                                metaText: meta,
                                isLeader: row.isLeader,
                                metaColor: !row.isSharing
                                    ? null
                                    : (liveRideIsStale(
                                            row.liveRider!.recordedAt,
                                          )
                                          ? Theme.of(
                                              context,
                                            ).extension<AppColors>()!.warning
                                          : null),
                                onCall: row.phone == null
                                    ? null
                                    : () => openSosPhoneDialer(row.phone!),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
