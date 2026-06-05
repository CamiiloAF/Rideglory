# PRD Normalizado — RTM Push Notifications & Notification Center

> **Slug:** `rtm-push-notifications`
> **Fuente:** `docs/plans/tecnomecanica-rtm/phases/phase-05-recordatorios-push-y-centro-de-notificaciones-pa.md`
> **Generado:** 2026-06-05T00:00:07Z
> **Nivel rg-exec:** normal (normalizer pass)
> **Repo afectado:** `rideglory-api` (NestJS backend exclusivo)

---

## 1 Objetivo

El conductor recibe avisos push automáticos a **30, 7 y 0 días** del vencimiento de su Revisión Técnico-Mecánica (RTM). Cada aviso aparece también en el centro de notificaciones de la app y, al tocarlo, lleva al usuario al **garage** (`rideglory://garage`, paridad con SOAT). El trabajo es 100% backend en `rideglory-api`: generalizar el helper de recordatorios SOAT a un helper de documentos genérico, añadir 3 crons RTM, 3 nuevos `NotificationType` y tests correspondientes — **sin romper los 3 crons SOAT vivos en producción (regresión cero absoluta)**.

---

## 2 Por que

Los usuarios con Revisión Técnico-Mecánica próxima a vencer no reciben ningún aviso proactivo hoy. La funcionalidad SOAT ya probó el flujo completo (crons + RPC + FCM + centro de notificaciones); replicarlo para RTM es el cierre natural del corte `tecnomecanica-rtm` (PR #3) y evita que el conductor circule con RTM vencida por olvido.

---

## 3 Alcance

### Entra
- **Refactor del scheduler:** `sendSoatReminders(daysUntilExpiry, type)` → helper genérico `sendDocumentExpiryReminders(kind, daysUntilExpiry, notificationType)` donde `kind` selecciona el RPC (`findSoatsExpiringIn` vs `findTecnomecanicasExpiringIn`) y el bloque de copy FCM/notificación.
- **3 crons SOAT mantenidos vivos** reapuntados al helper genérico (regresión cero; mismo comportamiento observable que hoy).
- **3 crons RTM nuevos** (`tecnomecanicaReminder30Days`, `7Days`, `DayOf`) con expresión `0 9 * * *` y `timeZone: 'America/Bogota'`.
- **3 nuevos `NotificationType`** (`TECNOMECANICA_30D | TECNOMECANICA_7D | TECNOMECANICA_DAY_OF`) añadidos en **ambos** paquetes: `api-gateway/src/notifications/notifications.service.ts` y `notifications-ms/src/notifications/notifications.service.ts`.
- **Copy RTM propio por notificación** (título/cuerpo distintos del SOAT), parametrizado por `kind` y umbral de días.
- `route: 'rideglory://garage'` en el payload de cada notificación RTM (paridad SOAT).
- **Tests:** crons RTM con fixtures a 30/7/0 días; `notifications.service.spec.ts` actualizado para cubrir los 3 tipos RTM; regresión SOAT verde sin tocar su acceptance.

### No entra
- Pantalla nueva de routing / deep-link `detail-by-id` (fuera de alcance, decisión R7/A5).
- Cambios en el modelo de datos de `notifications-ms` (solo string-union TypeScript, sin columnas enum).
- El RPC `findTecnomecanicasExpiringIn` en `vehicles-ms` ni la tabla/migración `Tecnomecanica` (pertenecen a Fase 2, prerequisito de esta fase).
- Cambios en el deep-linking del cliente Flutter (`AppRouter.pushDeepLink` ya funciona).
- Nuevas dependencias, cambios de plataforma, OCR o WebSocket.

---

## 4 Areas afectadas

### Backend (`rideglory-api`)
| Archivo | Cambio |
|---------|--------|
| `api-gateway/src/scheduler/notification-scheduler.service.ts` | Refactor `sendSoatReminders` → `sendDocumentExpiryReminders(kind, days, type)`; 3 crons SOAT reapuntados; 3 crons RTM nuevos; mapa de copy por `kind` y umbral. |
| `api-gateway/src/notifications/notifications.service.ts` | Añadir `TECNOMECANICA_30D \| TECNOMECANICA_7D \| TECNOMECANICA_DAY_OF` al string-union `NotificationType`. |
| `notifications-ms/src/notifications/notifications.service.ts` | Añadir los mismos 3 valores (paridad obligatoria con api-gateway). |
| `api-gateway/src/notifications/notifications.service.spec.ts` | Cubrir payload de los 3 tipos RTM (`vehicleId`, `vehicleName`, `route`, `type`). |
| `api-gateway/src/scheduler/notification-scheduler.service.spec.ts` (crear si no existe) | Tests crons RTM con fixtures a 30/7/0 días + regresión SOAT. |

### Flutter (`lib/`)
- **Sin cambios.** El deep-link `rideglory://garage` ya es manejado por `AppRouter.pushDeepLink`.

### Base de datos / migraciones
- **Ninguna.** `NotificationType` es un string-union TypeScript; no hay columnas enum afectadas.

---

## 5 Criterios de aceptacion

1. Los **3 `NotificationType` RTM** (`TECNOMECANICA_30D`, `TECNOMECANICA_7D`, `TECNOMECANICA_DAY_OF`) están presentes en **AMBOS** archivos (`api-gateway` y `notifications-ms`) y son idénticos entre sí.
2. Existe un único helper `sendDocumentExpiryReminders(kind, daysUntilExpiry, notificationType)`; `sendSoatReminders` ya no existe como helper duplicado (su lógica vive en el genérico).
3. Los **3 crons SOAT siguen vivos** y, ejecutados, disparan el RPC `findSoatsExpiringIn` con el `daysUntilExpiry` correcto (30/7/0) y producen el **mismo payload observable que hoy** (`route: 'rideglory://garage'`, `type` SOAT correcto). **Regresión cero backend.**
4. Existen **3 crons RTM** con expresión `0 9 * * *` y `timeZone: 'America/Bogota'` que disparan `findTecnomecanicasExpiringIn` con `daysUntilExpiry` 30, 7 y 0 respectivamente.
5. Cada notificación RTM lleva `route: 'rideglory://garage'` y el `type` RTM correcto en el payload.
6. El **copy RTM es propio** (título/cuerpo distintos del literal SOAT) y varía por umbral (30/7/0 días).
7. `notifications.service.spec.ts` cubre el payload de los **3 tipos RTM** (incluye `vehicleId`, `vehicleName`, `route`, `type`) sin alterar las assertions SOAT existentes.
8. Hay **tests de los crons RTM con fixtures a 30/7/0 días** que verifican el RPC invocado y el `type`/copy emitido; el caso borde "lista vacía" no emite ninguna notificación.
9. La suite backend (`npm test` en `api-gateway` y `notifications-ms`) pasa al **100% sin modificar la acceptance de los tests SOAT existentes**. Si un test SOAT requiere cambiar su assertion, se clasifica como regresión, no como refactor.
10. El **gate de bloqueo previo** está satisfecho: confirmación de una línea del PO humano de que `rideglory://garage` es el destino aceptado para las notificaciones RTM (registrada antes de iniciar cualquier cambio de código).

---

## 6 Guardrails de regresion

- **Regresión cero en crons SOAT:** los 3 crons SOAT (`soatReminder30Days`, `soatReminder7Days`, `soatReminderDayOf`) deben seguir disparando `findSoatsExpiringIn` con los mismos `daysUntilExpiry`, el mismo `route` y el mismo `type` que antes del refactor. Cualquier diferencia observable en el payload es regresión, no mejora.
- **Paridad obligatoria `NotificationType`:** los mismos valores deben estar presentes en `api-gateway` y `notifications-ms`. Una diferencia entre paquetes es un bug latente que se clasifica como bloqueante.
- **Sin cambios en Flutter:** esta fase no toca `lib/`. Si un agente propone cambios en código Flutter, es fuera de alcance y debe rechazarse.
- **Sin migraciones de base de datos:** `NotificationType` es string-union TypeScript. Cualquier cambio de esquema de DB es fuera de alcance.
- **Gate humano antes de código:** el PO humano debe confirmar `rideglory://garage` explícitamente. Sin esa confirmación, no se modifica ningún archivo.
- **Bloqueo por Fase 2:** si el RPC `findTecnomecanicasExpiringIn` no existe en `vehicles-ms`, la fase queda bloqueada; no se crea el RPC en esta fase.

---

## 7 Constraints heredados

- **No commitear:** `rg-exec` deja el working tree sucio para revisión humana; el humano commitea tras aprobar.
- **Copy en español / legal:** los textos de notificación RTM deben ser en español, apropiados para un recordatorio de documento vehicular oficial colombiano, y distintos del copy SOAT.
- **Timezone Colombia:** todos los crons deben usar `timeZone: 'America/Bogota'` (no UTC).
- **Flujo de notificación invariable:** el flujo `getVehicleById` → `findOneUser` → `createNotification` + `sendFcm` se reutiliza sin cambios estructurales; solo el RPC de consulta de vencimientos varía por `kind`.
- **Prerequisito Fase 2 duro:** esta fase solo consume el RPC `findTecnomecanicasExpiringIn`; no lo crea. Si no está disponible, la fase no arranca.
- **Nivel rg-exec: full (fuente):** la fuente recomienda nivel `full` por la combinación contrato cross-cutting + reversibilidad complicada en producción. Esta corrida se ejecuta en nivel `normal` por instrucción del orchestrador.
