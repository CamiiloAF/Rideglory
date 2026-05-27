import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_counter.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_item_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_limit_banner.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_search_field.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoints_empty_hint.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:rideglory/shared/models/address_location.dart';

const int _maxWaypoints = 9;
const _routeSourceId = 'config-route-source';
const _routeLayerId = 'config-route-layer';

// Colombia center — default camera when no waypoints are loaded.
const _colombiaLng = -73.0;
const _colombiaLat = 4.0;
const _colombiaZoom = 5.0;

/// Full-screen custom route builder.
///
/// Manages waypoints via [EventFormCubit]. Stores waypoint coordinates locally
/// to render numbered Mapbox pins and an orange polyline preview.
class EventRouteConfigScreen extends StatefulWidget {
  const EventRouteConfigScreen({super.key});

  @override
  State<EventRouteConfigScreen> createState() => _EventRouteConfigScreenState();
}

class _EventRouteConfigScreenState extends State<EventRouteConfigScreen> {
  final _searchFormKey = GlobalKey<FormBuilderState>();

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _routeLayerAdded = false;
  bool _isPickMode = false;

  // Local coords parallel to cubit.state.waypoints — null when coords unknown.
  final List<AddressLocation?> _waypointLocations = [];

  @override
  void initState() {
    super.initState();
    final cubitState = context.read<EventFormCubit>().state;
    final existing = cubitState.waypoints;
    final savedLocations = cubitState.waypointLocations;
    for (var i = 0; i < existing.length; i++) {
      _waypointLocations.add(
        i < savedLocations.length ? savedLocations[i] : null,
      );
    }
  }

  List<AddressLocation> get _resolvedCoords =>
      _waypointLocations.whereType<AddressLocation>().toList();

  void _onWaypointAdded(String name, AddressLocation? location) {
    final cubit = context.read<EventFormCubit>();
    final index = cubit.state.waypoints.length;
    cubit.addWaypoint(name);
    if (location != null) cubit.setWaypointLocation(index, location);
    setState(() => _waypointLocations.add(location));
    unawaited(_renderWaypointMode());
  }

  void _togglePickMode() {
    setState(() => _isPickMode = !_isPickMode);
  }

  Future<void> _centerOnLocation() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    try {
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        return;
      }
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(pos.longitude, pos.latitude),
          ),
          zoom: 14,
        ),
        MapAnimationOptions(duration: 600),
      );
    } catch (_) {}
  }

  Future<void> _confirmPickMode() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    setState(() => _isPickMode = false);

    final camera = await mapboxMap.getCameraState();
    final pos = camera.center.coordinates;
    final lat = pos.lat.toDouble();
    final lng = pos.lng.toDouble();

    String name = 'Punto en el mapa';
    AddressLocation location = AddressLocation(latitude: lat, longitude: lng);
    try {
      final result = await getIt<PlaceService>().geocode('$lng,$lat');
      name = result.formattedAddress ?? name;
      location = AddressLocation(
        latitude: result.latitude,
        longitude: result.longitude,
        label: name,
      );
    } catch (_) {}

    if (!mounted) return;
    _onWaypointAdded(name, location);
  }

  void _onWaypointRemoved(int index) {
    context.read<EventFormCubit>().removeWaypoint(index);
    setState(() {
      if (index < _waypointLocations.length) {
        _waypointLocations.removeAt(index);
      }
    });
    unawaited(_renderWaypointMode());
  }

  Future<void> _renderWaypointMode() async {
    final mapboxMap = _mapboxMap;
    final manager = _annotationManager;
    if (mapboxMap == null || manager == null) return;

    final coords = _resolvedCoords;
    await manager.deleteAll();

    for (var i = 0; i < coords.length; i++) {
      final w = coords[i];
      final Color color = i == 0 ? AppColors.success : AppColors.primary;
      final image = await buildNumberedPinImage(i + 1, color);
      await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(w.longitude, w.latitude)),
          image: image,
          iconSize: 1.0,
        ),
      );
    }

    final coordinates = coords.map((w) => [w.longitude, w.latitude]).toList();
    await _updatePolyline(mapboxMap, coordinates);

    if (coords.isEmpty) return;

    if (coords.length == 1) {
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              coords.first.longitude,
              coords.first.latitude,
            ),
          ),
          zoom: 13,
        ),
        MapAnimationOptions(duration: 400),
      );
      return;
    }

    final points = coords
        .map((w) => Point(coordinates: Position(w.longitude, w.latitude)))
        .toList();
    final camera = await mapboxMap.cameraForCoordinatesPadding(
      points,
      CameraOptions(),
      MbxEdgeInsets(top: 60, left: 60, bottom: 60, right: 60),
      null,
      null,
    );
    await mapboxMap.flyTo(camera, MapAnimationOptions(duration: 500));
  }

  Future<void> _updatePolyline(
    MapboxMap mapboxMap,
    List<List<double>> coordinates,
  ) async {
    final geojson = jsonEncode({
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': coordinates},
    });

    try {
      if (_routeLayerAdded) {
        await mapboxMap.style.setStyleSourceProperty(
          _routeSourceId,
          'data',
          geojson,
        );
        return;
      }
      final sourceExists = await mapboxMap.style.styleSourceExists(
        _routeSourceId,
      );
      if (!sourceExists) {
        await mapboxMap.style.addSource(
          GeoJsonSource(id: _routeSourceId, data: geojson),
        );
      } else {
        await mapboxMap.style.setStyleSourceProperty(
          _routeSourceId,
          'data',
          geojson,
        );
      }
      final layerExists = await mapboxMap.style.styleLayerExists(_routeLayerId);
      if (!layerExists) {
        await mapboxMap.style.addLayer(
          LineLayer(
            id: _routeLayerId,
            sourceId: _routeSourceId,
            lineColor: 0xFFF98C1F,
            lineWidth: 3.0,
          ),
        );
      }
      _routeLayerAdded = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      buildWhen: (prev, curr) => prev.waypoints != curr.waypoints,
      builder: (context, state) {
        final waypoints = state.waypoints;
        final atLimit = waypoints.length >= _maxWaypoints;
        final hasWaypoints = waypoints.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.darkBgPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.darkBgPrimary,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.darkTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textOnDarkPrimary,
                  size: 20,
                ),
              ),
            ),
            title: Text(
              context.l10n.route_builder_title,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDarkPrimary,
              ),
            ),
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FormBuilder(
                  key: _searchFormKey,
                  child: _RouteSearchBar(
                    atLimit: atLimit,
                    onPlaceSelected: _onWaypointAdded,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Map with pick mode support
              _RouteMapArea(
                atLimit: atLimit,
                isPickMode: _isPickMode,
                onMapCreated: (map, manager) {
                  _mapboxMap = map;
                  _annotationManager = manager;
                  _routeLayerAdded = false;
                  unawaited(_renderWaypointMode());
                },
                onTogglePickMode: _togglePickMode,
                onConfirmPickMode: _confirmPickMode,
                onCenterOnLocation: _centerOnLocation,
              ),

              // Limit banner
              if (atLimit)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: WaypointLimitBanner(
                    message: context.l10n.route_builder_limit_banner,
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.darkBorderPrimary),
              ),

              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.route_builder_section_title,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                    WaypointCounter(count: waypoints.length),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Waypoints list
              Expanded(
                child: hasWaypoints
                    ? ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: waypoints.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: WaypointItemCard(
                            key: ValueKey('wp_$index'),
                            index: index,
                            name: waypoints[index],
                            onDelete: () => _onWaypointRemoved(index),
                          ),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: WaypointsEmptyHint(),
                      ),
              ),
            ],
          ),
          bottomNavigationBar: _RouteCtaBar(hasWaypoints: hasWaypoints),
        );
      },
    );
  }
}

class _RouteSearchBar extends StatelessWidget {
  const _RouteSearchBar({
    required this.atLimit,
    required this.onPlaceSelected,
  });

  final bool atLimit;
  final void Function(String name, AddressLocation? location) onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: atLimit ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: atLimit ? AppColors.darkTertiary : AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(
              LucideIcons.search,
              size: 16,
              color: AppColors.textOnDarkTertiary,
            ),
            const SizedBox(width: 10),
            if (atLimit)
              Expanded(
                child: Text(
                  context.l10n.route_builder_search_placeholder_disabled,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              Expanded(
                child: WaypointSearchField(
                  onPlaceSelected: onPlaceSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapArea extends StatelessWidget {
  const _RouteMapArea({
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
              final manager = await mapboxMap.annotations
                  .createPointAnnotationManager();
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
                        LucideIcons.mapPin,
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

class _RouteCtaBar extends StatelessWidget {
  const _RouteCtaBar({required this.hasWaypoints});

  final bool hasWaypoints;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Opacity(
          opacity: hasWaypoints ? 1.0 : 0.4,
          child: AppButton(
            label: context.l10n.route_builder_continue,
            onPressed: hasWaypoints ? () => Navigator.of(context).pop() : null,
          ),
        ),
      ),
    );
  }
}
