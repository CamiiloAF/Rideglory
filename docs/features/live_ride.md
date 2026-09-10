# Live ride (rodada en vivo, tracking y SOS)

> Bloque 3 de `docs/product/ALCANCE-V2.md` (F9-F12, decisiones D13-D23 en `docs/plans/refactor-v2-plan.md`). Desbloqueado el 2026-09-10 por decisión del fundador, sin esperar el experimento 1 de `docs/product/validacion.md` — esa validación sigue pendiente; las reglas de seguridad de `CLAUDE.md` se tratan como criterios de aceptación cerrados, no como hipótesis.

## Problema que resuelve

Mientras la rodada avanza, el grupo se dispersa y no hay forma de saber dónde está cada uno ni de pedir ayuda si algo sale mal — la coordinación de WhatsApp (Bloque 2) sirve antes de salir, no en la vía. `live_ride` resuelve dos cosas separadas: **ver al grupo en un mapa mientras la rodada está en curso** y **un SOS de rescate entre pares** que nunca falla en silencio, con fallback sin datos.

## Qué NO hace

- **No llama al 123 ni a ningún servicio de emergencia automáticamente.** Hay un botón terciario "Llamar al 123" en la pantalla de SOS activo que solo marca si el rider lo pulsa (D18).
- **No detecta rezagados.** No hay alarma automática por distancia o por "sin señal hace rato": el organizador ve la distancia al líder y el tiempo sin señal de cada rider en LV6, pero interpretarlo es su criterio, no un algoritmo (D20).
- No guarda histórico de ruta: `live_positions` es una fila por rider y evento (últimas coordenadas), sin trayectoria.
- No funciona fuera de un evento `started`: publicar posición fuera de ese estado lo rechaza `upsert_live_position` (`event_not_started`).

## Pantallas (Pencil)

Todas las páginas llevan el comentario `/// Pencil: <id>` (a diferencia de `events`, que no lo tiene).

| Pantalla | Archivo | nodeId |
|---|---|---|
| LV1 rodada en vivo, compartiendo | `presentation/pages/live_ride_view.dart` | `RJ9Aq` |
| LV1b rodada en vivo, sin compartir | `presentation/pages/live_ride_view.dart` | `gcRLk` |
| Carga | `presentation/pages/live_ride_view.dart` | `lMJpQ` |
| Sin permiso de ubicación | `presentation/widgets/live_ride_permission_state_view.dart` | `J22QFC` |
| Sin GPS (servicio desactivado) | `presentation/widgets/live_ride_no_gps_state_view.dart` | `eYAbY` |
| Sin conexión | `presentation/pages/live_ride_view.dart` (vía `OfflineStateView`) | `o19cv` |
| LV2 consentimiento "mientras usa la app" | `presentation/widgets/live_ride_consent_sheet.dart` | `iJUhj` |
| LV2b consentimiento "todo el tiempo" | `presentation/widgets/live_ride_consent_always_sheet.dart` | `DdSIR` |
| LV3 confirmar SOS (mantener pulsado) | `presentation/widgets/sos_confirm_sheet.dart` (+ `sos_hold_button.dart` `IZNg5`) | `k4dms` |
| LV4a SOS propio pendiente | `presentation/pages/sos_active_view.dart` | `bAklu` |
| LV4b SOS propio confirmado | `presentation/pages/sos_active_view.dart` | `KVhKk` |
| LV5a banner de SOS de otro rider | `presentation/widgets/sos_other_banner.dart` | `KkFzQ` |
| LV5b tarjeta de SOS de otro rider | `presentation/widgets/sos_other_sheet.dart` | `p4830` |
| LV5c encabezado de SOS de otro (llamar / cerrar) | `presentation/widgets/sos_active_header.dart` | `affuy` + `eWftM` |
| LV6 lista de riders del organizador | `presentation/pages/live_riders_view.dart` (hoja: `live_riders_sheet.dart`) | `UGgbU` (hoja `juEgy`) |
| LV7 rodada terminada | `presentation/widgets/live_ride_finished_view.dart` | `OQJZS` |
| LV7 + SOS abierto | `presentation/widgets/live_ride_finished_with_sos_view.dart` | `NdP2O` |

Rutas (`live_ride_routes.dart`), las tres bajo un `ShellRoute` (`LiveRideSessionScope`) que crea **un solo** `LiveRideCubit` y `SosCubit` por sesión — necesario para que un SOS confirmado en LV3 no se pierda al navegar a `/live/sos`:

- `/events/detail/:id/live` (LV1/LV1b/LV7)
- `/events/detail/:id/live/sos` (LV3/LV4/LV5c)
- `/events/detail/:id/live/riders` (LV6)

## Flujo de compartir ubicación (D21)

Orden fijo, nunca se salta un paso: **LV2 (aviso propio) → diálogo del sistema `whileInUse` → arranca el tracking → LV2b (aviso propio para "todo el tiempo") → diálogo del sistema `always`** (`live_ride_share_flow.dart`, `startLiveRideSharingFlow`).

- El diálogo nativo del sistema **nunca se muestra sin haber pasado antes por la hoja propia** — ni siquiera para el segundo permiso.
- Si el rider niega el permiso en LV2 (toca "Ahora no") o en LV2b, sigue compartiendo mientras la app esté abierta; solo se pierde el tracking en segundo plano.
- Al cargar LV1, el permiso se **consulta** (`GetLocationPermissionStateUseCase` → `checkPermission`), nunca se **pide**: la vista de "sin permiso" no se monta por el solo hecho de abrir la pantalla, solo tras pulsar "Compartir mi ubicación".
- Al confirmarse el permiso, `StartSharingLocationUseCase` cachea `LiveRideContacts` (D17) y arranca `BackgroundTrackingService` (foreground service Android / `UIBackgroundModes` iOS).
- Transporte: `upsert_live_position` cada ~5 s (throttle en el propio isolate) o 25 m de `distanceFilter`, upsert por `(event_id, user_id)` — sin historial (D15). El cliente ve al grupo por `WatchLiveRidersUseCase`, Realtime `postgres_changes` sobre `live_positions` filtrado por evento vía la vista `live_riders`.
- **Detener** siempre a un toque: botón en la notificación persistente (foreground service) y en la propia pantalla LV1.

### Foreground service y el isolate

`ForegroundTaskBackgroundTrackingService` (Android: notificación persistente con botón **Detener**; canal `rideglory_live_ride`, prioridad baja) arranca `LiveRideTrackingTaskHandler`, que corre en un **isolate sin bindings de Flutter**. Ese isolate no puede leer `Supabase.instance` (depende de plugins que no están garantizados ahí), así que construye su propio `SupabaseClient` puro con el `access token` vigente, pasado por `FlutterForegroundTask.saveData` antes de arrancar el servicio.

**Sesión dentro del isolate** (`live_ride_tracking_task_handler.dart`): el servicio recibe access token y refresh token por `saveData`, hace `setSession(refreshToken)` al arrancar y lo repite cada 45 min con un `Timer`, reconstruyendo el cliente con el token fresco. Publicar posición es "mejor esfuerzo": un fallo puntual de `upsert_live_position` se traga en el isolate (no hay UI ahí para reportarlo); la siguiente lectura llega en ~5 s.

## Flujo de SOS

### Emitir (LV3 → LV4)

`SosConfirmSheet` (LV3) exige **mantener pulsado 1,5 s** (`SosHoldButton`) para evitar un SOS por toque accidental. Al completarse, `SosCubit.raise()`:

1. Encola el item **en `SosOutbox` (local, `SharedPreferences`, `shared_preferences`) antes de intentar la red** — sobrevive a que maten la app. `enqueue` es idempotente por `clientId`.
2. Llama a la RPC `raise_sos`, también idempotente por `client_id`: un reintento del mismo item nunca duplica la fila.
3. La UI navega a LV4 sin esperar la respuesta del servidor: **`pendiente` (LV4a, `SosSendPending`) es el estado por defecto** — la UI dice explícitamente que no ha salido, nunca "enviado". Al confirmar el servidor, pasa a `confirmado` (LV4b, `SosSendConfirmed`).

**Reintento**: `SosOutboxRetryCubit` (global, sin UI propia, provisto una vez en la raíz junto a `ConnectivityCubit`) reintenta toda la cola pendiente al arrancar la app y cada vez que `ConnectivityCubit` pasa a online — un SOS encolado en un tramo sin señal sale solo apenas vuelve la cobertura, sin depender de que el rider tenga la pantalla abierta. `RetrySosOutboxUseCase.call()` nunca lanza: cada fallo individual deja el item en cola (`markAttempt`) para el próximo intento.

### Confirmado por el servidor (backend)

`raise_sos` (RPC, `security definer`): valida que el caller sea organizador o inscrito aprobado (`is_event_staff_or_approved`), sella `created_at` con `now()` (trigger `seal_sos_alert_created_at`, ignora cualquier timestamp del cliente), y si el evento sigue `started` también deja esa posición en `live_positions`. Puede emitirse aunque el evento ya esté `finished`.

Tres patas de entrega, nunca solo una (comentario de la propia tabla `sos_alerts`): escritura durable en Postgres, broadcast por Realtime (`postgres_changes` sobre `sos_alerts`, vía la vista `sos_alerts_visible`), y push a organizador + inscritos aprobados (menos el emisor) desde la Edge Function `notify-sos`, disparada por un **Database Webhook** en el `INSERT` de `sos_alerts`.

### Ver el SOS de otro rider (LV5)

`SosCubit.state.others` trae **todas** las alertas visibles del evento (propias y ajenas) vía la vista `sos_alerts_visible` — decidir cuál es "mía" para la tarjeta LV5 es responsabilidad de la UI (conoce al usuario autenticado). `sos_alerts_visible` incluye `rider_phone` **a propósito**: el SOS es rescate entre pares, así que un compañero pueda llamar al que lo emitió es parte del rescate, no una fuga — a diferencia de `event_registrations_for_organizer`, aquí no aplica `allow_organizer_contact`.

### Cerrar (LV4/LV5c, D19)

Solo dos personas pueden cerrar un SOS: **el rider que lo emitió, o el organizador del evento** — nunca una desconexión, nunca el fin del evento. `close_sos` (RPC) lo valida server-side; `protect_sos_alerts_mutation` (trigger `BEFORE UPDATE`) rechaza reabrir un SOS cerrado, cambiar `created_at`, o poner `status='closed'` sin `closed_by`/`closed_at`. Es idempotente: cerrar un SOS ya cerrado devuelve la fila tal cual, sin error (protege un doble tap en la UI). Un SOS abierto sigue visible en LV7 (rodada terminada) hasta que alguien lo cierre — `LiveRideFinishedGate` decide entre `LiveRideFinishedView` y `LiveRideFinishedWithSosView` según `SosCubit.state.mine`.

`SosCubit._reconcileMine` refleja en la UI, sin que el rider haga nada, un cierre que llegó por Realtime (por ejemplo, si lo cerró el organizador).

## Fallback sin datos (D17)

Al confirmarse el permiso de ubicación (`StartSharingLocationUseCase`), se cachea `LiveRideContacts` (`SharedPreferencesLiveRideContactsCache`, una entrada por `eventId`) leído de la RPC `get_live_ride_contacts`: nombre y teléfono del organizador (el teléfono solo si el caller es inscrito aprobado — el organizador expone su propio contacto de rescate a sus inscritos, no al revés) y el contacto de emergencia del propio caller. La pantalla de SOS activo (`sos_fallback_actions.dart`) ofrece, sin depender de red:

- **Llamar a mi contacto** (`openSosPhoneDialer`, abre el marcador nativo vía `tel:`).
- **SMS con coordenadas** (`openSosSms`, `sms:` con un link de Google Maps en el cuerpo, resuelto en `context.l10n.sos_sms_body`).

Ninguna de las dos llama o envía por sí sola: siempre abren la app nativa con el contenido precargado para que el rider confirme.

## Fin del tracking (D22)

Termina por: **Detener** (rider, desde LV1 o la notificación persistente), fin del evento (`finished` visto por `WatchEventFinishedUseCase` vía Realtime, o al reabrir la pantalla), o cierre de sesión. Cada camino para el servicio nativo (`BackgroundTrackingService.stop()`) y llama a `end_live_ride`, que borra la fila del caller en `live_positions` para ese evento. **Ninguna de las tres cierra un SOS abierto.**

## Contrato de backend (`supabase/migrations/20260910000021_live_ride.sql`)

- **`live_positions`** — PK `(event_id, user_id)`: una fila por rider y evento, sin historial ("a 1 Hz por rider eso serían cientos de miles de filas que nadie consulta después", comentario de la propia tabla). RLS: solo `select` para organizador o inscrito aprobado (`is_event_staff_or_approved`); toda escritura pasa por RPC `security definer`, no por `GRANT insert/update`. `replica identity full` + agregada a `supabase_realtime`.
- **`sos_alerts`** — `status` (`active`/`closed`), `client_id` único (idempotencia del cliente), `created_at`/`closed_at`/`closed_by` sellados por trigger, nunca por el cliente. Mismo patrón de RLS solo-`select` + RPC.
- **RPCs**: `upsert_live_position` (rechaza si el evento no está `started` o el caller no participa), `raise_sos` (idempotente por `client_id`), `close_sos` (solo emisor u organizador, idempotente), `end_live_ride` (borra la posición del caller), `get_live_ride_contacts` (fallback D17).
- **Vistas de enmascarado**: `live_riders` (posición + nombre + `is_organizer`, sin teléfono ni correo) y `sos_alerts_visible` (incluye `rider_phone` a propósito, ver arriba). Ambas `security_barrier`, filtradas por `is_event_staff_or_approved`.
- **`is_event_staff_or_approved(event_id)`**: helper `security definer` compartido por RLS y vistas — una sola definición de "quién puede ver el tracking de esta rodada".
- **Edge Function `notify-sos`** (`supabase/functions/notify-sos/index.ts`): invocada por un Database Webhook en el `INSERT` de `sos_alerts` (no hay CLI declarativo para webhooks todavía — se configura a mano en Supabase Studio, igual que `notify-route-change`). Manda push FCM a organizador + inscritos aprobados, excluyendo al emisor.

## Seguridad y legal

Cumple las reglas de "Seguridad del rider" de `CLAUDE.md`:

- SOS nunca falla en silencio: cola local antes de la red (`SosOutbox`), UI que dice "pendiente" en vez de "enviado" hasta la confirmación del servidor, reintento automático al recuperar señal o al abrir la app.
- Fallback sin datos con contacto cacheado al empezar la rodada, no leído durante la emergencia.
- SOS de rescate entre pares, no médico: sin llamada automática al 123.
- Solo el emisor o el organizador cierran un SOS; el fin del evento o una desconexión no lo tocan.
- Consentimiento explícito en dos pasos (LV2/LV2b) antes de cada diálogo nativo, con indicador de que se está compartiendo y **Detener** siempre a un toque.
- Tracking en segundo plano termina de verdad en los tres caminos de D22.
- Enmascarado en la base: `live_riders` nunca expone teléfono/correo; `sos_alerts_visible` expone teléfono a propósito porque es el propio mecanismo de rescate, no un descuido.
- Estados sin permiso / sin GPS / sin conexión diseñados (J22QFC/eYAbY/o19cv), nunca pantalla vacía.
- Edad y demás requisitos legales de la inscripción no se repiten aquí: ya los exige `event_registrations` (ver `docs/features/events.md`) antes de que alguien pueda entrar a una rodada en vivo.

Pendiente para el humano antes de producción: prominent disclosure de Play/Apple para ubicación en segundo plano, el webhook de `notify-sos` configurado en el proyecto remoto, y el texto legal (Ley 1581) sobre ubicación en vivo y teléfono compartido en el SOS — ver `docs/dev-runs/refactor-v2.md`.

## Límites conocidos

- **Token del isolate del foreground service**: se refresca cada 45 min con el refresh token; si el refresh falla (sin red prolongada), el servicio sigue leyendo GPS pero deja de publicar hasta el siguiente intento. Documentado en `live_ride_tracking_task_handler.dart`.
- **Pensado para paradas, no para el manubrio** (D23, P-16/Waze): elementos grandes, uso a una mano, en menos de dos segundos. El SOS también es accesible desde el banner en el detalle del evento (`EventLiveRideBanner`) y desde la notificación persistente, no solo desde LV1.
- **Tiles del mapa**: `flutter_map` + `latlong2` (D13, Mapbox SDK descartado por frágil y por requerir token secreto en Gradle). `AppEnv.mapTileUrl` lee `MAP_TILE_URL` por `dart-define`; en dev usa OpenStreetMap, en producción una URL raster de MapTiler/Mapbox con token en `config/prod.json`. `LiveRideView`/`LiveRideContent` exponen `showMapTiles` (`LiveRideMap.showTiles` por debajo) para dejar el `TileLayer` fuera del árbol en golden tests — el mapa no renderiza bajo `flutter_test`.
- **Sin detección de rezagados**: ver "Qué NO hace".
- **Sin histórico de ruta**: `live_positions` guarda solo la última posición por rider.

## Estados

`LiveRideCubit`: `riders: ResultState<List<LiveRider>>`, más `permission`, `sharing` (`SharingStatus`), `myPosition`, `contacts`, `isEventFinished`, `args` — sueltos porque no comparten ciclo de carga con `riders`. `SosCubit`: `others: ResultState<List<SosAlert>>` (Realtime) y `mine: SosSendState` (idle/sending/pending/confirmed/closing/closed), ciclo local independiente de Realtime para no esperar la reconciliación antes de mostrar "pendiente".

Obligatorios: skeleton (`SkeletonList`), vacío, error con reintentar (`ErrorStateView`), sin conexión (`OfflineStateView`), y los propios del Bloque 3: sin permiso de ubicación, sin GPS.
