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
import 'package:rideglory/features/events/presentation/tracking/widgets/organizer_control_bar.dart';
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
    required this.isOrganizer,
    required this.event,
    required this.mapController,
    required this.initialCameraOptions,
    required this.onSosPressed,
    required this.onEndRidePressed,
  });

  final LiveTrackingCubit trackingCubit;
  final bool isOrganizer;
  final EventModel event;
  final ValueNotifier<LiveMapController?> mapController;
  final CameraOptions? initialCameraOptions;
  final VoidCallback onSosPressed;
  final VoidCallback onEndRidePressed;

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
                        prev.ridersResult != next.ridersResult,
                    builder: (context, state) {
                      if (state.isFinished) {
                        return RideFinishedOverlay(eventName: event.name);
                      }

                      final riders = state.ridersResult.maybeWhen(
                        data: (data) => data,
                        orElse: () => <RiderTrackingModel>[],
                      );

                      return LiveMapWidget(
                        initialCameraOptions: initialCamera,
                        riders: riders,
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

          // Organizer control bar (top, only when organizer)
          if (isOrganizer)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 4,
              left: 0,
              right: 0,
              child: BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
                buildWhen: (prev, next) => prev.isFinished != next.isFinished,
                builder: (context, state) {
                  return OrganizerControlBar(onEndRide: onEndRidePressed);
                },
              ),
            ),

          // // SOS banner (below organizer bar)
          Positioned(
            top:
                kToolbarHeight +
                MediaQuery.of(context).padding.top +
                (isOrganizer ? 60 : 4),
            left: 0,
            right: 0,
            child: BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
              buildWhen: (prev, next) =>
                  prev.sosAlertResult != next.sosAlertResult,
              builder: (context, state) {
                final sosAlert = state.sosAlertResult.whenOrNull(
                  data: (alert) => alert,
                );
                if (sosAlert == null) return const SizedBox.shrink();
                return SosBannerWidget(sosAlert: sosAlert);
              },
            ),
          ),

          // Map controls (top-right)
          Positioned(
            right: 12,
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
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
                bottom: RiderTelemetryPanel.expandedBaseHeight +
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
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RiderTelemetryPanel(),
          ),
        ],
    );
  }
}
