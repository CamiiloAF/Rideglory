import 'package:flutter/widgets.dart';

/// Spacing tokens (mostly used for widget-to-widget gaps).
///
/// Keep the values aligned with the existing codebase patterns.
abstract class AppSpacing {
  AppSpacing._();

  // Vertical gaps
  static const Widget gapXxs = SizedBox(height: 4);
  static const Widget gapXs = SizedBox(height: 6);
  static const Widget gapSm = SizedBox(height: 8);
  static const Widget gapMd = SizedBox(height: 12);
  static const Widget gapLg = SizedBox(height: 16);
  static const Widget gapXl = SizedBox(height: 20);
  static const Widget gapXxl = SizedBox(height: 24);
  static const Widget gapXxxl = SizedBox(height: 32);

  // Horizontal gaps
  static const Widget hGapXxs = SizedBox(width: 4);
  static const Widget hGapXs = SizedBox(width: 6);
  static const Widget hGapSm = SizedBox(width: 8);
  static const Widget hGapMd = SizedBox(width: 12);
  static const Widget hGapLg = SizedBox(width: 16);
}

