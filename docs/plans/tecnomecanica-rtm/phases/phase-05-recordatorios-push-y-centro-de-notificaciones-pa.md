# Fase 5 — Recordatorios push y centro de notificaciones para RTM

> **Plan:** `tecnomecanica-rtm` · **Fase:** 5 · **Repo principal de esta fase:** `rideglory-api` (NestJS) · **Depende de:** 1, 2 · **Nivel rg-exec:** full
> **Generado:** 2026-06-04T13:18:04Z · **Rol:** Tech Lead / PO
> **Insumos:** `05-sintesis.md`, `01-scan.md`, `03-architect-review.md` + verificación directa de `rideglory-api`.

---

## Objetivo

El conductor recibe avisos push automáticos a **30, 7 y 0 días** del vencimiento de su Revisión Técnico-Mecánica (RTM). Cada aviso aparece también en el centro de notificaciones de la app y, al tocarlo, lo lleva a su **garage** (`rideglory://garage`, paridad exacta con SOAT). El trabajo es backend en `rideglory-api`: se generaliza el helper de recordatorios SOAT a un helper de documentos, se añaden 3 crons RTM, 3 nuevos `NotificationType` y los tests correspondientes — **sin romper los 3 crons SOAT vivos en producción (regresión cero)**.

---

## Alcance (entra / no entra)

### Entra
- **Refactor del scheduler:** `sendSoatReminders(daysUntilExpiry, type)` → helper genérico `sendDocumentExpiryReminders(kind, daysUntilExpiry, notificationType)` donde `kind` selecciona el RPC (`findSoatsExpiringIn` vs `findTecnomecanicasExpiringIn`) y el bloque de copy FCM/notificación.
- **3 crons SOAT mantenidos vivos** apuntando al helper genérico (regresión cero backend; mismo comportamiento observable que hoy).
- **3 crons RTM nuevos** (`tecnomecanicaReminder30Days / 7Days / DayOf`, `0 9 * * *`, `America/Bogota`).
- **3 nuevos `NotificationType`** (`TECNOMECANICA_30D | TECNOMECANICA_7D | TECNOMECANICA_DAY_OF`) añadidos en **AMBOS** archivos (`api-gateway` + `notifications-ms`) — checklist obligatorio.
- **Copy RTM propio por notificación** (título/cuerpo distintos del SOAT), parametrizado por `kind`.
- `route: 'rideglory://garage'` en el payload de cada notificación RTM (paridad SOAT).
- **Tests:** crons RTM con fixtures a 30/7/0 días; `notifications.service.spec.ts` actualizado para cubrir los 3 tipos RTM; regresión SOAT verde sin tocar su acceptance.
- Cierra el corte RTM (PR #3) de punta a punta.

### No entra
- **Pantalla nueva de routing / deep-link `detail-by-id`** (abrir el detalle de la moto por `vehicleId`): **explícitamente fuera de alcance** (decisión R7/A5). Se usa `rideglory://garage`, igual que SOAT.
- **Cambios en el modelo de datos de `notifications-ms`** (solo se añaden valores al string-union `NotificationType`).
- **El RPC `findTecnomecanicasExpiringIn` en `vehicles-ms`** y la tabla/migración `Tecnomecanica`: son de la **Fase 2** (prerequisito). Esta fase solo lo **consume**.
- **Cualquier cambio en el deep-linking del cliente Flutter** (`AppRouter.pushDeepLink` ya funciona; las notifs RTM solo proveen un `route` válido).
- **Nuevas dependencias, cambios de plataforma, OCR, WebSocket.**

---

## Que se debe hacer (pasos concretos y ordenados)

> **Bloqueo previo (gate humano):** la fase NO arranca hasta obtener confirmación de una línea del PO humano de que `rideglory://garage` es aceptable como destino de las notificaciones RTM (paridad SOAT). Si el PO humano pide `detail-by-id`, se reabre alcance y el trabajo de routing se contabiliza como ítem nuevo. Mientras no haya respuesta, no se toca código.

1. **Verificar prerequisito de Fase 2:** confirmar que `vehicles-ms` expone el RPC `findTecnomecanicasExpiringIn` (`@MessagePattern`) y que `TecnomecanicaService` tiene el método espejo de `findSoatsExpiringIn`. Si no existe, la Fase 5 está bloqueada por la Fase 2.
2. **Añadir los 3 `NotificationType` RTM en `notifications-ms`:** extender el string-union en `notifications-ms/src/notifications/notifications.service.ts` con `'TECNOMECANICA_30D' | 'TECNOMECANICA_7D' | 'TECNOMECANICA_DAY_OF'`.
3. **Añadir los mismos 3 `NotificationType` en `api-gateway`:** extender el string-union en `api-gateway/src/notifications/notifications.service.ts`. **Checklist:** ambos archivos deben quedar idénticos en estos valores (riesgo de desincronización R5).
4. **Refactorizar el helper del scheduler** en `api-gateway/src/scheduler/notification-scheduler.service.ts`:
   - Renombrar/generalizar `sendSoatReminders(daysUntilExpiry, type)` → `sendDocumentExpiryReminders(kind, daysUntilExpiry, notificationType)`.
   - `kind` (p.ej. `'soat' | 'tecnomecanica'`) selecciona el RPC a emitir: `findSoatsExpiringIn` o `findTecnomecanicasExpiringIn`.
   - Mover el `Record` de copy FCM hardcodeado (hoy líneas ~286-298, por `type`) a un mapa de copy **por `kind` y por umbral de días**, de modo que SOAT y RTM tengan textos propios. RTM con copy legal/recordatorio propio (no reutilizar el literal SOAT).
   - Mantener `route: 'rideglory://garage'` en el payload para ambos kinds.
   - El resto del flujo (`getVehicleById` → `findOneUser` → `createNotification` + `sendFcm`) se reutiliza sin cambios de forma.
5. **Reapuntar los 3 crons SOAT** (`soatReminder30Days/7Days/DayOf`, líneas ~64-78) para que llamen a `sendDocumentExpiryReminders('soat', 30, 'SOAT_30D')`, etc. **Comportamiento observable idéntico** al actual.
6. **Añadir los 3 crons RTM** (`tecnomecanicaReminder30Days/7Days/DayOf`), cada uno `@Cron('0 9 * * *', { timeZone: 'America/Bogota' })`, llamando a `sendDocumentExpiryReminders('tecnomecanica', 30|7|0, 'TECNOMECANICA_30D|7D|DAY_OF')`.
7. **Actualizar/añadir tests** (ver sección Pruebas): crons RTM con fixtures a 30/7/0 días; `notifications.service.spec.ts` con los 3 tipos RTM en el payload; verificar regresión cero SOAT.
8. **Correr la suite backend** (`npm test` en `api-gateway`, y en `notifications-ms` si toca) y dejar verde sin tocar la acceptance de los tests SOAT existentes.
9. **No commitear** (rg-exec deja el working tree sucio para revisión humana).

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

Todas las rutas son relativas a `/Users/cami/Developer/Personal/rideglory-api`.

| Ruta | Qué cambia |
|------|-----------|
| `api-gateway/src/scheduler/notification-scheduler.service.ts` | Refactor: `sendSoatReminders` → `sendDocumentExpiryReminders(kind, days, type)`; 3 crons SOAT reapuntados (regresión cero); 3 crons RTM nuevos; copy por `kind`. |
| `api-gateway/src/notifications/notifications.service.ts` | Añadir `TECNOMECANICA_30D | _7D | _DAY_OF` al string-union `NotificationType`. |
| `notifications-ms/src/notifications/notifications.service.ts` | Añadir los mismos 3 valores al string-union `NotificationType` (paridad obligatoria con gateway). |
| `api-gateway/src/notifications/notifications.service.spec.ts` | Actualizar: cubrir payload de los 3 tipos RTM (`vehicleId`, `vehicleName`, `route`, `type`). |
| `api-gateway/src/scheduler/notification-scheduler.service.spec.ts` (crear si no existe) | Tests de los crons RTM con fixtures a 30/7/0 días + verificación de que los crons SOAT siguen disparando el RPC correcto. |

> Si el RPC `findTecnomecanicasExpiringIn` no estuviera presente en `vehicles-ms` (debería venir de Fase 2), la fase queda bloqueada — no se crea aquí.

---

## Contratos / API rideglory-api

**No se añaden rutas REST públicas nuevas en esta fase.** El contrato afectado es interno:

- **RPC consumido (provisto por Fase 2):** `findTecnomecanicasExpiringIn` con payload `{ daysUntilExpiry: number }`, espejo de `findSoatsExpiringIn` (ventana UTC día-exacto). Esta fase solo lo invoca.
- **`NotificationType` (string-union, contrato duplicado en 2 paquetes):** se extiende con `'TECNOMECANICA_30D' | 'TECNOMECANICA_7D' | 'TECNOMECANICA_DAY_OF'` en:
  - `api-gateway/src/notifications/notifications.service.ts`
  - `notifications-ms/src/notifications/notifications.service.ts`
  Ambos deben quedar sincronizados (desincronización = bug latente).
- **Payload de notificación RTM:** `{ type: 'TECNOMECANICA_30D|7D|DAY_OF', vehicleId, vehicleName, route: 'rideglory://garage' }` — misma forma que el payload SOAT, con `type`/copy propios.

---

## Cambios de datos / migraciones

**Ninguno.** `notifications-ms` no cambia su modelo de datos: `NotificationType` es un string-union en TypeScript, no una columna enum de base de datos. La tabla/migración `Tecnomecanica` pertenece a la **Fase 2** y no se toca aquí.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. Los **3 `NotificationType` RTM** (`TECNOMECANICA_30D`, `TECNOMECANICA_7D`, `TECNOMECANICA_DAY_OF`) están presentes en **AMBOS** archivos (`api-gateway` y `notifications-ms`) y son idénticos entre sí.
2. Existe un único helper `sendDocumentExpiryReminders(kind, daysUntilExpiry, notificationType)`; `sendSoatReminders` ya no existe como helper duplicado (su lógica vive en el genérico).
3. Los **3 crons SOAT siguen vivos** y, ejecutados, disparan el RPC `findSoatsExpiringIn` con el `daysUntilExpiry` correcto (30/7/0) y producen el **mismo payload observable que hoy** (`route: 'rideglory://garage'`, `type` SOAT correcto). **Regresión cero backend.**
4. Existen **3 crons RTM** con expresión `0 9 * * *` y `timeZone: 'America/Bogota'` que disparan `findTecnomecanicasExpiringIn` con `daysUntilExpiry` 30/7/0 respectivamente.
5. Cada notificación RTM lleva `route: 'rideglory://garage'` y un `type` RTM correcto en el payload.
6. El **copy RTM es propio** (título/cuerpo distintos del literal SOAT) y varía por umbral (30/7/0 días).
7. `notifications.service.spec.ts` cubre el payload de los **3 tipos RTM** (incluye `vehicleId`, `vehicleName`, `route`, `type`).
8. Hay **tests de crons RTM con fixtures a 30/7/0 días** que verifican el RPC invocado y el `type`/copy emitido.
9. La suite backend pasa al 100% **sin modificar la acceptance de los tests SOAT existentes** (si un test SOAT requiere cambiar su assertion para pasar, es regresión, no refactor).
10. Confirmación de una línea del PO humano sobre `rideglory://garage` registrada antes de iniciar (gate de bloqueo previo).

---

## Pruebas (unitarias/widget/integracion)

Esta fase es 100% backend NestJS; no hay tests Flutter/widget.

- **`api-gateway/src/scheduler/notification-scheduler.service.spec.ts`** (crear si no existe):
  - Fixtures de vehículos con RTM venciendo a **30, 7 y 0 días**.
  - Mock del cliente RPC: el cron RTM 30d invoca `findTecnomecanicasExpiringIn` con `{ daysUntilExpiry: 30 }`; análogo para 7 y 0.
  - Verificar que para cada vehículo se llama `createNotification` + `sendFcm` con `type` RTM correcto, `route: 'rideglory://garage'` y el copy propio del umbral.
  - **Regresión SOAT:** los crons SOAT siguen invocando `findSoatsExpiringIn` con `30/7/0` y el `type`/route SOAT esperados.
  - Caso borde: lista vacía de vencimientos → no se emite ninguna notificación.
- **`api-gateway/src/notifications/notifications.service.spec.ts`** (actualizar):
  - Extender el bloque "notification payload" para los 3 tipos RTM: payload contiene `vehicleId`, `vehicleName`, `route`, `type`.
  - No alterar las assertions existentes del payload SOAT (regresión cero).
- **Comando:** `npm test` en `api-gateway` (y `notifications-ms` si el tipo se testea allí) en verde.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R5 | `NotificationType` duplicado en 2 paquetes → desincronización (un valor en gateway pero no en ms, o viceversa). | Media | Paso explícito que toca ambos archivos (pasos 2-3); criterio de aceptación #1 exige paridad; test que cubre los 3 tipos RTM. |
| RA | El refactor de `sendSoatReminders` rompe el comportamiento de los crons SOAT en producción (difícil de revertir si un cron falla en prod). | Alta | Regresión cero como criterio duro (#3, #9); tests de los 3 crons SOAT verificando RPC + payload idénticos; el refactor preserva la forma del flujo (`getVehicleById`→`findOneUser`→`createNotification`+`sendFcm`). |
| RB | El RPC `findTecnomecanicasExpiringIn` no existe aún (Fase 2 incompleta). | Media | Paso 1 verifica el prerequisito antes de codificar; si falta, la fase está bloqueada por Fase 2 (no se crea el RPC aquí). |
| RC | Copy RTM reutiliza el literal SOAT por descuido al genericar el `Record` de mensajes. | Baja | Criterio #6 exige copy propio por `kind` y umbral; revisión del mapa de copy en review. |
| R7 | Destino del deep-link (`garage` vs `detail-by-id`). | **Resuelto** | Decidido `rideglory://garage` (paridad SOAT); `detail-by-id` fuera de alcance. Gate de bloqueo previo = confirmación de una línea del PO humano. |
| RD | Las 6 expresiones cron `0 9 * * *` corriendo en el mismo minuto podrían solaparse. | Baja | Es el patrón actual de SOAT (3 crons ya coexisten a la misma hora); RTM lo replica sin cambio de diseño. No introduce regresión nueva. |

---

## Dependencias (fases prerequisito y por que)

- **Fase 1** — establece la abstracción `vehicle_documents/` y el corte conceptual SOAT↔documento genérico que justifica el helper `sendDocumentExpiryReminders` parametrizado por `kind`. (Dependencia conceptual/de plan; el código de esta fase vive en backend.)
- **Fase 2** — **dependencia dura.** Provee en `vehicles-ms` la tabla/migración `Tecnomecanica`, el `TecnomecanicaService` y el RPC `findTecnomecanicasExpiringIn` que estos crons consumen. Sin él, los crons RTM no tienen de dónde leer vencimientos y la fase está bloqueada.

---

## Ejecucion recomendada (nivel rg-exec: full)

**Por qué full:** Backend de producción. El refactor del scheduler exige **regresión cero en 3 crons SOAT vivos** (cualquier error rompe avisos reales a usuarios y es difícil de revertir si un cron falla en prod). Se duplican 3 `NotificationType` en **2 paquetes** con riesgo de desincronización, y se añaden 3 crons cron-scheduled. Es cross-cutting en el subsistema de notificaciones con reversibilidad complicada en producción. La rúbrica lo clasifica como **full** por la combinación contrato + cross-cutting + reversibilidad: justifica auditor Opus iterativo, QA adversarial sobre la regresión SOAT y fix-loops hasta verde.
