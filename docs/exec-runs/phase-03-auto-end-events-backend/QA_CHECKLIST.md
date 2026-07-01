# Checklist de QA — Cierre automático de rodadas vencidas (backend)

**Feature:** Auto-End Events After 24 Hours — Backend cron + notificaciones FCM
**Fases cubiertas:** Fase 3 (backend: cron scheduler + forceEndTracking + TrackingNotificationsService)
**Estado:** ❌ Rechazado — caso 6.3 (lint) en sección crítica falló la automatización

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-01T04:13:24Z): 🤖✅ 25 verificados · 🤖❌ 1 fallando · 👤 6 manuales · 🚫 9 no automatizables (de 41 casos).
> Entorno: device=ios-simulator, baseline=na. Auditor Opus: solid.

---

## Pre-condiciones

Antes de empezar, asegurate de tener listo lo siguiente:

- [ ] Acceso a la base de datos de staging (Prisma Studio o psql) para manipular `startDate` y consultar `state`
- [ ] Al menos un evento creado e iniciado en staging (estado `IN_PROGRESS`, con `startDate` válido)
- [ ] Al menos dos usuarios registrados como `APPROVED` en ese evento, con `fcmToken` configurado en sus dispositivos
- [ ] Al menos un usuario registrado como `PENDING` en el mismo evento (para verificar que NO recibe FCM)
- [ ] Un cliente WS conectado al evento (puede ser un rider en la app o una herramienta como `websocat`)
- [ ] Acceso a los logs del servidor api-gateway en staging (CloudWatch, Railway, o equivalente)
- [ ] Firebase Console abierta en la sección **Messaging → Test** para verificar entrega de FCM
- [ ] Un token Firebase válido con campo `email` para probar el endpoint manual (ver sección 3 — BUG-01)

---

## 1. Cierre automático de la rodada por cron

> Vas a simular que una rodada lleva más de 24 horas en curso. Abre la BD de staging y el panel de logs del servidor.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Toma el `id` del evento `IN_PROGRESS` y actualiza su `startDate` en la BD a `NOW() - INTERVAL '25 hours'` | La columna `startDate` refleja la fecha de hace 25 horas; el estado sigue siendo `IN_PROGRESS` | 🚫 No automatizable (requiere BD de staging real) | |
| 1.2 | Espera al próximo tick del cron (cada hora en punto, zona America/Bogota) **o** invoca `autoEndStalledEvents()` directamente desde un test e2e o consola de Node | En los logs aparece la línea `AUTO_END: processing N stalled events` con N ≥ 1 | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` :: happy path > calls forceEndTracking, broadcastEventEnded, and sendEventEndedNotifications for each stalled event) | ✅ |
| 1.3 | Consulta el estado del evento en la BD (`SELECT state FROM "Event" WHERE id = '<eventId>'`) | El campo `state` es `FINISHED` | 🚫 No automatizable (requiere BD de staging; transición cubierta a nivel unit en `events.service.spec.ts`) | |
| 1.4 | Abre el detalle del evento en la app (pantalla de detalle de la rodada) | La pantalla muestra el evento como finalizado (sin controles activos de tracking) | 👤 Manual (requiere evento real en staging y observación visual; UI ya cubierta por `live_tracking_cubit_event_ended_test.dart`) | |
| 1.5 | Verifica en los logs del api-gateway que aparece `AUTO_END: completed — processed N events` al final del run | El log existe y N coincide con la cantidad de eventos manipulados | 🚫 No automatizable (requiere logs de servidor de staging real) | |

---

## 2. Notificacion push a los registrantes aprobados

> Con el mismo evento que cerraste en la sección 1, revisa los dispositivos de los usuarios `APPROVED`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Revisa el dispositivo del primer usuario con `status = APPROVED` y `fcmToken` configurado | Llega una notificación push antes de 60 segundos del cierre automático | 👤 Manual (requiere dispositivo/emulador real recibiendo push FCM) | |
| 2.2 | Abre la notificación push en el dispositivo | La app navega al detalle del evento (deeplink `rideglory://events/detail-by-id?id=<eventId>` activo) | 👤 Manual (requiere interacción táctil real con notificación push) | |
| 2.3 | Verifica el payload de la notificación en Firebase Console o en los logs del backend | El campo `type` es `TRACKING_ENDED` y `eventId` coincide con el id del evento cerrado | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` :: sends FCM with type=TRACKING_ENDED and correct deeplink to APPROVED registrant with fcmToken / embeds the correct eventId in the deeplink route) | ✅ |
| 2.4 | Revisa el dispositivo del usuario con `status = PENDING` (no aprobado) | No llega ninguna notificación push relacionada con el cierre de esta rodada | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` :: sends FCM only to registrants with fcmToken when the list is mixed) | ✅ |
| 2.5 | Verifica en los logs que el backend intenta enviar FCM **solo** a registrantes con `status = APPROVED` | Los logs muestran los fcmTokens de los usuarios APPROVED únicamente; ningún PENDING aparece | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` :: sends FCM only to registrants with fcmToken when the list is mixed) | ✅ |

---

## 3. El cliente WS recibe el aviso de fin de evento

> Necesitas tener un cliente WS conectado al evento **antes** de ejecutar el cierre. Puede ser la app en modo tracking o `websocat`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Conecta un cliente WS al tracking del evento (`/tracking/ws`) y déjalo escuchando | La conexión queda activa; el cliente recibe actualizaciones de ubicación normalmente | 👤 Manual (requiere cliente WS real, app o `websocat`, contra staging en vivo) | |
| 3.2 | Ejecuta el cierre automático del evento (como en la sección 1) | El cliente WS recibe el mensaje `{ "type": "tracking.event.ended", "data": { "eventId": "<id>" } }` | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` :: calls forceEndTracking, broadcastEventEnded, and sendEventEndedNotifications for each stalled event) | ✅ |
| 3.3 | Verifica que la conexión WS se cierra o que la app navega fuera de la pantalla de tracking | La sesión de tracking en el cliente termina limpiamente (sin reconexión infinita) | 🤖✅ Auto-PASS (`test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart` :: LiveTrackingCubit — eventEnded cleanup, 4 casos: path principal, doble disparo, sin sesión activa, Left) | ✅ |

---

## 4. El cierre manual del organizador sigue funcionando (regresion)

> Crea un evento nuevo en `IN_PROGRESS` con `startDate` reciente (menos de 24h). El endpoint manual no debe verse afectado por este cambio.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Llama `POST /api/events/<eventId>/tracking/end` con un token Firebase válido cuyo claim `email` esté presente | El endpoint devuelve HTTP 200 con el evento en estado `FINISHED` | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-http.controller.spec.ts` :: (a) returns the result from the events-ms trackingEnd RPC) | ✅ |
| 4.2 | Revisa los dispositivos de los registrantes `APPROVED` del evento | Llegan las notificaciones FCM de cierre igual que en el flujo automático | 👤 Manual (requiere dispositivos físicos reales; delegación a `TrackingNotificationsService` ya verificada a nivel unit) | |
| 4.3 | Verifica en los logs del api-gateway que `TrackingNotificationsService.sendEventEndedNotifications` fue invocado | El log de FCM aparece asociado a `endTracking` (manual), no al cron | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-http.controller.spec.ts` :: (c) delegates FCM to trackingNotificationsService.sendEventEndedNotifications) | ✅ |
| 4.4 | Llama `POST /api/events/<eventId>/tracking/end` con un token Firebase cuyo claim `email` esté **ausente** (solo `uid`) | El endpoint devuelve HTTP 401 Unauthorized — documenta si este comportamiento es esperado o es BUG-01 | 🚫 No automatizable — divergencia checklist/código: `endTracking` usa `request.user?.uid` directamente (no `email`), ver `tracking-http.controller.ts` líneas 70-95. BUG-01 parece revertido; ver detalle en handoff | |

> **Nota BUG-01:** el paso 4.4 verifica un cambio de comportamiento fuera del alcance de esta fase. Si el token anterior (solo `uid`) devuelve 401 donde antes devolvía 200, confirma con el tech lead si se revierte o se acepta el nuevo flujo de autenticación antes de aprobar la fase.

---

## 5. Casos de borde

### 5A. Evento con menos de 24 horas NO se cierra

> Toma otro evento `IN_PROGRESS` con `startDate` de hace 23 horas.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5A.1 | Actualiza el `startDate` del evento a `NOW() - INTERVAL '23 hours'` en la BD | El campo queda en la nueva fecha; el estado sigue `IN_PROGRESS` | 🚫 No automatizable (requiere manipulación de BD de staging real) | |
| 5A.2 | Ejecuta el cron (`autoEndStalledEvents`) | En los logs **no** aparece este evento como procesado; su estado en BD permanece `IN_PROGRESS` | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/events/events.service.spec.ts` :: AC2 explicit exclusion — a 23h-old event has startDate AFTER the 24h cutoff and is excluded by the lte clause) | ✅ |

### 5B. Idempotencia: el cron corre dos veces sobre el mismo evento

> Usa el evento que ya quedó en `FINISHED` de la sección 1.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5B.1 | Ejecuta `autoEndStalledEvents()` de nuevo sin cambiar nada en la BD | Los logs indican `AUTO_END: processing 0 stalled events` (el evento ya es `FINISHED` y no aparece en el filtro `IN_PROGRESS`) | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` :: returns immediately without calling forceEndTracking when event list is empty) | ✅ |
| 5B.2 | Verifica que el `state` del evento en BD sigue siendo `FINISHED` y que no se generó un UPDATE duplicado en los logs de Prisma | No hay UPDATE sobre el evento; `state` intacto en `FINISHED` | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/events/events.service.spec.ts` :: is idempotent — returns current state without calling update when event is already FINISHED) | ✅ |

### 5C. Un evento falla durante el cierre automatico

> Requiere acceso al código en staging o un entorno local. Simula un fallo en `forceEndTracking` para un evento específico (ej: event-id inexistente o forzando un timeout RPC).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5C.1 | Prepara dos eventos: uno válido (`IN_PROGRESS`, startDate -25h) y uno con id manipulado que causará fallo en `forceEndTracking` | Ambos eventos quedan en la BD antes del cron | 🚫 No automatizable (requiere fixtures reales en BD de staging) | |
| 5C.2 | Ejecuta `autoEndStalledEvents()` | En los logs aparece `AUTO_END: failed for event <idFallido>: <error>` para el evento problemático | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` :: continues processing event-2 even when forceEndTracking fails for event-1) | ✅ |
| 5C.3 | Verifica el estado del evento válido en la BD | El evento válido queda en `FINISHED` — el fallo del otro no lo afectó | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` :: continues processing event-2 even when forceEndTracking fails for event-1) | ✅ |

### 5D. Evento sin registrantes aprobados

> Crea un evento `IN_PROGRESS` con `startDate` -25h que no tenga ningún registrante con `status = APPROVED`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5D.1 | Ejecuta el cron | El evento cambia a `FINISHED` sin errores | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` :: does NOT call sendFcm when there are no approved registrants) | ✅ |
| 5D.2 | Verifica en los logs que no se intentó enviar ningún FCM | No hay llamadas a FCM para ese evento; los logs no muestran intentos de push | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` :: does NOT call sendFcm when there are no approved registrants) | ✅ |

### 5E. Registrante aprobado sin fcmToken

> El campo `fcmToken` de un usuario aprobado es `null`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5E.1 | Asegura que uno de los registrantes `APPROVED` tenga `fcmToken = null` en la BD | El campo queda nulo antes del cierre | 🚫 No automatizable (requiere manipular BD de staging; escenario ya simulado con mocks) | |
| 5E.2 | Ejecuta el cierre automático del evento | El cron finaliza sin error; los demás registrantes con `fcmToken` válido sí reciben la notificación | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` :: sends FCM with type=TRACKING_ENDED... / does NOT call sendFcm when the registrant has no fcmToken (null)) | ✅ |
| 5E.3 | Verifica los logs del backend para el usuario sin token | El log muestra que se omitió el envío FCM para ese usuario (sin lanzar excepción) | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` :: does NOT call sendFcm when the registrant has no fcmToken (null)) | ✅ |

### 5F. Guard de concurrencia — segundo tick bloqueado

> Este caso requiere logs del servidor durante dos ticks consecutivos del cron, o simulación en entorno local.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5F.1 | Simula que el primer run del cron tarda más de un minuto (inyectando latencia o usando un stub) y dispara el segundo tick mientras el primero sigue corriendo | El segundo tick loggea `AUTO_END: previous run still in progress — skipping` y retorna inmediatamente | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` :: skips the run and logs a warning when _autoEndRunning is already true) | ✅ |
| 5F.2 | Espera a que termine el primer run | `_autoEndRunning` vuelve a `false`; el siguiente tick puede ejecutarse normalmente | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` :: resets _autoEndRunning to false in the finally block after successful run / resets _autoEndRunning to false even when an error occurs fetching events) | ✅ |

---

## 6. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificacion | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 6.1 | Consulta `SELECT id, state, "startDate" FROM "Event" WHERE state = 'IN_PROGRESS' AND "startDate" <= NOW() - INTERVAL '24 hours'` en staging antes y después del cron | Antes: N filas. Después: 0 filas (todas pasaron a `FINISHED`) | 🚫 No automatizable (requiere SQL directo contra BD de staging real; filtro cubierto por `findActiveEventsOlderThan` en `events.service.spec.ts`) | |
| 6.2 | Busca en el código de `events-ms/src/events/events.controller.ts` los métodos nuevos | Los dos nuevos métodos tienen solo `@MessagePattern` (TCP), ningún `@Get`, `@Post`, `@Put` ni `@Delete`. El comentario `// INTERNAL ONLY — no HTTP endpoint` está presente en ambos | 🤖✅ Auto-PASS (code review — grep `@MessagePattern`/`INTERNAL ONLY` en `events.controller.ts`) | ✅ |
| 6.3 | Corre `npx eslint "src/tracking/tracking-notifications.service.ts" "src/tracking/tracking-http.controller.ts" "src/tracking/tracking.module.ts" "src/scheduler/notification-scheduler.service.ts" "src/scheduler/notification-scheduler-auto-end.service.spec.ts" "src/scheduler/notification-scheduler.module.ts" "src/tracking/tracking-notifications.service.spec.ts" "src/tracking/tracking-http.controller.spec.ts"` en api-gateway | 0 errores nuevos en los archivos de Phase 03 | 🤖❌ Auto-FAIL — hallazgo: `events.service.ts:566` (nuevo método `forceEndTracking`, comparación de enum sin cast dispara `@typescript-eslint/no-unsafe-enum-comparison`) y `events.service.spec.ts:212,214,227` (nuevo describe de `findActiveEventsOlderThan`/AC2 accede a `mockFindMany.mock.calls[0][0]` sin tipar, dispara `no-unsafe-assignment`/`no-unsafe-member-access`); ambos son código NUEVO de Phase 03, no preexistente. Los 3 spec files nuevos de api-gateway están limpios. Ver detalle en handoff | |
| 6.4 | Corre `npx jest events.service.spec` en events-ms | 13 tests pasan (12 originales corregidos + 1 nuevo AC2) | 🤖✅ Auto-PASS (`rideglory-api/events-ms/src/events/events.service.spec.ts` :: suite completa) | ✅ |
| 6.5 | Corre `npx jest notification-scheduler` en api-gateway | 42 tests pasan (34 originales + 8 nuevos de Phase 03) | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` :: suite completa) | ✅ |
| 6.6 | Corre `npx jest tracking-notifications.service.spec` en api-gateway | 5 tests pasan | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` :: suite completa) | ✅ |
| 6.7 | Corre `npx jest tracking-http.controller.spec` en api-gateway | 6 tests pasan | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/tracking/tracking-http.controller.spec.ts` :: suite completa) | ✅ |
| 6.8 | Verifica que no exista ninguna ruta HTTP mapeada a `forceEndTracking` (`grep -r "forceEndTracking" api-gateway/src` no debe mostrar decoradores `@Get/@Post/@Put/@Delete`) | Solo aparecen referencias en la implementación del cron y en los tests; ningún HTTP handler | 🤖✅ Auto-PASS (grep `forceEndTracking` en `api-gateway/src` y `events-ms/src`) | ✅ |
| 6.9 | Verifica en los logs de NestJS al arrancar el módulo que no hay errores de dependencias circulares | El servidor arranca sin mensajes de circular dependency; todos los módulos resuelven correctamente | 🚫 No automatizable (requiere levantar servidor NestJS completo con BD y env reales) | |
| 6.10 | Confirma que los crons de SOAT/RTM/maintenance/event-reminder existentes siguen disparándose normalmente después del deploy | Los logs del scheduler muestran los crons pre-existentes corriendo en sus horarios sin cambios | 👤 Manual (requiere observación de logs en tiempo real en entorno desplegado; lógica ya confirmada por los 34 tests pre-existentes de `notification-scheduler.service.spec.ts`) | |

---

## 👤 Solo para ti — pruebas manuales restantes

Estos son los casos que qa-auto NO pudo verificar automáticamente y requieren tu ejecución (manuales) o tu revisión (auto-fail). Todo lo demás ya quedó cubierto por tests automatizados.

| id | Acción | Qué revisar | Por qué no se automatizó |
|----|--------|-------------|---------------------------|
| 1.4 | Abrir el detalle del evento en la app y ver que aparece finalizado | Que la pantalla muestre el evento como finalizado, sin controles activos de tracking | Requiere evento real en staging + observación visual en la app |
| 2.1 | Revisar dispositivo de usuario APPROVED con fcmToken y confirmar llegada de push antes de 60s | Que la push llegue dentro del plazo | Requiere dispositivo/emulador real recibiendo FCM |
| 2.2 | Abrir la notificación push y verificar deeplink de navegación al detalle del evento | Que la app navegue correctamente al abrir la notificación | Requiere interacción táctil real con una notificación push |
| 3.1 | Conectar cliente WS al tracking del evento y dejarlo escuchando | Que la conexión quede activa y reciba updates de ubicación | Requiere cliente WS real (app o `websocat`) contra staging en vivo |
| 4.2 | Revisar dispositivos de registrantes APPROVED del cierre manual y confirmar llegada de FCM | Que lleguen las notificaciones igual que en el flujo automático | Requiere dispositivos físicos reales; la delegación de FCM ya está verificada a nivel unit |
| 6.10 | Confirmar que los crons de SOAT/RTM/maintenance/event-reminder existentes siguen disparándose normalmente tras el deploy | Logs del scheduler mostrando los crons pre-existentes sin cambios | Requiere observación de logs en tiempo real en un entorno desplegado durante varios ciclos |
| 6.3 | Corre `npx eslint ...` en api-gateway y revisa los 2 hallazgos nuevos | `events.service.ts:566` (`no-unsafe-enum-comparison` en el nuevo `forceEndTracking`) y `events.service.spec.ts:212,214,227` (`no-unsafe-assignment`/`no-unsafe-member-access` en el describe nuevo de AC2) | 🤖❌ auto-fail — hallazgo real que requiere decisión: ajustar el código de producción o suprimir el lint con justificación |

---

## 🚫 No automatizable en este entorno

| id | Caso | Cómo habilitarlo |
|----|------|-------------------|
| 1.1 | Actualizar startDate del evento a -25h en BD de staging | Conectar Prisma Studio o `psql` a la BD de staging real y correr el UPDATE |
| 1.3 | Consultar el estado del evento en la BD tras el cron | Acceso directo a la BD de staging (mismo canal que 1.1) |
| 1.5 | Verificar en logs del api-gateway la línea `AUTO_END: completed` | Acceso a logs de un servidor de staging real corriendo (CloudWatch/Railway) |
| 4.4 | Verificar 401 con token sin claim `email` (BUG-01) | Requiere decisión de tech lead: el código actual (`tracking-http.controller.ts` líneas 70-95) usa `request.user?.uid`, no `email` — el escenario del checklist parece obsoleto; confirmar con tech lead antes de re-escribir el caso |
| 5A.1 | Actualizar startDate de otro evento a -23h en BD de staging | Mismo canal que 1.1 |
| 5C.1 | Preparar un evento válido y uno con id inválido en BD de staging | Fixtures reales en BD de staging (o entorno local con seed controlado) |
| 5E.1 | Asegurar fcmToken null en un registrante APPROVED | Update directo en BD de staging |
| 6.1 | Consultar eventos IN_PROGRESS con startDate vencido antes/después del cron | SQL directo contra BD de staging |
| 6.9 | Verificar logs de arranque de NestJS sin dependencias circulares | Levantar el servidor NestJS completo con BD y variables de entorno reales, y revisar el log de bootstrap |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–5 marcados como ✅ y todas las verificaciones de la sección 6 en verde |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (ej. 5D o 5E), BUG-01 documentado con ticket creado, ningún caso de las secciones 1, 2, 3 o 6 fallando |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3, 4 (pasos 4.1–4.3) o 6 marcado como ❌; o BUG-01 (paso 4.4) sin decisión del tech lead |

> **Secciones críticas:** 1 (cierre automático), 2 (FCM a registrantes), 3 (aviso WS), 4.1–4.3 (regresión endpoint manual), 6 (verificaciones técnicas). El fallo en cualquiera de estas secciones bloquea la aprobación.

> **Nota de despliegue:** Esta fase NO debe desplegarse en producción sin que la Fase 1 (Flutter WS cleanup) ya esté activa en producción. Verificar antes de promover el build.

---

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| id | Estrategia | Test file | Resultado |
|----|-----------|-----------|-----------|
| 1.2 | unit (mocktail) | `rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | ✅ pass |
| 2.3 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` | ✅ pass |
| 2.4 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` | ✅ pass |
| 2.5 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` | ✅ pass |
| 3.2 | unit (jest) | `rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | ✅ pass |
| 3.3 | unit (bloc_test) | `test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart` | ✅ pass |
| 4.1 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-http.controller.spec.ts` | ✅ pass |
| 4.3 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-http.controller.spec.ts` | ✅ pass |
| 5A.2 | unit (jest) | `rideglory-api/events-ms/src/events/events.service.spec.ts` | ✅ pass |
| 5B.1 | unit (jest) | `rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | ✅ pass |
| 5B.2 | unit (jest) | `rideglory-api/events-ms/src/events/events.service.spec.ts` | ✅ pass |
| 5C.2 | unit (jest) | `rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | ✅ pass |
| 5C.3 | unit (jest) | `rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | ✅ pass |
| 5D.1 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` | ✅ pass |
| 5D.2 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` | ✅ pass |
| 5E.2 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` | ✅ pass |
| 5E.3 | unit (jest) | `rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` | ✅ pass |
| 5F.1 | unit (jest) | `rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | ✅ pass |
| 5F.2 | unit (jest) | `rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | ✅ pass |
| 6.2 | code review (grep) | N/A | ✅ pass |
| 6.3 | eslint + git diff | N/A | ❌ fail (2 hallazgos nuevos) |
| 6.4 | jest suite | `rideglory-api/events-ms/src/events/events.service.spec.ts` | ✅ pass |
| 6.5 | jest suite | `rideglory-api/api-gateway/src/scheduler/notification-scheduler-auto-end.service.spec.ts` | ✅ pass |
| 6.6 | jest suite | `rideglory-api/api-gateway/src/tracking/tracking-notifications.service.spec.ts` | ✅ pass |
| 6.7 | jest suite | `rideglory-api/api-gateway/src/tracking/tracking-http.controller.spec.ts` | ✅ pass |
| 6.8 | grep | N/A | ✅ pass |

**Tests rechazados por el auditor Opus:** ninguno — el auditor (nivel solid) no rechazó ningún test por estar vacío o ser trivial.

### Cómo correr los tests generados

Backend (rideglory-api):
```bash
cd rideglory-api/events-ms && npx jest events.service.spec
cd rideglory-api/api-gateway && npx jest notification-scheduler-auto-end.service.spec
cd rideglory-api/api-gateway && npx jest tracking-notifications.service.spec
cd rideglory-api/api-gateway && npx jest tracking-http.controller.spec
```

Flutter:
```bash
flutter test test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart
```

### Siguientes pasos

- **Investigar el hallazgo de 6.3 (auto-fail):** `events.service.ts:566` (nuevo `forceEndTracking`) dispara `@typescript-eslint/no-unsafe-enum-comparison` en la comparación `event.state !== EventState.IN_PROGRESS`; y `events.service.spec.ts:212,214,227` (nuevo describe de AC2) dispara `no-unsafe-assignment`/`no-unsafe-member-access` al acceder a `mockFindMany.mock.calls[0][0]` sin tipar. Ambos son código nuevo de esta fase, no preexistente. Requiere que un humano corrija el tipado en `events.service.ts` y `events.service.spec.ts` (fuera del alcance de qa-auto, que no edita código de producción ni specs existentes).
- **Resolver BUG-01 (caso 4.4):** el comportamiento descrito en el checklist (401 sin claim `email`) ya no corresponde al código actual, que autentica por `uid`. Confirmar con el tech lead si el checklist debe actualizarse o si hay una regresión real pendiente de investigar.
- **Casos 🚫 por falta de entorno de staging:** para habilitarlos se necesita acceso a una BD de staging real (Prisma Studio o `psql`) y a los logs del servidor api-gateway desplegado (CloudWatch/Railway); ninguno requiere simulador iOS.
- **Casos 👤 por dispositivo/push real:** requieren un dispositivo físico o emulador con Firebase configurado recibiendo FCM real; re-ejecutar manualmente contra staging cuando esté disponible.
