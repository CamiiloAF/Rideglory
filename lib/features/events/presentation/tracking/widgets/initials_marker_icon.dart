import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:rideglory/core/utils/initials.dart';

/// Visual variant of a rider marker on the live map.
enum RiderMarkerVariant {
  /// Ride leader: solid accent fill, dark initials, glow and a crown badge.
  lead,

  /// Regular rider: accent-subtle fill, accent border and initials, soft glow.
  rider,

  /// Rider broadcasting an SOS: red fill, red border, initials and glow.
  sos,
}

/// Encoded PNG bitmap for a marker, ready to register as a Mapbox style image.
class MarkerBitmap {
  const MarkerBitmap({
    required this.data,
    required this.width,
    required this.height,
  });

  final Uint8List data;
  final int width;
  final int height;
}

abstract class InitialsMarkerIcon {
  static const Color _accent = Color(0xFFF98C1F);
  static const Color _accentSubtle = Color(0xFF2D2117);
  static const Color _bgPrimary = Color(0xFF0D0D0F);
  static const Color _error = Color(0xFFEF4444);
  static const Color _sosFill = Color(0xFF3D1515);

  /// Renders a rider marker for [variant] as PNG bytes for `Style.addStyleImage`.
  ///
  /// The bitmap is rasterized at [devicePixelRatio] so it stays crisp; register
  /// it with `scale: devicePixelRatio` so the on-screen size equals the logical
  /// diameter (48 px for lead/SOS, 44 px for regular riders).
  static Future<MarkerBitmap> createBitmap({
    required String fullName,
    required RiderMarkerVariant variant,
    required double devicePixelRatio,
  }) async {
    final double diameter = variant == RiderMarkerVariant.rider ? 44 : 48;
    const double pad = 22;
    final double box = diameter + pad * 2;
    final double scale = devicePixelRatio <= 0 ? 1 : devicePixelRatio;
    final int pxSize = (box * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);

    final Offset center = Offset(box / 2, box / 2);
    final double radius = diameter / 2;

    final Color fill;
    final Color stroke;
    final Color initialsColor;
    final Color glow;
    final double strokeWidth;
    switch (variant) {
      case RiderMarkerVariant.lead:
        fill = _accent;
        stroke = _accent;
        initialsColor = _bgPrimary;
        glow = _accent;
        strokeWidth = 0;
      case RiderMarkerVariant.rider:
        fill = _accentSubtle;
        stroke = _accent;
        initialsColor = _accent;
        glow = _accent;
        strokeWidth = 2.5;
      case RiderMarkerVariant.sos:
        fill = _sosFill;
        stroke = _error;
        initialsColor = _error;
        glow = _error;
        strokeWidth = 2.5;
    }

    // Glow as a radial gradient fully contained within the bitmap bounds. A
    // MaskFilter.blur would leak its Gaussian tail to the image edge and clip
    // into a faint square; a radial gradient fades cleanly to transparent.
    final bool soft = variant == RiderMarkerVariant.rider;
    final double glowRadius = radius + (soft ? 6 : 10);
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = ui.Gradient.radial(center, glowRadius, [
          glow.withValues(alpha: soft ? 0.35 : 0.50),
          glow.withValues(alpha: 0.0),
        ], [
          radius / glowRadius,
          1.0,
        ]),
    );

    canvas.drawCircle(center, radius, Paint()..color = fill);

    if (strokeWidth > 0) {
      canvas.drawCircle(
        center,
        radius - strokeWidth / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = stroke,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: Initials.buildFromFullName(fullName),
        style: TextStyle(
          color: initialsColor,
          fontWeight: FontWeight.w700,
          fontSize: diameter * 0.33,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    if (variant == RiderMarkerVariant.lead) {
      final Offset badgeCenter =
          Offset(center.dx + radius * 0.74, center.dy - radius * 0.74);
      const double badgeRadius = 11;
      canvas.drawCircle(badgeCenter, badgeRadius, Paint()..color = _bgPrimary);
      canvas.drawCircle(
        badgeCenter,
        badgeRadius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _accent,
      );
      _drawCrown(canvas, badgeCenter, 12.5, _accent);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(pxSize, pxSize);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return MarkerBitmap(
      data: Uint8List.view(bytes!.buffer),
      width: pxSize,
      height: pxSize,
    );
  }

  static void _drawCrown(Canvas canvas, Offset center, double size, Color color) {
    final double w = size;
    final double h = size * 0.82;
    final double left = center.dx - w / 2;
    final double top = center.dy - h / 2;
    final path = Path()
      ..moveTo(left, top + h)
      ..lineTo(left, top + h * 0.34)
      ..lineTo(left + w * 0.30, top + h * 0.62)
      ..lineTo(left + w * 0.50, top)
      ..lineTo(left + w * 0.70, top + h * 0.62)
      ..lineTo(left + w, top + h * 0.34)
      ..lineTo(left + w, top + h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
}
