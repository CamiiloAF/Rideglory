import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_widget.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/map_zoom_controls.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/my_location_button.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/ride_finished_overlay.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_banner.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_button.dart';

/// The main body Stack for the live map page, containing the map, controls,
/// SOS elements, telemetry panel, and the ride-finished overlay.
class LiveMapBody extends StatelessWidget {
  const LiveMapBody({
    super.key,
    required this.trackingCubit,
    required this.event,
    this.currentUserId,
    required this.mapController,
    required this.selectedRiderId,
    required this.initialCameraOptions,
    required this.onSosPressed,
  });

  final LiveTrackingCubit trackingCubit;
  final EventModel event;
  final String? currentUserId;
  final ValueNotifier<LiveMapController?> mapController;

  /// Shared selection between the map and the telemetry list.
  final ValueNotifier<String?> selectedRiderId;
  final CameraOptions? initialCameraOptions;
  final VoidCallback onSosPressed;

  void _selectRider(RiderTrackingModel rider) {
    selectedRiderId.value = rider.userId;
    mapController.value?.centerOn(rider.latitude, rider.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final initialCamera = initialCameraOptions;

    return Stack(
      children: [
        // Map layer
        Positioned.fill(
          child: initialCamera != null
              ? BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
                  buildWhen: (prev, next) =>
                      prev.ridersResult != next.ridersResult ||
                      prev.currentUserLatitude != next.currentUserLatitude ||
                      prev.currentUserLongitude != next.currentUserLongitude ||
                      prev.sosAlertResult != next.sosAlertResult,
                  builder: (context, state) {
                    if (state.isFinished) {
                      return RideFinishedOverlay(eventName: event.name);
                    }

                    var riders = state.ridersResult.maybeWhen(
                      data: (data) => data,
                      orElse: () => <RiderTrackingModel>[],
                    );

                    // Override local user position in real-time without
                    // waiting for the WebSocket round-trip (every 4 s).
                    final uid = currentUserId;
                    final lat = state.currentUserLatitude;
                    final lng = state.currentUserLongitude;
                    if (uid != null && lat != null && lng != null) {
                      riders = riders
                          .map(
                            (r) => r.userId == uid
                                ? r.copyWith(latitude: lat, longitude: lng)
                                : r,
                          )
                          .toList();
                    }

                    final sosUserId = state.sosAlertResult.whenOrNull(
                      data: (alert) => alert?.userId,
                    );

                    return LiveMapWidget(
                      initialCameraOptions: initialCamera,
                      riders: riders,
                      currentUserId: currentUserId,
                      sosUserId: sosUserId,
                      onMarkerTap: _selectRider,
                      onMapReady: (controller) =>
                          mapController.value = controller,
                      onMapError: (message) {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.removeCurrentSnackBar();
                        messenger.showSnackBar(
                          SnackBar(content: Text(context.l10n.map_loadError)),
                        );
                      },
                    );
                  },
                )
              : const ColoredBox(
                  color: AppColors.trackingMapBg,
                  child: Center(
                    child: AppLoadingIndicator(
                      variant: AppLoadingIndicatorVariant.inline,
                    ),
                  ),
                ),
        ),

        // SOS banner, tucked right under the app bar buttons. The body origin
        // is the screen top, so include the status-bar inset and the app bar
        // height; -2 sits it snug just below the back/participants buttons.
        Positioned(
          top: MediaQuery.of(context).padding.top + (kToolbarHeight * .1),
          left: 0,
          right: 0,
          child: BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
            buildWhen: (prev, next) =>
                prev.sosAlertResult != next.sosAlertResult ||
                prev.ridersResult != next.ridersResult,
            builder: (context, state) {
              final sosAlert = state.sosAlertResult.whenOrNull(
                data: (alert) => alert,
              );
              if (sosAlert == null) return const SizedBox.shrink();

              final riders = state.ridersResult.maybeWhen(
                data: (data) => data,
                orElse: () => <RiderTrackingModel>[],
              );
              RiderTrackingModel? sosRider;
              for (final rider in riders) {
                if (rider.userId == sosAlert.userId) {
                  sosRider = rider;
                  break;
                }
              }
              final resolvedName =
                  (sosRider?.fullName.trim().isNotEmpty ?? false)
                  ? sosRider!.fullName.trim()
                  : sosAlert.riderName;

              return SosBannerWidget(
                sosAlert: sosAlert,
                displayName: resolvedName,
                onLocate: () {
                  selectedRiderId.value = sosAlert.userId;
                  final lat = sosRider?.latitude ?? sosAlert.latitude;
                  final lng = sosRider?.longitude ?? sosAlert.longitude;
                  if (lat != null && lng != null) {
                    mapController.value?.centerOn(lat, lng);
                  }
                },
              );
            },
          ),
        ),

        // Map controls (top-right). Sit below the SOS banner band so they
        // never overlap it when an alert is active.
        Positioned(
          right: 12,
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 76,
          child: ValueListenableBuilder<LiveMapController?>(
            valueListenable: mapController,
            builder: (context, controller, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MapZoomControls(controller: controller),
                  AppSpacing.gapMd,
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

        // // SOS button (bottom-right, above telemetry panel)
        BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
          buildWhen: (prev, next) => prev.hasSentSos != next.hasSentSos,
          builder: (context, state) {
            return Positioned(
              right: 16,
              bottom:
                  RiderTelemetryPanel.expandedBaseHeight +
                  MediaQuery.of(context).padding.bottom +
                  12,
              child: SosButton(
                label: context.l10n.map_sos,
                isActive: state.hasSentSos,
                onPressed: onSosPressed,
              ),
            );
          },
        ),

        // Telemetry panel (bottom)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: RiderTelemetryPanel(
            selectedRiderId: selectedRiderId,
            onRiderTap: _selectRider,
          ),
        ),
      ],
    );
  }
}
