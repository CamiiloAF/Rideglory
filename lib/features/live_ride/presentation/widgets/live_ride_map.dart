import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_env.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../domain/live_rider.dart';
import '../../domain/rider_position.dart';
import '../live_ride_formatters.dart';
import 'live_ride_marker.dart';

/// Mapa de la rodada en vivo (D13: `flutter_map` + tiles raster). Se
/// centra en [focus] si se provee (ej. al tocar "Ver en el mapa" desde la
/// tarjeta de un SOS ajeno), si no en [myPosition], si no en el líder.
///
/// [showTiles] en `false` deja el `TileLayer` fuera del árbol: Mapbox/OSM
/// nunca renderiza en golden tests (trampa conocida de CLAUDE.md), así
/// que los tests de esta pantalla auditan los overlays, no el mapa.
class LiveRideMap extends StatelessWidget {
  const LiveRideMap({
    required this.riders,
    super.key,
    this.myPosition,
    this.leaderUserId,
    this.focus,
    this.showTiles = true,
  });

  final List<LiveRider> riders;
  final RiderPosition? myPosition;
  final String? leaderUserId;
  final LatLng? focus;
  final bool showTiles;

  LatLng? get _center {
    if (focus != null) return focus;
    if (myPosition != null) {
      return LatLng(myPosition!.lat, myPosition!.lng);
    }
    if (riders.isNotEmpty) {
      final leader = riders.where((rider) => rider.userId == leaderUserId);
      final reference = leader.isNotEmpty ? leader.first : riders.first;
      return LatLng(reference.lat, reference.lng);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final center = _center ?? const LatLng(4.6, -75.6);
    return ColoredBox(
      color: colors.surface,
      child: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 14),
        children: [
          if (showTiles)
            TileLayer(
              urlTemplate: AppEnv.mapTileUrl,
              userAgentPackageName: AppEnv.mapUserAgentPackageName,
            ),
          MarkerLayer(
            markers: [
              for (final rider in riders)
                Marker(
                  point: LatLng(rider.lat, rider.lng),
                  width: 44,
                  height: 44,
                  child: LiveRideMarker(
                    initials: liveRideInitials(rider.fullName),
                    isLeader: rider.userId == leaderUserId,
                    isStale:
                        DateTime.now()
                            .toUtc()
                            .difference(rider.recordedAt.toUtc())
                            .inMinutes >=
                        3,
                  ),
                ),
              if (myPosition != null)
                Marker(
                  point: LatLng(myPosition!.lat, myPosition!.lng),
                  width: 40,
                  height: 40,
                  child: const LiveRideMarker(initials: '•', isLeader: false),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
