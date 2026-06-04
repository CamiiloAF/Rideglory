# Tech Lead handoff — obs-fundaciones-crashlytics

**Generated:** 2026-06-04T03:45:21Z
**Tech Lead:** Sonnet 4.6
**Verdict:** READY — sin blockers

---

## Veredicto

**READY.** Todos los criterios de aceptación automatizables están GREEN. No hay violaciones de arquitectura, seguridad, ni Clean Architecture. Los tests cubren adecuadamente cada AC verificable sin build real. La única condición pendiente (CA-1) requiere build release manual y es inherentemente no automatizable.

---

## Hallazgos

| Archivo:Línea | Severidad | Descripción | Acción |
|---------------|-----------|-------------|--------|
| `lib/core/services/crash/crash_handler_setup.dart:1` | info | Archivo no estaba en el change map original del architect — fue añadido por QA para testabilidad aislada. Semánticamente equivalente a registrar los handlers directamente en main.dart. | Ninguna — mejora válida. |
| `pubspec.yaml` | info | Versión `firebase_crashlytics: ^5.2.0` difiere del `^4.3.0` especificado por el architect. La corrección es necesaria y correcta — `^4.3.0` es incompatible con `firebase_remote_config ^6.4.0` ya en el proyecto. | Actualizar architect.md si se archiva. No es blocker. |
| `lib/main.dart:77` | info | `getIt<CrashReporter>().recordError(...)` en el zone handler de `runZonedGuarded` no está envuelto en try/catch. Si `recordError` lanza, la excepción se propagaría fuera de la zone. En la práctica `FirebaseCrashReporter.recordError` delega al SDK (que maneja sus propios errores internamente), y el gating `kDebugMode` ya está. Riesgo muy bajo. | Watchlist para fases futuras. No es blocker. |

---

## Seguridad

- Sin secretos hardcodeados en ningún archivo del diff.
- Sin PII en logs ni en firmas de API (`setUserId` recibe ID ya hasheado — cumple constraint §7).
- Sin SQL concatenado ni XSS (no aplica a esta fase — sin backend, sin HTML).
- Auth Firebase no fue modificado; CORS no aplica (no hay cambios de endpoint).
- G0 verificado: 0 violaciones de importación fuera de los archivos legítimos.

---

## Arquitectura

- **Clean Architecture:** Ningún import cruzado de capas ilegítimo. `crash_reporter.dart` y `analytics_service.dart` son Dart puro (sin Flutter ni Firebase). Solo `firebase_crash_reporter.dart` importa `package:firebase_crashlytics` y solo `firebase_analytics_service.dart` importa `package:firebase_analytics` — invariante G0 intacto.
- **DI:** `FirebaseCrashlytics` registrado como `@lazySingleton` en `FirebaseInjectableModule` siguiendo el patrón de `FirebaseAnalytics`. `injection.config.dart` regenerado correctamente con environments `{_test}` / `{_prod, _dev}`.
- **Orden de init en `main()`:** `configureDependencies()` → init defensivo → `registerCrashHandlers()` → `runZonedGuarded(runApp)` — exactamente el orden especificado por el architect (D5). El invariante crítico se respeta: ningún `getIt<CrashReporter>()` ocurre antes de `configureDependencies()`.
- **Non-breaking:** Las 4 firmas nuevas en `AnalyticsService` tienen default impl vacía — `ScanSoatUseCase` y cualquier otra subclase existente compilan sin cambios.
- **Sin regresión de navegación ni autenticación:** Ningún archivo de `features/authentication/`, `shared/router/`, ni cubits globales fue modificado.
- **Env vars:** Sin URLs hardcodeadas; Crashlytics se configura mediante `google-services.json` / `GoogleService-Info.plist` ya en el proyecto.

---

## Tests

| Suite | Tests | Cobertura de AC |
|-------|-------|-----------------|
| `crash_reporter_test.dart` | 9 | TC-crash-1..5 (NoOp con verifyNever), TC-crash-6..9 (Firebase delegación) |
| `crash_handler_setup_test.dart` | 5 | CA-2 (init defensivo), CA-3 (gating debug) |
| `firebase_analytics_service_test.dart` | 5 | TC-analytics-1..5 (4 nuevas firmas) |
| **Total nuevos** | **19** | |
| Baseline | 191 | |
| **Total** | **210** | 0 fallos |

Cada AC automatizable tiene al menos un test que falla sin el cambio correspondiente. CA-1 (crash simbolizado en consola Crashlytics) es el único AC inherentemente no automatizable — requiere build release con signing real.

---

## Pruebas manuales

Delegar al humano antes de commitear (ver `REVIEW_CHECKLIST.md`):

1. **PM-1:** Build release Android → forzar crash → verificar stack simbolizado en Firebase Console.
2. **PM-2:** Build release iOS → ídem.
3. **PM-3:** Flutter run debug → forzar excepción → confirmar que NO aparece en Crashlytics console.
4. **PM-4:** Xcode > Build Phases → confirmar dSYM Run Script Phase presente.
5. **PM-5/PM-6:** Navegar flujos de auth y shell completa → sin regresiones observables.
