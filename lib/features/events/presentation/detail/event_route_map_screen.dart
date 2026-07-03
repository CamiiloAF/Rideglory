import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
import 'package:rideglory/core/config/app_map_defaults.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/models/address_location.dart';

const _routeSourceId = 'detail-route-source';
const _routeLayerId = 'detail-route-layer';

/// Full-screen read-only map showing event route pins and polyline.
class EventRouteMapScreen extends StatefulWidget {
  const EventRouteMapScreen({super.key, required this.points, this.title});

  final List<AddressLocation> points;
  final String? title;

  @override
  State<EventRouteMapScreen> createState() => _EventRouteMapScreenState();
}

class _EventRouteMapScreenState extends State<EventRouteMapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _layerAdded = false;

  Future<void> _renderRoute() async {
    final mapboxMap = _mapboxMap;
    final manager = _annotationManager;
    if (mapboxMap == null || manager == null) return;

    final points = widget.points;
    await manager.deleteAll();

    for (var i = 0; i < points.length; i++) {
      final color = i == 0 ? AppColors.success : AppColors.primary;
      final image = await buildNumberedPinImage(i + 1, color);
      await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(points[i].longitude, points[i].latitude),
          ),
          image: image,
          iconSize: 1.0,
        ),
      );
    }

    await _updatePolyline(mapboxMap, points);

    if (points.isEmpty) return;
    if (points.length == 1) {
      await mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              points.first.longitude,
              points.first.latitude,
            ),
          ),
          zoom: 13,
        ),
        MapAnimationOptions(duration: 400),
      );
      return;
    }

    final pts = points
        .map((w) => Point(coordinates: Position(w.longitude, w.latitude)))
        .toList();
    final camera = await mapboxMap.cameraForCoordinatesPadding(
      pts,
      CameraOptions(),
      MbxEdgeInsets(top: 80, left: 60, bottom: 80, right: 60),
      null,
      null,
    );
    await mapboxMap.flyTo(camera, MapAnimationOptions(duration: 500));
  }

  Future<void> _updatePolyline(
    MapboxMap mapboxMap,
    List<AddressLocation> points,
  ) async {
    final coordinates = points.length >= 2
        ? points.map((w) => [w.longitude, w.latitude]).toList()
        : <List<double>>[];

    final geojson = jsonEncode({
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': coordinates},
    });

    try {
      if (_layerAdded) {
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
      _layerAdded = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgPrimary,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: AppCircleIconButton.back(
            surfaceColor: AppColors.darkTertiary,
            onTap: () => context.pop(),
          ),
        ),
        title: Text(
          widget.title ?? 'Ruta del evento',
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
      ),
      // PopScope evita el gesto interactivo de iOS (swipe-left).
      // Mientras el gesto estaba activo, ambas instancias de MapWidget
      // corrían simultáneamente y el SDK compartido de Mapbox/Metal
      // provocaba un redraw visible en la preview. Con canPop:false el
      // swipe dispara onPlatformViewCreated que llamamos manualmente con
      // Navigator.pop(), que usa la animación estándar (no interactiva).
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.of(context).pop();
        },
        child: MapWidget(
          viewport: AppMapDefaults.colombiaViewport,
          styleUri: MapboxStyles.DARK,
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
            _annotationManager = await mapboxMap.annotations
                .createPointAnnotationManager();
            _mapboxMap = mapboxMap;
            unawaited(_renderRoute());
          },
        ),
      ),
    );
  }
}
