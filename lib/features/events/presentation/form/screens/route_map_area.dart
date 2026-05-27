import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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
  });

  final bool atLimit;
  final bool isPickMode;
  final void Function(MapboxMap, PointAnnotationManager) onMapCreated;
  final VoidCallback onTogglePickMode;
  final VoidCallback onConfirmPickMode;
  final VoidCallback onCenterOnLocation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
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

          // Current location button — top-right, always visible
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: onCenterOnLocation,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.darkBgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBorderPrimary),
                ),
                child: const Icon(
                  Icons.my_location,
                  size: 18,
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
