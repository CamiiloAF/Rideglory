# Fase 1 — Fundaciones de observabilidad, captura de crashes y regla de capa

> Plan: `analytics-crashlytics-cobertura-total` · Fase **1** de 11 · dependsOn: **[]**
> Sesión: PLANEACIÓN (no se modifica código de la app en esta corrida)
> Generado (UTC): 2026-06-04T01:06:49Z

## Objetivo

El equipo recibe **automáticamente** los crashes fatales y no-fatales de cualquier usuario,
con **gating** en debug/tests (no se reporta ni se envían eventos), **sin que la app cambie
de comportamiento** y sin pantalla nueva. Esta fase deja la base que reutilizan todas las
fases 2–11: la abstracción `CrashReporter`, la interfaz `AnalyticsService` ampliada, la no-op
impl para tests, el cableado de captura en `main.dart` y la **regla de capa única (G0)** que
legitima que `domain` consuma estas abstracciones.

Estado de captura de esta fase: **release** = activa (los handlers reportan crashes);
**debug** = off (handlers no reportan en `kDebugMode`); **tests** = no-op impl +
`setEnabled(false)`. **Sin UI nueva. Sin regresión de comportamiento.**

## Alcance (entra / no entra)

**Entra:**
- Añadir dependencia `firebase_crashlytics` (major alineado con `firebase_core 4.x`,
  resuelto vía `pub`, no fijado a ciegas).
- Setup nativo Android: plugin Gradle `com.google.firebase.crashlytics` en
  `android/settings.gradle.kts` y `android/app/build.gradle.kts` (junto al
  `com.google.gms.google-services` ya presente) + subida de mapping para deobfuscación.
- Setup nativo iOS: subida de dSYM (build phase / upload-symbols) para símbolos en consola.
- Ampliar la interfaz `AnalyticsService` con `logScreenView`, `setUserId`, `setUserProperty`,
  `setEnabled` (la impl Firebase los envuelve 1:1; **firma sin PII**).
- Crear la **abstracción `CrashReporter`** (Dart puro, en `core/`) + impl Crashlytics
  (`@Injectable(as: CrashReporter)` bajo `core/services/.../firebase_*`) + **no-op impl** para
  tests. Proveer `FirebaseCrashlytics` en `firebase_module.dart`.
- Cablear captura en `main.dart`: `runZonedGuarded` envolviendo **`configureDependencies()` +
  `runApp()`** en la misma zona; registrar `FlutterError.onError` y
  `PlatformDispatcher.onError` antes de `runApp`; handlers **no reportan en `kDebugMode`**.
- Que un fallo de init de Crashlytics **no rompa `runApp`** (degradación silenciosa).
- **Escribir la regla de capa (G0)** como doc y declarar que el call site de `ScanSoatUseCase`
  **YA cumple** (sin refactor).

**No entra:**
- Ninguna instrumentación de eventos de features (eso es fases 2–9).
- La taxonomía/constantes centralizadas, el mapa de rutas y los límites GA4 (eso es **fase 2**;
  la normalización del call site de soat a constantes ocurre en fase 2, no aquí).
- El `NavigatorObserver`/`screen_view` automático (fase 3) — aquí solo se **declara** la firma
  `logScreenView` en la interfaz, no se registra observer.
- El enganche de no-fatales de red en `handlerExceptionHttp` (fase 4) — aquí solo se entrega la
  abstracción `CrashReporter` que esa fase consume.
- `setUserId` real desde `AuthCubit` con hash SHA-256 (fase 5) — aquí solo se declara la firma.
- UI de opt-out, `setEnabled` desde perfil, strings ES, política de privacidad (fases 10–11).
- Cualquier cambio en `rideglory-api`.

## Que se debe hacer (pasos concretos y ordenados)

1. **Dependencia.** Añadir `firebase_crashlytics` a `pubspec.yaml` (sección `dependencies`),
   resolviendo la versión compatible con `firebase_core ^4.2.1` vía `flutter pub add
   firebase_crashlytics` (no fijar el major a ciegas). Correr `flutter pub get`.

2. **Provider DI.** En `firebase_module.dart`, añadir
   `@lazySingleton FirebaseCrashlytics get firebaseCrashlytics => FirebaseCrashlytics.instance;`
   (mismo patrón que `firebaseAnalytics` en L21).

3. **Ampliar `AnalyticsService`.** Añadir a la interfaz (`analytics_service.dart`):
   `Future<void> logScreenView(String screenName)`,
   `Future<void> setUserId(String? id)`,
   `Future<void> setUserProperty(String name, String? value)`,
   `Future<void> setEnabled(bool enabled)`. Mantener el doc-comment de "anonymous, no PII".
   Implementarlos en `FirebaseAnalyticsService` envolviendo el SDK 1:1
   (`logScreenView(screenName:)`, `setUserId(id:)`, `setUserProperty(name:value:)`,
   `setAnalyticsCollectionEnabled(enabled)`).

4. **Abstracción `CrashReporter`.** Crear `core/services/crash/crash_reporter.dart` (Dart puro,
   **sin imports de Flutter ni del SDK**), con al menos:
   `Future<void> recordError(Object error, StackTrace? stack, {bool fatal})`,
   `Future<void> recordFlutterError(/* tipo neutral */)` o un `recordError` único reutilizable
   por los handlers, `Future<void> log(String message)`,
   `Future<void> setCustomKey(String key, Object value)`,
   `Future<void> setUserId(String? id)`,
   `Future<void> setEnabled(bool enabled)`. Las firmas no aceptan PII.

5. **Impl Crashlytics.** Crear `core/services/crash/firebase_crash_reporter.dart` con
   `@Injectable(as: CrashReporter)`, recibiendo `FirebaseCrashlytics` por constructor y
   delegando 1:1 (`recordError`, `recordFlutterError`, `log`, `setCustomKey`,
   `setUserIdentifier`, `setCrashlyticsCollectionEnabled`). **Único** archivo (junto a
   `firebase_analytics_service.dart`) autorizado a importar el SDK de Crashlytics.

6. **No-op impl para tests.** Crear `core/services/crash/no_op_crash_reporter.dart` con
   `@Injectable(as: CrashReporter, env: [Environment.test])` (o equivalente) que no hace nada.
   De forma simétrica, garantizar que en tests la analítica quede inerte vía **no-op +
   `setEnabled(false)`** (registrar también la estrategia para `AnalyticsService` en test si la
   impl Firebase no es segura en el entorno de test). Documentar cómo el harness de tests
   selecciona el environment.

7. **Cableado de captura en `main.dart`.**
   - Importar `dart:async` (`runZonedGuarded`), `dart:ui` (`PlatformDispatcher`),
     `package:flutter/foundation.dart` (`kDebugMode`) y `firebase_crashlytics`.
   - Envolver el cuerpo de `main` (desde `configureDependencies()` hasta `runApp()`) dentro de
     **un mismo** `runZonedGuarded(() async { ... }, (error, stack) { ... })`.
   - Antes de `runApp`, registrar:
     - `FlutterError.onError`: si `kDebugMode` → delegar a `FlutterError.presentError`
       (comportamiento por defecto, **no reportar**); si no → enviar a Crashlytics.
     - `PlatformDispatcher.instance.onError`: en release reporta como fatal y retorna `true`;
       en debug no reporta.
   - El handler de `runZonedGuarded` reporta el error no-capturado (no fatal/según política),
     **solo fuera de `kDebugMode`**.
   - **Init defensivo:** el acceso a Crashlytics dentro de los handlers debe ir en
     `try/catch` (o detrás de un guard) para que un fallo de init **no rompa `runApp`**;
     la app degrada en silencio (sin pantalla en blanco). `runApp` permanece dentro de la zona.

8. **Regla de capa (G0).** Escribir el documento de la regla bajo `docs/` (sugerido
   `docs/features/analytics.md` o `docs/adr/`): *"`AnalyticsService` y `CrashReporter` son
   abstracciones **puras** en `core/services/` (Dart puro, sin Flutter ni SDK), consumibles por
   `domain` y `presentation`; el SDK Firebase (Analytics/Crashlytics) aparece **solo** en las
   impl `@Injectable(as: Interface)` bajo `core/services/.../firebase_*`."* Declarar
   explícitamente que el call site de `ScanSoatUseCase` (domain inyecta `AnalyticsService`)
   **YA cumple** la regla → **sin refactor en esta fase**; su normalización a constantes de
   taxonomía se hará en fase 2.

9. **Regen + checks.** Correr
   `dart run build_runner build --delete-conflicting-outputs` (nuevos `@Injectable`),
   `dart analyze` (limpio) y `flutter test` (verde con no-op + `setEnabled(false)`).
   Verificar grep G0 (paso de aceptación e).

10. **Verificación nativa (DevOps).** Forzar un crash de prueba y confirmar que aparece
    **simbolizado** en consola Crashlytics en build **staging Android e iOS** (no en debug).
    Documentar los pasos de setup nativo en el handoff DevOps.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

- `pubspec.yaml` — añade `firebase_crashlytics` (major compatible con `firebase_core 4.x`).
- `android/settings.gradle.kts` — declara el plugin `com.google.firebase.crashlytics` (apply false) junto al `com.google.gms.google-services` (L23).
- `android/app/build.gradle.kts` — aplica `com.google.firebase.crashlytics` junto a `google-services` (L4-6) + habilita mapping upload.
- iOS (build phase / `ios/Runner.xcodeproj` o Fastlane) — agrega subida de dSYM (`upload-symbols`) para símbolos en consola.
- `lib/main.dart` — envuelve `configureDependencies()`+`runApp()` en `runZonedGuarded`; registra `FlutterError.onError` y `PlatformDispatcher.onError`; gating por `kDebugMode`; init defensivo de Crashlytics (L26-54).
- `lib/core/di/firebase_module.dart` — añade `@lazySingleton FirebaseCrashlytics` (junto a `FirebaseAnalytics` L21).
- `lib/core/services/analytics/analytics_service.dart` — amplía la interfaz con `logScreenView`/`setUserId`/`setUserProperty`/`setEnabled` (L5-7).
- `lib/core/services/analytics/firebase_analytics_service.dart` — implementa los métodos nuevos envolviendo el SDK 1:1.
- `lib/core/services/crash/crash_reporter.dart` — **nuevo**: abstracción Dart-pura del crash reporting.
- `lib/core/services/crash/firebase_crash_reporter.dart` — **nuevo**: impl `@Injectable(as: CrashReporter)` que envuelve `FirebaseCrashlytics`.
- `lib/core/services/crash/no_op_crash_reporter.dart` — **nuevo**: no-op impl para el entorno de test.
- `lib/core/di/injection.config.dart` — **regenerado** por `build_runner` (registra los nuevos providers/impl). No editar a mano.
- `docs/features/analytics.md` (o ADR equivalente) — **nuevo/actualizado**: regla de capa G0 + nota de que el call site de soat ya cumple.

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** Toda la observabilidad de esta fase es 100% client-side. `rideglory-api` no
cambia: no hay endpoints nuevos, ni cambios en `GET /me`, ni DTOs (no aplica Pattern B; la
analítica no serializa modelos de API).

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** No hay migración de BD. No se añade persistencia local en esta fase (la clave de
opt-out en `UserStorageService`/SharedPreferences es de la **fase 11**). Único "code-gen":
re-correr `build_runner` para registrar los nuevos `@Injectable` (`FirebaseCrashlytics`,
`FirebaseCrashReporter`, `NoOpCrashReporter`).

## Criterios de aceptacion (numerados, observables, testeables)

1. **Crash simbolizado en staging.** Un crash de prueba forzado aparece **simbolizado** (con
   stack legible) en la consola Crashlytics en build **staging Android** y **staging iOS**.
2. **Init defensivo.** Un fallo de init de Crashlytics **no** rompe `runApp`: la app arranca y
   navega normalmente (degradación silenciosa, sin pantalla en blanco). Verificable forzando un
   fallo de init y confirmando que la app sigue usable.
3. **Gating en debug.** En `kDebugMode`, ni `FlutterError.onError`, ni
   `PlatformDispatcher.onError`, ni el handler de `runZonedGuarded` envían reportes a
   Crashlytics (verificable en log / ausencia de reporte en consola).
4. **Gating en tests.** Con la no-op impl de `CrashReporter` + `setEnabled(false)`,
   `flutter test` no intenta enviar eventos ni reportes; `dart analyze` queda **limpio**.
5. **Regla de capa G0 (grep).** `grep -r "package:firebase_crashlytics" lib/` y
   `grep -r "package:firebase_analytics" lib/` devuelven **0** coincidencias fuera de
   `lib/core/services/.../firebase_*` (es decir: solo `firebase_analytics_service.dart` y
   `firebase_crash_reporter.dart`).
6. **Abstracciones puras.** `crash_reporter.dart` y `analytics_service.dart` no importan
   `package:flutter/*` ni ningún `package:firebase_*` (Dart puro, consumibles por domain).
7. **Sin refactor de soat.** `ScanSoatUseCase` sigue compilando e inyectando
   `AnalyticsService` sin cambios en esta fase; el doc G0 declara que ya cumple.
8. **Sin UI / sin regresión.** No hay pantalla nueva ni cambio de comportamiento observable
   para el usuario; el árbol de navegación y los flujos existentes son idénticos.

## Pruebas (unitarias/widget/integracion)

- **Unitaria — handlers de captura (gating debug).** Test que, simulando los handlers con un
  mock de `CrashReporter`, verifica que **en `kDebugMode` no se llama** `recordError` y **fuera
  de debug sí** (parametrizable). Cubre `FlutterError.onError`, `PlatformDispatcher.onError` y
  el callback de `runZonedGuarded`.
- **Unitaria — no-op `CrashReporter`.** Test que confirma que la no-op impl no lanza y no tiene
  efectos (métodos completan sin error), garantizando que la suite no toca red.
- **Unitaria — `FirebaseAnalyticsService` ampliado.** Con un mock/fake de `FirebaseAnalytics`,
  verificar que `logScreenView`, `setUserId`, `setUserProperty`, `setEnabled` delegan 1:1 al
  SDK con los argumentos correctos (incluido `setAnalyticsCollectionEnabled(false)`).
- **Unitaria — DI selecciona no-op en test.** Verificar que en el environment de test
  `getIt<CrashReporter>()` resuelve a la no-op impl (no a la Firebase).
- **Smoke de arranque (degradación).** Test/escenario que fuerza un fallo de init de Crashlytics
  y confirma que `main`/`runApp` no propaga la excepción (la zona la absorbe).
- Usar `bloc_test ^10.0.0` / mocks ya disponibles en `dev_dependencies`; no se requieren
  dependencias de test nuevas.

## Riesgos y mitigaciones

1. **Setup nativo frágil (Gradle Android + dSYM iOS).** Mal setup = crashes sin símbolos.
   *Mitigación:* criterio de aceptación #1 (crash simbolizado en staging Android+iOS) es
   **bloqueante** para cerrar la fase; documentar los pasos en el handoff DevOps; verificar en
   build real, nunca en debug.
2. **Versión `firebase_crashlytics` vs `firebase_core 4.x`.** Incompatibilidad de major.
   *Mitigación:* resolver con `flutter pub add` (no fijar a ciegas) + `flutter pub get` +
   `build_runner`; si hay conflicto, alinear al major que el solver elija para `firebase_core`.
3. **Fallo de init de Crashlytics rompe el arranque.** *Mitigación:* init defensivo en
   `try/catch`, `runApp` dentro de la zona, criterio de aceptación #2.
4. **Gating insuficiente (eventos/reportes en debug o CI).** Flakiness o ruido.
   *Mitigación:* no-op impl + `setEnabled(false)` + handlers no-report en `kDebugMode`,
   verificado por los tests unitarios de gating y el grep G0.
5. **Fuga de capa (SDK fuera de `firebase_*`).** Propagaría la dependencia a 11 features.
   *Mitigación:* regla G0 escrita + criterio de aceptación #5 (grep = 0) revisado por el
   revisor de arquitectura antes de instrumentar features.
6. **`build_runner` falla en worktrees/CI frescos.** *Mitigación:* usar `--force-jit` o copiar
   `pubspec.lock`/`.env`/configs Firebase de `main` (aprendizaje del proyecto); correr el build
   tras añadir los `@Injectable`.

## Dependencias (fases prerequisito y por que)

**Ninguna (dependsOn: []).** Esta es la fase **fundacional y desbloqueante**: entrega la
abstracción `CrashReporter`, la interfaz `AnalyticsService` ampliada, la no-op impl, el
cableado de captura y la regla de capa G0. Todas las fases siguientes la consumen:
- Fase 2 (taxonomía) normaliza el call site de soat usando `AnalyticsService` ya disponible.
- Fase 3 (`screen_view`) usa la firma `logScreenView` declarada aquí.
- Fase 4 (no-fatales de red) consume la abstracción `CrashReporter` en `handlerExceptionHttp`.
- Fase 5 (`setUserId` hasheado) usa la firma `setUserId` declarada aquí.
- Fases 6–9 reutilizan el gating único (no-op + `setEnabled(false)` + no-report en `kDebugMode`).
- Fase 11 (opt-out) usa `setEnabled` declarado aquí.
