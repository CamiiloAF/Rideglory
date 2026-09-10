# Plan maestro · refactor v2 (2026-09-09 → 2026-09-10)

> Artefacto de orquestación. Lo escribe el orquestador (Fable) y lo ejecutan agentes Sonnet.
> Alcance fijado por `docs/product/ALCANCE-V2.md`: **Bloques 0, 1 y 2**. El Bloque 3 (mapa, tracking, SOS) queda fuera hasta el experimento 1.

## Decisiones tomadas por el orquestador (no rediscutir)

| # | Decisión | Razón |
|---|---|---|
| D1 | **Identidad C2**: Outfit, amarillo `#FFD400` en dosis baja, tema claro y oscuro. Los tokens `$c-*` del `.pen` son la fuente. CLAUDE.md se corrige (la tabla Asphalt queda obsoleta) | Cerrado en el frame `POD7C` del `.pen` |
| D2 | **`lib/`, `test/` e `integration_test/` se borran en `refactor/v2` y se reconstruyen.** La referencia de comportamiento es `git show main:lib/...`. Se puede *portar* (copiar y adaptar) solo código puro y probado: `ResultState`, el servicio OCR, los catálogos de ciudades y marcas, el `pii_denylist`, y keys del `.arb` que sigan teniendo pantalla | El contrato lo exige; portar lo puro ahorra un día |
| D3 | **Bienvenida = L2 (con propósito)** con Google, Apple y correo en la misma pantalla. L1 se elimina | Deseabilidad fue la razón del rediseño; L2 explica para qué sirve la app |
| D4 | **Pestaña de entrada: MANTENIMIENTO** | Único uso real; ya decidido el 2026-08-19 |
| D5 | **Odómetro derivado** del último mantenimiento registrado; corrección manual desde el detalle de la moto | ALCANCE-V2 |
| D6 | **Recordatorios de vencimiento (SOAT, RTM, próximo servicio) son notificaciones locales** programadas en el dispositivo, con toggles por documento. FCM se reserva para inicio de rodada y cambio de ruta (Bloque 2) | Sin servidor propio; local es lo único que funciona sin señal |
| D7 | **Caché de documentos en `ApplicationSupportDirectory`**, nunca en temp. Se descarga al subir y al abrir; el visor sin conexión lee de ahí | P-12 |
| D8 | **Auth: Supabase Auth** con Google, Apple y correo+contraseña. Sin recuperar cuentas Firebase: los pocos usuarios crean cuenta de nuevo el día del corte | Migración no bloqueante (memoria del proyecto) |
| D9 | **Supabase local** (`supabase start`) para todo el desarrollo y QA. **No existe aún proyecto remoto de Rideglory**; crearlo es tarea del humano antes de producción | Regla del contrato |
| D10 | **Evento sin mapa interactivo**: la ruta es texto + destino con punto exacto (lat/lng elegido con buscador de lugares, mostrado como imagen estática o link) | Bloque 3 bloqueado; Mapbox fuera de v2 |
| D11 | **Eventos: aviso de inicio** = `pg_cron` + Edge Function que a la hora de inicio, si el organizador no pulsó "iniciar", manda push a organizador e inscritos | P-09 |
| D12 | Edad ≥ 18 validada con `CHECK`/trigger en la inscripción; sellos de consentimiento con `now()` del servidor e inmutables (trigger que impide `UPDATE`) | Requisito legal |

## Modelo de datos (Supabase)

`profiles` (1:1 con `auth.users`: full_name, phone, birth_date, residence_city, eps, medical_insurance, blood_type, emergency_contact_name/phone, medical_consent_accepted_at, deleted_at) ·
`vehicles` (owner_id, name, brand, model, year, license_plate, current_mileage, image_path, is_main, archived_at) ·
`maintenances` (vehicle_id, type, service_date, odometer, cost, workshop, notes, next_date, next_odometer) ·
`vehicle_documents` (vehicle_id, kind soat|rtm, number, issuer, start_date, expiry_date, file_path, reminder_enabled) ·
`events` (owner_id, name, description, route_text, start_at, difficulty, destination_name, destination_lat/lng, image_path, price default 0, max_participants, state draft|published|started|finished|cancelled, started_at) ·
`event_registrations` (event_id, user_id, status, snapshot legal: full_name, phone, blood_type, eps, emergency_contact_*, share_medical_info, allow_organizer_contact, risk_accepted_at, medical_consent_at, consent_version) ·
`event_route_changes` (event_id, message, created_at) · `device_tokens` (user_id, token, platform) · `consent_log` (user_id, kind, version, accepted_at) — inmutable, sobrevive a la anonimización.

**RLS**: cada fila la ve su dueño; eventos publicados los ve cualquier autenticado; el organizador ve las inscripciones de su evento **a través de una vista** `event_registrations_for_organizer` que solo expone datos médicos si `share_medical_info` y contacto si `allow_organizer_contact`. **Storage**: buckets privados `vehicle-images` y `documents` con política por `owner_id` en la ruta. **Borrado de cuenta**: Edge Function `delete-account` que anonimiza `profiles`, borra vehículos/documentos/Storage, conserva `consent_log`, y elimina el usuario de `auth`.

## Fases

| Fase | Qué | Agentes (Sonnet) | Gate |
|---|---|---|---|
| **F1 Diseño** | Resolver las 19 notas del canvas, borrar 10 frames huérfanos y L1. Diseñar **Eventos** (lista, detalle, crear en pasos, inscripción con consentimientos, asistentes del organizador con botón llamar, estados). Diseñar estados genéricos sin permiso de ubicación / sin GPS (para Bloque 3 futuro, solo componente). Aprobar borradores de garaje, auth, documentos, perfil, estados de mantenimiento | pencil-designer, ui-ux-reviewer | Orquestador aprueba con screenshots |
| **F2 Supabase** | `supabase init`, migraciones, RLS, vistas, triggers, Storage, Edge Functions `delete-account`, `event-start-watchdog`, `notify-route-change`; seed de QA (qa1/qa2) | supabase-backend-dev, sql-migration-helper | RLS probada con `supabase test db` o script SQL de asserts |
| **F3 Cimientos Flutter** | Borrar `lib/` viejo. pubspec nuevo (quita dio/retrofit/firestore/mapbox/foreground_task/quill; añade supabase_flutter, connectivity_plus, flutter_local_notifications ya está). Tema C2 claro/oscuro desde tokens del `.pen`, `design_system/` con los 17 componentes reutilizables, router con shell y Pill Tab Bar, DI, `ResultState`, estados obligatorios (skeleton, vacío, error con reintentar, sin conexión), l10n limpio, Sentry/Analytics | flutter-dev | `dart analyze` limpio, app arranca en flavor dev |
| **F4 Auth + Perfil + Cuenta** | Bienvenida L2, correo, recuperar, errores. Perfil P1/P2, contacto de emergencia, borrar cuenta 4 pasos, consentimientos | flutter-dev, qa-automator | reviewers |
| **F5 Garaje + Documentos** | Galería, alta por placa, editar, archivar, principal, foto a Storage. SOAT/RTM: subir (cámara/archivo, OCR portado para SOAT), visor con caché, recordatorios locales | flutter-dev, qa-automator | reviewers + fidelity |
| **F6 Mantenimiento** | Agenda+historial, registrar en 3 pasos, detalle, borrar con confirmación, intervalo, recordatorio, odómetro derivado | flutter-dev, qa-automator | reviewers + fidelity |
| **F7 Eventos + Inscripción** | Lista, detalle, crear/publicar, cambio de ruta con aviso, iniciar/finalizar, inscripción legal, asistentes del organizador con llamar, push FCM | flutter-dev, supabase-backend-dev, qa-automator | safety-compliance-reviewer (gate) |
| **F8 Cierre** | `feature-review` sobre todo, Patrol mínimo por feature, docs/features actualizadas, CLAUDE.md corregido, `docs/dev-runs/refactor-v2.md` | reviewers | humano commitea |

Orden real: F1 ∥ F2 ∥ F3 hoy; F4 ∥ F5 ∥ F6 mañana temprano; F7 mañana; F8 cierre. Commit al cerrar cada fase.

## Presupuesto de cuota

Ejecución en Sonnet; Fable solo lee resúmenes y screenshots. Checkpoint de `/usage` al cerrar cada fase. Recortes en orden si hace falta: goldens → Patrol → reviewer de UI → segundo reviewer.

---

## Bloque 3 · En marcha (2026-09-10)

**Desbloqueo:** el fundador decidió el 2026-09-10 abrir el Bloque 3 sin esperar el experimento 1 (*"Demos todo por cerrado hoy"*). Las premisas de `ALCANCE-V2.md` §Bloque 3 se mantienen como criterios de aceptación; lo que el experimento iba a decidir se resolvió así:

| Decisión | Qué se decidió | Por qué |
|---|---|---|
| D13 Mapa | **`flutter_map` + `latlong2`** con tiles raster por URL (OpenStreetMap en dev; en prod una URL de MapTiler/Mapbox raster con token en `config/prod.json`, clave `MAP_TILE_URL`) | Sin SDK nativo, sin token para arrancar, renderiza en goldens. Mapbox SDK queda fuera (frágil, token secreto en Gradle) |
| D14 Ubicación en segundo plano | `geolocator` + `flutter_foreground_task` (Android foreground service con notificación persistente que incluye **Detener**); iOS `location` en `UIBackgroundModes` | Mismo enfoque que la v1, que sí funcionó; la parada es accesible desde la notificación aunque la app esté cerrada |
| D15 Transporte de posiciones | Tabla `live_positions` (una fila por rider y evento, **upsert** cada 5 s o 25 m) + **Supabase Realtime (postgres_changes)** filtrado por `event_id`. Sin Broadcast | Un solo transporte, durable: quien entra tarde ve la última posición; la última posición de un SOS queda en la base |
| D16 SOS | Tabla `sos_alerts` (`active`/`closed`, `closed_by`, timestamps sellados por el servidor). Cliente: **cola local persistente antes de la red** (`shared_preferences`, JSON), envío por RPC `raise_sos` que devuelve la fila confirmada, reintento al recuperar conectividad y al abrir la app. UI: `pendiente` (no salió) vs `confirmado` (el servidor respondió). Push a los participantes por Edge Function `notify-sos` (webhook de BD) + Realtime para el banner in-app | Reglas de seguridad de `CLAUDE.md`: nunca falla en silencio, nunca dice "enviado" sin confirmación |
| D17 Fallback sin datos | Al iniciar el tracking se cachea **contacto de emergencia + teléfono del organizador**. La pantalla de SOS activo ofrece **Llamar a mi contacto** y **SMS con coordenadas** (url_launcher) aunque no haya red | Los datos no se leen durante la emergencia |
| D18 ¿123? (P-05) | **Rideglory no llama al 123 automáticamente, nunca.** Hay un botón terciario "Llamar al 123" que marca el número solo si el rider lo pulsa | El SOS es de rescate entre pares; llamar a emergencias es decisión explícita del rider |
| D19 Cierre del SOS | Solo lo cierra **el rider que lo emitió o el organizador** (RPC `close_sos`); un trigger impide cerrarlo al terminar el evento o al perder conexión. Un SOS abierto sigue visible tras terminar la rodada | Regla "el SOS solo lo cierra una persona" |
| D20 Rezagados | **No se construye detección automática.** El organizador ve por rider distancia al líder y "sin señal hace X min"; nunca una alarma | P-07: tasa base de paradas normales desconocida |
| D21 Consentimiento | Hoja propia (`LV2`) antes del diálogo del sistema, **solo al pulsar "Compartir mi ubicación"**, nunca en splash ni al abrir el evento. Primero *mientras usa la app*; *todo el tiempo* se pide en un segundo paso explicando la notificación persistente. Indicador visible mientras está activa y **Detener** siempre a un toque | Prominent disclosure Play / Apple 5.1.5 |
| D22 Fin del tracking | Termina por: Detener del rider, fin del evento (estado `finished` visto por Realtime o al reabrir), o cierre de sesión. Cada una **para el servicio nativo** y borra la fila de `live_positions`. **Ninguna cierra un SOS** | "El tracking en background termina de verdad" |
| D23 Uso en marcha | La pantalla en vivo se diseña para **paradas**, no para el manubrio (P-16, Waze). Elementos grandes, una mano, dos segundos. El SOS también es accesible desde el detalle del evento en curso y desde la notificación persistente | Uso declarado |

### Fases

| Fase | Contenido | Ejecuta |
|---|---|---|
| **F9 Diseño** | LV1 Rodada en vivo (mapa + hoja de riders), LV2 aviso previo de ubicación, LV3 confirmar SOS (mantener pulsado), LV4 SOS activo propio (pendiente/confirmado + fallbacks + cerrar), LV5 SOS de otro rider (banner + tarjeta con distancia, llamar, ver en mapa), LV6 lista de riders del organizador, estados sin permiso / sin GPS / sin conexión / carga / vacío | pencil-designer + ui-ux-reviewer |
| **F10 Backend** | `live_positions`, `sos_alerts`, RPCs `upsert_live_position`, `raise_sos`, `close_sos`, `end_live_ride`, RLS (solo participantes aprobados + organizador del evento en curso), vistas de enmascarado, Realtime habilitado, Edge Function `notify-sos`, pgTAP | supabase-backend-dev |
| **F11 App** | Feature `live_ride`: dominio, datos, servicios (ubicación, foreground task, cola SOS), cubits y pantallas según Pencil; integración en detalle de evento (CTA "Ver rodada en vivo" cuando `started`) | flutter-dev |
| **F12 Cierre** | Tests unit/widget/golden, suite Patrol, safety gate, reviews, fidelidad visual, docs | qa-automator, reviewers |
