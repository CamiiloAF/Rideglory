/// Configuración de entorno de la app.
///
/// Decisión F3: las claves (Supabase, Sentry) viven en `config/<flavor>.json`
/// y se pasan con `--dart-define-from-file=config/<flavor>.json`, el mismo
/// mecanismo que ya usaban las claves de Firebase — no se introduce un
/// segundo canal de secretos vía `.env`/envied para evitar tener dos fuentes
/// de verdad para configuración de entorno. `envied` se conserva en
/// `pubspec.yaml` por si un secreto puramente local (no específico de
/// flavor) lo necesita más adelante.
abstract final class AppEnv {
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// D13: tiles raster por URL. Vacío en dev usa OpenStreetMap; en prod se
  /// espera una URL de MapTiler/Mapbox raster con token embebido en
  /// `config/prod.json`. Sin SDK nativo, sin token para arrancar en dev.
  static const String _mapTileUrl = String.fromEnvironment('MAP_TILE_URL');

  static String get mapTileUrl => _mapTileUrl.isEmpty
      ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
      : _mapTileUrl;

  /// Exigido por la política de uso de tiles de OpenStreetMap.
  static const String mapUserAgentPackageName = 'com.camiloagudelo.rideglory';

  static bool get isProd => flavor == 'prod';
}
