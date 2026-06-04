# PRD Normalizado — Fase 1: Fundaciones de Observabilidad, Captura de Crashes y Regla de Capa

> Generado (UTC): 2026-06-04T03:09:45Z
> Fuente: `docs/plans/analytics-crashlytics-cobertura-total/phases/phase-01-fundaciones-de-observabilidad-captura-de-crashes.md`
> Slug: `obs-fundaciones-crashlytics`

---

## 1 Objetivo

Establecer la base de observabilidad de la app Rideglory para que el equipo reciba automáticamente los crashes fatales y no-fatales de cualquier usuario en producción/staging, con gating completo en debug y tests (ningún reporte se envía en esos entornos), sin que la app cambie de comportamiento y sin introducir ninguna pantalla nueva.

Esta fase entrega:
- La abstracción `CrashReporter` (Dart puro, `core/services/crash/`)
- La interfaz `AnalyticsService` ampliada con firmas de `logScreenView`, `setUserId`, `setUserProperty`, `setEnabled`
- La impl `FirebaseCrashReporter` + no-op impl para tests
- El cableado de captura en `main.dart` (`runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError`)
- La **regla de capa G0** documentada que legitima que `domain` consuma estas abstracciones

Es la fase fundacional (dependsOn: []) que desbloquea las fases 2–11 del plan `analytics-crashlytics-cobertura-total`.

---

## 2 Por qué

Rideglory no tiene hoy visibilidad de crashes en producción. Sin captura de crashes simbolizados, los bugs fatales que afectan a usuarios reales son invisibles hasta que un usuario reporta manualmente. La ausencia de la abstracción `CrashReporter` también bloquea las fases 2–11 del plan de analytics/observabilidad. Esta fase cierra ese gap de observabilidad sin afectar comportamiento ni UI.

---

## 3 Alcance

### Entra
- Añadir dependencia `firebase_crashlytics` a `pubspec.yaml` (major compatible con `firebase_core ^4.2.1`, resuelto vía `flutter pub add`)
- Setup nativo Android: plugin Gradle `com.google.firebase.crashlytics` en `android/settings.gradle.kts` y `android/app/build.gradle.kts` + subida de mapping para deobfuscación
- Setup nativo iOS: subida de dSYM (build phase / `upload-symbols`) para símbolos en consola Crashlytics
- Ampliar la interfaz `AnalyticsService` con `logScreenView`, `setUserId`, `setUserProperty`, `setEnabled` (firma sin PII); implementarlos en `FirebaseAnalyticsService` envolviendo el SDK 1:1
- Crear abstracción `CrashReporter` en `core/services/crash/crash_reporter.dart` (Dart puro, sin imports Flutter ni SDK)
- Crear impl `FirebaseCrashReporter` (`@Injectable(as: CrashReporter)`) en `core/services/crash/firebase_crash_reporter.dart`
- Crear no-op impl `NoOpCrashReporter` (`@Injectable(as: CrashReporter, env: [Environment.test])`) en `core/services/crash/no_op_crash_reporter.dart`
- Proveer `FirebaseCrashlytics` en `firebase_module.dart` como `@lazySingleton`
- Cableado de captura en `main.dart`: `runZonedGuarded` envolviendo `configureDependencies()` + `runApp()`; registrar `FlutterError.onError` y `PlatformDispatcher.onError` antes de `runApp`; handlers **no reportan en `kDebugMode`**; init defensivo con `try/catch` para que un fallo de Crashlytics no rompa `runApp`
- Documento de la regla de capa G0 bajo `docs/features/analytics.md` (o ADR equivalente), declarando que el call site de `ScanSoatUseCase` ya cumple sin refactor
- Regen `build_runner`, `dart analyze` limpio, `flutter test` verde con no-op + `setEnabled(false)`

### No entra
- Instrumentación de eventos de features (fases 2–9)
- Taxonomía/constantes centralizadas, mapa de rutas y límites GA4 (fase 2)
- `NavigatorObserver`/`screen_view` automático (fase 3) — solo se declara la firma aquí
- Enganche de no-fatales de red en `handlerExceptionHttp` (fase 4)
- `setUserId` real con hash SHA-256 desde `AuthCubit` (fase 5)
- UI de opt-out, `setEnabled` desde perfil, strings ES, política de privacidad (fases 10–11)
- Normalización del call site de `ScanSoatUseCase` a constantes de taxonomía (fase 2)
- Cualquier cambio en `rideglory-api`

---

## 4 Áreas afectadas

| Área | Archivos / Directorios |
|------|----------------------|
| Configuración de dependencias | `pubspec.yaml` |
| Nativo Android | `android/settings.gradle.kts`, `android/app/build.gradle.kts` |
| Nativo iOS | `ios/Runner.xcodeproj` (build phase dSYM) o Fastlane |
| Punto de entrada | `lib/main.dart` |
| DI Firebase | `lib/core/di/firebase_module.dart`, `lib/core/di/injection.config.dart` (regenerado) |
| Servicios analytics | `lib/core/services/analytics/analytics_service.dart`, `lib/core/services/analytics/firebase_analytics_service.dart` |
| Servicios crash (nuevos) | `lib/core/services/crash/crash_reporter.dart`, `lib/core/services/crash/firebase_crash_reporter.dart`, `lib/core/services/crash/no_op_crash_reporter.dart` |
| Docs / ADR | `docs/features/analytics.md` (nuevo o actualizado) |
| Tests | `test/` — tests unitarios de handlers, no-op, DI, degradación |

---

## 5 Criterios de aceptación

1. **Crash simbolizado en staging.** Un crash de prueba forzado aparece **simbolizado** (stack legible) en la consola Crashlytics en build **staging Android** y **staging iOS**.
2. **Init defensivo.** Un fallo de init de Crashlytics **no** rompe `runApp`: la app arranca y navega normalmente (degradación silenciosa, sin pantalla en blanco). Verificable forzando un fallo de init y confirmando que la app sigue usable.
3. **Gating en debug.** En `kDebugMode`, ni `FlutterError.onError`, ni `PlatformDispatcher.onError`, ni el handler de `runZonedGuarded` envían reportes a Crashlytics (verificable en log / ausencia de reporte en consola).
4. **Gating en tests.** Con la no-op impl de `CrashReporter` + `setEnabled(false)`, `flutter test` no intenta enviar eventos ni reportes; `dart analyze` queda **limpio**.
5. **Regla de capa G0 (grep).** `grep -r "package:firebase_crashlytics" lib/` y `grep -r "package:firebase_analytics" lib/` devuelven **0** coincidencias fuera de `lib/core/services/.../firebase_*` (solo `firebase_analytics_service.dart` y `firebase_crash_reporter.dart`).
6. **Abstracciones puras.** `crash_reporter.dart` y `analytics_service.dart` no importan `package:flutter/*` ni ningún `package:firebase_*` (Dart puro, consumibles por domain).
7. **Sin refactor de soat.** `ScanSoatUseCase` sigue compilando e inyectando `AnalyticsService` sin cambios en esta fase; el doc G0 declara que ya cumple.
8. **Sin UI / sin regresión.** No hay pantalla nueva ni cambio de comportamiento observable para el usuario; el árbol de navegación y los flujos existentes son idénticos.

---

## 6 Guardrails de regresión

Los siguientes flujos/pantallas/endpoints **no deben romperse** con esta implementación:

- **Arranque de la app**: `main()` → `configureDependencies()` → `runApp()` — el flujo de inicio debe funcionar aun si Crashlytics falla en init (degradación silenciosa).
- **Autenticación**: flujos de email, Google y Apple sign-in en `lib/features/authentication/` — ningún cambio en AuthCubit ni en el router.
- **Navegación principal**: `AppRouter` con guard de auth, shell con bottom nav, todas las rutas existentes — el árbol de navegación es idéntico tras la fase.
- **`ScanSoatUseCase`** y cualquier use case que inyecte `AnalyticsService` — deben seguir compilando y funcionando sin cambios.
- **Suite de tests existente**: `flutter test` verde antes y después; no se introducen dependencias transitivas que rompan tests existentes.
- **`dart analyze` limpio**: 0 errores y 0 warnings nuevos (los 2 lints del hack `shouldUseLocalApi=true` son preexistentes y no se tocan).
- **`build_runner` reproducible**: `injection.config.dart` se regenera correctamente; no quedan conflictos de código generado.

---

## 7 Constraints heredados

- **Pattern B DTO (no aplica aquí):** La analítica no serializa modelos de API; no se crean DTOs en esta fase.
- **`rideglory-api` inmutable:** Ningún endpoint nuevo, ningún DTO, ningún cambio en el backend.
- **Gating estricto debug/test:** Ningún reporte ni evento debe enviarse en `kDebugMode` ni en la suite de tests — es un requisito de producto, no solo técnico.
- **Firma sin PII:** Las firmas de `CrashReporter` y `AnalyticsService` no aceptan PII directamente; `setUserId` recibe un ID ya hasheado (la fase 5 aplica el hash SHA-256 desde `AuthCubit`).
- **Un único punto de importación del SDK:** Solo `firebase_crash_reporter.dart` puede importar `package:firebase_crashlytics`; solo `firebase_analytics_service.dart` puede importar `package:firebase_analytics`. Esto es un invariante de arquitectura (regla G0).
- **`@lazySingleton` para `FirebaseCrashlytics`:** Seguir el patrón ya establecido en `firebase_module.dart` para `FirebaseAnalytics`.
- **`build_runner --force-jit`:** En worktrees o CI frescos usar `--force-jit` o copiar `pubspec.lock`/`.env`/configs Firebase de `main` (aprendizaje del proyecto).
- **`shouldUseLocalApi=true` en `api_base_url_resolver.dart`:** Config de testing local del usuario — no commitear, no revertir, ignorar sus 2 lints.
- **Texto oscuro sobre primario:** No aplica aquí (no hay UI nueva), pero cualquier badge/elemento sobre naranja debe usar `darkBgPrimary`, no blanco.
- **Un widget por archivo:** No aplica aquí (no hay widgets nuevos), pero si se agregan pantallas futuras, cada widget va en su propio archivo.
