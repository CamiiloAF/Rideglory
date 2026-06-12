# Tech Lead handoff — observability-sentry Fase 4

**Fecha (UTC):** 2026-06-12T17:15:56Z
**Veredicto:** READY — sin blockers

---

## Veredicto

La fase está lista para commit. Todos los CAs §5 tienen cobertura de test, `dart analyze lib/` está
limpio, y los 33 tests nuevos pasan en verde. No hay cambios de seguridad, PII, contratos de API ni
backend.

---

## Hallazgos

| # | Tipo | Archivo | Descripción |
|---|------|---------|-------------|
| W1 | watchlist | `event_form_cubit.dart` | `_stepName` usa strings literales `['basics','config','route','review']` en vez de las constantes `AnalyticsParams.stepName*` que se añaden en la misma fase. Los valores son idénticos; no hay impacto en datos. Refactor cosmético diferible. |
| W2 | watchlist | `registration_form_cubit.dart` | `buildRegistrationOverride` y `markTerminalEventEmittedForTesting()` exponen superficie `@visibleForTesting` en código de producción. Patrón estándar Flutter para cubits sin árbol de widgets; correctamente anotados y comentados. |
| W3 | watchlist | `pubspec.yaml` | `sentry_dart_plugin: ^3.4.0` y sección `sentry:` no estaban en el change map del architect. Dev tooling puro, sin impacto en runtime. `.gitignore` agrega `sentry.properties` correctamente. |
| W4 | watchlist | `registration_form_cubit.dart` | La emisión de `registration_submit_attempted` ocurre después del early-return por `_buildRegistration() == null` pero antes del trabajo async. CA1b cubre el negative path; CA1b_positive cubre el positive path vía seam. Correcto por diseño. |

---

## Seguridad

- Sin PII en ningún parámetro de analytics: `form_mode` (enum cerrado), `step_index` (int 0-3),
  `step_name` (enum cerrado de 4 valores), `abandoned_at_step` (int 0-3).
- Sin secretos hardcodeados. El DSN de Sentry sigue leyéndose de `--dart-define=SENTRY_DSN` (Fase 3).
- `sentry.properties` añadido a `.gitignore` — previene commit accidental de credenciales del plugin.
- `pubspec.yaml` expone `org: camilo-agudelo` y `project: rideglory` — metadatos no sensibles
  (slugs públicos de Sentry).
- Sin SQL concatenado, XSS, ni acceso a Firebase Auth bypasseado.

---

## Arquitectura

- **Clean Architecture respetada**: toda la instrumentación ocurre en Presentación (cubits) y en
  el shared design system. El dominio y la capa de datos no son tocados.
- **`getIt<AnalyticsService>()` en handlers**: correcto — se resuelve en el handler de `onTap`, no
  en `build`. El singleton ya está registrado en el momento del primer tap.
- **`_wrapWithAnalytics` en AppTextButton**: retorna `VoidCallback?`, no `Widget`. Cumple la regla
  de no tener helpers que retornan widgets.
- **`SentryNavigatorObserver` en `app_router.dart`**: gating `kReleaseMode || kSentryDevVerify`
  es consistente con el patrón de Fase 3. El extractor `sentry_config.dart` evita el ciclo de
  imports `main.dart → app_router.dart → main.dart`.
- **Flag `_terminalEventEmitted`**: patrón idempotente correctamente implementado. Se activa antes
  de `emit(ResultState.data(...))` en ambos cubits para que el `close()` síncrono subsecuente
  encuentre el flag ya activado.
- **Un widget por archivo**: sin violaciones. `app_text_button.dart` es una clase que extiende
  `StatelessWidget`; el helper `_wrapWithAnalytics` es un método de instancia que retorna callback.

---

## Tests

| Suite | Tests nuevos | Estado |
|-------|-------------|--------|
| `event_form_cubit_analytics_test.dart` | 7 (CA1, CA2a-f) | PASS |
| `registration_form_cubit_analytics_test.dart` | 11 (CA1b, CA1b_positive, CA3, CA3b, CA3c, CA3c_real, AC1-auth + ronda 2) | PASS |
| `app_button_test.dart` | 3 (CA7a, CA7b, CA7c) | PASS |
| **Total nuevos** | **33** | **Verde** |

Suite completa: 956 passed, 2 fallos pre-existentes (TC-stp-8, TC-stp-11 en
`event_form_stepper_cubit_test.dart`) — sin regresiones.

`dart analyze lib/` — sin issues.

---

## Pruebas manuales antes de commit

1. **Step tracking wizard de creación**: `flutter run --flavor dev --dart-define-from-file=config/dev.json`
   → Crear evento → avanzar/retroceder pasos → Firebase DebugView muestra `events_step_advanced` y
   `events_step_back` con `step_index` y `step_name` correctos.

2. **Intención de publicar**: Tap en "Publicar" → `events_publish_attempted` aparece antes del
   spinner en la consola de Flutter.

3. **Abandono de creación**: Abrir wizard → no publicar → hacer pop → `events_create_abandoned`
   con `abandoned_at_step` correcto. **Verificar que `BlocProvider` del wizard cierra el cubit al
   hacer pop** (si no se emite el evento de abandono, falta `BlocProvider(create:..., lazy: false)`
   o el `dispose` manual en la página).

4. **Home CTA vacío**: En home sin eventos, tap en "Ver eventos" → `home_empty_events_cta` en
   consola.

5. **SentryNavigatorObserver** (requiere flag):
   ```
   flutter run --flavor dev --dart-define-from-file=config/dev.json --dart-define=SENTRY_DEV_VERIFY=true --dart-define=SENTRY_DSN=<dsn-real>
   ```
   → Navegar entre pantallas → verificar breadcrumbs de navegación en Sentry.

6. **Opt-out intacto**: Perfil → toggle de analytics → `AppSwitch` pill naranja con knob oscuro,
   sin cambios visuales.
