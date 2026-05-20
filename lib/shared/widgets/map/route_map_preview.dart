import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/models/address_location.dart';

/// A widget that shows a Mapbox map preview with origin and destination
/// markers. It geocodes address strings asynchronously via [PlaceService]
/// and renders a [MapWidget].
class RouteMapPreview extends StatefulWidget {
  const RouteMapPreview({
    super.key,
    this.meetingPoint,
    this.destination,
    this.onViewMapTap,
  });

  final String? meetingPoint;
  final String? destination;
  final VoidCallback? onViewMapTap;

  @override
  State<RouteMapPreview> createState() => _RouteMapPreviewState();
}

class _RouteMapPreviewState extends State<RouteMapPreview> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _mapLoadError = false;

  ResultState<AddressLocation> _originResult = const ResultState.initial();
  ResultState<AddressLocation> _destResult = const ResultState.initial();

  Timer? _debounceOrigin;
  Timer? _debounceDest;

  AddressLocation? get _origin => _originResult.whenOrNull(data: (d) => d);
  AddressLocation? get _dest => _destResult.whenOrNull(data: (d) => d);

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

  Future<void> _geocodeAddress(
    String? address, {
    required bool isOrigin,
  }) async {
    if (address == null || address.trim().length < 4) return;

    setState(() {
      if (isOrigin) {
        _originResult = const ResultState.loading();
      } else {
        _destResult = const ResultState.loading();
      }
    });

    try {
      final dto = await getIt<PlaceService>()
          .geocode(address.trim())
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      final location = AddressLocation(
        latitude: dto.latitude,
        longitude: dto.longitude,
        label: dto.formattedAddress,
      );

      setState(() {
        if (isOrigin) {
          _originResult = ResultState.data(data: location);
        } else {
          _destResult = ResultState.data(data: location);
        }
      });
      await _fitMapBounds();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final exception = DomainException(message: error.toString());
        if (isOrigin) {
          _originResult = ResultState.error(error: exception);
        } else {
          _destResult = ResultState.error(error: exception);
        }
      });
    }
  }

  Future<void> _fitMapBounds() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    final origin = _origin;
    final dest = _dest;

    if (origin != null && dest != null) {
      final coordinates = [
        Point(coordinates: Position(origin.longitude, origin.latitude)),
        Point(coordinates: Position(dest.longitude, dest.latitude)),
      ];
      final camera = await mapboxMap.cameraForCoordinatesPadding(
        coordinates,
        CameraOptions(),
        MbxEdgeInsets(top: 60, left: 60, bottom: 60, right: 60),
        null,
        null,
      );
      await mapboxMap.flyTo(camera, MapAnimationOptions(duration: 500));
    } else if (origin != null) {
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(origin.longitude, origin.latitude),
          ),
          zoom: 13,
        ),
        MapAnimationOptions(duration: 400),
      );
    } else if (dest != null) {
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(dest.longitude, dest.latitude)),
          zoom: 13,
        ),
        MapAnimationOptions(duration: 400),
      );
    }
    await _updateAnnotations();
  }

  Future<void> _updateAnnotations() async {
    final manager = _annotationManager;
    if (manager == null) return;

    await manager.deleteAll();

    final origin = _origin;
    final dest = _dest;

    if (origin != null) {
      await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(origin.longitude, origin.latitude),
          ),
        ),
      );
    }
    if (dest != null) {
      await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(dest.longitude, dest.latitude)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounceOrigin?.cancel();
    _debounceDest?.cancel();
    super.dispose();
  }

  bool get _isLoading => _originResult is Loading || _destResult is Loading;

  bool get _hasError => (_originResult is Error) || (_destResult is Error);

  bool get _hasCoordsToShow => _origin != null || _dest != null;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapMd,
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
            color: cs.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (_hasCoordsToShow && !_mapLoadError)
                MapWidget(
                  viewport: CameraViewportState(
                    center: Point(
                      coordinates: Position(
                        (_origin ?? _dest!).longitude,
                        (_origin ?? _dest!).latitude,
                      ),
                    ),
                    zoom: 12,
                  ),
                  styleUri: MapboxStyles.DARK,
                  onMapCreated: (mapboxMap) async {
                    _mapboxMap = mapboxMap;
                    _annotationManager = await mapboxMap.annotations
                        .createPointAnnotationManager();
                    await _fitMapBounds();
                  },
                  onMapLoadErrorListener: (MapLoadingErrorEventData data) {
                    if (!mounted) return;
                    setState(() => _mapLoadError = true);
                  },
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: cs.onSurfaceVariant,
                      ),
                      AppSpacing.gapSm,
                      Text(
                        'Vista previa del mapa',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Ingresa las dirección para ver la ruta',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

              // Error banner
              if (_hasError)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.l10n.map_geocodeError,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // View-on-map button
              if (widget.onViewMapTap != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: cs.surface.withValues(alpha: 0),
                      child: InkWell(
                        onTap: widget.onViewMapTap,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: cs.onSurface.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 20,
                                color: cs.onPrimary,
                              ),
                              AppSpacing.hGapSm,
                              Text(
                                'Ver en mapa',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Loading spinner
              if (_isLoading)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: AppLoadingIndicator(
                        variant: AppLoadingIndicatorVariant.inline,
                      ),
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
