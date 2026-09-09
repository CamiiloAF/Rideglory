import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía de la identidad C2: `$c-font` = Outfit.
abstract final class AppTypography {
  /// Bajo `flutter test`, `TestWidgetsFlutterBinding` fuerza a que toda
  /// petición HTTP falle — la descarga en runtime de `google_fonts` nunca
  /// puede completar ahí, y sin este corte, el error queda pendiente y
  /// revienta el test después de que ya terminó. Se detecta con la misma
  /// variable de entorno que usa el propio paquete `google_fonts`
  /// internamente (`FLUTTER_TEST`).
  static bool get _isRunningInTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  static TextTheme textTheme(Color textColor, Color secondaryColor) {
    final base = _isRunningInTest
        ? const TextTheme().apply(fontFamily: 'Outfit')
        : GoogleFonts.outfitTextTheme();
    return base.copyWith(
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: textColor),
      bodyMedium: base.bodyMedium?.copyWith(color: textColor),
      bodySmall: base.bodySmall?.copyWith(color: secondaryColor),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}
