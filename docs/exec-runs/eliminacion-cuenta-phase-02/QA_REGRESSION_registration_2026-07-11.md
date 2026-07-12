# Regresión e2e — Inscripción a evento (post eliminacion-cuenta-phase-02)

**Fecha (UTC):** 2026-07-11T14:51:50Z → 2026-07-11T15:08:41Z
**Test ejecutado:** `integration_test/registration_patrol_test.dart`
**Device:** `emulator-5554` (Pixel_9a AVD API 16), flavor `dev`
**Rider:** qa1@gmail.com — **Evento:** "Mi Evento" (owner qa2@gmail.com)

## Entorno preparado para esta corrida
- Postgres de microservicios: contenedores Docker (`events-db`, `users-db`, `vehicles-db`,
  `maintenances-db`, `gateway-db`) — Docker Desktop no estaba corriendo al iniciar; se levantó y los
  contenedores (restart policy `unless-stopped`) subieron solos con sus datos previos intactos.
- Microservicios Node (`users-ms`, `vehicles-ms`, `events-ms`, `maintenances-ms`, `notifications-ms`,
  `api-gateway`) NO estaban corriendo; se arrancaron temporalmente en background (`npm run start:dev` /
  `start:dev:local`) solo para esta corrida y se **detuvieron al finalizar** (no se dejaron corriendo).
- Pre-limpieza: `DELETE FROM "EventRegistration" ... WHERE email='qa1@gmail.com' AND status='PENDING'`
  → 0 filas (ya estaba limpio).

## Comando Patrol ejecutado
```
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 --flavor dev \
  --dart-define-from-file=config/dev.json \
  --dart-define=TEST_EMAIL=qa1@gmail.com --dart-define=TEST_PASSWORD=Test123.
```

## Resultado: ❌ FAIL

Los 34 pasos funcionales del flujo (login → tab Eventos → detalle "Mi Evento" → wizard de 4 pasos →
consentimiento Ley 1581 → selección de vehículo → confirmar inscripción → waiver de riesgos →
aparición de "Tu solicitud está siendo revisada por el organizador.") **pasaron todos**, incluida la
aserción final. Inmediatamente después, el test framework capturó una `PlatformException` async no
manejada proveniente de Mapbox:

```
PlatformException(Throwable, java.lang.Throwable: Source 'rg-route-source' is not in style, ...)
  at com.mapbox.maps.mapbox_maps.StyleController.setStyleSourceProperties(StyleController.kt:424)
  ...
  at StyleManager.setStyleSourceProperties (map_interfaces.dart:7969:7)
```

Esto tumbó el test completo (`❌ inscripción: usuario completa el wizard y ve el éxito`) pese a que el
flujo de negocio fue exitoso en la UI. El propio archivo de test documenta este riesgo (líneas 36-43):
el guard `_guardMapCamera` en `RouteMapPreview` debía capturar el cierre del canal de Mapbox al navegar
fuera del detalle del evento; si vuelve a fallar por esto, **es una regresión de ese guard**, no un
problema del test. Esto amerita revisión del guard en
`lib/features/events/presentation/widgets/.../route_map_preview.dart` (no tocado en esta corrida QA).

## Verificación de base de datos: ❌ FAIL (bug adicional, independiente del crash de Mapbox)

A pesar de que la UI llegó al estado "pendiente de revisión" y el `api-gateway` respondió:
```
POST /api/events/97244389-40a5-413c-8ab7-9d6e7995ef78/registrations → 201 Created (89ms)
```
la tabla `EventRegistration` de la BD de `events-ms` **NO tiene ninguna fila nueva** para
`qa1@gmail.com` en "Mi Evento" (ni en ningún evento) tras la corrida:

```sql
SELECT count(*), max("createdAt") FROM "EventRegistration";
-- 5 filas, la más reciente de 2026-07-07 (nada nuevo pese al 201 de las 09:59:53 del 2026-07-11)
```

Se revisó `api-gateway/src/registrations/registrations.controller.ts`: el endpoint hace
`firstValueFrom(eventsService.send('createRegistration', ...).pipe(timeout(...)))` y devuelve
directamente la respuesta real del microservicio (no hay stub/mock ni fallback que fabrique un 201). No
se encontraron logs de error en `events-ms` ni en `api-gateway` alrededor de esa llamada. Es decir: el
backend devolvió éxito con un payload de registración real, pero el registro no quedó persistido — un
posible bug de rollback/transacción o de conexión a una réplica distinta en `events-ms`. **Esto es un
bug real de persistencia, no un falso positivo de UI**, y debería priorizarse antes que el crash de
Mapbox porque implica que el usuario cree estar inscrito cuando no lo está en la fuente de verdad.

## Limpieza final
- Se re-ejecutó el `DELETE` de limpieza (idempotente): 0 filas afectadas (no había nada que borrar,
  consistente con el hallazgo de que la inscripción nunca se persistió).
- Se detuvieron los 6 procesos Node temporales (`users-ms`, `vehicles-ms`, `events-ms`,
  `maintenances-ms`, `notifications-ms`, `api-gateway`); los contenedores Docker de bases de datos se
  dejaron corriendo (ya tenían restart policy `unless-stopped` antes de esta corrida).

## Fixes requeridos (para rg-exec lite, a decisión del humano)

1. **[Alta prioridad] Persistencia de inscripción no confirmada en `events-ms`.** El endpoint
   `POST /api/events/:eventId/registrations` devuelve 201 con un payload de registración pero la fila
   no aparece en `EventRegistration` tras la respuesta. Investigar el handler `createRegistration` en
   `events-ms` (posible transacción no commiteada, excepción silenciada tras el `return`, o conexión a
   un pool/réplica de solo lectura). Repo: `rideglory-api/events-ms`.
2. **[Media prioridad] Regresión del guard de Mapbox en `RouteMapPreview`.** El `PlatformException`
   `Source 'rg-route-source' is not in style` vuelve a producirse al salir del detalle del evento hacia
   el wizard de inscripción, indicando que `_guardMapCamera` no está capturando el cierre del canal en
   este flujo. Repo: `Rideglory` (Flutter), `lib/features/events/...` (ubicación exacta del widget no
   confirmada en esta corrida QA — solo se corrió el test, no se tocó código).
