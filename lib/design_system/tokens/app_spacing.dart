/// Escala de espaciados. `rideglory.pen` no expone variables `$c-spacing-*`
/// (los componentes usan `gap`/`padding` puntuales); esta escala estándar de
/// 4/8/16/24/32 es la que ya regía en Asphalt y se mantiene como convención
/// de layout mientras no exista un token explícito que la reemplace.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
