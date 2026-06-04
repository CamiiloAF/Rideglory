> Slim handoff — lee esto antes de docs/exec-runs/obs-fundaciones-crashlytics/handoffs/architect.md

# Architect → QA (obs-fundaciones-crashlytics)

---

## Comandos de verificación

```bash
# 1. Análisis estático (debe ser 0 errores, 0 warnings nuevos)
dart analyze

# 2. Tests unitarios (suite completa debe ser verde)
flutter test

# 3. Regla G0 — debe devolver 0 líneas en ambos casos
#
# Archivos legítimamente excluidos:
#   firebase_crash_reporter.dart  — impl prod de CrashReporter (único punto de import crashlytics)
#   firebase_module.dart          — provee @lazySingleton FirebaseCrashlytics (DI infrastructure)
#   injection.config.dart         — generado por build_runner (registra el lazySingleton automáticamente)
#
grep -r "package:firebase_crashlytics" lib/ \
  | grep -v "lib/core/services/crash/firebase_crash_reporter.dart" \
  | grep -v "lib/core/di/firebase_module.dart" \
  | grep -v "lib/core/di/injection.config.dart"

# Archivos legítimamente excluidos para analytics:
#   firebase_analytics_service.dart — impl prod de AnalyticsService (único punto de import analytics)
#   firebase_module.dart            — provee @lazySingleton FirebaseAnalytics
#   injection.config.dart           — generado por build_runner
#
grep -r "package:firebase_analytics" lib/ \
  | grep -v "lib/core/services/analytics/firebase_analytics_service.dart" \
  | grep -v "lib/core/di/firebase_module.dart" \
  | grep -v "lib/core/di/injection.config.dart"

# 4. Abstracciones puras — deben devolver 0
grep "package:flutter" lib/core/services/crash/crash_reporter.dart
grep "package:firebase" lib/core/services/crash/crash_reporter.dart
grep "package:flutter" lib/core/services/analytics/analytics_service.dart
grep "package:firebase" lib/core/services/analytics/analytics_service.dart
```

---

## Tests a escribir: `test/core/services/crash/crash_reporter_test.dart`

| Caso | Qué verificar |
|------|--------------|
| `NoOpCrashReporter.recordError` | No lanza, no llama SDK |
| `NoOpCrashReporter.setEnabled` | No lanza |
| `FirebaseCrashReporter.recordError` | Delega a `FirebaseCrashlytics.recordError` con args correctos |
| `FirebaseCrashReporter.setEnabled(false)` | Llama `setCrashlyticsCollectionEnabled(false)` |
| Init defensivo en `main` | Si `CrashReporter` falla init, `runApp` no lanza |

Usar `mocktail` para mockear `FirebaseCrashlytics`.

---

## Criterios de aceptación trazables

| CA | Verificación |
|----|-------------|
| CA-1 Crash simbolizado staging | Manual: forzar crash en build staging, confirmar en consola Crashlytics |
| CA-2 Init defensivo | Test unitario de degradación silenciosa; manual: forzar fallo init |
| CA-3 Gating debug | `kDebugMode=true` → handler no llama `recordError` (test unitario con mock) |
| CA-4 Gating tests | `flutter test` verde; no-op impl no llama SDK |
| CA-5 Regla G0 grep | Los comandos grep devuelven 0 líneas. Archivos legítimamente excluidos del grep: `firebase_crash_reporter.dart`, `firebase_analytics_service.dart`, `firebase_module.dart`, `injection.config.dart` (DI infra y código generado). |
| CA-6 Abstracciones puras | grep imports Flutter/Firebase en abstracts devuelve 0 |
| CA-7 ScanSoatUseCase compila | `dart analyze` limpio; `flutter test` no rompe tests de soat |
| CA-8 Sin UI / sin regresión | Ningún widget nuevo; árbol de navegación idéntico |

---

## Lints preexistentes a ignorar

Los 2 lints de `api_base_url_resolver.dart` (hack `shouldUseLocalApi=true`) son preexistentes — no contarlos como regresión.

> Full detail: docs/exec-runs/obs-fundaciones-crashlytics/handoffs/architect.md
