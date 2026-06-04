# QA Handoff — obs-fundaciones-crashlytics

**Generated:** 2026-06-04T03:41:04Z
**QA Agent:** Sonnet 4.6
**Status:** Sign-off GREEN (pendiente PM-1 manual)

---

## Catalogo

Mapeo de cada AC del §5 al test que lo cubre.

| CA | Descripcion | Test | Estado |
|----|-------------|------|--------|
| CA-1 | Crash simbolizado en staging (Android e iOS) | Manual PM-1 — no hay test automatizado posible | GAP (manual requerido) |
| CA-2 | Init defensivo — fallo de Crashlytics no rompe runApp | `crash_handler_setup_test.dart` CA-2 (2 tests) — replica try/catch de PASO 2 main.dart con mock que lanza, verifica que flujo continua | CUBIERTO |
| CA-3 | Gating en debug — handlers NO se registran con isDebug=true | `crash_handler_setup_test.dart` CA-3 (3 tests) — `registerCrashHandlers(isDebug=true)` no modifica handlers, `isDebug=false` delega; `verifyNever` confirma que recordError no se invoca en debug | CUBIERTO |
| CA-4 | Gating en tests — `flutter test` verde, no-op impl, no llama SDK | TC-crash-1..5 con `verifyNever` contra spy MockFirebaseCrashlytics — suite 210/210 verde | CUBIERTO |
| CA-5 | Regla G0 (grep) — 0 coincidencias fuera de archivos legitimos | `grep -r "package:firebase_crashlytics" lib/` con exclusiones = 0 hits; igual para analytics | CUBIERTO |
| CA-6 | Abstracciones puras — sin imports Flutter/Firebase en abstracts | grep en crash_reporter.dart y analytics_service.dart = 0 | CUBIERTO |
| CA-7 | ScanSoatUseCase compila e inyecta AnalyticsService sin cambios | `dart analyze` limpio; tests de soat verdes | CUBIERTO |
| CA-8 | Sin UI / sin regresion — navegacion identica | No hay widgets nuevos en el diff; `flutter test` 210/210 | CUBIERTO |

---

## Matriz de regresion

| Guardrail §6 | Mecanismo de verificacion | Estado |
|--------------|--------------------------|--------|
| Arranque de la app — `main()` no se rompe si Crashlytics falla | CA-2 tests en `crash_handler_setup_test.dart` + try/catch PASO 2 main.dart | CUBIERTO (test) |
| Autenticacion — flujos email/Google/Apple sin cambios | `dart analyze` limpio; no se tocaron archivos de `features/authentication/` | VERIFICADO |
| Navegacion principal — `AppRouter` identico | Ningun archivo de `shared/router/` en el diff | VERIFICADO |
| `ScanSoatUseCase` y use cases con `AnalyticsService` compilan | `dart analyze` No issues found; tests de soat verdes | VERIFICADO |
| Suite de tests existente — `flutter test` verde | 210 tests passed, 0 failed (baseline 191 + 19 nuevos) | VERIFICADO |
| `dart analyze` limpio — 0 errores/warnings nuevos | `dart analyze lib/` → "No issues found" | VERIFICADO |
| `build_runner` reproducible — `injection.config.dart` correcto | `injection.config.dart` regenerado correctamente por frontend | VERIFICADO |

---

## Ejecucion

### Cambios adicionales aplicados por QA (instruccion auditor Opus)

1. **Extraccion de `registerCrashHandlers`:** La logica de registro de handlers fue extraida de `lib/main.dart` a `lib/core/services/crash/crash_handler_setup.dart` (funcion `registerCrashHandlers({required bool isDebug, required CrashReporter reporter})`). `main.dart` llama a esta funcion en PASO 3. Semanticamente identico, pero ahora testeable de forma aislada.

2. **TC-crash-1..5 reforzados con `verifyNever`:** Se anadio un spy `MockFirebaseCrashlytics` en el grupo `NoOpCrashReporter`. Cada test ahora asevera que ninguna llamada al SDK fue realizada — el test falla si `NoOpCrashReporter` deja de ser verdaderamente no-op.

3. **Nuevos tests CA-2 y CA-3** en `test/core/services/crash/crash_handler_setup_test.dart`.

4. **Nuevos tests TC-analytics-1..5** en `test/core/services/analytics/firebase_analytics_service_test.dart`.

### Comandos ejecutados

```bash
# 1. Analisis estatico
dart analyze lib/
# Resultado: No issues found — EXIT 0

# 2. Suite de tests completa
flutter test
# Resultado: 210 tests passed, 0 failed — EXIT 0

# 3. Tests nuevos individuales
flutter test test/core/services/crash/crash_reporter_test.dart
# 9 passed (TC-crash-1..9, con verifyNever en 1..5)

flutter test test/core/services/crash/crash_handler_setup_test.dart
# 5 passed (CA-2: 2 tests, CA-3: 3 tests)

flutter test test/core/services/analytics/firebase_analytics_service_test.dart
# 5 passed (TC-analytics-1..5)

# 4. G0 — crashlytics (0 violaciones fuera de archivos legitimos)
grep -r "package:firebase_crashlytics" lib/ \
  | grep -v "lib/core/services/crash/firebase_crash_reporter.dart" \
  | grep -v "lib/core/di/firebase_module.dart" \
  | grep -v "lib/core/di/injection.config.dart"
# Resultado: 0 lineas — CLEAN

# 5. G0 — analytics (0 violaciones)
grep -r "package:firebase_analytics" lib/ \
  | grep -v "lib/core/services/analytics/firebase_analytics_service.dart" \
  | grep -v "lib/core/di/firebase_module.dart" \
  | grep -v "lib/core/di/injection.config.dart"
# Resultado: 0 lineas — CLEAN

# 6. Abstracciones puras
grep "package:flutter" lib/core/services/crash/crash_reporter.dart   # 0 — CLEAN
grep "package:firebase" lib/core/services/crash/crash_reporter.dart  # 0 — CLEAN
grep "package:flutter" lib/core/services/analytics/analytics_service.dart  # 0 — CLEAN
grep "package:firebase" lib/core/services/analytics/analytics_service.dart # 0 — CLEAN
```

### Conteos

| Metrica | Valor |
|---------|-------|
| Tests baseline (pre-fase) | 191 |
| Tests nuevos (TC-crash-1..9 reforzados) | 9 |
| Tests nuevos (CA-2/CA-3 crash_handler_setup) | 5 |
| Tests nuevos (TC-analytics-1..5) | 5 |
| **Total tests post-QA** | **210** |
| Tests fallidos | 0 |
| Warnings `dart analyze` | 0 |
| Errores `dart analyze` | 0 |
| Violaciones G0 crashlytics | 0 |
| Violaciones G0 analytics | 0 |
| Violaciones abstracciones puras | 0 |

---

## Bugs

No se detectaron bugs ni regresiones. 0 tests fallidos, 0 errores en `dart analyze`.

Lints preexistentes ignorados (per instruccion del proyecto):
- 2 lints en `lib/core/http/api_base_url_resolver.dart` (hack `shouldUseLocalApi=true`) — preexistentes, no tocar.

---

## Pruebas manuales para el humano

| # | Que hacer | Criterio de exito |
|---|-----------|------------------|
| PM-1 | Build release Android con keystore, forzar crash con `FirebaseCrashlytics.instance.crash()`, esperar ~5 min | Crash simbolizado (stack legible) en Firebase Crashlytics console — REQUERIDO para sign-off CA-1 |
| PM-2 | Repetir PM-1 en iOS (build release con firma) | Crash simbolizado en Crashlytics console iOS |
| PM-3 | `flutter run` (debug mode), forzar excepcion no capturada | NO aparece reporte en Firebase console; logs no muestran envio Crashlytics |
| PM-4 | Build release Android, verificar Firebase Console > Crashlytics > App Quality | Existe mapping file para la version del APK (mappingFileUploadEnabled=true) |
| PM-5 | Abrir Xcode > Runner > Build Phases | Run Script phase con `${PODS_ROOT}/FirebaseCrashlytics/run` presente |
| PM-6 | Navegar todos los flujos de autenticacion (email, Google, Apple) en dispositivo fisico | Sin cambio de comportamiento observable |
| PM-7 | Navegar shell completa (home, eventos, vehiculos, perfil, mantenimiento) | Arbol de navegacion identico, sin regresiones |

---

## Sign-off

**Resultado automatizable:** GREEN
- `dart analyze lib/`: 0 issues
- `flutter test`: 210/210 passed, 0 failed
- G0 crashlytics: 0 violaciones
- G0 analytics: 0 violaciones
- Abstracciones puras: verificadas
- CA-2 (init defensivo): cubierto con test unitario
- CA-3 (gating debug): cubierto con test unitario via `registerCrashHandlers`
- TC-crash-1..5: reforzados con `verifyNever` — NoOp verdaderamente no-op
- TC-analytics-1..5: nuevos, cubren 4 metodos nuevos de FirebaseAnalyticsService

**Sign-off global:** GREEN (automatizable)

La unica condicion pendiente es PM-1/PM-2 (verificacion manual de crash simbolizado en consola Crashlytics con build release real), que no es automatizable en `flutter test`. Todos los criterios de aceptacion automatizables estan VERDES. No hay bugs, no hay regresiones.
