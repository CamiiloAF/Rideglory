# Architect handoff — obs-fundaciones-crashlytics

**Date:** 2026-06-04T03:11:41Z
**Status:** done

---

## Decisiones

### D1 — `firebase_crashlytics` como nueva dependencia pubspec

`firebase_crashlytics` no está en `pubspec.yaml`. Se añade con `flutter pub add firebase_crashlytics`. Versión compatible con `firebase_core ^4.2.1` (mismo SDK Firebase ya en uso). No se requiere major bump.

### D2 — Regla G0: un único punto de importación por SDK Firebase

Solo `lib/core/services/crash/firebase_crash_reporter.dart` puede importar `package:firebase_crashlytics`.
Solo `lib/core/services/analytics/firebase_analytics_service.dart` puede importar `package:firebase_analytics`.
Las abstracciones (`crash_reporter.dart`, `analytics_service.dart`) son Dart puro — sin imports Flutter ni Firebase.
Esta regla es un invariante de arquitectura verificable con `grep`.

### D3 — `CrashReporter` vive en `core/services/crash/` (NO en domain)

Aunque `domain` puede consumir `CrashReporter` (regla G0 lo permite), la abstracción reside en `core/services/crash/`. Es un servicio transversal de infraestructura, no un contrato de negocio.

### D4 — Ampliación non-breaking de `AnalyticsService`

Se añaden 4 métodos con implementación default (`Future<void> logScreenView(...){}`, etc.) para no romper `ScanSoatUseCase` ni `FirebaseAnalyticsService` existentes. `ScanSoatUseCase` sigue compilando sin cambios — declara el cumplimiento G0 en el doc `docs/features/analytics.md`.

### D5 — `runZonedGuarded` en `main()` con gating `kDebugMode`

El flujo actual en `main.dart`:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp()`
3. `FirebaseMessaging`, `ApiRemoteConfig`, `initializeDateFormatting`, Mapbox
4. `configureDependencies()`
5. `runApp()`

La refactorización mantiene este orden y lo extiende:
1–3: igual que hoy (sin cambio).
4: `configureDependencies()` — **DI se inicializa primero**; `getIt<CrashReporter>()` ya está disponible a partir de aquí.
5: Registrar `FlutterError.onError` y `PlatformDispatcher.onError` **inmediatamente después** de `configureDependencies()`, y **antes** de `runApp()`. Los handlers acceden a `getIt<CrashReporter>()` en tiempo de ejecución (cuando se disparan), no en tiempo de registro — pero DI ya está lista en ese punto de todas formas.
6: Init defensivo de Crashlytics con `try/catch` (fallo silencioso).
7: `runZonedGuarded(() => runApp(...), handler)` — el zone handler también usa `getIt<CrashReporter>()` en tiempo de ejecución.

**Invariante crítico:** Ninguna llamada a `getIt<CrashReporter>()` ocurre antes de `configureDependencies()`. Los closures de los handlers se registran después de que DI está lista.

### D6 — `NoOpCrashReporter` para env `test`

Patrón idéntico al que usaría una `NoOpAnalyticsService` (si existiera). Marcado `@Injectable(as: CrashReporter, env: [Environment.test])` para que en la suite de tests no haya llamadas reales al SDK.

### D7 — `FirebaseCrashlytics` provisto en `FirebaseInjectableModule`

Sigue el patrón ya establecido para `FirebaseAnalytics`: `@lazySingleton FirebaseCrashlytics get firebaseCrashlytics => FirebaseCrashlytics.instance;`. Se regenera `injection.config.dart` con `build_runner`.

### D8 — Android: plugin Crashlytics en Gradle

`android/settings.gradle.kts`: añadir `id("com.google.firebase.crashlytics") version "3.0.3" apply false`.
`android/app/build.gradle.kts`: añadir `id("com.google.firebase.crashlytics")` en el bloque `plugins {}` y en `buildTypes.release` la extensión `firebaseCrashlytics { mappingFileUploadEnabled = true }` para subir el mapping de ProGuard.

### D9 — iOS: dSYM via build phase

Se añade un "Run Script Phase" en `ios/Runner.xcodeproj/project.pbxproj` que invoca `"${PODS_ROOT}/FirebaseCrashlytics/run"`. Esto permite símbolos legibles en la consola Crashlytics para iOS.

### D10 — Docs G0 en `docs/features/analytics.md`

El archivo no existe aún. Se crea declarando: (a) la regla G0, (b) que `ScanSoatUseCase` ya cumple, (c) el contrato de `CrashReporter`, (d) las firmas ampliadas de `AnalyticsService`.

**Aclaración del invariante G0 para el grep de verificación:**
El grep que verifica la regla G0 debe excluir los siguientes archivos que legítimamente importan los SDKs Firebase como infraestructura de DI:
- `lib/core/services/crash/firebase_crash_reporter.dart` — único punto de import de `firebase_crashlytics` (impl prod)
- `lib/core/services/analytics/firebase_analytics_service.dart` — único punto de import de `firebase_analytics` (impl prod)
- `lib/core/di/firebase_module.dart` — provee `@lazySingleton FirebaseCrashlytics` y `@lazySingleton FirebaseAnalytics` (módulo DI, per D7)
- `lib/core/di/injection.config.dart` — generado automáticamente por `build_runner`; registra los lazySingletons sin que el desarrollador lo controle

El grep que falla con cualquier coincidencia fuera de estos 4 archivos constituye una violación de G0.

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `pubspec.yaml` | modify | Añadir `firebase_crashlytics` dep | low |
| `android/settings.gradle.kts` | modify | Declarar plugin Crashlytics con `apply false` | low |
| `android/app/build.gradle.kts` | modify | Aplicar plugin + mapping upload en release | low |
| `ios/Runner.xcodeproj/project.pbxproj` | modify | Run Script Phase para upload-symbols dSYM | med |
| `lib/main.dart` | modify | `runZonedGuarded` + handlers + init defensivo Crashlytics | med |
| `lib/core/di/firebase_module.dart` | modify | `@lazySingleton FirebaseCrashlytics` | low |
| `lib/core/di/injection.config.dart` | modify | Regenerado por `build_runner` (no editar a mano) | low |
| `lib/core/services/analytics/analytics_service.dart` | modify | Añadir `logScreenView`, `setUserId`, `setUserProperty`, `setEnabled` con default impl vacía | low |
| `lib/core/services/analytics/firebase_analytics_service.dart` | modify | Implementar las 4 nuevas firmas delegando al SDK | low |
| `lib/core/services/crash/crash_reporter.dart` | create | Abstracción Dart puro (interfaz) | low |
| `lib/core/services/crash/firebase_crash_reporter.dart` | create | Impl prod que delega a `FirebaseCrashlytics` | low |
| `lib/core/services/crash/no_op_crash_reporter.dart` | create | Impl no-op para `Environment.test` | low |
| `test/core/services/crash/crash_reporter_test.dart` | create | Tests unitarios handlers, no-op, degradación | low |
| `docs/features/analytics.md` | create | Regla G0 + declaración cumplimiento ScanSoatUseCase | low |

---

## Contratos

### `CrashReporter` (abstracción Dart puro)

```dart
// lib/core/services/crash/crash_reporter.dart
abstract class CrashReporter {
  /// Reporta un error no fatal con stack trace opcional.
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Habilita o deshabilita la colección (opt-out o gating debug/test).
  Future<void> setEnabled(bool enabled);
}
```

**Restricciones de firma:**
- No acepta PII directamente.
- `fatal: true` solo para `FlutterError.onError` / `PlatformDispatcher.onError`.
- `fatal: false` para el handler de `runZonedGuarded`.

### `AnalyticsService` ampliado (Dart puro)

```dart
abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);

  // Nuevas firmas (fases futuras las usan; esta fase solo las declara + implementa vacío)
  Future<void> logScreenView(String screenName) async {}
  Future<void> setUserId(String hashedId) async {}
  Future<void> setUserProperty(String name, String value) async {}
  Future<void> setEnabled(bool enabled) async {}
}
```

### `FirebaseCrashReporter`

```dart
// lib/core/services/crash/firebase_crash_reporter.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';
import 'crash_reporter.dart';

@Injectable(as: CrashReporter)
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);
  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(Object exception, StackTrace? stack, {
    String? reason, bool fatal = false,
  }) => _crashlytics.recordError(exception, stack, reason: reason, fatal: fatal);

  @override
  Future<void> setEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);
}
```

### `NoOpCrashReporter`

```dart
// lib/core/services/crash/no_op_crash_reporter.dart
import 'package:injectable/injectable.dart';
import 'crash_reporter.dart';

@Injectable(as: CrashReporter, env: [Environment.test])
class NoOpCrashReporter implements CrashReporter {
  @override
  Future<void> recordError(Object exception, StackTrace? stack, {
    String? reason, bool fatal = false,
  }) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
```

### `main.dart` — patrón de cableado

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... Firebase.initializeApp, FCM, RemoteConfig, DateFormatting, Mapbox (sin cambio)

  // PASO 1: DI primero — getIt<CrashReporter>() disponible a partir de aquí
  configureDependencies();

  // PASO 2: Init defensivo de Crashlytics (post-DI)
  try {
    await getIt<CrashReporter>().setEnabled(!kDebugMode);
  } catch (_) {
    // fallo silencioso — un fallo de Crashlytics no debe romper runApp
  }

  // PASO 3: Registrar handlers DESPUÉS de configureDependencies() y ANTES de runApp.
  // Los closures invocan getIt<CrashReporter>() en tiempo de ejecución (cuando el handler
  // se dispara), no en tiempo de registro. DI ya está inicializada en ambos momentos.
  if (!kDebugMode) {
    FlutterError.onError = (details) {
      getIt<CrashReporter>().recordError(
        details.exception,
        details.stack,
        reason: details.exceptionAsString(),
        fatal: true,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      getIt<CrashReporter>().recordError(error, stack, fatal: true);
      return true;
    };
  }

  // PASO 4: runZonedGuarded envuelve runApp; el zone handler reporta errores no-fatales
  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) {
      if (!kDebugMode) {
        getIt<CrashReporter>().recordError(error, stack, fatal: false);
      }
    },
  );
}
```

**Invariante de orden:** `configureDependencies()` → init defensivo → registro de handlers → `runZonedGuarded(runApp)`. Nunca invocar `getIt<CrashReporter>()` antes de `configureDependencies()`.

---

## Datos / Migraciones

No hay migraciones de base de datos. No hay cambios en `rideglory-api`. No se requiere `analysis/MIGRATION_PLAN.md`.

---

## Env

No hay variables de entorno nuevas. Crashlytics se configura mediante `google-services.json` (Android) y `GoogleService-Info.plist` (iOS), que ya están en el proyecto. No se requiere `analysis/ENV_DELTA.md`.

---

## Riesgos

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| `build_runner` falla en worktree/CI fresco por `objective_c` hooks | media | Usar `--force-jit` (aprendizaje documentado en MEMORY) |
| dSYM upload iOS rompe build Xcode si el script path es incorrecto | media | Verificar path `${PODS_ROOT}/FirebaseCrashlytics/run` post-`pod install`; si falla, usar upload manual |
| `runZonedGuarded` + `PlatformDispatcher.onError` interacción con errores de Mapbox | baja | Los handlers tienen gating `kDebugMode` y `try/catch` interno; no afecta arranque |
| ProGuard mapping upload en CI sin keystore configurado | baja | `mappingFileUploadEnabled` solo actúa en release signing real; sin keystore no falla |
| `injection.config.dart` desactualizado si no se regenera | media | Frontend DEBE correr `dart run build_runner build --delete-conflicting-outputs` después de añadir `firebase_crash_reporter.dart` |

---

## Orden de implementación

1. `pubspec.yaml` — añadir `firebase_crashlytics` (`flutter pub add`)
2. `lib/core/services/analytics/analytics_service.dart` — ampliar interfaz (non-breaking)
3. `lib/core/services/analytics/firebase_analytics_service.dart` — implementar nuevas firmas
4. `lib/core/services/crash/crash_reporter.dart` — crear abstracción
5. `lib/core/services/crash/firebase_crash_reporter.dart` — crear impl prod
6. `lib/core/services/crash/no_op_crash_reporter.dart` — crear impl test
7. `lib/core/di/firebase_module.dart` — añadir `FirebaseCrashlytics` lazySingleton
8. Ejecutar `dart run build_runner build --delete-conflicting-outputs` → regenera `injection.config.dart`
9. `lib/main.dart` — cablear `runZonedGuarded` + handlers + init defensivo
10. `android/settings.gradle.kts` — declarar plugin Crashlytics
11. `android/app/build.gradle.kts` — aplicar plugin + mapping upload
12. `ios/Runner.xcodeproj/project.pbxproj` — añadir Run Script Phase dSYM
13. `test/core/services/crash/crash_reporter_test.dart` — tests unitarios
14. `docs/features/analytics.md` — doc regla G0
15. Verificar: `dart analyze` limpio, `flutter test` verde, `grep` G0 pasa

---

## Superficie de regresión

- **`main()` init flow**: si `runZonedGuarded` o los handlers están mal cableados, la app puede no arrancar o silenciar excepciones legítimas.
- **DI**: añadir `FirebaseCrashlytics` al módulo y regenerar `injection.config.dart` — un conflicto de código generado puede romper toda la DI.
- **`ScanSoatUseCase`**: cambios en la firma de `AnalyticsService` deben ser non-breaking; `logEvent` no se toca.
- **Suite de tests existente**: la no-op impl debe estar correctamente condicionada a `Environment.test`; si no, los tests intentan contactar Firebase.
- **Android release build**: el mapping upload solo actúa con signing real; sin keystore no debe romper el build.

---

## Fuera de alcance

- Instrumentación de eventos de features (fases 2–9).
- `NavigatorObserver` / `screen_view` automático (fase 3).
- Enganche no-fatales de red en `handlerExceptionHttp` (fase 4).
- `setUserId` con hash SHA-256 real desde `AuthCubit` (fase 5).
- UI de opt-out (fases 10–11).
- Taxonomía/constantes centralizadas (fase 2).
- Cualquier cambio en `rideglory-api`.
