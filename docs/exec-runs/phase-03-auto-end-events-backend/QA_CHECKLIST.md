# Checklist de QA — Cierre automático de rodadas vencidas (backend)

**Feature:** Auto-End Events After 24 Hours — Backend cron + notificaciones FCM
**Fases cubiertas:** Fase 3 (backend: cron scheduler + forceEndTracking + TrackingNotificationsService)
**Estado:** Pendiente de aprobacion PO

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

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | Toma el `id` del evento `IN_PROGRESS` y actualiza su `startDate` en la BD a `NOW() - INTERVAL '25 hours'` | La columna `startDate` refleja la fecha de hace 25 horas; el estado sigue siendo `IN_PROGRESS` | |
| 1.2 | Espera al próximo tick del cron (cada hora en punto, zona America/Bogota) **o** invoca `autoEndStalledEvents()` directamente desde un test e2e o consola de Node | En los logs aparece la línea `AUTO_END: processing N stalled events` con N ≥ 1 | |
| 1.3 | Consulta el estado del evento en la BD (`SELECT state FROM "Event" WHERE id = '<eventId>'`) | El campo `state` es `FINISHED` | |
| 1.4 | Abre el detalle del evento en la app (pantalla de detalle de la rodada) | La pantalla muestra el evento como finalizado (sin controles activos de tracking) | |
| 1.5 | Verifica en los logs del api-gateway que aparece `AUTO_END: completed — processed N events` al final del run | El log existe y N coincide con la cantidad de eventos manipulados | |

---

## 2. Notificacion push a los registrantes aprobados

> Con el mismo evento que cerraste en la sección 1, revisa los dispositivos de los usuarios `APPROVED`.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 2.1 | Revisa el dispositivo del primer usuario con `status = APPROVED` y `fcmToken` configurado | Llega una notificación push antes de 60 segundos del cierre automático | |
| 2.2 | Abre la notificación push en el dispositivo | La app navega al detalle del evento (deeplink `rideglory://events/detail-by-id?id=<eventId>` activo) | |
| 2.3 | Verifica el payload de la notificación en Firebase Console o en los logs del backend | El campo `type` es `TRACKING_ENDED` y `eventId` coincide con el id del evento cerrado | |
| 2.4 | Revisa el dispositivo del usuario con `status = PENDING` (no aprobado) | No llega ninguna notificación push relacionada con el cierre de esta rodada | |
| 2.5 | Verifica en los logs que el backend intenta enviar FCM **solo** a registrantes con `status = APPROVED` | Los logs muestran los fcmTokens de los usuarios APPROVED únicamente; ningún PENDING aparece | |

---

## 3. El cliente WS recibe el aviso de fin de evento

> Necesitas tener un cliente WS conectado al evento **antes** de ejecutar el cierre. Puede ser la app en modo tracking o `websocat`.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3.1 | Conecta un cliente WS al tracking del evento (`/tracking/ws`) y déjalo escuchando | La conexión queda activa; el cliente recibe actualizaciones de ubicación normalmente | |
| 3.2 | Ejecuta el cierre automático del evento (como en la sección 1) | El cliente WS recibe el mensaje `{ "type": "tracking.event.ended", "data": { "eventId": "<id>" } }` | |
| 3.3 | Verifica que la conexión WS se cierra o que la app navega fuera de la pantalla de tracking | La sesión de tracking en el cliente termina limpiamente (sin reconexión infinita) | |

---

## 4. El cierre manual del organizador sigue funcionando (regresion)

> Crea un evento nuevo en `IN_PROGRESS` con `startDate` reciente (menos de 24h). El endpoint manual no debe verse afectado por este cambio.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 4.1 | Llama `POST /api/events/<eventId>/tracking/end` con un token Firebase válido cuyo claim `email` esté presente | El endpoint devuelve HTTP 200 con el evento en estado `FINISHED` | |
| 4.2 | Revisa los dispositivos de los registrantes `APPROVED` del evento | Llegan las notificaciones FCM de cierre igual que en el flujo automático | |
| 4.3 | Verifica en los logs del api-gateway que `TrackingNotificationsService.sendEventEndedNotifications` fue invocado | El log de FCM aparece asociado a `endTracking` (manual), no al cron | |
| 4.4 | Llama `POST /api/events/<eventId>/tracking/end` con un token Firebase cuyo claim `email` esté **ausente** (solo `uid`) | El endpoint devuelve HTTP 401 Unauthorized — documenta si este comportamiento es esperado o es BUG-01 | |

> **Nota BUG-01:** el paso 4.4 verifica un cambio de comportamiento fuera del alcance de esta fase. Si el token anterior (solo `uid`) devuelve 401 donde antes devolvía 200, confirma con el tech lead si se revierte o se acepta el nuevo flujo de autenticación antes de aprobar la fase.

---

## 5. Casos de borde

### 5A. Evento con menos de 24 horas NO se cierra

> Toma otro evento `IN_PROGRESS` con `startDate` de hace 23 horas.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5A.1 | Actualiza el `startDate` del evento a `NOW() - INTERVAL '23 hours'` en la BD | El campo queda en la nueva fecha; el estado sigue `IN_PROGRESS` | |
| 5A.2 | Ejecuta el cron (`autoEndStalledEvents`) | En los logs **no** aparece este evento como procesado; su estado en BD permanece `IN_PROGRESS` | |

### 5B. Idempotencia: el cron corre dos veces sobre el mismo evento

> Usa el evento que ya quedó en `FINISHED` de la sección 1.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5B.1 | Ejecuta `autoEndStalledEvents()` de nuevo sin cambiar nada en la BD | Los logs indican `AUTO_END: processing 0 stalled events` (el evento ya es `FINISHED` y no aparece en el filtro `IN_PROGRESS`) | |
| 5B.2 | Verifica que el `state` del evento en BD sigue siendo `FINISHED` y que no se generó un UPDATE duplicado en los logs de Prisma | No hay UPDATE sobre el evento; `state` intacto en `FINISHED` | |

### 5C. Un evento falla durante el cierre automatico

> Requiere acceso al código en staging o un entorno local. Simula un fallo en `forceEndTracking` para un evento específico (ej: event-id inexistente o forzando un timeout RPC).

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5C.1 | Prepara dos eventos: uno válido (`IN_PROGRESS`, startDate -25h) y uno con id manipulado que causará fallo en `forceEndTracking` | Ambos eventos quedan en la BD antes del cron | |
| 5C.2 | Ejecuta `autoEndStalledEvents()` | En los logs aparece `AUTO_END: failed for event <idFallido>: <error>` para el evento problemático | |
| 5C.3 | Verifica el estado del evento válido en la BD | El evento válido queda en `FINISHED` — el fallo del otro no lo afectó | |

### 5D. Evento sin registrantes aprobados

> Crea un evento `IN_PROGRESS` con `startDate` -25h que no tenga ningún registrante con `status = APPROVED`.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5D.1 | Ejecuta el cron | El evento cambia a `FINISHED` sin errores | |
| 5D.2 | Verifica en los logs que no se intentó enviar ningún FCM | No hay llamadas a FCM para ese evento; los logs no muestran intentos de push | |

### 5E. Registrante aprobado sin fcmToken

> El campo `fcmToken` de un usuario aprobado es `null`.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5E.1 | Asegura que uno de los registrantes `APPROVED` tenga `fcmToken = null` en la BD | El campo queda nulo antes del cierre | |
| 5E.2 | Ejecuta el cierre automático del evento | El cron finaliza sin error; los demás registrantes con `fcmToken` válido sí reciben la notificación | |
| 5E.3 | Verifica los logs del backend para el usuario sin token | El log muestra que se omitió el envío FCM para ese usuario (sin lanzar excepción) | |

### 5F. Guard de concurrencia — segundo tick bloqueado

> Este caso requiere logs del servidor durante dos ticks consecutivos del cron, o simulación en entorno local.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5F.1 | Simula que el primer run del cron tarda más de un minuto (inyectando latencia o usando un stub) y dispara el segundo tick mientras el primero sigue corriendo | El segundo tick loggea `AUTO_END: previous run still in progress — skipping` y retorna inmediatamente | |
| 5F.2 | Espera a que termine el primer run | `_autoEndRunning` vuelve a `false`; el siguiente tick puede ejecutarse normalmente | |

---

## 6. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 6.1 | Consulta `SELECT id, state, "startDate" FROM "Event" WHERE state = 'IN_PROGRESS' AND "startDate" <= NOW() - INTERVAL '24 hours'` en staging antes y después del cron | Antes: N filas. Después: 0 filas (todas pasaron a `FINISHED`) | |
| 6.2 | Busca en el código de `events-ms/src/events/events.controller.ts` los métodos nuevos | Los dos nuevos métodos tienen solo `@MessagePattern` (TCP), ningún `@Get`, `@Post`, `@Put` ni `@Delete`. El comentario `// INTERNAL ONLY — no HTTP endpoint` está presente en ambos | |
| 6.3 | Corre `npx eslint "src/tracking/tracking-notifications.service.ts" "src/tracking/tracking-http.controller.ts" "src/tracking/tracking.module.ts" "src/scheduler/notification-scheduler.service.ts" "src/scheduler/notification-scheduler-auto-end.service.spec.ts" "src/scheduler/notification-scheduler.module.ts" "src/tracking/tracking-notifications.service.spec.ts" "src/tracking/tracking-http.controller.spec.ts"` en api-gateway | 0 errores nuevos en los archivos de Phase 03 | |
| 6.4 | Corre `npx jest events.service.spec` en events-ms | 13 tests pasan (12 originales corregidos + 1 nuevo AC2) | |
| 6.5 | Corre `npx jest notification-scheduler` en api-gateway | 42 tests pasan (34 originales + 8 nuevos de Phase 03) | |
| 6.6 | Corre `npx jest tracking-notifications.service.spec` en api-gateway | 5 tests pasan | |
| 6.7 | Corre `npx jest tracking-http.controller.spec` en api-gateway | 6 tests pasan | |
| 6.8 | Verifica que no exista ninguna ruta HTTP mapeada a `forceEndTracking` (`grep -r "forceEndTracking" api-gateway/src` no debe mostrar decoradores `@Get/@Post/@Put/@Delete`) | Solo aparecen referencias en la implementación del cron y en los tests; ningún HTTP handler | |
| 6.9 | Verifica en los logs de NestJS al arrancar el módulo que no hay errores de dependencias circulares | El servidor arranca sin mensajes de circular dependency; todos los módulos resuelven correctamente | |
| 6.10 | Confirma que los crons de SOAT/RTM/maintenance/event-reminder existentes siguen disparándose normalmente después del deploy | Los logs del scheduler muestran los crons pre-existentes corriendo en sus horarios sin cambios | |

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
