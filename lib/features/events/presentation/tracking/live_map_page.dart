import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_chip.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_widget.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/map_zoom_controls.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/my_location_button.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_button.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key, required this.event});

  final EventModel event;

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final ValueNotifier<LiveMapController?> _mapController = ValueNotifier(null);
  CameraPosition? _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    unawaited(_guardPermission());
    unawaited(_loadInitialCamera());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _guardPermission() async {
    final status = await LocationPermissionHandler.status();
    if (status == LocationPermissionResult.granted) return;
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await InfoDialog.show(
        context: context,
        title: context.l10n.locationPermissionTitle,
        content: context.l10n.locationPermissionMapRequiredMessage,
        type: DialogType.warning,
      );
      if (mounted) context.pop();
    });
  }

  Future<void> _loadInitialCamera() async {
    final permission = await LocationPermissionHandler.status();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (permission == LocationPermissionResult.granted && serviceEnabled) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (!mounted) return;
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          );
        });
        return;
      } catch (_) {
        // Fall through to default.
      }
    }

    if (!mounted) return;
    setState(() {
      _initialCameraPosition = const CameraPosition(
        target: LatLng(4.8133, -75.6961), // Pereira, Colombia
        zoom: 12,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    final initialCamera = _initialCameraPosition;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppAppBar(
        title: event.name,
        actions: [
          IconButton(
            onPressed: () {
              context.pushNamed(AppRoutes.participants, extra: event);
            },
            icon: Icon(Icons.group),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (initialCamera != null)
                  LiveMapWidget(
                    initialCameraPosition: initialCamera,
                    onMapReady: (controller) =>
                        _mapController.value = controller,
                  )
                else
                  Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: EventDetailChip(
                    label: '${context.l10n.map_activeRidersChip} 5',
                    color: context.appColors.success,
                    isSolid: true,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: ValueListenableBuilder<LiveMapController?>(
                    valueListenable: _mapController,
                    builder: (context, controller, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MapZoomControls(controller: controller),
                          SizedBox(height: 12),
                          MyLocationButton(
                            isEnabled: controller != null,
                            onTap: controller == null
                                ? null
                                : () => controller.centerOnMyLocation(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: SosButton(label: context.l10n.map_sos, onPressed: () {}),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RiderTelemetryPanel(event: event),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
