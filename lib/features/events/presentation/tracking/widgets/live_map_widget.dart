import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/initials_marker_icon.dart';

typedef LiveMapReadyCallback = void Function(LiveMapController controller);

class LiveMapWidget extends StatefulWidget {
  const LiveMapWidget({
    super.key,
    required this.onMapReady,
    required this.initialCameraPosition,
  });

  final LiveMapReadyCallback onMapReady;
  final CameraPosition initialCameraPosition;

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
    unawaited(_loadMarkerIcons());
  }

  Future<void> _loadMarkerIcons() async {
    final futures = _mockRiders.map((riders) async {
      final icon = await InitialsMarkerIcon.create(
        firstName: riders.firstName,
        lastName: riders.lastName,
        size: riders.isLead ? 60 : 56,
        backgroundColor: riders.isLead
            ? AppColors.primary
            : AppColors.primaryDark,
        borderColor: riders.isLead ? AppColors.primaryLight : AppColors.primary,
        highlight: riders.isLead,
      );
      return MapEntry(riders.id, icon);
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
    final target = widget.initialCameraPosition.target;
    final markers = _iconsLoaded
        ? _buildRiderMarkers(target)
        : const <Marker>{};

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

  Set<Marker> _buildRiderMarkers(LatLng target) {
    return _mockRiders.map((r) {
      final position = LatLng(
        target.latitude + r.offsetLat,
        target.longitude + r.offsetLng,
      );
      final icon = _iconsById[r.id];

      return Marker(
        markerId: MarkerId(r.id),
        position: position,
        infoWindow: InfoWindow(
          title: '${r.firstName} ${r.lastName} (${r.role})',
        ),
        icon: icon!,
      );
    }).toSet();
  }
}

class RiderMarkerData {
  const RiderMarkerData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isLead,
    required this.offsetLat,
    required this.offsetLng,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final bool isLead;
  final double offsetLat;
  final double offsetLng;
}

const List<RiderMarkerData> _mockRiders = [
  RiderMarkerData(
    id: 'lead',
    firstName: 'Alex',
    lastName: 'Rivera',
    role: 'Lead',
    isLead: true,
    offsetLat: 0.00020,
    offsetLng: 0.00025,
  ),
  RiderMarkerData(
    id: 'rider-1',
    firstName: 'Mark',
    lastName: 'Thompson',
    role: 'Rider',
    isLead: false,
    offsetLat: -0.00018,
    offsetLng: 0.00032,
  ),
  RiderMarkerData(
    id: 'rider-2',
    firstName: 'Sarah',
    lastName: 'Jenkins',
    role: 'Rider',
    isLead: false,
    offsetLat: 0.00034,
    offsetLng: -0.00014,
  ),
  RiderMarkerData(
    id: 'rider-3',
    firstName: 'Maria',
    lastName: 'Garcia',
    role: 'Rider',
    isLead: false,
    offsetLat: -0.00030,
    offsetLng: -0.00022,
  ),
];

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
