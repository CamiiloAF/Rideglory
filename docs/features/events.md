# Events

> Reescrito para v2 (F7, EV1-EV7). Fusiona `events.md` y `event_registration.md` de la v1: en v2 la inscripción es un flujo dentro del mismo feature, no uno separado.

## Problema que resuelve

Bloque 2 de `docs/product/ALCANCE-V2.md`: "la rodada, sin el mapa" — coordinación previa que ocurre parado y con señal, sin depender del supuesto en marcha (eso era el Bloque 3, ya desbloqueado el 2026-09-10 — ver `docs/features/live_ride.md`). Resuelve P-08 (crear y publicar rodada con el mínimo real, y destino con punto exacto — el fallo textual de la única rodada real de la v1), P-09 (aviso de inicio, para que nadie descubra al final que el mapa nunca arrancó) y P-13/P-14 (datos de emergencia del inscrito accesibles al organizador en la vía, con botón de llamar). La capa legal de la inscripción (edad ≥18 validada en servidor, consentimientos sellados) es requisito de `CLAUDE.md`, no una decisión de producto.

## Flujos

- **Lista con segmentos Próximas/Mías** (`EventsPage`/`EventsListView`, EV1): dos resultados independientes (organizo o estoy inscrito, vs. públicos futuros), porque cambiar de segmento no debe re-disparar la otra carga.
- **Detalle con tres vistas** (`EventDetailPage`, EV2): participante, inscrito, organizador — la misma pantalla cambia de composición según `Event.isOwnedByMe` y `myRegistrationStatus`.
- **Crear en 3 pasos con buscador de destino** (`CreateEventPage`, EV3): nombre/fecha/dificultad/precio → ruta y punto exacto (buscador contra **Nominatim**, no Mapbox — el mapa interactivo queda fuera hasta el Bloque 3, decisión D10) → foto y revisión. Al confirmar, crea en `draft`, sube la foto en el mejor esfuerzo, y publica (`draft → published`) en la misma acción — es la única transición que dispara `CreateEventUseCase`.
- **Inscripción con capa legal** (`RegistrationPage`, EV4): exige perfil completo (nombre, teléfono, contacto de emergencia) antes de habilitar el envío. Recoge opt-in médico (`shareMedicalInfo`, condiciona si se envían `bloodType`/`eps`), opt-in de contacto (`allowOrganizerContact`), aceptación de riesgo (`acceptsRisk`) y `consentVersion` fija (`v1.0`). **El timestamp real de consentimiento lo sella un trigger de la base con `now()`** — el valor que manda el cliente es solo la bandera que dispara el sello, nunca la evidencia legal en sí.
- **Edad mínima validada en servidor**: sin chequeo de edad en Dart. El repositorio traduce los errores Postgres `registration_requires_18_years_or_older` y `birth_date_required_for_registration` a `EventErrorCode`, y `duplicate key`/`event_registrations_event_id_user_id_key` a `alreadyRegistered`.
- **Inscritos del organizador con botón de llamar** (`EventRegistrantsPage`, EV5): lee la vista `event_registrations_for_organizer`, que ya llega con los campos enmascarados según los opt-in de cada inscrito (el cliente nunca decide qué ocultar). `openPhoneDialer()` abre el marcador nativo vía `tel:`, deshabilitado cuando el teléfono es `null` (enmascarado).
- **Cambio de ruta con aviso** (EV6): `AddRouteChangeUseCase` inserta en `event_route_changes`, un log inmutable (sin update/delete) — es el mecanismo detrás de "contingencias del día antes" del `ALCANCE-V2`.
- **Aviso de inicio atrasado** (EV7): `Event.isOverdueToStart` (publicado + hora de inicio ya pasada) se muestra como banner (`EventStartOverdueBanner`) y CTA de "iniciar" en el footer del organizador — aplica la lección de P-09: el ciclo de vida no puede depender de que alguien se acuerde de pulsar un botón sin que nadie se entere si no lo hace.
- **Navegación desde push FCM**: `EventPushNavigator` (singleton) escucha `onMessageOpenedApp`/`getInitialMessage` y navega al detalle del evento cuando el payload trae `eventId`. Tolerante a Firebase sin configurar.
- **Ver rodada en vivo** (`EventLiveRideBanner`, EV2): cuando el evento está `started` y quien mira es organizador o inscrito aprobado, CTA a la pantalla LV1 del feature `live_ride` (Bloque 3, desbloqueado el 2026-09-10). Si el rider ya tiene un SOS propio pendiente o confirmado, un banner encima ("SOS activo") lleva directo a la pantalla de SOS en vez de perderlo en el mapa — ver `docs/features/live_ride.md`.
- **Ciclo de vida**: `EventState` (`draft/published/started/finished/cancelled`) con las transiciones **impuestas por un trigger de base** (`enforce_event_state_transition`), nunca asumidas del lado cliente. El cliente dispara `draft→published` (al crear), `→started` (`StartEventUseCase`) y `→cancelled` (`CancelEventUseCase`); no se encontró una transición a `finished` disparada desde este feature — ocurre en otro punto del sistema (trigger o job), a verificar antes de asumir que el cliente la controla.

## Pantallas (Pencil)

Las páginas de eventos no llevan el comentario `/// Pencil: <id>` en el archivo de la página en sí — usan una numeración interna EV1–EV7 y referencian nodeIds solo en sub-widgets:

| Pantalla | Archivo | Referencia |
|---|---|---|
| Lista (EV1) | `presentation/pages/events_page.dart` / `events_list_view.dart` | control segmentado `j4t1js` |
| Detalle (EV2) | `presentation/pages/event_detail_page.dart` / `event_detail_view.dart` | fila de organizador referenciada como "EV2 — Organizador" |
| Crear (EV3) | `presentation/pages/create_event_page.dart` / `create_event_view.dart` | — |
| Inscripción (EV4) | `presentation/pages/registration_page.dart` / `registration_view.dart` | perfil incompleto `Mt9ij` |
| Inscritos del organizador (EV5) | `presentation/pages/event_registrants_page.dart` / `event_registrants_view.dart` | — |

## Datos

- Tabla `events`: `owner_id, name, description, route_text, meeting_point, start_at, difficulty, destination_name, destination_lat/lng, image_path, price, max_participants, state, started_at`.
- Vista `events_public`: nombre del organizador sin exponer `profiles` directamente; conteo de cupos vía `event_capacity`.
- Tabla `event_registrations`: `event_id, user_id, status, snapshot legal (full_name, phone, blood_type, eps, emergency_contact_*, share_medical_info, allow_organizer_contact, risk_accepted_at, medical_consent_at, consent_version)`.
- Vista `event_registrations_for_organizer`: enmascara datos médicos/contacto según los opt-in del inscrito, y extiende con la moto del inscrito.
- Tabla `event_route_changes`: log inmutable (`event_id, message, created_at`).
- **RPC `organizer_set_registration_status`** (`p_registration_id, p_status`): aprobar/rechazar inscripciones.
- Storage: bucket `event-images`, URL firmada TTL 1h.
- Fuente externa (no Supabase): **Nominatim** (`nominatim.openstreetmap.org/search`) para el buscador de destino, con `User-Agent` propio requerido.
- Migración `20260909000020_events_f7_gaps.sql`: agrega `events.meeting_point`, el bucket `event-images`, la vista `events_public`, `event_capacity` y extiende `event_registrations_for_organizer` con la moto del inscrito.

## Estados

`EventsListCubit`: dos `ResultState<List<Event>>` independientes (próximas / mías). `EventDetailCubit`: `event`, `routeChanges` y `action`, tres `ResultState` independientes. `CreateEventCubit`: estado propio con paso del asistente, un `ResultState<List<DestinationSuggestion>>` para el buscador y una `submission: ResultState<Unit>`. `RegistrationCubit`: `profile`, `vehicles` (independientes) más los toggles de consentimiento y `submission`. `RegistrantsCubit`: `ResultState<List<EventRegistrant>>`.

Obligatorios: skeleton (`SkeletonList`), vacío (`EmptyStateView`, usado dos veces en inscritos: sin inscritos / filtro sin resultados), error con reintentar (`ErrorStateView`), sin conexión (`OfflineStateView`, gateado por `ConnectivityCubit`). Sin permiso de ubicación / sin GPS no aplican todavía: el buscador de destino usa texto contra Nominatim, no la ubicación del dispositivo — eso es explícitamente Bloque 3.

## Pendientes

- Ninguna nota `TODO`/`FIXME`/pendiente encontrada en el código de esta feature (solo coincidencias falsas con la palabra "independientes").
- Verificar dónde se dispara la transición a `finished` — no está en este feature; documentar su origen real antes de asumir un flujo cliente-controlado.
- Ninguna página de eventos lleva el comentario `/// Pencil: <id>` estándar — a diferencia de garaje/documentos/mantenimiento. Si se vuelve a tocar el feature, vale la pena alinear la convención.
- El Bloque 3 (mapa en vivo, tracking, SOS) se desbloqueó el 2026-09-10 y ya está implementado como feature propio `live_ride` — ver `docs/features/live_ride.md`. Este feature solo aporta el CTA de entrada (`EventLiveRideBanner`) cuando el evento está `started`.
