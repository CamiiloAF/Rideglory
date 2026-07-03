import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/models/address_location.dart';

/// Creates a circular numbered pin bitmap for use as a Mapbox annotation image.
Future<Uint8List> buildNumberedPinImage(int number, Color color) async {
  const double size = 28.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2,
    Paint()..color = color,
  );

  final textPainter = TextPainter(
    text: TextSpan(
      text: '$number',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// A widget that shows a Mapbox map preview with origin and destination
/// markers. It geocodes address strings asynchronously via [PlaceService]
/// and renders a [MapWidget].
///
/// [inCard] mode renders at 130px height with bottom-only rounded corners and
/// no outer border, matching the Route Card design.
///
/// When [meetingPointCoords] or [destinationCoords] are provided, geocoding is
/// skipped for those points and the coordinates are used directly.
///
/// When [waypointCoords] is provided, the map renders numbered pins at each
/// waypoint and draws an orange polyline connecting them in order. The
/// [meetingPoint]/[destination] params are ignored in this mode.
class RouteMapPreview extends StatefulWidget {
  const RouteMapPreview({
    super.key,
    this.meetingPoint,
    this.destination,
    this.meetingPointCoords,
    this.destinationCoords,
    this.waypointCoords,
    this.onViewMapTap,
    this.inCard = false,
    this.suppressPreview = false,
  });

  final String? meetingPoint;
  final String? destination;
  final AddressLocation? meetingPointCoords;
  final AddressLocation? destinationCoords;

  /// When non-null, renders numbered pins + polyline for custom routes instead
  /// of the simple meeting-point/destination pair.
  final List<AddressLocation>? waypointCoords;

  final VoidCallback? onViewMapTap;
  final bool inCard;

  /// Cuando true, reemplaza el MapWidget con un contenedor estático del mismo
  /// tamaño. Evita tener dos instancias de Mapbox/Metal activas al mismo tiempo
  /// durante transiciones de pantalla.
  final bool suppressPreview;

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

  static const _routeSourceId = 'rg-route-source';
  static const _routeLayerId = 'rg-route-layer';
  bool _routeLayerAdded = false;

  // Props estables para MapWidget: evitan que Mapbox reaccione a diferencias
  // de referencia en cada rebuild del padre.
  // • _stableViewport  → solo se actualiza cuando los waypoints cambian
  // • _mapKey          → GlobalKey garantiza que Flutter no recree el widget
  // • _onMapCreated    → tear-off almacenado una vez en initState
  // • _onMapLoadError  → idem
  final _mapKey = GlobalKey();
  late CameraViewportState _stableViewport;
  late void Function(MapboxMap) _onMapCreated;
  late void Function(MapLoadingErrorEventData) _onMapLoadError;

  AddressLocation? get _origin => _originResult.whenOrNull(data: (d) => d);
  AddressLocation? get _dest => _destResult.whenOrNull(data: (d) => d);

  bool get _isWaypointMode => widget.waypointCoords != null;

  @override
  void initState() {
    super.initState();
    _stableViewport = _computeInitialViewport();
    _onMapCreated = _handleMapCreated;
    _onMapLoadError = _handleMapLoadError;
    _initCoords();
  }

  CameraViewportState _computeInitialViewport() {
    if (_isWaypointMode) {
      final first = widget.waypointCoords?.firstOrNull;
      if (first != null) {
        return CameraViewportState(
          center: Point(coordinates: Position(first.longitude, first.latitude)),
          zoom: 12,
        );
      }
    }
    final point = widget.meetingPointCoords ?? widget.destinationCoords;
    if (point != null) {
      return CameraViewportState(
        center: Point(coordinates: Position(point.longitude, point.latitude)),
        zoom: 12,
      );
    }
    // Colombia como fallback inicial (la cámara se mueve luego vía flyTo)
    return CameraViewportState(
      center: Point(coordinates: Position(-74.0721, 4.7110)),
      zoom: 5,
    );
  }

  void _initCoords() {
    if (widget.meetingPointCoords != null) {
      _originResult = ResultState.data(data: widget.meetingPointCoords!);
    }
    if (widget.destinationCoords != null) {
      _destResult = ResultState.data(data: widget.destinationCoords!);
    }
    _geocodeBoth();
  }

  @override
  void didUpdateWidget(RouteMapPreview old) {
    super.didUpdateWidget(old);

    if (_isWaypointMode) {
      if (old.waypointCoords != widget.waypointCoords) {
        _stableViewport = _computeInitialViewport();
        unawaited(_renderWaypointMode());
      }
      return;
    }

    if (old.meetingPointCoords != widget.meetingPointCoords &&
        widget.meetingPointCoords != null) {
      setState(() {
        _originResult = ResultState.data(data: widget.meetingPointCoords!);
      });
      unawaited(_fitMapBounds());
    } else if (old.meetingPoint != widget.meetingPoint &&
        widget.meetingPointCoords == null) {
      _debounceOrigin?.cancel();
      _debounceOrigin = Timer(const Duration(milliseconds: 800), () {
        _geocodeAddress(widget.meetingPoint, isOrigin: true);
      });
    }

    if (old.destinationCoords != widget.destinationCoords &&
        widget.destinationCoords != null) {
      setState(() {
        _destResult = ResultState.data(data: widget.destinationCoords!);
      });
      unawaited(_fitMapBounds());
    } else if (old.destination != widget.destination &&
        widget.destinationCoords == null) {
      _debounceDest?.cancel();
      _debounceDest = Timer(const Duration(milliseconds: 800), () {
        _geocodeAddress(widget.destination, isOrigin: false);
      });
    }
  }

  Future<void> _geocodeBoth() async {
    if (_isWaypointMode) return;
    await Future.wait([
      if (widget.meetingPointCoords == null)
        _geocodeAddress(widget.meetingPoint, isOrigin: true),
      if (widget.destinationCoords == null)
        _geocodeAddress(widget.destination, isOrigin: false),
    ]);
    if (widget.meetingPointCoords != null || widget.destinationCoords != null) {
      await _fitMapBounds();
    }
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

  /// Ejecuta una operación de cámara del mapa tolerando el cierre del canal de
  /// plataforma. Si el `MapWidget` se dispuso mientras la animación (`flyTo`)
  /// seguía en vuelo —p. ej. al navegar del detalle del evento al wizard de
  /// inscripción— Mapbox lanza una `PlatformException`. Como estas llamadas van
  /// `unawaited`, sin capturar escalaría a un error async global (que en tests
  /// e2e tumba la corrida completa). La tragamos igual que en
  /// [_updateWaypointAnnotations].
  Future<void> _guardMapCamera(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Canal del mapa cerrado (widget dispuesto); es un preview, ignorable.
    }
  }

  Future<void> _fitMapBounds() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    if (_isWaypointMode) {
      await _renderWaypointMode();
      return;
    }

    final origin = _origin;
    final dest = _dest;

    final simplePoints = [if (origin != null) origin, if (dest != null) dest];

    await _updateWaypointAnnotations(simplePoints);
    await _updatePolyline(mapboxMap, simplePoints);

    await _guardMapCamera(() async {
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
    });
  }

  Future<void> _renderWaypointMode() async {
    if (!mounted) return;
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    final waypoints = widget.waypointCoords ?? [];

    await _updateWaypointAnnotations(waypoints);
    if (!mounted) return;
    await _updatePolyline(mapboxMap, waypoints);

    if (waypoints.isEmpty) return;

    await _guardMapCamera(() async {
      if (waypoints.length == 1) {
        await mapboxMap.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(
                waypoints.first.longitude,
                waypoints.first.latitude,
              ),
            ),
            zoom: 13,
          ),
          MapAnimationOptions(duration: 400),
        );
        return;
      }

      final points = waypoints
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
    });
  }

  Future<void> _updateWaypointAnnotations(
    List<AddressLocation> waypoints,
  ) async {
    final manager = _annotationManager;
    if (manager == null) return;
    if (!mounted) return;

    // The annotation manager's platform channel may have closed if the MapWidget
    // was replaced or disposed while this widget is still mounted. Catch any
    // PlatformException so the caller doesn't crash.
    try {
      await manager.deleteAll();
      for (var i = 0; i < waypoints.length; i++) {
        if (!mounted) return;
        final w = waypoints[i];
        final color = i == 0 ? AppColors.success : AppColors.primary;
        final image = await buildNumberedPinImage(i + 1, color);
        if (!mounted) return;
        await manager.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(w.longitude, w.latitude)),
            image: image,
            iconSize: 1.0,
          ),
        );
      }
    } catch (_) {
      // Channel closed; reset manager so next map creation re-initialises it.
      _annotationManager = null;
    }
  }

  Future<void> _updatePolyline(
    MapboxMap mapboxMap,
    List<AddressLocation> waypoints,
  ) async {
    // LineString requires ≥2 positions. With fewer points use an empty
    // FeatureCollection so the source is cleared without a parse error.
    final geojson = waypoints.length >= 2
        ? jsonEncode({
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates': waypoints
                  .map((w) => [w.longitude, w.latitude])
                  .toList(),
            },
          })
        : jsonEncode({'type': 'FeatureCollection', 'features': []});

    try {
      if (_routeLayerAdded) {
        await mapboxMap.style.setStyleSourceProperty(
          _routeSourceId,
          'data',
          geojson,
        );
      } else {
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

        final layerExists = await mapboxMap.style.styleLayerExists(
          _routeLayerId,
        );
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
      }
    } catch (_) {}
  }

  Future<void> _handleMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.logo.updateSettings(
      LogoSettings(marginLeft: -200, marginBottom: -200),
    );
    await mapboxMap.attribution.updateSettings(
      AttributionSettings(iconColor: 0x00000000),
    );
    _annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    if (_isWaypointMode) {
      await _renderWaypointMode();
    } else {
      await _fitMapBounds();
    }
  }

  void _handleMapLoadError(MapLoadingErrorEventData data) {
    if (!mounted) return;
    setState(() => _mapLoadError = true);
  }

  @override
  void dispose() {
    _debounceOrigin?.cancel();
    _debounceDest?.cancel();
    super.dispose();
  }

  bool get _isLoading => _originResult is Loading || _destResult is Loading;

  bool get _hasError => (_originResult is Error) || (_destResult is Error);

  bool get _hasCoordsToShow {
    if (_isWaypointMode) {
      return widget.waypointCoords?.isNotEmpty ?? false;
    }
    return _origin != null || _dest != null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    final double height = widget.inCard ? 180 : 260;
    final BorderRadius borderRadius = widget.inCard
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          )
        : BorderRadius.circular(12);

    final mapContainer = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: widget.inCard ? null : Border.all(color: cs.outlineVariant),
        color: widget.inCard
            ? AppColors.darkBgPrimary
            : cs.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_hasCoordsToShow && !_mapLoadError && !widget.suppressPreview)
            MapWidget(
              key: _mapKey,
              viewport: _stableViewport,
              styleUri: MapboxStyles.DARK,
              onMapCreated: _onMapCreated,
              onMapLoadErrorListener: _onMapLoadError,
            )
          else if (widget.suppressPreview && _hasCoordsToShow)
            const ColoredBox(color: AppColors.darkBgPrimary)
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
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                  Text(
                    'Ingresa las dirección para ver la ruta',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),

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
    );

    if (widget.inCard) return mapContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [AppSpacing.gapMd, mapContainer],
    );
  }
}
