import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/utils/initials.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

abstract class InitialsMarkerIcon {
  static Future<BitmapDescriptor> create({
    required String firstName,
    required String lastName,
    required ColorScheme colorScheme,
    double size = 96,
    Color? backgroundColor,
    Color? borderColor,
    bool highlight = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final radius = size / 2.0;

    final resolvedBorder = borderColor ?? colorScheme.primary;
    final bgPaint = Paint()..color = backgroundColor ?? colorScheme.primary;
    final glowPaint = Paint()
      ..color = resolvedBorder.withValues(alpha: 0.30)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);
    final borderPaint = Paint()
      ..color = highlight ? resolvedBorder : resolvedBorder.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * (highlight ? 0.085 : 0.06);

    final center = Offset(radius, radius);
    if (highlight) {
      canvas.drawCircle(center, radius, glowPaint);
    }
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(
      center,
      radius - (borderPaint.strokeWidth / 2),
      borderPaint,
    );

    final textSpan = TextSpan(
      text: Initials.buildInitials(firstName: firstName, lastName: lastName),
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.9,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      radius - (textPainter.width / 2),
      radius - (textPainter.height / 2),
    );
    textPainter.paint(canvas, textOffset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(Uint8List.view(bytes!.buffer));
  }
}
