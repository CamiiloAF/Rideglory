# Auditoría Backend — rtm-push-notifications

**Auditor:** Opus (rg-exec)
**Fecha:** 2026-06-05T00:10:26Z
**Veredicto:** RECHAZADO (approved=false) — score 62/100

---

## Resumen

La **implementación de producción es correcta y de alta calidad** (cumple AC 1–6, regresión SOAT cero, sin secretos, sin migraciones, sin tocar Flutter, RPC prerequisito presente). El **bloqueante es la calidad de las pruebas nuevas**: son tautológicas — no ejercitan el código bajo prueba, por lo que **no fallarían si el cambio se rompe**. Esto viola el criterio duro del auditor ("pruebas que fallarían sin el cambio") y deja los guardrails AC 7 y AC 8 sin cobertura real.

---

## Lo que está bien (verificado)

- **AC 1 (paridad NotificationType):** los 3 valores RTM presentes e idénticos en `api-gateway/src/notifications/notifications.service.ts` y `notifications-ms/src/notifications/notifications.service.ts`, en la misma posición (tras `SOAT_DAY_OF`). ✓
- **AC 2 (helper único):** `sendSoatReminders` eliminado; existe `sendDocumentExpiryReminders(kind, daysUntilExpiry, type)`. ✓
- **AC 3 (regresión SOAT):** crons SOAT reapuntados; `findSoatsExpiringIn` con 30/7/0; payload `route: 'rideglory://garage'` y `type` SOAT idénticos. Diff del spec SOAT es puramente aditivo (ninguna assertion SOAT removida). ✓
- **AC 4 (crons RTM):** 3 métodos con `@Cron('0 9 * * *', { timeZone: 'America/Bogota' })` → `findTecnomecanicasExpiringIn` con 30/7/0. ✓
- **AC 5 (payload RTM):** `route: 'rideglory://garage'` + `type` RTM en createNotification y sendFcm data. ✓
- **AC 6 (copy propio):** títulos/cuerpos RTM distintos del SOAT, varían por umbral. ✓
- **Prerequisito Fase 2:** `findTecnomecanicasExpiringIn` existe en `vehicles-ms/src/vehicles/vehicles.controller.ts:127`. ✓
- **Compila:** `npx tsc --noEmit` → exit 0.
- **Suite verde:** `npx jest` → 4 suites, 55/55.
- **Sin secretos / URLs http hardcodeadas / SQL concatenado / PII.** Único literal de ruta es el deep-link de contrato `rideglory://garage`.
- **Change map respetado:** solo los 4 archivos del map en api-gateway + el union de paridad en notifications-ms. Flutter sin tocar.

## Mejora de diseño (no bloqueante, positiva)

El campo `body` del mapa `messages` pasó de string a `(vehicleName: string) => string`, izándose fuera del loop. Es una mejora limpia y compatible.

---

## BLOQUEANTE — Pruebas tautológicas (AC 7, AC 8 sin cobertura real)

El archivo nuevo `src/scheduler/notification-scheduler.service.spec.ts` **no prueba `NotificationSchedulerService`**. En lugar de invocar el servicio:

1. **Re-declara una copia local** del mapa `messages` (líneas 69–94) y de `getRpcPattern` (98–99), y hace assertions contra esas copias locales — no contra el servicio.
2. El "empty-list guard" itera un array local vacío (`const records: unknown[] = []`), nunca llama a `sendDocumentExpiryReminders`.
3. El único test que toca la clase real (`cron method names exist`) solo verifica `typeof === 'function'`; pasaría aun con los cuerpos vacíos.
4. El helper `makeClientProxy` y el mock de rxjs descritos en los comentarios **nunca se usan** (código muerto: `makeVehicleRecord`, `makeUserRecord`, `makeClientProxy`, `makeNotificationsService` solo se usan en los guards triviales).

Los 3 tests añadidos a `notifications.service.spec.ts` tienen el mismo defecto: construyen un objeto `payload` literal inline y se hacen assert a sí mismos; nunca llaman al servicio.

**Prueba empírica (sabotaje):** rompí el copy real `'Tu RTM vence en 30 días'` → `'SABOTAGED'` Y renombré el RPC real `findTecnomecanicasExpiringIn` → `findBROKEN` en el servicio. La spec del scheduler **siguió pasando 21/21**. Una prueba válida debe ponerse en rojo ante ese sabotaje. (Cambios revertidos; árbol restaurado; suite de nuevo 55/55.)

Conclusión: AC 7 ("`notifications.service.spec.ts` cubre el payload de los 3 tipos RTM") y AC 8 ("tests de los crons RTM con fixtures a 30/7/0 que verifican el RPC invocado y el type/copy emitido; lista vacía no emite") **no están realmente satisfechos** — la cobertura es aparente, no efectiva.

---

## Cambios requeridos

1. **`src/scheduler/notification-scheduler.service.spec.ts`** — reescribir como test real del servicio:
   - Instanciar `NotificationSchedulerService` con `vehiclesService` (ClientProxy), `notificationsService` y `logger` mockeados. Mockear `firstValueFrom`/rxjs o `clientProxy.send().pipe()` para devolver fixtures resolubles por `firstValueFrom`.
   - Para 30/7/0: invocar `tecnomecanicaReminder30Days/7Days/DayOf()` y `expect(clientProxy.send).toHaveBeenCalledWith('findTecnomecanicasExpiringIn', { daysUntilExpiry: N })`.
   - Assert que `notificationsService.createNotification` y `sendFcm` se llaman con el `type` RTM correcto, `route: 'rideglory://garage'`, y el `title`/`body` reales producidos por el servicio (no por una copia local del mapa). Eliminar las constantes locales `messages` y `getRpcPattern`.
   - Empty-list: mockear el RPC para devolver `[]` e invocar el cron real; `expect(createNotification).not.toHaveBeenCalled()` y `sendFcm` idem.
   - Regresión SOAT: invocar `soatReminder30Days/7Days/DayOf()` y assert `findSoatsExpiringIn` + payload/type SOAT desde el servicio real.

2. **`src/notifications/notifications.service.spec.ts`** — los 3 tests RTM deben ejercitar el flujo real (p. ej. `createNotification` persistiendo `type` y `payload`), no objetos literales auto-afirmados. Como mínimo, derivar el payload del código bajo prueba, no de un literal inline.

3. Tras reescribir, **correr el mismo sabotaje** (romper copy + renombrar RPC en el servicio) y confirmar que la suite se pone en ROJO; luego revertir y confirmar verde.
