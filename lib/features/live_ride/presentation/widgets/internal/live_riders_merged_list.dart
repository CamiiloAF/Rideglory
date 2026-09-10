import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/result_state.dart';
import '../../../../../design_system/components/live_rider_card.dart';
import '../../../../../design_system/tokens/app_colors.dart';
import '../../../../../l10n/l10n_extensions.dart';
import '../../../../../shared/widgets/states/empty_state_view.dart';
import '../../../../events/domain/event_registrant.dart';
import '../../../domain/live_rider.dart';
import '../../cubit/live_ride_cubit.dart';
import '../../cubit/live_ride_state.dart';
import '../../live_ride_external_actions.dart';
import '../../live_ride_formatters.dart';
import '../../live_ride_labels.dart';
import '../../live_ride_rider_row.dart';
import '../../live_ride_route_args.dart';

/// LV6: fusiona los inscritos aprobados (organizador) con la posición en
/// vivo (`LiveRideCubit`), y completa al organizador como líder desde
/// `contacts` cuando el viewer es un participante que no lo ve en
/// `event_registrations` (regla D17). Separado de [LiveRidersView] porque
/// necesita reaccionar tanto a `RegistrantsState.empty` (participante)
/// como a `.data` (organizador) con la misma lógica de fusión.
class LiveRidersMergedList extends StatelessWidget {
  const LiveRidersMergedList({
    required this.approvedRegistrants,
    required this.args,
    super.key,
  });

  final List<EventRegistrant> approvedRegistrants;
  final LiveRideRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveRideCubit, LiveRideState>(
      builder: (context, liveState) {
        final liveRiders =
            liveState.riders.whenOrNull(data: (data) => data) ??
            const <LiveRider>[];
        final rows = mergeLiveRiderRows(
          registrants: approvedRegistrants,
          liveRiders: liveRiders,
          ownerId: args.ownerId,
          organizerName: args.isOwner
              ? null
              : liveState.contacts?.organizerName,
          organizerPhone: args.isOwner
              ? null
              : liveState.contacts?.organizerPhone,
        );
        if (rows.isEmpty) {
          return EmptyStateView(
            title: context.l10n.events_registrants_empty_title,
          );
        }
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
                        : (liveRideIsStale(row.liveRider!.recordedAt)
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
  }
}
