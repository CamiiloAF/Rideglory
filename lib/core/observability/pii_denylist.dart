/// Claves prohibidas en eventos y breadcrumbs Sentry.
///
/// Cualquier clave de request/response header, query param, o dato de
/// contexto que aparezca en esta lista debe ser redactada (reemplazada
/// por `[redacted]`) antes de que el evento sea enviado.
///
/// La lógica de scrub vive en [SentryCrashReporter]; esta constante es la
/// fuente de verdad independiente del SDK.
const Set<String> kPiiDenylist = {
  'authorization',
  'id_token',
  'password',
  'email',
  'phone',
  'telefono',
  'soat',
  'placa',
  'vin',
};
