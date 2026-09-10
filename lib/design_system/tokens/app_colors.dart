import 'package:flutter/material.dart';

/// Paleta de la identidad C2 (dirección "C" del `.pen`, variables `$c-*`).
///
/// Fuente de verdad: `rideglory.pen`, tema `dir C`. Nunca hardcodear un hex
/// fuera de este archivo — todo lo demás debe leer de aquí a través de
/// `Theme.of(context).extension<AppColors>()`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSecondary,
    required this.accent,
    required this.accentSoft,
    required this.accentText,
    required this.onAccent,
    required this.success,
    required this.successSoft,
    required this.successText,
    required this.successOnBlock,
    required this.warning,
    required this.warningSoft,
    required this.warningOnBlock,
    required this.error,
    required this.errorSoft,
    required this.errorText,
    required this.errorOnBlock,
    required this.errorSolid,
    required this.plate,
    required this.plateText,
    required this.plateChip,
    required this.shadow,
    required this.block,
    required this.onBlock,
    required this.onBlockSecondary,
  });

  final Color bg;
  final Color surface;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textSecondary;
  final Color accent;
  final Color accentSoft;
  final Color accentText;
  final Color onAccent;
  final Color success;
  final Color successSoft;
  final Color successText;
  final Color successOnBlock;
  final Color warning;
  final Color warningSoft;
  final Color warningOnBlock;
  final Color error;
  final Color errorSoft;
  final Color errorText;
  final Color errorOnBlock;
  final Color errorSolid;
  final Color plate;
  final Color plateText;
  final Color plateChip;
  final Color shadow;
  final Color block;
  final Color onBlock;
  final Color onBlockSecondary;

  /// `$c-*` light theme values from `rideglory.pen`.
  static const AppColors light = AppColors(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F4),
    border: Color(0xFFD6D2CD),
    borderStrong: Color(0xFF9A948E),
    text: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF6B6B6B),
    accent: Color(0xFFFFD400),
    accentSoft: Color(0xFFFFF8CC),
    accentText: Color(0xFF0A0A0A),
    onAccent: Color(0xFF0A0A0A),
    success: Color(0xFF15803D),
    successSoft: Color(0xFFE6F4EA),
    successText: Color(0xFF146C34),
    successOnBlock: Color(0xFF4ADE80),
    warning: Color(0xFFC2410C),
    warningSoft: Color(0xFFFDEDE3),
    warningOnBlock: Color(0xFFFBBF24),
    error: Color(0xFFDC2626),
    errorSoft: Color(0xFFFDECEC),
    errorText: Color(0xFFB91C1C),
    errorOnBlock: Color(0xFFF87171),
    errorSolid: Color(0xFFB91C1C),
    plate: Color(0xF20A0A0A),
    plateText: Color(0xFFFAFAFA),
    plateChip: Color(0x2EFFFFFF),
    shadow: Color(0x0F0A0A0A),
    block: Color(0xFF111111),
    onBlock: Color(0xFFFAFAFA),
    onBlockSecondary: Color(0xFFA3A3A3),
  );

  /// `$c-*` dark theme values from `rideglory.pen`.
  static const AppColors dark = AppColors(
    bg: Color(0xFF0C0C0C),
    surface: Color(0xFF1A1A1A),
    border: Color(0xFF3A3A3A),
    borderStrong: Color(0xFF626262),
    text: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA3A3A3),
    accent: Color(0xFFFFD400),
    accentSoft: Color(0xFF332B00),
    accentText: Color(0xFFFFD400),
    onAccent: Color(0xFF0A0A0A),
    success: Color(0xFF4ADE80),
    successSoft: Color(0xFF0F2A18),
    successText: Color(0xFF4ADE80),
    successOnBlock: Color(0xFF4ADE80),
    warning: Color(0xFFFB923C),
    warningSoft: Color(0xFF331A0A),
    warningOnBlock: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    errorSoft: Color(0xFF33110F),
    errorText: Color(0xFFF87171),
    errorOnBlock: Color(0xFFF87171),
    errorSolid: Color(0xFFB91C1C),
    plate: Color(0xF2000000),
    plateText: Color(0xFFFAFAFA),
    plateChip: Color(0x2EFFFFFF),
    shadow: Color(0x66000000),
    block: Color(0xFF1A1A1A),
    onBlock: Color(0xFFFAFAFA),
    onBlockSecondary: Color(0xFFA3A3A3),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? textSecondary,
    Color? accent,
    Color? accentSoft,
    Color? accentText,
    Color? onAccent,
    Color? success,
    Color? successSoft,
    Color? successText,
    Color? successOnBlock,
    Color? warning,
    Color? warningSoft,
    Color? warningOnBlock,
    Color? error,
    Color? errorSoft,
    Color? errorText,
    Color? errorOnBlock,
    Color? errorSolid,
    Color? plate,
    Color? plateText,
    Color? plateChip,
    Color? shadow,
    Color? block,
    Color? onBlock,
    Color? onBlockSecondary,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentText: accentText ?? this.accentText,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      successText: successText ?? this.successText,
      successOnBlock: successOnBlock ?? this.successOnBlock,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      warningOnBlock: warningOnBlock ?? this.warningOnBlock,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      errorText: errorText ?? this.errorText,
      errorOnBlock: errorOnBlock ?? this.errorOnBlock,
      errorSolid: errorSolid ?? this.errorSolid,
      plate: plate ?? this.plate,
      plateText: plateText ?? this.plateText,
      plateChip: plateChip ?? this.plateChip,
      shadow: shadow ?? this.shadow,
      block: block ?? this.block,
      onBlock: onBlock ?? this.onBlock,
      onBlockSecondary: onBlockSecondary ?? this.onBlockSecondary,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      successOnBlock: Color.lerp(successOnBlock, other.successOnBlock, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      warningOnBlock: Color.lerp(warningOnBlock, other.warningOnBlock, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      errorOnBlock: Color.lerp(errorOnBlock, other.errorOnBlock, t)!,
      errorSolid: Color.lerp(errorSolid, other.errorSolid, t)!,
      plate: Color.lerp(plate, other.plate, t)!,
      plateText: Color.lerp(plateText, other.plateText, t)!,
      plateChip: Color.lerp(plateChip, other.plateChip, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      block: Color.lerp(block, other.block, t)!,
      onBlock: Color.lerp(onBlock, other.onBlock, t)!,
      onBlockSecondary: Color.lerp(
        onBlockSecondary,
        other.onBlockSecondary,
        t,
      )!,
    );
  }
}
