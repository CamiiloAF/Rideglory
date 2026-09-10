import 'package:flutter/material.dart';

import '../../../../design_system/components/live_rider_card.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/live_rider.dart';
import '../live_ride_formatters.dart';
import '../live_ride_labels.dart';

/// Hoja inferior arrastrable de LV1/LV1b/LV5a con la lista de riders:
/// distancia a mí y frescura de la señal ("Hace X min" / "Sin señal hace X
/// min" en advertencia si la posición tiene más de 3 min, D20).
///
/// Pencil: juEgy
class LiveRidersSheet extends StatelessWidget {
  const LiveRidersSheet({
    required this.riders,
    required this.leaderUserId,
    required this.myUserId,
    super.key,
    this.myLat,
    this.myLng,
  });

  final List<LiveRider> riders;
  final String leaderUserId;
  final String? myUserId;
  final double? myLat;
  final double? myLng;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.16,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.live_ride_riders_sheet_title(riders.length),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: riders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final rider = riders[index];
                    final isLeader = rider.userId == leaderUserId;
                    final isMe = rider.userId == myUserId;
                    final isStale = liveRideIsStale(rider.recordedAt);
                    final name = isMe
                        ? '${rider.fullName} ${context.l10n.live_ride_me_suffix}'
                        : rider.fullName;
                    final meta = isStale
                        ? liveRideStaleLabel(context, rider.recordedAt)
                        : liveRideFreshnessLabel(context, rider.recordedAt);
                    final distance = (myLat != null && myLng != null)
                        ? liveRideDistanceLabel(
                            context,
                            liveRideDistanceMeters(
                              lat1: myLat!,
                              lng1: myLng!,
                              lat2: rider.lat,
                              lng2: rider.lng,
                            ),
                          )
                        : null;
                    return LiveRiderCard(
                      initials: liveRideInitials(rider.fullName),
                      name: isLeader
                          ? '$name · ${context.l10n.live_ride_leader_suffix}'
                          : name,
                      metaText: distance == null ? meta : '$distance · $meta',
                      isLeader: isLeader,
                      metaColor: isStale ? colors.warning : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
