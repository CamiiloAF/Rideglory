# SUMMARY — obs-fundaciones-crashlytics

**Generated:** 2026-06-04T03:45:21Z
**Tech Lead:** Sonnet 4.6
**Verdict:** READY

---

## Objetivo

Establecer la base de observabilidad de Rideglory: captura de crashes fatales y no-fatales desde producción/staging con gating estricto en debug y tests. Sin UI nueva, sin cambio de comportamiento observable para el usuario.

---

## Qué cambió por área

### Dependencias
- `pubspec.yaml`: `firebase_crashlytics: ^5.2.0` (versión `^4.3.0` del architect era incompatible con `firebase_remote_config ^6.4.0`; corrección válida del frontend).

### Nativo Android
- `android/settings.gradle.kts`: plugin `com.google.firebase.crashlytics` versión `3.0.3` declarado con `apply false`.
- `android/app/build.gradle.kts`: plugin aplicado + `firebaseCrashlytics { mappingFileUploadEnabled = true }` en release.

### Nativo iOS
- `ios/Runner.xcodeproj/project.pbxproj`: Run Script Phase `FC7A1B2C00000000CRASHLYTICS` — invoca `"${PODS_ROOT}/FirebaseCrashlytics/run"` para upload dSYM.

### DI Firebase
- `lib/core/di/firebase_module.dart`: `@lazySingleton FirebaseCrashlytics`.
- `lib/core/di/injection.config.dart`: regenerado; `NoOpCrashReporter` en `{_test}`, `FirebaseCrashReporter` en `{_prod, _dev}`.

### Servicios analytics
- `lib/core/services/analytics/analytics_service.dart`: 4 firmas nuevas non-breaking con default impl vacía.
- `lib/core/services/analytics/firebase_analytics_service.dart`: implementación delegando al SDK.

### Servicios crash (nuevos)
- `lib/core/services/crash/crash_reporter.dart`: abstracción Dart puro.
- `lib/core/services/crash/firebase_crash_reporter.dart`: impl prod, único import de `firebase_crashlytics`.
- `lib/core/services/crash/no_op_crash_reporter.dart`: impl test, body vacío.
- `lib/core/services/crash/crash_handler_setup.dart`: extracción de QA para testabilidad aislada de `registerCrashHandlers()`.

### Punto de entrada
- `lib/main.dart`: init defensivo post-DI, `registerCrashHandlers()` con gating `kDebugMode`, `runZonedGuarded` envolviendo `runApp`.

### Docs
- `docs/features/analytics.md`: regla G0, contrato `CrashReporter`, firmas ampliadas, cumplimiento `ScanSoatUseCase`.

---

## Archivos (git diff --stat)

```
android/app/build.gradle.kts                                |  4 +++
android/settings.gradle.kts                                |  1 +
ios/Runner.xcodeproj/project.pbxproj                       | 19 ++++++++++++++
lib/core/di/firebase_module.dart                           |  3 +++
lib/core/services/analytics/analytics_service.dart         |  6 +++++
lib/core/services/analytics/firebase_analytics_service.dart| 20 +++++++++++++++
lib/main.dart                                              | 29 +++++++++++++++++++++-
pubspec.yaml                                               |  2 ++
8 files changed, 83 insertions(+), 1 deletion(-)

Nuevos (untracked):
+ lib/core/services/crash/crash_reporter.dart
+ lib/core/services/crash/firebase_crash_reporter.dart
+ lib/core/services/crash/no_op_crash_reporter.dart
+ lib/core/services/crash/crash_handler_setup.dart
+ test/core/services/crash/crash_reporter_test.dart (9 tests)
+ test/core/services/crash/crash_handler_setup_test.dart (5 tests)
+ test/core/services/analytics/firebase_analytics_service_test.dart (5 tests)
+ docs/features/analytics.md
```

---

## Pruebas

| Métrica | Valor |
|---------|-------|
| `dart analyze lib/` | No issues found |
| Tests baseline | 191 |
| Tests nuevos | 19 |
| Total post-QA | 210 |
| Tests fallidos | 0 |
| Violaciones G0 crashlytics | 0 |
| Violaciones G0 analytics | 0 |

---

## Riesgos / Watchlist

| Riesgo | Severidad | Acción |
|--------|-----------|--------|
| CA-1 (crash simbolizado) no automatizable | baja | PM-1/PM-2: build release → forzar crash → Firebase console |
| dSYM iOS script path post pod install | media | Verificar en Xcode > Build Phases |
| `build_runner` en CI fresco | media | Usar `--force-jit` (documentado en MEMORY) |
| `recordError` sin try/catch en zone handler | info/watchlist | Riesgo muy bajo — SDK maneja internamente; revisar en fases futuras |

---

## Mensaje de commit sugerido

```
feat(observability): add Firebase Crashlytics foundation and crash handlers

- Add firebase_crashlytics ^5.2.0 dependency
- Implement CrashReporter abstraction (Dart-pure) with Firebase and no-op impls
- Wire runZonedGuarded, FlutterError.onError, PlatformDispatcher.onError in main()
- Gate all crash reporting behind kDebugMode (no reports in debug/test)
- Extend AnalyticsService with logScreenView, setUserId, setUserProperty, setEnabled
- Add Android Crashlytics Gradle plugin with ProGuard mapping upload
- Add iOS dSYM upload Run Script Phase
- Add 19 new tests covering crash reporter, handler setup, and analytics service
- Document G0 rule in docs/features/analytics.md
```
