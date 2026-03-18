import 'package:flutter/widgets.dart';

/// Spacing tokens — standard scale for widget-to-widget gaps.
///
/// ## Usage rule
/// Always prefer a token from the **standard scale** below.
/// Only reach for the `special` section when the design explicitly requires
/// a value that cannot be expressed through the standard scale (e.g. a fixed
/// bottom-nav clearance that has to match a physical layout dimension).
///
/// Standard vertical scale:
///   gapXxs(4) → gapXs(6) → gapSm(8) → gapMd(12) → gapLg(16) →
///   gapXl(20) → gapXxl(24) → gapXxxl(32)
///
/// Standard horizontal scale:
///   hGapXxs(4) → hGapXs(6) → hGapSm(8) → hGapMd(12) → hGapLg(16) →
///   hGapXl(20)
abstract class AppSpacing {
  AppSpacing._();

  // ── Standard vertical scale ───────────────────────────────────────────────
  static const Widget gapXxs = SizedBox(height: 4);
  static const Widget gapXs = SizedBox(height: 6);
  static const Widget gapSm = SizedBox(height: 8);
  static const Widget gapMd = SizedBox(height: 12);
  static const Widget gapLg = SizedBox(height: 16);
  static const Widget gapXl = SizedBox(height: 20);
  static const Widget gapXxl = SizedBox(height: 24);
  static const Widget gapXxxl = SizedBox(height: 32);

  // ── Standard horizontal scale ─────────────────────────────────────────────
  static const Widget hGapXxs = SizedBox(width: 4);
  static const Widget hGapXs = SizedBox(width: 6);
  static const Widget hGapSm = SizedBox(width: 8);
  static const Widget hGapMd = SizedBox(width: 12);
  static const Widget hGapLg = SizedBox(width: 16);
  static const Widget hGapXl = SizedBox(width: 20);

  // ── Special-purpose gaps ──────────────────────────────────────────────────
  // Only add entries here when the standard scale truly cannot cover the need.
  // Each entry must include a comment explaining the specific use-case.

  /// Section-level breathing room (e.g. between major content blocks in
  /// detail/form pages). Consider gapXxxl (32) first; use this only when
  /// the design explicitly requires 40 px.
  static const Widget gap40 = SizedBox(height: 40);

  /// Bottom-nav bar clearance — ensures scrollable content is never hidden
  /// behind the floating bottom navigation bar.
  static const Widget gap100 = SizedBox(height: 100);
}
