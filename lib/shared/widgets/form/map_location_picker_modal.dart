import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
import 'package:rideglory/core/config/app_map_defaults.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Full-screen map picker. Shows a fixed crosshair pin in the center of the
/// map. User drags the map to position the pin, then taps "Confirmar" to
/// reverse-geocode the center coordinate and return the formatted address.
class MapLocationPickerModal extends StatefulWidget {
  const MapLocationPickerModal({super.key});

  static Future<String?> show(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const MapLocationPickerModal(),
      ),
    );
  }

  @override
  State<MapLocationPickerModal> createState() => _MapLocationPickerModalState();
}

class _MapLocationPickerModalState extends State<MapLocationPickerModal> {
  MapboxMap? _mapboxMap;
  bool _isConfirming = false;
  bool _mapReady = false;

  Future<void> _confirm() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || _isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      final camera = await mapboxMap.getCameraState();
      final lng = camera.center.coordinates.lng.toDouble();
      final lat = camera.center.coordinates.lat.toDouble();

      final result = await getIt<PlaceService>()
          .geocode('$lng,$lat')
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;
      Navigator.of(context).pop(result.formattedAddress);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.map_addressNotFound),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: Stack(
        children: [
          // Map
          MapWidget(
            viewport: AppMapDefaults.colombiaViewport,
            styleUri: MapboxStyles.DARK,
            onMapCreated: (map) {
              _mapboxMap = map;
              setState(() => _mapReady = true);
            },
          ),

          // Top bar
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: AppColors.darkBgPrimary.withValues(alpha: 0.85),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.map_pickLocation,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Centered crosshair pin
          const Center(child: _CrosshairPin()),

          // Hint label below pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBgPrimary.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.map_dragToPosition,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          // Confirm button at bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding + 24,
            child: AppButton(
              label: _isConfirming
                  ? context.l10n.map_searchingAddress
                  : context.l10n.map_confirmLocation,
              onPressed: _mapReady && !_isConfirming ? _confirm : null,
              isLoading: _isConfirming,
              shape: AppButtonShape.pill,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrosshairPin extends StatelessWidget {
  const _CrosshairPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 22),
        ),
        Container(width: 2, height: 12, color: AppColors.primary),
      ],
    );
  }
}
