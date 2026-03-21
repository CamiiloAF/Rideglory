import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/initials_marker_icon.dart';
import 'package:rideglory/design_system/design_system.dart';

typedef LiveMapReadyCallback = void Function(LiveMapController controller);

class LiveMapWidget extends StatefulWidget {
  const LiveMapWidget({
    super.key,
    required this.onMapReady,
    required this.initialCameraPosition,
    required this.riders,
  });

  final LiveMapReadyCallback onMapReady;
  final CameraPosition initialCameraPosition;
  final List<RiderTrackingModel> riders;

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  final Map<String, BitmapDescriptor> _iconsById = {};
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
        _iconsById.clear();
      });
      unawaited(_loadMarkerIcons());
    }
  }

  String _riderSignature(List<RiderTrackingModel> riders) {
    return riders
        .map((r) => '${r.userId}:${r.firstName}:${r.lastName}:${r.role.name}')
        .join('|');
  }

  Future<void> _loadMarkerIcons() async {
    if (widget.riders.isEmpty) {
      if (!mounted) return;
      setState(() {
        _iconsLoaded = true;
      });
      return;
    }

    final futures = widget.riders.map((rider) async {
      final isLead = rider.role == RiderTrackingRole.lead;
      final icon = await InitialsMarkerIcon.create(
        firstName: rider.firstName,
        lastName: rider.lastName,
        colorScheme: context.colorScheme,
        size: isLead ? 60 : 56,
        backgroundColor: context.colorScheme.primary,
        borderColor: context.colorScheme.primary,
        highlight: isLead,
      );
      return MapEntry(rider.userId, icon);
    });

    final entries = await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      for (final e in entries) {
        _iconsById[e.key] = e.value;
      }
      _iconsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = _iconsLoaded ? _buildRiderMarkers() : const <Marker>{};

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: GoogleMap(
        initialCameraPosition: widget.initialCameraPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          if (!_controller.isCompleted) {
            _controller.complete(controller);
            widget.onMapReady(LiveMapController(controller));
          }
        },
        markers: markers,
      ),
    );
  }

  Set<Marker> _buildRiderMarkers() {
    return widget.riders.map((r) {
      final position = LatLng(r.latitude, r.longitude);
      final icon = _iconsById[r.userId];

      return Marker(
        markerId: MarkerId(r.userId),
        position: position,
        infoWindow: InfoWindow(title: '${r.firstName} ${r.lastName}'.trim()),
        icon: icon ?? BitmapDescriptor.defaultMarker,
      );
    }).toSet();
  }
}

class LiveMapController {
  LiveMapController(this._controller);

  final GoogleMapController _controller;

  Future<void> zoomIn() async {
    final zoom = await _controller.getZoomLevel();
    await _controller.animateCamera(CameraUpdate.zoomTo(zoom + 1));
  }

  Future<void> zoomOut() async {
    final zoom = await _controller.getZoomLevel();
    await _controller.animateCamera(CameraUpdate.zoomTo(zoom - 1));
  }

  Future<void> centerOnMyLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final zoom = await _controller.getZoomLevel();
    await _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: zoom < 15 ? 15 : zoom,
        ),
      ),
    );
  }
}
