import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/initials_marker_icon.dart';
import 'package:rideglory/design_system/design_system.dart';

typedef LiveMapReadyCallback = void Function(LiveMapController controller);

class LiveMapWidget extends StatefulWidget {
  const LiveMapWidget({
    super.key,
    required this.onMapReady,
    required this.initialCameraOptions,
    required this.riders,
  });

  final LiveMapReadyCallback onMapReady;
  final CameraOptions initialCameraOptions;
  final List<RiderTrackingModel> riders;

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  PointAnnotationManager? _annotationManager;
  final Map<String, PointAnnotation> _annotationsById = {};
  final Map<String, Uint8List> _iconBytesById = {};
  bool _iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadMarkerIcons());
    });
  }

  @override
  void didUpdateWidget(LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_riderSignature(oldWidget.riders) != _riderSignature(widget.riders)) {
      setState(() {
        _iconsLoaded = false;
        _iconBytesById.clear();
      });
      unawaited(_loadMarkerIcons());
    }
  }

  String _riderSignature(List<RiderTrackingModel> riders) {
    return riders
        .map((rider) => '${rider.userId}:${rider.fullName}:${rider.role.name}')
        .join('|');
  }

  Future<void> _loadMarkerIcons() async {
    if (widget.riders.isEmpty) {
      if (!mounted) return;
      setState(() => _iconsLoaded = true);
      return;
    }

    final futures = widget.riders.map((rider) async {
      final isLead = rider.role == RiderTrackingRole.lead;
      final bytes = await InitialsMarkerIcon.createBytes(
        fullName: rider.fullName,
        colorScheme: context.colorScheme,
        size: isLead ? 60 : 56,
        backgroundColor: context.colorScheme.primary,
        borderColor: context.colorScheme.primary,
        highlight: isLead,
      );
      return MapEntry(rider.userId, bytes);
    });

    final entries = await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      for (final entry in entries) {
        _iconBytesById[entry.key] = entry.value;
      }
      _iconsLoaded = true;
    });
    await _updateAnnotations();
  }

  Future<void> _updateAnnotations() async {
    final manager = _annotationManager;
    if (manager == null || !_iconsLoaded) return;

    // Remove annotations for riders no longer present.
    final currentIds = widget.riders.map((r) => r.userId).toSet();
    final toRemove = _annotationsById.keys
        .where((id) => !currentIds.contains(id))
        .toList();
    for (final id in toRemove) {
      final annotation = _annotationsById.remove(id);
      if (annotation != null) {
        await manager.delete(annotation);
      }
    }

    // Add or update annotations for current riders.
    for (final rider in widget.riders) {
      final bytes = _iconBytesById[rider.userId];
      if (bytes == null) continue;

      final point = Point(
        coordinates: Position(rider.longitude, rider.latitude),
      );

      final existing = _annotationsById[rider.userId];
      if (existing != null) {
        final updated = PointAnnotation(
          id: existing.id,
          geometry: point,
          image: bytes,
        );
        await manager.update(updated);
        _annotationsById[rider.userId] = updated;
      } else {
        final created = await manager.create(
          PointAnnotationOptions(geometry: point, image: bytes),
        );
        _annotationsById[rider.userId] = created;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      viewport: CameraViewportState(
        center: widget.initialCameraOptions.center,
        zoom: widget.initialCameraOptions.zoom,
      ),
      styleUri: MapboxStyles.STANDARD,
      onMapCreated: (mapboxMap) async {
        _annotationManager = await mapboxMap.annotations
            .createPointAnnotationManager();
        widget.onMapReady(LiveMapController(mapboxMap));
        await _updateAnnotations();
      },
    );
  }
}

class LiveMapController {
  LiveMapController(this._mapboxMap);

  final MapboxMap _mapboxMap;
  double _currentZoom = 15.0;

  Future<void> zoomIn() async {
    _currentZoom += 1;
    await _mapboxMap.flyTo(
      CameraOptions(zoom: _currentZoom),
      MapAnimationOptions(duration: 300),
    );
  }

  Future<void> zoomOut() async {
    _currentZoom -= 1;
    await _mapboxMap.flyTo(
      CameraOptions(zoom: _currentZoom),
      MapAnimationOptions(duration: 300),
    );
  }

  Future<void> centerOnMyLocation() async {
    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    );
    await _mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: _currentZoom < 15 ? 15 : _currentZoom,
      ),
      MapAnimationOptions(duration: 500),
    );
  }
}
