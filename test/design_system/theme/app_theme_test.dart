import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/design_system/tokens/app_colors.dart';

void main() {
  group('AppTheme', () {
    test('light theme exposes AppColors.light as an extension', () {
      final colors = AppTheme.light.extension<AppColors>();

      expect(colors, isNotNull);
      expect(colors!.accent, AppColors.light.accent);
      expect(colors.bg, const Color(0xFFFFFFFF));
    });

    test('dark theme exposes AppColors.dark as an extension', () {
      final colors = AppTheme.dark.extension<AppColors>();

      expect(colors, isNotNull);
      expect(colors!.accent, AppColors.dark.accent);
      expect(colors.bg, const Color(0xFF0C0C0C));
    });

    test('accent is the same yellow in both themes (D1)', () {
      expect(AppTheme.light.colorScheme.primary, const Color(0xFFFFD400));
      expect(AppTheme.dark.colorScheme.primary, const Color(0xFFFFD400));
    });

    test('text over accent is always dark, never white', () {
      expect(AppTheme.light.colorScheme.onPrimary, const Color(0xFF0A0A0A));
      expect(AppTheme.dark.colorScheme.onPrimary, const Color(0xFF0A0A0A));
    });
  });
}
