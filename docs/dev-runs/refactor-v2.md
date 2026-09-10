# Cierre — refactor total v2

> Artefacto de cierre de la corrida de refactor descrita en `docs/plans/refactor-v2-plan.md`. Rango: `main..HEAD` en `refactor/v2` (HEAD `ce47630a` al momento de escribir esto). No commitea nada por sí mismo.

## Qué se construyó, por fase

El plan definía F1–F8; lo que sigue es lo que de verdad quedó en el árbol, con nombres y conteos de `git log --stat main..HEAD`.

### F1 — Diseño (Pencil)

Commits: `f94e004c` (identidad y primeras pantallas), `fa341817` (cierre de mantenimiento v2 y reorganización del canvas por feature), `dca79bcd` (fase 0 y correcciones de mantenimiento), `bdcfbf29` (Design refactor, part 1 — 18.443 líneas del `.pen` tocadas), `1db2ce39` (eventos y estados genéricos, notas de review resueltas, canvas aprobado). Resolvió las 19 notas del canvas heredadas, borró 10 frames huérfanos y L1, y diseñó eventos completo (lista, detalle, crear en pasos, inscripción con consentimientos, asistentes del organizador, estados genéricos sin permiso de ubicación / sin GPS para el Bloque 3 futuro).

### F2 — Supabase

Commit `45aef6c2` (**feat(supabase): esquema v2 con RLS, vistas de enmascarado, Storage, Edge Functions y pruebas de RLS** — 1152 archivos, +2021/−119259; el grueso del borrado es el `lib/`, `test/` e `integration_test/` de la v1 que se fue en el mismo commit por decisión D2). Dejó 20 migraciones (`supabase/migrations/20260909000001` a `...000016`), RLS desde el día uno, vistas de enmascarado, Storage y Edge Functions (`delete-account` entre ellas), verificadas con `supabase test db`.

### F3 — Cimientos Flutter

Commit `968c47fa` (**feat(core): cimientos v2 — tema C2, design system desde Pencil, estados obligatorios, router, DI y Supabase** — 76 archivos, +4089/−641). `pubspec` limpio de Dio/Retrofit/Firestore/Mapbox; tema claro/oscuro desde los tokens `$c-*`; `design_system/` con los componentes reutilizables; router con shell y Pill Tab Bar; DI; `ResultState`; estados obligatorios (skeleton, vacío, error con reintentar, sin conexión); l10n limpio; Sentry/Analytics.

### F4 — Auth + Perfil + Cuenta

Commit `85928eea` (**feat(auth,profile): F4** — 109 archivos, +6880/−149), sobre `10232dfa` (merge de F4 sobre F5). Bienvenida L2, Supabase Auth (Google/Apple/correo), perfil editable, borrado de cuenta en 4 pasos contra `delete-account` con bloqueo si el rider organiza una rodada activa, registro del token FCM en `device_tokens`.

### F5 — Garaje + Documentos

Commit `2648e182` (**feat(garage,documents): F5** — 101 archivos, +5906/−19). Galería en dos columnas, alta por placa en dos pasos, buscador de marca, foto a Storage con URL firmada, SOAT/RTM con OCR portado, visor con caché offline en `ApplicationSupportDirectory` (D7), recordatorios locales 30/7/1 días. Migración `20260909000017_vehicles_engine_cc.sql` (el `.pen` pedía cilindraje, no estaba en el modelo original). **Desviaciones documentadas en el propio commit**: la fila de documentos y archivar/restaurar en editar moto no estaban en el frame aprobado `tbZKM`; la captura de documento usa la cámara nativa de `image_picker` en vez del overlay de encuadre custom de `rbRuw`.

### F6 — Mantenimiento

Commit `a5e77ecc` (**feat(maintenance): agenda, historial, registro en 3 pasos y detalle** — 89 archivos, +6218/−53), sobre `315ec467` (merge de F6 sobre F4+F5). Agenda derivada (`MaintenanceAgendaCalculator`) e historial agrupado, ambos puros y con unit tests. RPC `register_maintenance` (migración `20260909000019_register_maintenance.sql`, renumerada desde `...017` por colisión con la migración de garaje — ver "Trampas conocidas" en `CLAUDE.md`) que inserta y actualiza el odómetro atómicamente (D5). 19 frames de Pencil mapeados 1:1.

### F7 — Eventos + Inscripción

Commit `ce47630a` (**feat(events): F7 rodadas e inscripción (EV1-EV7)** — 122 archivos, +7637/−28). Lista, detalle con tres vistas, creación en 3 pasos con buscador de destino contra Nominatim, inscripción con snapshot legal y consentimientos sellados por el servidor, inscritos del organizador vía `event_registrations_for_organizer`, cambio de ruta, aviso de inicio atrasado (EV7) y navegación desde push FCM. Migración `20260909000020_events_f7_gaps.sql` (meeting_point, bucket `event-images`, vista `events_public`, `event_capacity`). 89 tests (`flutter test` verde), `dart analyze` limpio, `flutter build apk --flavor dev` compila.

### F8 — Cierre

Este mismo artefacto, la actualización de `CLAUDE.md` y la reescritura de `docs/features/`. Sin commit propio todavía — lo hace el humano al revisar.

## Decisiones tomadas (de `docs/plans/refactor-v2-plan.md`)

| # | Decisión | Razón |
|---|---|---|
| D1 | **Identidad C2**: Outfit, amarillo `#FFD400` en dosis baja, tema claro y oscuro. Los tokens `$c-*` del `.pen` son la fuente. `CLAUDE.md` se corrige (la tabla Asphalt queda obsoleta) | Cerrado en el frame `POD7C` del `.pen` |
| D2 | `lib/`, `test/` e `integration_test/` se borran en `refactor/v2` y se reconstruyen. La referencia de comportamiento es `git show main:lib/...`. Se puede portar (copiar y adaptar) solo código puro y probado: `ResultState`, el servicio OCR, los catálogos de ciudades y marcas, el `pii_denylist`, y keys del `.arb` que sigan teniendo pantalla | El contrato lo exige; portar lo puro ahorra un día |
| D3 | Bienvenida = L2 (con propósito) con Google, Apple y correo en la misma pantalla. L1 se elimina | Deseabilidad fue la razón del rediseño; L2 explica para qué sirve la app |
| D4 | Pestaña de entrada: MANTENIMIENTO | Único uso real; ya decidido el 2026-08-19 |
| D5 | Odómetro derivado del último mantenimiento registrado; corrección manual desde el detalle de la moto | ALCANCE-V2 |
| D6 | Recordatorios de vencimiento (SOAT, RTM, próximo servicio) son notificaciones locales programadas en el dispositivo, con toggles por documento. FCM se reserva para inicio de rodada y cambio de ruta (Bloque 2) | Sin servidor propio; local es lo único que funciona sin señal |
| D7 | Caché de documentos en `ApplicationSupportDirectory`, nunca en temp. Se descarga al subir y al abrir; el visor sin conexión lee de ahí | P-12 |
| D8 | Auth: Supabase Auth con Google, Apple y correo+contraseña. Sin recuperar cuentas Firebase: los pocos usuarios crean cuenta de nuevo el día del corte | Migración no bloqueante (memoria del proyecto) |
| D9 | Supabase local (`supabase start`) para todo el desarrollo y QA. No existe aún proyecto remoto de Rideglory; crearlo es tarea del humano antes de producción | Regla del contrato |
| D10 | Evento sin mapa interactivo: la ruta es texto + destino con punto exacto (lat/lng elegido con buscador de lugares, mostrado como imagen estática o link) | Bloque 3 bloqueado; Mapbox fuera de v2 |
| D11 | Eventos: aviso de inicio = `pg_cron` + Edge Function que a la hora de inicio, si el organizador no pulsó "iniciar", manda push a organizador e inscritos | P-09 |
| D12 | Edad ≥ 18 validada con `CHECK`/trigger en la inscripción; sellos de consentimiento con `now()` del servidor e inmutables (trigger que impide `UPDATE`) | Requisito legal |

## Pendiente para el humano antes de producción

- **Crear el proyecto Supabase remoto de Rideglory** — hoy solo existe el local (`supabase start`). Todas las migraciones (20 archivos en `supabase/migrations/`) deben aplicarse ahí.
- **Secret `FCM_SERVICE_ACCOUNT_JSON`** (u otro nombre que use la Edge Function de push) para que el envío de notificaciones funcione fuera de local.
- **Webhook de `notify-route-change`** — configurar el disparo real (hoy corre contra Supabase local sin webhook externo conectado).
- **Reemplazar la service-role key del cron** (`pg_cron` / `cron_watchdog`, migración `20260909000015_cron_watchdog.sql`) — la que hay en local no sirve en producción.
- **Configurar Google y Apple en Supabase Auth** (client IDs, redirect URIs, Service ID de Apple) — el código ya llama a `signInWithIdToken`, pero el proveedor no está dado de alta en ningún proyecto remoto.
- **iOS flavors en Xcode** — los flavors `dev`/`prod` están resueltos en Android/Flutter; falta la configuración de esquemas en Xcode (nota heredada de memoria del proyecto, no verificada como resuelta en esta corrida).
- **Páginas legales reales** (política de privacidad, términos) — `legal_links.dart` existe en `profile/presentation/` pero apunta a contenido pendiente de redactar por `privacy-legal-officer` contra el código real.
- **Día del corte**: `pg_dump` de la EC2 del backend NestJS viejo, restaurarlo una vez en local para comprobar que sirve, migrar lo recuperable a Supabase (no bloqueante — si falla, se arranca con la base vacía), y apagar la instancia. Rescatar antes los `.env` de cada microservicio y lo configurado a mano en el servidor (crontab, systemd, nginx, certificados).

## Lo que quedó pendiente dentro del propio código (agentes)

- **Garaje (F5)**: la fila de documentos y archivar/restaurar en `VehicleEditPage` no están en el frame aprobado `tbZKM` del `.pen` — hay que reconciliar el frame o retirar la funcionalidad.
- **Documentos (F5)**: la captura usa la cámara nativa de `image_picker` en vez del overlay de encuadre custom del frame `rbRuw` (no se agregó la dependencia `camera`).
- **Mantenimiento (F6)**: la actualización de odómetro al **editar** un mantenimiento no es atómica con el `update` del registro (dos llamadas separadas), a diferencia de **crear**, que sí lo es vía RPC `register_maintenance`.
- **Eventos (F7)**: ninguna página del feature lleva el comentario `/// Pencil: <id>` estándar que sí usan garaje/documentos/mantenimiento (usa una numeración interna EV1–EV7 en su lugar). No se identificó dentro del feature dónde se dispara la transición de evento a `finished` — no está en `lib/features/events/`, hay que rastrear su origen real antes de asumir que el cliente la controla.
- **`local_notifications_initializer.dart`**: pendiente conocido y documentado en el propio código — sin `flutter_native_timezone` (fuera de alcance), asume Colombia en UTC-5 fijo todo el año, lo cual es correcto porque el país no tiene horario de verano, pero es una asunción explícita, no una detección real de zona horaria.
- **`social_auth_button.dart`**: el `.pen` todavía no tiene terminado el nodo de logo (comentario "Logo (pendiente)" en el código).
- **`ConsentsPage` y `EditProfilePage`**: sin frame de Pencil documentado en comentarios del código — a diferencia del resto de pantallas de perfil.

## Bloque 3 — todavía no empieza

Mapa en vivo, tracking, SOS y detección de rezagados **no se diseñan ni se implementan** hasta que el experimento 1 de `docs/product/validacion.md` diga qué se abre y cuándo. La regla de seguridad del rider en `CLAUDE.md` sigue describiendo la v2 que hay que construir, no comportamiento existente — nada de esto cambió en esta corrida.
