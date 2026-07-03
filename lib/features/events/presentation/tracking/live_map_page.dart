import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/live_tracking_session_holder.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_app_bar.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_body.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_simple_app_bar.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_widget.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_confirm_dialog.dart';
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

  /// Rider currently selected (by tapping the list or a map marker). Shared
  /// between the map and the telemetry list so they stay in sync.
  final ValueNotifier<String?> _selectedRiderId = ValueNotifier(null);
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
    _selectedRiderId.dispose();
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
    // Show the map immediately with the fallback so it never blocks on GPS.
    // Center of Colombia (lng-first for Mapbox), zoom out to show the country.
    setState(() {
      _initialCameraOptions = CameraOptions(
        center: Point(coordinates: Position(-74.2973, 4.5709)),
        zoom: 5.0,
      );
    });

    // Refine with actual GPS position in the background.
    try {
      final permission = await LocationPermissionHandler.status();
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (permission != LocationPermissionResult.granted || !serviceEnabled) {
        return;
      }
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _initialCameraOptions = CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15.0,
        );
      });
    } catch (_) {
      // GPS failed — fallback already shown.
    }
  }

  Future<void> _onSosPressed(LiveTrackingCubit cubit) async {
    // Pressing SOS while active asks to confirm before turning it off.
    if (cubit.state.hasSentSos) {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: context.l10n.sos_cancel_confirm_title,
        content: context.l10n.sos_cancel_confirm_body,
        confirmLabel: context.l10n.sos_cancel_confirm_action,
        confirmType: DialogActionType.danger,
      );
      if (confirmed == true && mounted) {
        cubit.cancelSos();
      }
      return;
    }

    final confirmed = await SosConfirmDialog.show(context: context);
    if (confirmed == true && mounted) {
      cubit.triggerSos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final eventId = event.id;

    if (eventId == null || eventId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: LiveMapSimpleAppBar(title: event.name),
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
        appBar: LiveMapSimpleAppBar(title: event.name),
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

    return BlocProvider.value(
      value: trackingCubit,
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        extendBodyBehindAppBar: true,
        appBar: LiveMapOverlayAppBar(event: event),
        body: BlocListener<LiveTrackingCubit, LiveTrackingState>(
          listenWhen: (prev, next) => prev.isFinished != next.isFinished,
          listener: (ctx, state) {
            if (state.isFinished) {
              // Overlay handles navigation via its own button.
            }
          },
          child: LiveMapBody(
            trackingCubit: trackingCubit,
            event: event,
            currentUserId: currentUser?.id,
            mapController: _mapController,
            selectedRiderId: _selectedRiderId,
            initialCameraOptions: _initialCameraOptions,
            onSosPressed: () => _onSosPressed(trackingCubit),
          ),
        ),
      ),
    );
  }
}
