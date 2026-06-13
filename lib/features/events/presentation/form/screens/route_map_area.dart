import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/pulsing_map_dot.dart';

// Colombia center — default camera when no waypoints are loaded.
const _colombiaLng = -73.0;
const _colombiaLat = 4.0;
const _colombiaZoom = 5.0;

class RouteMapArea extends StatelessWidget {
  const RouteMapArea({
    super.key,
    required this.atLimit,
    required this.isPickMode,
    required this.onMapCreated,
    required this.onTogglePickMode,
    required this.onConfirmPickMode,
    required this.onCenterOnLocation,
    this.hasWaypoints = false,
  });

  final bool atLimit;
  final bool isPickMode;
  final void Function(MapboxMap, PointAnnotationManager) onMapCreated;
  final VoidCallback onTogglePickMode;
  final VoidCallback onConfirmPickMode;
  final VoidCallback onCenterOnLocation;
  /// When [false] (no waypoints yet), a [PulsingMapDot] is shown as a centered
  /// overlay to hint the user to add a route point (AC19).
  final bool hasWaypoints;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // Map
          MapWidget(
            styleUri: MapboxStyles.DARK,
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(_colombiaLng, _colombiaLat),
              ),
              zoom: _colombiaZoom,
            ),
            onMapCreated: (mapboxMap) async {
              await mapboxMap.scaleBar.updateSettings(
                ScaleBarSettings(enabled: false),
              );
              await mapboxMap.logo.updateSettings(
                LogoSettings(marginLeft: -200, marginBottom: -200),
              );
              await mapboxMap.attribution.updateSettings(
                AttributionSettings(iconColor: 0x00000000),
              );
              final manager =
                  await mapboxMap.annotations.createPointAnnotationManager();
              onMapCreated(mapboxMap, manager);
            },
          ),

          // PulsingMapDot: centered overlay when map has 0 waypoints (AC19).
          // Hidden once the user adds at least one waypoint.
          if (!hasWaypoints && !isPickMode)
            const IgnorePointer(
              child: Center(child: PulsingMapDot()),
            ),

          // Centered pin shown in pick mode — IgnorePointer so map stays pannable
          if (isPickMode)
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: const Icon(
                    Icons.location_pin,
                    size: 44,
                    color: AppColors.primary,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Current location button — bottom-right, circular (Pencil veaGt: recenterBtn)
          Positioned(
            bottom: 10,
            right: 12,
            child: GestureDetector(
              onTap: onCenterOnLocation,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.darkBorderPrimary),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x60000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  size: 16,
                  color: AppColors.textOnDarkPrimary,
                ),
              ),
            ),
          ),

          // "Seleccionar en mapa" toggle button — bottom-right when not in pick mode
          if (!atLimit && !isPickMode)
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: onTogglePickMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkBorderPrimary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.route_builder_pick_mode_button,
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDarkPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Pick mode confirm bar at bottom of map
          if (isPickMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                color: AppColors.darkBgPrimary.withValues(alpha: 0.93),
                child: Row(
                  children: [
                    AppTextButton(
                      label: context.l10n.cancel,
                      onPressed: onTogglePickMode,
                      variant: AppTextButtonVariant.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: context.l10n.route_builder_pick_mode_confirm,
                        onPressed: onConfirmPickMode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
