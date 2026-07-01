import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/initials_marker_icon.dart';

typedef LiveMapReadyCallback = void Function(LiveMapController controller);

class LiveMapWidget extends StatefulWidget {
  const LiveMapWidget({
    super.key,
    required this.onMapReady,
    required this.initialCameraOptions,
    required this.riders,
    this.currentUserId,
    this.sosUserId,
    this.onMarkerTap,
    this.onMapError,
  });

  final LiveMapReadyCallback onMapReady;
  final CameraOptions initialCameraOptions;
  final List<RiderTrackingModel> riders;
  final String? currentUserId;

  /// User id of the rider currently broadcasting an SOS, if any. That rider's
  /// marker is rendered with the SOS variant.
  final String? sosUserId;

  /// Called when the user taps a rider's marker on the map.
  final ValueChanged<RiderTrackingModel>? onMarkerTap;
  final ValueChanged<String>? onMapError;

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  Cancelable? _tapEvents;
  final Map<String, PointAnnotation> _annotationsById = {};
  // Style-image ids registered per rider. Each rider's icon is added to the map
  // style ONCE under a stable name and referenced via `iconImage`, so moving a
  // marker only updates its geometry — no per-move image churn, no dangling
  // "Required image missing" references.
  final Set<String> _registeredImageIds = {};
  bool _iconsLoaded = false;
  // Style images can only be added once the style is fully loaded; adding them
  // in onMapCreated is too early and silently no-ops (markers never render).
  bool _styleLoaded = false;

  /// When true, the camera follows the current user's marker on each position
  /// update (keeping the current zoom). Disabled as soon as the user pans the
  /// map by hand. Off by default so the map stays where it loads.
  bool _isFollowing = false;

  /// Default zoom applied when the user taps the "center" button.
  static const double _defaultZoom = 16.0;

  /// Single source of truth for the zoom level shared by the zoom +/- buttons
  /// and the center button, so tapping center re-bases the +/- steps too.
  double _currentZoom = _defaultZoom;

  // Stable viewport instance. MapWidget only re-applies the viewport when this
  // reference changes, so we keep the same one across rider-update rebuilds (no
  // camera snap) and only rebuild it when the initial camera options change
  // (e.g. the GPS fix refines the fallback location).
  CameraViewportState? _viewport;
  CameraOptions? _viewportSource;

  CameraViewportState _resolveViewport() {
    if (_viewport == null ||
        !identical(_viewportSource, widget.initialCameraOptions)) {
      _viewportSource = widget.initialCameraOptions;
      _viewport = CameraViewportState(
        center: widget.initialCameraOptions.center,
        zoom: widget.initialCameraOptions.zoom,
      );
      // Keep the shared zoom in sync with the camera actually applied.
      _currentZoom = widget.initialCameraOptions.zoom ?? _currentZoom;
    }
    return _viewport!;
  }

  String _imageIdFor(String userId) => 'rider_marker_$userId';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadMarkerIcons());
    });
  }

  @override
  void dispose() {
    _tapEvents?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_riderIdentitySignature(oldWidget.riders, oldWidget.sosUserId) !=
        _riderIdentitySignature(widget.riders, widget.sosUserId)) {
      // Rider set or a marker variant (lead/SOS) changed → re-register icons.
      unawaited(_loadMarkerIcons());
    } else if (_riderPositionSignature(oldWidget.riders) !=
        _riderPositionSignature(widget.riders)) {
      // Only positions changed → skip icon reload, just move the markers.
      unawaited(_updateAnnotations());
      if (_isFollowing) unawaited(_easeToCurrentUser(durationMs: 350));
    }
  }

  RiderMarkerVariant _variantFor(RiderTrackingModel rider) {
    if (widget.sosUserId != null && rider.userId == widget.sosUserId) {
      return RiderMarkerVariant.sos;
    }
    if (rider.role == RiderTrackingRole.lead) {
      return RiderMarkerVariant.lead;
    }
    return RiderMarkerVariant.rider;
  }

  /// Smoothly recenters on the current user. Uses the live marker position when
  /// available, falling back to a fresh GPS fix. When [zoom] is null the current
  /// zoom is preserved (used while following); the center button passes a fixed
  /// default zoom so it always lands at the same comfortable level.
  Future<void> _easeToCurrentUser({int durationMs = 500, double? zoom}) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    double? latitude;
    double? longitude;
    final uid = widget.currentUserId;
    if (uid != null) {
      for (final rider in widget.riders) {
        if (rider.userId == uid) {
          latitude = rider.latitude;
          longitude = rider.longitude;
          break;
        }
      }
    }

    if (latitude == null || longitude == null) {
      try {
        final position = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
          ),
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {
        return;
      }
    }

    if (zoom != null) _currentZoom = zoom;

    await mapboxMap.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: durationMs),
    );
  }

  void _enableFollowAndCenter() {
    _isFollowing = true;
    // Tapping center resets the shared zoom back to the default level, so the
    // zoom +/- buttons step from there too (no stale, jarring zoom-out).
    unawaited(_easeToCurrentUser(durationMs: 600, zoom: _defaultZoom));
  }

  /// Centers the camera on an explicit coordinate (a rider selected from the
  /// list or by tapping its marker). Stops following and snaps to the default
  /// zoom so the selected rider is clearly framed.
  void _centerOnCoordinate(double latitude, double longitude) {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    _isFollowing = false;
    _currentZoom = _defaultZoom;
    unawaited(
      mapboxMap.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: _defaultZoom,
        ),
        MapAnimationOptions(duration: 500),
      ),
    );
  }

  void _handleMarkerTap(PointAnnotation annotation) {
    final onMarkerTap = widget.onMarkerTap;
    if (onMarkerTap == null) return;
    String? userId;
    for (final entry in _annotationsById.entries) {
      if (entry.value.id == annotation.id) {
        userId = entry.key;
        break;
      }
    }
    if (userId == null) return;
    for (final rider in widget.riders) {
      if (rider.userId == userId) {
        onMarkerTap(rider);
        return;
      }
    }
  }

  Future<void> _zoomIn() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    _currentZoom += 1;
    await mapboxMap.flyTo(
      CameraOptions(zoom: _currentZoom),
      MapAnimationOptions(duration: 300),
    );
  }

  Future<void> _zoomOut() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    _currentZoom -= 1;
    await mapboxMap.flyTo(
      CameraOptions(zoom: _currentZoom),
      MapAnimationOptions(duration: 300),
    );
  }

  String _riderIdentitySignature(
    List<RiderTrackingModel> riders,
    String? sosUserId,
  ) {
    String variant(RiderTrackingModel r) {
      if (sosUserId != null && r.userId == sosUserId) return 'sos';
      return r.role.name;
    }

    return riders
        .map((r) => '${r.userId}:${r.fullName}:${variant(r)}')
        .join('|');
  }

  String _riderPositionSignature(List<RiderTrackingModel> riders) {
    return riders
        .map((r) => '${r.userId}:${r.latitude}:${r.longitude}')
        .join('|');
  }

  Future<void> _loadMarkerIcons() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !_styleLoaded) {
      // Map/style not ready yet — onStyleLoadedListener will re-run this.
      return;
    }

    if (widget.riders.isEmpty) {
      if (!mounted) return;
      setState(() => _iconsLoaded = true);
      await _updateAnnotations();
      return;
    }

    final double dpr = MediaQuery.of(context).devicePixelRatio;

    await Future.wait(
      widget.riders.map((rider) async {
        final bitmap = await InitialsMarkerIcon.createBitmap(
          fullName: rider.fullName,
          variant: _variantFor(rider),
          devicePixelRatio: dpr,
        );
        await mapboxMap.style.addStyleImage(
          _imageIdFor(rider.userId),
          dpr,
          MbxImage(
            width: bitmap.width,
            height: bitmap.height,
            data: bitmap.data,
          ),
          false,
          <ImageStretches>[],
          <ImageStretches>[],
          null,
        );
        _registeredImageIds.add(rider.userId);
      }),
    );

    if (!mounted) return;
    setState(() => _iconsLoaded = true);
    await _updateAnnotations();
  }

  /// Re-entrancy guard: position updates fire rapidly while moving, and
  /// `_applyAnnotations` awaits async map calls. Without serialization two
  /// concurrent runs both see "no annotation yet" for a rider and each create
  /// one → a duplicated, orphaned marker. We run one at a time and coalesce.
  bool _updatingAnnotations = false;
  bool _annotationsDirty = false;

  Future<void> _updateAnnotations() async {
    if (_updatingAnnotations) {
      _annotationsDirty = true;
      return;
    }
    _updatingAnnotations = true;
    try {
      do {
        _annotationsDirty = false;
        await _applyAnnotations();
      } while (_annotationsDirty);
    } finally {
      _updatingAnnotations = false;
    }
  }

  Future<void> _applyAnnotations() async {
    final manager = _annotationManager;
    if (manager == null || !_iconsLoaded) return;

    // Remove annotations for riders no longer present.
    final currentIds = widget.riders.map((rider) => rider.userId).toSet();
    final toRemove = _annotationsById.keys
        .where((id) => !currentIds.contains(id))
        .toList();
    for (final id in toRemove) {
      final annotation = _annotationsById.remove(id);
      if (annotation != null) {
        await manager.delete(annotation);
      }
    }

    // Add or move annotations for current riders.
    for (final rider in widget.riders) {
      if (!_registeredImageIds.contains(rider.userId)) continue;

      final point = Point(
        coordinates: Position(rider.longitude, rider.latitude),
      );

      final existing = _annotationsById[rider.userId];
      if (existing != null) {
        // Only the position moves; the named style image stays referenced.
        existing.geometry = point;
        await manager.update(existing);
      } else {
        final created = await manager.create(
          PointAnnotationOptions(
            geometry: point,
            iconImage: _imageIdFor(rider.userId),
          ),
        );
        _annotationsById[rider.userId] = created;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      // A stable viewport instance — re-applied only when it changes, so rebuilds
      // on rider position updates never snap the camera back to the start.
      viewport: _resolveViewport(),
      styleUri: MapboxStyles.DARK,
      onMapCreated: (mapboxMap) async {
        _mapboxMap = mapboxMap;
        await mapboxMap.scaleBar.updateSettings(
          ScaleBarSettings(enabled: false),
        );
        final manager = await mapboxMap.annotations
            .createPointAnnotationManager();
        _annotationManager = manager;
        _tapEvents = manager.tapEvents(onTap: _handleMarkerTap);
        widget.onMapReady(
          LiveMapController(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onRecenter: _enableFollowAndCenter,
            onCenterOnCoordinate: _centerOnCoordinate,
          ),
        );
        // Covers the case where the style loaded before the manager was ready.
        await _loadMarkerIcons();
      },
      onStyleLoadedListener: (_) {
        // The style is ready: register the marker images and draw them.
        _styleLoaded = true;
        unawaited(_loadMarkerIcons());
      },
      onScrollListener: (_) {
        // The user is panning by hand → stop chasing the marker and leave the
        // camera where they drag it.
        _isFollowing = false;
      },
      onMapLoadErrorListener: (MapLoadingErrorEventData data) {
        widget.onMapError?.call(data.message);
      },
    );
  }
}

/// Thin facade over the map widget's state. All camera logic (zoom level,
/// follow mode) lives in the state so the zoom buttons and the center button
/// share one source of truth.
class LiveMapController {
  LiveMapController({
    this.onZoomIn,
    this.onZoomOut,
    this.onRecenter,
    this.onCenterOnCoordinate,
  });

  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onRecenter;
  final void Function(double latitude, double longitude)? onCenterOnCoordinate;

  void zoomIn() => onZoomIn?.call();
  void zoomOut() => onZoomOut?.call();
  void centerOnMyLocation() => onRecenter?.call();

  /// Centers the camera on a specific coordinate (e.g. a selected rider).
  void centerOn(double latitude, double longitude) =>
      onCenterOnCoordinate?.call(latitude, longitude);
}
