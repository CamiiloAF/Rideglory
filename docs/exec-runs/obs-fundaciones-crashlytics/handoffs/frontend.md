# Frontend handoff — obs-fundaciones-crashlytics

**Date:** 2026-06-04T03:27:17Z
**Status:** done

---

## Baseline

`flutter test` antes de cualquier cambio: **exit 0**, 191 tests passed, 0 failed.

---

## Archivos cambiados

| Archivo | Acción | Detalle |
|---------|--------|---------|
| `pubspec.yaml` | modify | Añadida dependencia `firebase_crashlytics: ^5.2.0` (^4.3.0 era incompatible con firebase_remote_config ^6.4.0; la herramienta sugirió ^5.2.0) |
| `lib/core/services/analytics/analytics_service.dart` | modify | Añadidos 4 métodos con default impl vacía: `logScreenView`, `setUserId`, `setUserProperty`, `setEnabled` — non-breaking |
| `lib/core/services/analytics/firebase_analytics_service.dart` | modify | Implementadas las 4 firmas nuevas delegando al SDK `FirebaseAnalytics` 1:1 |
| `lib/core/services/crash/crash_reporter.dart` | create | Abstracción Dart puro, sin imports Flutter/Firebase — contrato G0 |
| `lib/core/services/crash/firebase_crash_reporter.dart` | create | Impl prod — único import de `package:firebase_crashlytics`; `@Injectable(as: CrashReporter, env: [Environment.prod, Environment.dev])` |
| `lib/core/services/crash/no_op_crash_reporter.dart` | create | Impl test — `@Injectable(as: CrashReporter, env: [Environment.test])`, body vacío |
| `lib/core/di/firebase_module.dart` | modify | Añadido `@lazySingleton FirebaseCrashlytics get firebaseCrashlytics => FirebaseCrashlytics.instance` |
| `lib/core/di/injection.config.dart` | regenerado | `dart run build_runner build --delete-conflicting-outputs` — no editado a mano |
| `lib/main.dart` | modify | Añadidos: `dart:async`, `flutter/foundation.dart`, import `crash_reporter.dart`; `runZonedGuarded` + handlers `FlutterError.onError`/`PlatformDispatcher.onError` con gating `kDebugMode`; init defensivo `setEnabled` post-DI |
| `android/settings.gradle.kts` | modify | Declarado `id("com.google.firebase.crashlytics") version "3.0.3" apply false` |
| `android/app/build.gradle.kts` | modify | Aplicado plugin Crashlytics + `firebaseCrashlytics { mappingFileUploadEnabled = true }` en release |
| `ios/Runner.xcodeproj/project.pbxproj` | modify | Run Script Phase `FC7A1B2C00000000CRASHLYTICS` añadido al target Runner para upload-symbols dSYM vía `${PODS_ROOT}/FirebaseCrashlytics/run` |
| `test/core/services/crash/crash_reporter_test.dart` | create | 9 tests unitarios: 5 NoOpCrashReporter + 4 FirebaseCrashReporter (con MockFirebaseCrashlytics via mocktail) |
| `docs/features/analytics.md` | create | Documenta regla G0, archivos legítimos excluidos del grep, contrato CrashReporter, firmas AnalyticsService ampliadas, cumplimiento ScanSoatUseCase |

**Nota sobre versión firebase_crashlytics:** El architect especificó `^4.3.0` pero esa versión es incompatible con `firebase_remote_config ^6.4.0` ya en el proyecto. `flutter pub get` falló y sugirió `^5.2.0` como versión compatible. Se usó `^5.2.0`.

**Nota sobre env de FirebaseCrashReporter:** El architect especificó `@Injectable(as: CrashReporter)` (sin env), pero el injectable_generator lo registra en TODOS los environments incluyendo test, causando conflicto con NoOpCrashReporter. Se añadió `env: [Environment.prod, Environment.dev]` para evitar el conflicto. Esto es el patrón correcto para impl prod vs no-op test.

---

## Pruebas nuevas

`test/core/services/crash/crash_reporter_test.dart` — 9 tests:

| ID | Grupo | Descripción |
|----|-------|-------------|
| TC-crash-1 | NoOpCrashReporter | recordError no lanza ni contacta Firebase |
| TC-crash-2 | NoOpCrashReporter | recordError con stack y reason no lanza |
| TC-crash-3 | NoOpCrashReporter | recordError con fatal:true no lanza |
| TC-crash-4 | NoOpCrashReporter | setEnabled(true) no lanza |
| TC-crash-5 | NoOpCrashReporter | setEnabled(false) no lanza |
| TC-crash-6 | FirebaseCrashReporter | recordError delega al SDK con parámetros correctos |
| TC-crash-7 | FirebaseCrashReporter | recordError fatal:true delega al SDK correctamente |
| TC-crash-8 | FirebaseCrashReporter | setEnabled delega a setCrashlyticsCollectionEnabled |
| TC-crash-9 | FirebaseCrashReporter | setEnabled(true) delega al SDK |

---

## Resultado final

- `dart analyze lib/`: **No issues found**
- `flutter test`: **200 passed, 0 failed** (191 baseline + 9 nuevos)
- G0 crashlytics: **0 violaciones**
- G0 analytics: **0 violaciones**

---

## Verificación manual

Para confirmar en runtime:
1. Build release Android con keystore configurado — verificar que `mappingFileUploadEnabled` sube el mapping en Firebase Console bajo Crashlytics > App Quality.
2. Build iOS — verificar que el Run Script Phase aparece en Xcode > Build Phases del target Runner.
3. Forzar una excepción no capturada en release mode — verificar que aparece en Firebase Crashlytics console en ~5 minutos.
4. En debug mode — confirmar que los handlers NO se registran (gating `kDebugMode`).

---

## Notas para QA

1. **No hay UI nueva** — esta fase es 100% infraestructura. No hay pantallas ni widgets nuevos.
2. **No hay localization keys nuevas** — sin strings visibles al usuario.
3. El `runZonedGuarded` envuelve `runApp` — si la app no arranca, revisar el init defensivo (paso 2 de `main()`). El bloque `try/catch` silencia fallos de Crashlytics para no romper arranque.
4. **Regresión crítica a verificar:** `ScanSoatUseCase` sigue compilando y ejecutando sin cambios. `AnalyticsService.logEvent` no fue modificado.
5. `injection.config.dart` fue regenerado — si hay conflictos de código generado en CI, usar `dart run build_runner build --force-jit --delete-conflicting-outputs`.
6. La versión de `firebase_crashlytics` que queda en `pubspec.yaml` es `^5.2.0` (no `^4.3.0` como especificó el architect) — actualizar el architect.md si se archiva.
