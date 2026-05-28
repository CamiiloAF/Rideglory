import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_extraction.dart';

/// Small "magic wand" badge placed next to a field that was auto-filled from
/// OCR. Color reflects the field confidence (green = high, orange = medium).
class SoatAutofillBadge extends StatelessWidget {
  const SoatAutofillBadge({super.key, required this.confidence});

  final OcrFieldConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final color = confidence == OcrFieldConfidence.high
        ? context.appColors.success
        : AppColors.primary;
    return Tooltip(
      message: context.l10n.soat_scan_field_hint,
      child: Icon(Icons.auto_fix_high_rounded, size: 18, color: color),
    );
  }
}
