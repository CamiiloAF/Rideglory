# Architect handoff — rtm-push-notifications

**Date:** 2026-06-05T00:02:08Z
**Status:** done
**Scope:** 100% backend (`rideglory-api`). Flutter untouched.

---

## Decisiones

| ID  | Decisión | Razonamiento |
|-----|----------|--------------|
| A1  | Refactorizar `sendSoatReminders` en `sendDocumentExpiryReminders(kind, daysUntilExpiry, notificationType)` | Elimina duplicación; `kind: 'soat' | 'tecnomecanica'` selecciona el RPC y el copy en una tabla declarativa interna. Los 3 crons SOAT solo cambian su cuerpo de llamada; comportamiento observable idéntico. |
| A2  | Añadir interface `TecnomecanicaRecord { id, vehicleId, expiryDate }` al servicio scheduler | Paridad con `SoatRecord`; el RPC `findTecnomecanicasExpiringIn` devuelve `{ id, vehicleId, expiryDate, ... }` (Prisma `Tecnomecanica`). Solo se consumen `id` y `vehicleId`, siguiendo el mismo patrón que SOAT. |
| A3  | Copy RTM en tabla separada dentro del helper genérico (`TECNOMECANICA_30D / TECNOMECANICA_7D / TECNOMECANICA_DAY_OF`) | Mantiene el copy por tipo explícito y legible; no usa interpolación de días para evitar falsos positivos de lint. |
| A4  | `route: 'rideglory://garage'` — confirmado por PO (gate §10 del PRD satisfecho vía instrucción del orchestrador) | Deep-link `rideglory://garage` ya está manejado por `AppRouter.pushDeepLink` en Flutter. |
| A5  | NO implementar `detail-by-id` route — fuera de alcance explícito del PRD | |
| A6  | NO tocar migraciones — `NotificationType` es string-union TypeScript; la columna `type TEXT` en Prisma acepta cualquier string | |
| A7  | El RPC `findTecnomecanicasExpiringIn` ya existe en `vehicles-ms` (PR #3 prerequisito ya integrado) — **bloqueo de Fase 2 NO aplica** | Verificado: `vehicles-ms/src/vehicles/vehicles.controller.ts` línea 127-132 y `tecnomecanica.service.ts` línea 89-105. La fase puede arrancar. |
| A8  | Spec del scheduler: crear nuevo archivo `notification-scheduler.service.spec.ts` — no existe actualmente | Sigue el patrón de los specs existentes (lógica pura extraída, sin mocks de NestJS/Prisma). |
| A9  | `notifications.service.spec.ts` existente se extiende (no se reemplaza); se añaden assertions RTM en el bloque `notification payload` | |

---

## Change map

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `api-gateway/src/scheduler/notification-scheduler.service.ts` | modify | Refactor `sendSoatReminders` → `sendDocumentExpiryReminders(kind, days, type)`; añadir interface `TecnomecanicaRecord`; 3 crons SOAT reapuntados al helper genérico; 3 crons RTM nuevos | med — regresión SOAT si el refactor cambia el payload |
| `api-gateway/src/notifications/notifications.service.ts` | modify | Añadir `TECNOMECANICA_30D | TECNOMECANICA_7D | TECNOMECANICA_DAY_OF` al string-union `NotificationType` | low |
| `notifications-ms/src/notifications/notifications.service.ts` | modify | Mismos 3 valores (paridad obligatoria) | low |
| `api-gateway/src/notifications/notifications.service.spec.ts` | modify | Añadir casos RTM en bloque `notification payload` sin alterar assertions existentes | low |
| `api-gateway/src/scheduler/notification-scheduler.service.spec.ts` | create | Tests crons RTM (fixtures 30/7/0 días) + regresión SOAT; lógica pura sin mocks de NestJS | low |

**Total: 4 modify + 1 create. Flutter: 0 cambios.**

---

## Contratos

### RPC consumido (ya existe en `vehicles-ms`)

```
Pattern : findTecnomecanicasExpiringIn
Payload : { daysUntilExpiry: number }
Response: Array<{ id: string; vehicleId: string; expiryDate: Date | string; ... }>
```

El scheduler solo usa `record.id` y `record.vehicleId`. Paridad exacta con `findSoatsExpiringIn`.

### Flujo por cron RTM (mismo que SOAT, solo cambia RPC y copy)

```
1. RPC findTecnomecanicasExpiringIn({ daysUntilExpiry })  →  TecnomecanicaRecord[]
2. For each record:
   a. RPC getVehicleById({ vehicleId })                  →  VehicleRecord
   b. RPC findOneUser({ id: vehicle.ownerId })           →  UserRecord
   c. notificationsService.createNotification(userId, type, { vehicleId, vehicleName, route })
   d. if user.fcmToken → notificationsService.sendFcm(token, title, body, data)
```

### Nuevos `NotificationType` (ambos paquetes)

```typescript
| 'TECNOMECANICA_30D'
| 'TECNOMECANICA_7D'
| 'TECNOMECANICA_DAY_OF'
```

### Copy RTM por tipo

| Tipo | Título | Cuerpo |
|------|--------|--------|
| `TECNOMECANICA_30D` | `'Tu RTM vence en 30 días'` | `'La revisión técnico-mecánica de tu moto ${name} vence en 30 días. ¡Sácala a tiempo!'` |
| `TECNOMECANICA_7D` | `'Tu RTM vence en 7 días'` | `'La revisión técnico-mecánica de tu moto ${name} vence en 7 días. No esperes más.` |
| `TECNOMECANICA_DAY_OF` | `'Tu RTM vence hoy'` | `'La revisión técnico-mecánica de tu moto ${name} vence hoy. Preséntala cuanto antes.'` |

(Copy definitivo en español, distinto del SOAT, lenguaje de documento vehicular oficial colombiano.)

---

## Datos / migraciones

**Ninguna.** `NotificationType` es string-union TypeScript. La columna `type` en la tabla `Notification` de `notifications-ms` es `TEXT`; acepta cualquier string sin migración de esquema.

---

## Env

**Sin cambios.** No se introducen variables de entorno nuevas.

---

## Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Refactor de `sendSoatReminders` altera el payload SOAT observable (regresión) | Baja | Alto | Tests de regresión SOAT en el nuevo spec; el refactor debe ser mecánico y verificable línea a línea. |
| Paridad `NotificationType` rota entre `api-gateway` y `notifications-ms` | Baja | Alto | El change map incluye ambos archivos; QA verifica literalmente los mismos strings. |
| `findTecnomecanicasExpiringIn` devuelve campo `vehicleId` con nombre distinto al esperado | Muy Baja | Med | Verificado: `tecnomecanica.service.ts` devuelve registros Prisma con campo `vehicleId` (campo FK definido en el schema). |
| `TecnomecanicaRecord.id` nulo en algún escenario edge | Muy Baja | Low | Mismo manejo de errores try/catch por ítem que en SOAT; el log identifica `soat.id` → se replica con `record.id`. |

---

## Orden de implementación

1. **`notifications.service.ts` (api-gateway)** — añadir los 3 tipos RTM al string-union. Es la dependencia TypeScript que habilita el resto.
2. **`notifications.service.ts` (notifications-ms)** — paridad inmediata.
3. **`notification-scheduler.service.ts`** — refactor + 3 crons RTM (usa los tipos ya definidos).
4. **`notification-scheduler.service.spec.ts`** — crear spec con tests RTM + regresión SOAT.
5. **`notifications.service.spec.ts`** — añadir assertions RTM en bloque existente.

---

## Superficie de regresion

- Los 3 crons SOAT (`soatReminder30Days`, `soatReminder7Days`, `soatReminderDayOf`) deben conservar exactamente el mismo comportamiento: RPC `findSoatsExpiringIn`, `route: 'rideglory://garage'`, tipos `SOAT_30D/7D/DAY_OF`.
- El bloque `notification payload` del spec existente no debe tener ninguna assertion modificada o eliminada.
- `npm test` en `api-gateway` y `notifications-ms` deben pasar 100%.
- Flutter: sin cambios; `dart analyze` y `flutter test` no deben romperse (no aplica a este PR).

---

## Fuera de alcance

- Deep-link `detail-by-id` para RTM.
- Creación del RPC `findTecnomecanicasExpiringIn` (ya existe).
- Migraciones de base de datos.
- Cambios en Flutter (`lib/`).
- Nuevas dependencias npm.
- Copy multiidioma (solo español, Colombia).
