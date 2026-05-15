import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/live_tracking_session_holder.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_widget.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/map_zoom_controls.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/my_location_button.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/organizer_control_bar.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/ride_finished_overlay.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_banner.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_button.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_confirm_dialog.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';

class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key, required this.event});

  final EventModel event;

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final ValueNotifier<LiveMapController?> _mapController = ValueNotifier(null);
  CameraOptions? _initialCameraOptions;

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
    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();

    if (permission == LocationPermissionResult.granted && serviceEnabled) {
      try {
        final position = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
          ),
        );
        if (!mounted) return;
        setState(() {
          _initialCameraOptions = CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            zoom: 15.0,
          );
        });
        return;
      } catch (_) {
        // Fall through to default.
      }
    }

    if (!mounted) return;
    setState(() {
      // Default: Armenia, Colombia (lng, lat — Mapbox lng-first)
      _initialCameraOptions = CameraOptions(
        center: Point(
          coordinates: Position(-75.6961, 4.8133),
        ),
        zoom: 12.0,
      );
    });
  }

  Future<void> _onSosPressed(LiveTrackingCubit cubit) async {
    final hasSentSos = cubit.state.hasSentSos;
    if (hasSentSos) return;

    final confirmed = await SosConfirmDialog.show(context: context);
    if (confirmed == true && mounted) {
      cubit.triggerSos();
    }
  }

  Future<void> _onEndRidePressed(
    BuildContext ctx,
    LiveTrackingCubit cubit,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: ctx,
      title: ctx.l10n.tracking_end_ride_confirm_title,
      content: ctx.l10n.tracking_end_ride_confirm_body,
      confirmLabel: ctx.l10n.tracking_end_ride,
      confirmType: DialogActionType.danger,
    );
    if (confirmed == true && mounted) {
      await cubit.endRide(widget.event.id ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final eventId = event.id;

    if (eventId == null || eventId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: _buildAppBar(context, event.name),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              EventStrings.trackingEventMissing,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    if (event.state != EventState.inProgress) {
      return Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: _buildAppBar(context, event.name),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              EventStrings.trackingLiveMapOnlyWhenInProgress,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final trackingCubit = getIt<LiveTrackingSessionHolder>().obtainForEvent(
      eventId: eventId,
      eventOwnerId: event.ownerId,
    );

    final currentUser = context.read<AuthCubit>().state.currentUser;
    final isOrganizer = currentUser?.id == event.ownerId;

    return BlocProvider.value(
      value: trackingCubit,
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        extendBodyBehindAppBar: true,
        appBar: _buildLiveMapAppBar(context, event),
        body: BlocListener<LiveTrackingCubit, LiveTrackingState>(
          listenWhen: (prev, next) => prev.isFinished != next.isFinished,
          listener: (ctx, state) {
            if (state.isFinished) {
              // Overlay handles navigation via its own button.
            }
          },
          child: _buildBody(context, trackingCubit, isOrganizer, event),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: AppColors.darkCard,
      foregroundColor: AppColors.textOnDarkPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textOnDarkPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevation: 0,
    );
  }

  PreferredSizeWidget _buildLiveMapAppBar(
    BuildContext context,
    EventModel event,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _MapOverlayButton(
        onTap: () => context.pop(),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textOnDarkPrimary,
          size: 18,
        ),
      ),
      centerTitle: true,
      title: _LiveBadgeTitle(eventName: event.name),
      actions: [
        // Participants button
        _MapOverlayButton(
          onTap: () => context.pushNamed(AppRoutes.participants, extra: event),
          child: const Icon(
            Icons.group_rounded,
            color: AppColors.textOnDarkPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    LiveTrackingCubit trackingCubit,
    bool isOrganizer,
    EventModel event,
  ) {
    final initialCamera = _initialCameraOptions;

    return Stack(
      children: [
        // Map layer
        Positioned.fill(
          child: initialCamera != null
              ? BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
                  buildWhen: (prev, next) =>
                      prev.ridersResult != next.ridersResult,
                  builder: (context, state) {
                    final riders = state.ridersResult.when(
                      initial: () => <RiderTrackingModel>[],
                      loading: () => <RiderTrackingModel>[],
                      data: (data) => data,
                      empty: () => <RiderTrackingModel>[],
                      error: (_) => <RiderTrackingModel>[],
                    );
                    return LiveMapWidget(
                      initialCameraOptions: initialCamera,
                      riders: riders,
                      onMapReady: (controller) =>
                          _mapController.value = controller,
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
              buildWhen: (prev, next) =>
                  prev.isFinished != next.isFinished,
              builder: (context, state) {
                return OrganizerControlBar(
                  onEndRide: () =>
                      _onEndRidePressed(context, trackingCubit),
                );
              },
            ),
          ),

        // SOS banner (below organizer bar)
        Positioned(
          top: kToolbarHeight +
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
            valueListenable: _mapController,
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

        // SOS button (bottom-right, above telemetry panel)
        BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
          buildWhen: (prev, next) => prev.hasSentSos != next.hasSentSos,
          builder: (context, state) {
            return Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.32,
              child: SosButton(
                label: context.l10n.map_sos,
                isActive: state.hasSentSos,
                onPressed: () => _onSosPressed(trackingCubit),
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

        // Ride finished overlay
        BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
          buildWhen: (prev, next) => prev.isFinished != next.isFinished,
          builder: (context, state) {
            if (!state.isFinished) return const SizedBox.shrink();
            return Positioned.fill(
              child: RideFinishedOverlay(eventName: event.name),
            );
          },
        ),
      ],
    );
  }
}

// ── Private helper widgets ───────────────────────────────────────────────────

class _MapOverlayButton extends StatelessWidget {
  const _MapOverlayButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkCard.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _LiveBadgeTitle extends StatelessWidget {
  const _LiveBadgeTitle({required this.eventName});

  final String eventName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error,
            ),
          ),
          AppSpacing.hGapXxs,
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              eventName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
