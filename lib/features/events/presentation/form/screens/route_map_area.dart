import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

const _normalHeight = 260.0;
const _pickModeHeight = 420.0;

class RouteMapArea extends StatelessWidget {
  const RouteMapArea({
    super.key,
    required this.atLimit,
    required this.isPickMode,
    required this.isLocationLoading,
    required this.onMapCreated,
    required this.onTogglePickMode,
    required this.onConfirmPickMode,
    required this.onCenterOnLocation,
  });

  final bool atLimit;
  final bool isPickMode;

  /// Verdadero mientras se espera la primera ubicación GPS del usuario.
  /// Muestra un overlay de carga sobre el mapa y deshabilita interacciones.
  final bool isLocationLoading;

  final void Function(MapboxMap, PointAnnotationManager) onMapCreated;
  final VoidCallback onTogglePickMode;
  final VoidCallback onConfirmPickMode;
  final VoidCallback onCenterOnLocation;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isPickMode ? _pickModeHeight : _normalHeight,
      child: Stack(
        children: [
          // Map — sin viewport: evitar que cada rebuild resetee la cámara.
          // La posición inicial la maneja _centerOnLocation() en onMapCreated.
          MapWidget(
            styleUri: MapboxStyles.DARK,
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
              // Indicador nativo de ubicación del usuario (pulsing dot naranja).
              await mapboxMap.location.updateSettings(
                LocationComponentSettings(
                  enabled: true,
                  pulsingEnabled: true,
                  pulsingColor: AppColors.primary.toARGB32(),
                ),
              );
              final manager =
                  await mapboxMap.annotations.createPointAnnotationManager();
              onMapCreated(mapboxMap, manager);
            },
          ),

          // Overlay de carga: bloquea interacción hasta que se obtenga la ubicación.
          if (isLocationLoading)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.darkBgPrimary.withValues(alpha: 0.7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.route_map_locating,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 13,
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Centered pin shown in pick mode — IgnorePointer so map stays pannable
          if (isPickMode && !isLocationLoading)
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

          // Current location button — bottom-left, circular
          if (!isLocationLoading)
            Positioned(
              bottom: 10,
              left: 12,
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

          // "Seleccionar en mapa" toggle button — bottom-right, oculto durante carga
          if (!atLimit && !isPickMode && !isLocationLoading)
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
          if (isPickMode && !isLocationLoading)
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
