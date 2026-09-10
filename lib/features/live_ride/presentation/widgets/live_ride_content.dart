import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/sos_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/live_rider.dart';
import '../../domain/rider_position.dart';
import '../../domain/sos_status.dart';
import '../cubit/live_ride_cubit.dart';
import '../cubit/sharing_status.dart';
import '../cubit/sos_cubit.dart';
import '../cubit/sos_state.dart';
import '../live_ride_current_user.dart';
import '../live_ride_formatters.dart';
import '../live_ride_route_args.dart';
import '../live_ride_share_flow.dart';
import '../live_ride_sos_flow.dart';
import 'live_ride_header.dart';
import 'live_ride_map.dart';
import 'live_riders_sheet.dart';
import 'sos_other_banner.dart';
import 'sos_other_sheet.dart';

/// LV1/LV1b: mapa + header flotante + hoja de riders + botón de SOS +
/// banner del SOS de otro rider. `_mapFocus` es el único estado propio:
/// se centra el mapa en una alerta ajena al pulsar "Ver en el mapa"
/// (LV5b).
class LiveRideContent extends StatefulWidget {
  const LiveRideContent({
    required this.eventId,
    required this.args,
    required this.riders,
    required this.sharing,
    super.key,
    this.myPosition,
    this.showMapTiles = true,
  });

  final String eventId;
  final LiveRideRouteArgs args;
  final List<LiveRider> riders;
  final SharingStatus sharing;
  final RiderPosition? myPosition;

  /// `false` en tests/goldens: nunca renderiza tiles reales (trampa
  /// conocida de CLAUDE.md, mapas y red bajo `flutter_test`).
  final bool showMapTiles;

  @override
  State<LiveRideContent> createState() => _LiveRideContentState();
}

class _LiveRideContentState extends State<LiveRideContent> {
  LatLng? _mapFocus;
  late final String? _myUserId = liveRideCurrentUserId();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveRideMap(
              riders: widget.riders,
              myPosition: widget.myPosition,
              leaderUserId: widget.args.ownerId,
              focus: _mapFocus,
              showTiles: widget.showMapTiles,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                LiveRideHeader(
                  eventName: widget.args.eventName,
                  sharing: widget.sharing,
                  isOwner: widget.args.isOwner,
                  onBack: () => _backToEvent(context),
                  onShare: () =>
                      startLiveRideSharingFlow(context, widget.eventId),
                  onStop: () => context.read<LiveRideCubit>().stopSharing(),
                  onViewRiders: () => context.pushNamed(
                    AppRoutes.eventLiveRiders,
                    pathParameters: {'id': widget.eventId},
                    extra: widget.args,
                  ),
                ),
                BlocBuilder<SosCubit, SosState>(
                  builder: (context, sosState) => sosState.others.when(
                    initial: () => const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    empty: () => const SizedBox.shrink(),
                    error: (_) => const SizedBox.shrink(),
                    data: (alerts) {
                      final others = alerts
                          .where(
                            (alert) =>
                                alert.status == SosStatus.active &&
                                alert.userId != _myUserId,
                          )
                          .toList();
                      if (others.isEmpty) return const SizedBox.shrink();
                      final alert = others.first;
                      final distance = widget.myPosition == null
                          ? 0.0
                          : liveRideDistanceMeters(
                              lat1: widget.myPosition!.lat,
                              lng1: widget.myPosition!.lng,
                              lat2: alert.lat,
                              lng2: alert.lng,
                            );
                      return SosOtherBanner(
                        riderName: alert.riderName,
                        distanceMeters: distance,
                        onView: () => SosOtherSheet.show(
                          context,
                          alert: alert,
                          isOwner: widget.args.isOwner,
                          onViewMap: () => setState(
                            () => _mapFocus = LatLng(alert.lat, alert.lng),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 360,
            child: SosButton(
              label: context.l10n.sos_button_label,
              onPressed: () => triggerLiveRideSosFlow(
                context,
                eventId: widget.eventId,
                args: widget.args,
              ),
            ),
          ),
          LiveRidersSheet(
            riders: widget.riders,
            leaderUserId: widget.args.ownerId,
            myUserId: _myUserId,
            myLat: widget.myPosition?.lat,
            myLng: widget.myPosition?.lng,
          ),
        ],
      ),
    );
  }

  void _backToEvent(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        AppRoutes.eventDetail,
        pathParameters: {'id': widget.eventId},
      );
    }
  }
}
