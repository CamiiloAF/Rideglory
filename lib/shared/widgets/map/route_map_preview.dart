import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideglory/core/theme/app_colors.dart';

/// A widget that shows a Google Map preview with origin and destination markers.
/// It geocodes address strings into coordinates and renders a GoogleMap.
class RouteMapPreview extends StatefulWidget {
  final String? meetingPoint;
  final String? destination;

  const RouteMapPreview({
    super.key,
    this.meetingPoint,
    this.destination,
  });

  @override
  State<RouteMapPreview> createState() => _RouteMapPreviewState();
}

class _RouteMapPreviewState extends State<RouteMapPreview> {
  GoogleMapController? _mapController;
  LatLng? _origin;
  LatLng? _dest;
  bool _isLoading = false;

  Timer? _debounceOrigin;
  Timer? _debounceDest;

  @override
  void initState() {
    super.initState();
    _geocodeBoth();
  }

  @override
  void didUpdateWidget(RouteMapPreview old) {
    super.didUpdateWidget(old);
    if (old.meetingPoint != widget.meetingPoint) {
      _debounceOrigin?.cancel();
      _debounceOrigin = Timer(const Duration(milliseconds: 800), () {
        _geocodeAddress(widget.meetingPoint, isOrigin: true);
      });
    }
    if (old.destination != widget.destination) {
      _debounceDest?.cancel();
      _debounceDest = Timer(const Duration(milliseconds: 800), () {
        _geocodeAddress(widget.destination, isOrigin: false);
      });
    }
  }

  Future<void> _geocodeBoth() async {
    await Future.wait([
      _geocodeAddress(widget.meetingPoint, isOrigin: true),
      _geocodeAddress(widget.destination, isOrigin: false),
    ]);
  }

  Future<void> _geocodeAddress(String? address, {required bool isOrigin}) async {
    if (address == null || address.trim().length < 4) return;
    setState(() => _isLoading = true);
    try {
      final locations = await locationFromAddress(address.trim()).timeout(
        const Duration(seconds: 5),
      );
      if (locations.isNotEmpty && mounted) {
        final latlng = LatLng(locations.first.latitude, locations.first.longitude);
        setState(() {
          if (isOrigin) {
            _origin = latlng;
          } else {
            _dest = latlng;
          }
        });
        _fitMapBounds();
      }
    } catch (_) {
      // geocoding failed silently
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    if (_origin != null && _dest != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _origin!.latitude < _dest!.latitude ? _origin!.latitude : _dest!.latitude,
          _origin!.longitude < _dest!.longitude ? _origin!.longitude : _dest!.longitude,
        ),
        northeast: LatLng(
          _origin!.latitude > _dest!.latitude ? _origin!.latitude : _dest!.latitude,
          _origin!.longitude > _dest!.longitude ? _origin!.longitude : _dest!.longitude,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } else if (_origin != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_origin!));
    } else if (_dest != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_dest!));
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: _origin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: widget.meetingPoint ?? 'Punto de encuentro',
          ),
        ),
      );
    }
    if (_dest != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _dest!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.destination ?? 'Destino',
          ),
        ),
      );
    }
    return markers;
  }

  @override
  void dispose() {
    _debounceOrigin?.cancel();
    _debounceDest?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCoordsToShow = _origin != null || _dest != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            color: AppColors.surfaceGray,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (hasCoordsToShow)
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _origin ?? _dest!,
                    zoom: 12,
                  ),
                  markers: _buildMarkers(),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitMapBounds();
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vista previa del mapa',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Ingresa las dirección para ver la ruta',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isLoading)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
