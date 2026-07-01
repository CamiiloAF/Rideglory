> Slim handoff — read this before handoffs/architect.md

# Architect → QA

**Fase:** ws-cleanup-on-event-end (Fase 1 de event-tracking-fixes)

---

## Comandos de verificación

```bash
# 1. Análisis estático — cero violaciones nuevas
dart analyze

# 2. Suite de tests completa
flutter test

# 3. Solo los tests de tracking (más rápido durante desarrollo)
flutter test test/features/events/presentation/tracking/
```

---

## Criterios de aceptación (trazabilidad PRD §5)

| # | Criterio | Verificación |
|---|----------|-------------|
| AC1 | `dart analyze` sin nuevas violaciones | Salida limpia o solo warnings pre-existentes |
| AC2 | `flutter test` completo en verde | 0 tests fallando |
| AC3 | Existe `live_tracking_cubit_event_ended_test.dart` con exactamente 4 tests | `grep -c "test(" ...` = 4 |
| AC4 | Caso A: stopUseCase llamado 1 vez, logEvent sessionEnded 1 vez, estado `isTracking:false isFinished:true` | Test A pasa |
| AC5 | Caso B: doble-disparo — stopUseCase 1 vez (no 2), logEvent sessionEnded 1 vez (no 2) | Test B pasa |
| AC6 | Caso C: sin sesión — verifyNever stopUseCase, verifyNever logEvent sessionEnded, isFinished:true | Test C pasa |
| AC7 | Caso D: use case Left — cubit no lanza, isTracking:false isFinished:true, stopUseCase 1 vez | Test D pasa |
| AC8 | Orden de cleanup en código: (1) logSessionEnded, (2) cancel GPS, (3) stopUseCase fold, (4) emit con isClosed guard | Code review |
| AC9 | `live_tracking_cubit_analytics_test.dart` no modificado y sigue en verde | Git diff + flutter test |
| AC10 | `close()` y `_handleAuthSignedOut()` no modificados | Git diff |

---

## Superficie de regresión a verificar

- `test/features/events/presentation/tracking/live_tracking_cubit_analytics_test.dart` — 5 tests de SOS, deben pasar sin cambios
- Todos los tests bajo `test/features/events/` deben continuar en verde
- `pubspec.yaml` no debe tener cambios (sin dependencias nuevas)

---

## Red flags que bloquean merge

- Cualquier test previo roto
- `dart analyze` con nuevas violaciones (distintas a las pre-existentes del codebase)
- Menos o más de 4 tests en el archivo nuevo
- `_handleAuthSignedOut` o `close()` modificados

> Full detail: handoffs/architect.md
