# SUMMARY — rtm-push-notifications

**Tech Lead review:** 2026-06-05T00:24:38Z
**Veredicto:** LISTO PARA COMMIT

---

## Objetivo

Generalizar el helper de recordatorios SOAT a un helper de documentos genérico (`sendDocumentExpiryReminders`) y añadir 3 crons RTM nuevos (30d/7d/día-de) con sus `NotificationType` en `api-gateway` y `notifications-ms`. Regresión SOAT cero. Backend exclusivo según PRD. Los cambios Flutter en el working tree pertenecen al corte `tecnomecanica-rtm` del branch y son correctos.

---

## Que cambio por area

### Backend (en scope)

| Archivo | Cambio |
|---------|--------|
| `api-gateway/src/scheduler/notification-scheduler.service.ts` | `sendSoatReminders` → `sendDocumentExpiryReminders(kind,days,type)`; TecnomecanicaRecord interface; 3 crons SOAT reapuntados; 3 crons RTM nuevos (0 9 * * *, America/Bogota); mapa copy por kind+umbral |
| `api-gateway/src/notifications/notifications.service.ts` | +TECNOMECANICA_30D, TECNOMECANICA_7D, TECNOMECANICA_DAY_OF |
| `notifications-ms/src/notifications/notifications.service.ts` | Mismos 3 valores (paridad) |
| `api-gateway/src/notifications/notifications.service.spec.ts` | Reescritura: instancia real, 15 tests SOAT+RTM+registration |
| `api-gateway/src/scheduler/notification-scheduler.service.spec.ts` | Nuevo: 34 tests RTM+SOAT regression+empty-list guard |

### Flutter (fuera de scope PRD, en scope del branch, sin blockers)

- `tecnomecanica_manual_capture_page.dart`: modo creacion sin vehicleId retorna modelo pendiente
- `vehicle_form_state.dart`+`cubit.dart`: PendingRtm + storePendingRtm/clearPendingRtm
- `vehicle_form_docs_section.dart`: isEditing -> VehicleRtmFormSlot; creacion -> upload slot con captura
- `vehicle_rtm_form_slot.dart`: nuevo widget con estado live via GetTecnomecanicaUseCase
- `vehicle_form_view.dart`: _savePendingRtmAndPop — upload imagen + SaveTecnomecanicaUseCase post-creacion
- `vehicle_document_card.dart`: "Venció hace N días" cuando documento vencido
- l10n: pluralizacion soat_expired_days_ago y tecnomecanica_expired_days_ago

---

## Archivos

Backend (rideglory-api):
- api-gateway/src/scheduler/notification-scheduler.service.ts
- api-gateway/src/scheduler/notification-scheduler.service.spec.ts (nuevo)
- api-gateway/src/notifications/notifications.service.ts
- api-gateway/src/notifications/notifications.service.spec.ts
- notifications-ms/src/notifications/notifications.service.ts

Flutter (Rideglory/lib/):
- features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart
- features/vehicles/presentation/cubit/vehicle_form_cubit.dart
- features/vehicles/presentation/cubit/vehicle_form_state.dart
- features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart
- features/vehicles/presentation/form/widgets/vehicle_form_view.dart
- features/vehicles/presentation/form/widgets/vehicle_rtm_form_slot.dart (nuevo)
- features/vehicles/presentation/garage/widgets/vehicle_document_card.dart
- l10n/app_es.arb + app_localizations.dart + app_localizations_es.dart

---

## Pruebas

- npm test api-gateway: 71/71 verde (baseline 33)
- tsc --noEmit api-gateway: limpio
- dart analyze lib/: No issues found
- Sabotaje confirmado: RPC BROKEN -> 4 tests rojo

---

## Riesgos / watchlist

| Item | Severidad | Detalle |
|------|-----------|---------|
| _savePendingRtmAndPop sin loading UI | Low | Imagen falla silently; watchlist siguiente iteracion |
| getIt<TecnomecanicaCubit>() en widget | Aceptable | Factory transiente, paridad con flujo SOAT |
| notifications-ms sin spec files | Pre-existente | npm test falla "No tests found"; pre-existente |
| Mapa messages reconstruido por llamada | Cosmético | Cron diario, sin impacto de performance |

---

## Mensaje de commit sugerido

Backend (rideglory-api):

  feat(scheduler): add RTM push reminders; generalize SOAT helper to document expiry helper

  - Refactor sendSoatReminders -> sendDocumentExpiryReminders(kind, days, type)
  - Add TecnomecanicaRecord; SOAT crons repointed (zero regression)
  - Add 3 RTM crons: tecnomecanicaReminder30Days/7Days/DayOf (0 9 * * *, America/Bogota)
  - Add TECNOMECANICA_30D|7D|DAY_OF NotificationType in api-gateway + notifications-ms
  - RTM copy in Spanish, distinct from SOAT, route rideglory://garage
  - New scheduler spec: 34 tests (RTM + SOAT regression)
  - Extend notifications spec to 15 tests (3 RTM types)
  - 71/71 tests green; tsc clean

Flutter (Rideglory):

  feat(tecnomecanica): RTM slot in vehicle form — pending creation + live edit status

  - PendingRtm state + storePendingRtm/clearPendingRtm in VehicleFormCubit
  - Creation mode: capture RTM -> store pending -> save after vehicle created
  - Edit mode: VehicleRtmFormSlot loads live RTM status from API
  - TecnomecanicaManualCapturePage: creation mode returns pending model (no vehicleId)
  - VehicleDocumentCard: show "Venció hace N días" when expired (plural fix)
  - l10n: pluralize soat_expired_days_ago and tecnomecanica_expired_days_ago
