/// Palanca de desarrollo: poner a true temporalmente para verificar la
/// integración de Sentry en modo debug sin esperar a un build de producción.
///
/// Activar: `--dart-define=SENTRY_DEV_VERIFY=true`
/// Por defecto es `false` — en dev, Sentry NO envía eventos.
const bool kSentryDevVerify =
    bool.fromEnvironment('SENTRY_DEV_VERIFY');
