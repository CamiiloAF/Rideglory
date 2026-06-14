import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract final class AppMapDefaults {
  /// Viewport estable apuntando al centro de Colombia.
  ///
  /// Usar como `viewport:` en [MapWidget] cuando no hay coordenadas propias.
  /// Al ser una referencia estática fija, los rebuilds del widget no resetean
  /// la cámara (Mapbox solo re-aplica el viewport cuando cambia la instancia).
  static final colombiaViewport = CameraViewportState(
    center: Point(coordinates: Position(-74.2973, 4.5709)),
    zoom: 5.2,
  );
}
