# PO Proposal — Rideglory Iterations (Redesign-First Replan)

> Generated: 2026-05-13
> Run mode: FEEDBACK_REPLAN
> Key change: Redesign iteration inserted as iter-5; prior iters shifted to 6–9

---

## Summary

The human reviewer has flagged that the existing screens require significant visual and UX updates to align with the final `rideglory.pen` design system before new features are layered on top. Shipping a polished, consistent UI baseline first avoids compounding visual debt across every new screen built in iters 6–9.

**Iter-5** is now a pure UI/UX Redesign iteration covering 14 existing screens across splash, auth, home, events, garage, and maintenances. No new features. No new backend endpoints. No domain logic changes. Frontend-only visual polish pass.

All prior iterations are renumbered +1. Their content is unchanged.

Critical path: iter-5 → iter-6 → iter-7 → iter-8 → iter-9. No parallelization possible.

---

## Iteration numbering change

| Prior ID | New ID | Goal |
|----------|--------|------|
| 5 | 6 | SOAT + Notification Foundation |
| 6 | 7 | Tracking Completo + SOS + Maintenance Reminders |
| 7 | 8 | Seguidores + Perfil Completo |
| 8 | 9 | Deep Links + Apple Sign-In + Notification Routing |

---

## Proposed iterations

---

### Iteration 5: UI/UX Redesign

**Goal:** Bring all existing screens into alignment with the final `rideglory.pen` design system — typography, spacing, color tokens, component usage, empty states, loading states.

**Scope:** 14 screens across splash, auth, home, events, garage, and maintenances.

**What this is NOT:** New features. No new backend endpoints. No new domain logic. No new routes. The features already work — this is a visual and UX polish pass only.

**What redesign means concretely:**
- Layout fixes and spacing corrections to match Pencil frames
- Typography alignment (Space Grotesk applied consistently, correct weights and sizes)
- Component replacements: `ElevatedButton` → `AppButton`, raw `TextFormField` → `AppTextField`, raw `AlertDialog` → `AppDialog`
- Color token fixes: hardcoded hex literals replaced with `Theme.of(context).colorScheme.<property>` or `AppColors` constants
- Empty state improvements (correct illustrations, correct copy from `app_es.arb`)
- Loading state improvements (correct shimmer or spinner placement, correct sizing)
- Bottom navigation pill bar aligned with Pencil frame `VMmN0`
- Preservation of all iter-4 features (AI cover generation widget must remain fully functional after redesign)

**Pre-flight (before any code):**
- [ ] Designer runs `solo-design` to inspect all relevant Pencil frames in `rideglory.pen` via Pencil MCP
- [ ] Gap analysis document written listing every screen with specific mismatches (component, spacing, color, typography) before any Flutter code is touched
- [ ] Design gate confirmed: all 14 frames inspected, HTML mockups produced for any frame requiring clarification
- [ ] `dart analyze` passing cleanly on `main` branch before redesign begins (no pre-existing violations)

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 5.1 | As a designer reviewing existing screens, I can identify all visual gaps between the current implementation and `rideglory.pen` frames, documented in a gap analysis. | Gap analysis document lists every screen (all 14) with specific mismatches: component name, spacing value, color token, typography rule. Document reviewed and approved before any Flutter code changes begin. |
| 5.2 | As a rider opening the app, I see the splash screen with the correct logo, loading state indicator, and overall layout matching the `rideglory.pen` design. | Splash screen layout, logo sizing, background color, and loading indicator match the Pencil frame exactly. Catalog loading states (loading, error, success) handled visually. No hardcoded colors. |
| 5.3 | As a rider on the auth screens (login, signup, password recovery), the pages use `AppButton`, `AppTextField`, `AppPasswordTextField`, correct typography, and the exact color tokens from the design system. | No `ElevatedButton`, no `TextFormField` direct usage, no hardcoded color literals on any auth screen. `AppButton` used for all primary and secondary actions. Space Grotesk applied. Password recovery confirmation screen matches design. |
| 5.4 | As a rider on the Home Dashboard, the layout matches the `rideglory.pen` frame `dyWWs` — including the greeting header, garage card (main vehicle + empty state), upcoming rides section (horizontal scroll + empty state), and bottom navigation pill bar. | Frame `dyWWs` matched: correct spacing, correct card border radius (12px cards, 24px bottom sheets), correct color tokens. Bottom nav pill bar matches frame `VMmN0`. SOAT badge placeholder not included (iter-6). No layout regressions vs. current behavior. |
| 5.5 | As a rider browsing Events, the events list page and event detail page match the `rideglory.pen` frames `Neipf` and `kAubW` — including event cards, badges (`zKkmE`), filter chips, the filter bottom sheet, and the CTA bar on event detail. | Event list: search bar, filter chips, event cards (image overlay, badge, organizer avatar, chips) match frame `Neipf`. Event detail: hero image, metric chips, map preview, allowed brands chips, CTA bar match frame `kAubW`. Filter bottom sheet layout correct. |
| 5.6 | As a rider creating an event, the Create/Edit Event form matches the `rideglory.pen` frame `zbCa0` — correct input fields, layout sections, difficulty selector, and button styles. | Form layout matches frame `zbCa0`. AI cover generation widget (iter-4 feature) is preserved and functional. Mapbox route preview widget unchanged. All inputs use `AppTextField`. `AppButton` used for primary actions. |
| 5.7 | As a rider viewing the Garage, the vehicle list page and vehicle detail page match `rideglory.pen` frames `KCf6W` and `P1GSzZ` — including the main vehicle card, "other vehicles" list, spec chips, and document slots. | Vehicle list matches frame `KCf6W`: main vehicle card with full-width image, stats chips, quick-access buttons; compact other-vehicles list. Vehicle detail matches frame `P1GSzZ`: specs, document badges, action buttons. All states (loading, empty, data, error) visually correct. |
| 5.8 | As a rider adding or editing a vehicle, the Add/Edit vehicle form matches `rideglory.pen` frame `EqnMm` — correct field layout, image upload UI, and step structure. | Form fields, image upload banner, and section layout match frame `EqnMm`. Document slot section (SOAT, tech review) UI is present but non-functional pending iter-6. `AppTextField` and `AppButton` used throughout. |
| 5.9 | As a rider viewing Maintenance, the dashboard, history list, and new maintenance forms match `rideglory.pen` frames `Ako7u` (dashboard), `SykjL` (history), `J5h6P` (step 1), `eK2WW` (step 2 — completed), and `ELB5u` (step 2 — scheduled). | All 5 maintenance frames matched. Dashboard: donut chart health indicator, urgency color coding (red/yellow/green) correct. History: year grouping, cost summary, chronological order. Filters bottom sheet (frame `v6RqaX`) layout correct. Step 1 grid 2×4 card layout correct. Step 2 tab (Completado / Programado) layout correct. |

**Optional story (include if scope permits — flag for architect assessment):**

| ID | Story | Acceptance |
|----|-------|-----------|
| 5.10 | As a rider viewing their registrations, the My Registrations list and Registration Detail pages match `rideglory.pen` frames `oUv12` and the registration list layout. | Registration list and detail pages use design system components throughout; no hardcoded colors; empty and loading states correct. |

**Definition of done:**
- [ ] Design gate: Pencil MCP used to inspect all 14 `rideglory.pen` frames before implementation; HTML mockups produced for any frame requiring clarification
- [ ] Gap analysis document written and reviewed before any Flutter code changes begin
- [ ] `dart analyze` passes with zero new violations (violations pre-existing before iter-5 are tracked but not required to be fixed in this iteration)
- [ ] All existing `flutter test` cases pass — zero regressions
- [ ] No new backend endpoints (this is frontend-only)
- [ ] All replaced components use design system atoms: `AppButton`, `AppTextField`, `AppPasswordTextField`, `AppDialog`, `ConfirmationDialog`
- [ ] All hardcoded color hex literals replaced with `Theme.of(context).colorScheme.<property>` or `AppColors` constants
- [ ] `app_es.arb` updated if any UI copy changes were made during redesign
- [ ] Bottom navigation pill bar (`VMmN0`) implemented consistently across all shell screens
- [ ] Event badge component (`zKkmE`) used in all event card contexts
- [ ] Iter-4 AI cover generation widget verified functional after all changes
- [ ] No new routes, no new domain models, no new use cases introduced

---

### Iteration 6: SOAT + Notification Foundation

**Goal:** Allow riders to register and track their SOAT per vehicle, and receive push notifications for critical lifecycle events. Establishes the FCM infrastructure and persistent notification backend that every later iteration depends on.

> Same as prior iter-5. All stories renumbered 5.x → 6.x. Pre-flight, DoD, and risks unchanged.

**Pre-flight (before any code):**
- [ ] Create `seed.ts` in `vehicles-ms` with at least 2 test vehicles; add `"prisma": { "seed": "ts-node prisma/seed.ts" }` to `package.json`
- [ ] Create `seed.ts` in `events-ms` with at least 1 test event in `scheduled` state and 1 test registration
- [ ] Create `seed.ts` stubs in `users-ms` and `maintenances-ms` (empty, with comments for future data)
- [ ] Run `npx prisma migrate reset --force` in `events-ms`, `vehicles-ms`, `users-ms`, `maintenances-ms`
- [ ] Run `npx prisma migrate status` in each of the 4 services to verify migration history is clean
- [ ] In `api-gateway/` (FIRST-TIME setup, not reset): run `npx prisma init`, create `schema.prisma` with `Notification` model, configure `DATABASE_URL`, run `npx prisma migrate dev --name init_notifications`, generate client
- [ ] Add `@nestjs/schedule` to `api-gateway/package.json`: `npm install @nestjs/schedule`
- [ ] Verify `GET /api/vehicles` returns 200 with empty list in local environment

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 6.1 | Como rider, puedo subir el documento de mi SOAT (foto o PDF desde galería/cámara) para un vehículo de mi garaje y guardar los datos (número de póliza, fechas, aseguradora) en el backend. | El documento queda guardado; el badge del vehículo cambia a "Vigente" o "Por vencer" según la fecha de vencimiento. |
| 6.2 | Como rider, puedo ingresar manualmente los datos de mi SOAT (número de póliza, fecha inicio, fecha vencimiento, aseguradora) cuando no quiero subir el documento. | El formulario valida que la fecha de vencimiento sea obligatoria; al guardar el estado SOAT refleja la lógica de vigencia correcta. |
| 6.3 | Como rider, veo en el detalle de mi vehículo un badge de estado SOAT (Sin SOAT / Vigente / Por vencer / Vencido) y puedo tocar el badge para ir al flujo de SOAT. | Los cuatro estados se calculan correctamente con base en la fecha de vencimiento vs. hoy; el badge es tap-able y navega al flujo correcto. |
| 6.4 | Como rider, recibo una notificación push 30 días antes, 7 días antes y el día del vencimiento de mi SOAT con el nombre de la moto afectada. | Las tres notificaciones llegan al dispositivo en las fechas correctas y se muestran en el centro de notificaciones. (Navegación al tocar la notificación: iter-9.) |
| 6.5 | Como organizador de evento, recibo una notificación push cuando un nuevo rider se inscribe a mi evento. | La notificación aparece en el centro de notificaciones; el badge de no leídas en el ícono de campana se incrementa. (Navegación al tocar la notificación: iter-9.) |
| 6.6 | Como rider inscrito, recibo una notificación push cuando mi inscripción es aprobada o rechazada. | La notificación llega dentro de los 30 segundos de la acción del organizador; el estado en "Mis inscripciones" ya refleja el cambio al abrir la pantalla. (Navegación al tocar la notificación: iter-9.) |
| 6.7 | Como rider, puedo abrir el centro de notificaciones desde el ícono de campana del Home y ver todas mis notificaciones, diferenciando las no leídas (punto naranja) de las leídas. Al tocar una notificación o usar "Marcar todas como leídas", el estado se persiste en el backend. | La lista muestra notificaciones cargadas desde el backend con paginación cursor (`?cursor=<lastId>&limit=20`, respuesta `{ data, nextCursor }`); marcar como leído llama a `PATCH /api/notifications/:id/read`; "Marcar todas" llama a `PATCH /api/notifications/read-all`; badge del ícono refleja conteo de no leídas desde backend; empty state "Aún no tienes notificaciones" visible. |
| 6.8 | Como desarrollador, el backend persiste todas las notificaciones en una tabla `notifications` en api-gateway y expone endpoints para listarlas, marcarlas como leídas y registrar el token FCM. | `GET /api/notifications?cursor=<lastId>&limit=20` retorna `{ data: Notification[], nextCursor: string \| null }` del usuario autenticado, ordenadas por `createdAt desc`; `PATCH /api/notifications/:id/read` actualiza `isRead = true`; `PATCH /api/notifications/read-all` actualiza todas las no leídas del usuario; `POST /api/notifications/fcm-token` recibe `{ fcmToken: string }`, actualiza el campo `fcmToken String?` en el modelo User de `users-ms`; tabla `notifications` con campos `id`, `userId`, `type`, `payload` (JSON), `isRead`, `createdAt`. |

**Definition of done (same as prior iter-5 DoD, renumbered):**
- [ ] Design gate: Pantallas SOAT upload, SOAT manual form, SOAT status detail y notification center tienen frame en `rideglory.pen` antes de comenzar implementación — incluyendo vehicle detail page actualizada con badge de 4 estados y plantilla genérica de fila de notificación con slot de ícono por tipo
- [ ] Pre-flight verificado: seed.ts en `vehicles-ms` y `events-ms`; `prisma migrate reset` completado en 4 servicios; `prisma init` + `prisma migrate dev` completado en `api-gateway`; `GET /api/vehicles` retorna 200
- [ ] Backend: `POST /api/vehicles/:vehicleId/soat` y `GET /api/vehicles/:vehicleId/soat` operativos en `vehicles-ms`
- [ ] Backend: `POST /api/notifications/fcm-token` operativo; `users-ms` User model tiene `fcmToken String?`
- [ ] Backend: tabla `notifications` en `api-gateway` Prisma; endpoints GET (cursor), PATCH read, PATCH read-all operativos con guard Firebase Auth
- [ ] Backend: FCM push trigger en flujo de aprobación/rechazo en `events-ms`; cada push inserta fila en `notifications`
- [ ] Backend: `@nestjs/schedule` con `ScheduleModule.forRoot()` en `api-gateway AppModule`; `NotificationSchedulerService` con `@Cron` para SOAT (30d, 7d, día-de); expresiones cron usan timezone `America/Bogota`
- [ ] Flutter: `lib/features/soat/` con dominio (`SoatModel`), datos (`SoatDto`, `SoatService`), y presentación (`SoatCubit`, `SoatUploadPage`, `SoatManualFormPage`, `SoatStatusPage`)
- [ ] Flutter: `lib/features/notifications/` con dominio (`NotificationModel`), datos (`NotificationsService` con cursor pagination), y presentación (`NotificationsCubit`, `NotificationCenterPage`)
- [ ] FCM inicializado en `AuthCubit` post-login: token registration + permission request; background message handler con `@pragma('vm:entry-point')` y re-inicialización de DI documentada
- [ ] `flutter_local_notifications` configurado para banners iOS en primer plano; canal de notificación Android configurado
- [ ] 6 tipos de notificación configurados y probados en device real o emulador
- [ ] `dart analyze` sin errores; `app_es.arb` actualizado con todas las nuevas cadenas
- [ ] Unit tests: lógica de badge SOAT (4 estados); `NotificationsCubit` — carga inicial, cursor pagination, markRead, markAllRead
- [ ] Widget tests: `SoatUploadPage`, `SoatManualFormPage`, `NotificationCenterPage`
- [ ] **Scope reduction rule**: si 6.7 ("marcar como leído" en backend) está en riesgo al final de la iteración, el badge reset puede simplificarse a local (SharedPreferences) como medida provisional; los endpoints backend (6.8) deben estar completos
- [ ] **Home Dashboard SOAT badge NO incluido en esta iteración** — se agrega en iter-7

---

### Iteration 7: Tracking Completo + SOS + Maintenance Reminders

**Goal:** Completar la experiencia de rastreo en tiempo real con botón SOS, controles del organizador, GPS en background con notificación persistente, recordatorios de mantenimiento por fecha, y migración completa a Mapbox como único SDK de mapas.

> Same as prior iter-6. All stories renumbered 6.x → 7.x. Pre-flight, DoD, and risks unchanged.

**Pre-flight:**
- (None — the Mapbox SDK migration is Story 7.0, the first story of this iteration. Stories 7.1–7.7 are blocked on 7.0's PR being merged and `dart analyze` passing cleanly.)

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 7.0 | Como desarrollador, el proyecto usa `mapbox_maps_flutter` como único SDK de mapas. `google_maps_flutter` y `geocoding` han sido eliminados completamente. | `pubspec.yaml` declara `mapbox_maps_flutter ^2.6.0`; `google_maps_flutter` y `geocoding` eliminados. `dart analyze` pasa con cero errores o warnings en `lib/`. Sin imports de `google_maps_flutter` o `geocoding` en `lib/`. `live_map_widget.dart`, `live_map_page.dart`, `initials_marker_icon.dart` y `route_map_preview.dart` compilan y renderizan correctamente en device físico. `route_map_preview.dart` usa `PlaceService` (Retrofit async) para lookup de dirección; estados loading y error manejados con patrón `ResultState`. `AndroidManifest.xml` contiene Mapbox token meta-data; `Info.plist` contiene `MBXAccessToken`; ninguna API key de Google Maps permanece en native config. iOS Cocoapods install completado; app builds en simulator. |
| 7.1 | Como rider en una rodada activa, puedo presionar el botón SOS rojo visible en el mapa, confirmar la alerta en un diálogo, y todos los demás riders de la rodada reciben una notificación push de emergencia con mi nombre y ubicación. | La alerta SOS se procesa en menos de 5 segundos; el marcador en el mapa de todos los participantes cambia a rojo pulsante; aparece un banner rojo con el nombre del rider en crisis. |
| 7.2 | Como rider que ve una alerta SOS en el mapa, puedo tocar el banner del rider en crisis y acceder a Llamar (dialer nativo) y Localizar (Google Maps / Apple Maps con navegación). | Las dos acciones funcionales en iOS y Android; el teléfono del rider solo aparece si lo tiene registrado; si no tiene teléfono, solo se muestra Localizar. |
| 7.3 | Como organizador de un evento, puedo iniciar la rodada desde la pantalla de detalle del evento, cambiando el estado a `in_progress` y habilitando el rastreo para todos los inscritos aprobados. | Botón "Iniciar rodada" solo visible para el organizador; al confirmar, estado actualizado en backend; riders ven CTA "Ver rastreo" en detalle del evento. |
| 7.4 | Como organizador de un evento activo, puedo terminar la rodada desde la pantalla de rastreo, cambiando el estado a `finished` y cerrando la pantalla para todos. | Estado cambia a `finished`; pantalla de rastreo cierra en todos los dispositivos conectados al WebSocket; push "La rodada ha terminado" llega en menos de 10s. |
| 7.5 | Como rider en una rodada activa con app en background, el app sigue enviando mi ubicación al WebSocket cada 5 segundos. Android: notificación persistente no descartable "Rideglory — Rodada activa". iOS: indicador de ubicación azul del sistema. | Android: ubicación actualiza con app en background, foreground service visible y no descartable (device físico requerido). iOS: ubicación actualiza, indicador sistema visible (comportamiento nativo, device físico requerido). |
| 7.6 | Como rider con un mantenimiento programado, recibo una push 30 días antes de la fecha programada. (Solo fecha — sin km.) | Push generada al guardar mantenimiento con fecha futura; texto incluye tipo de servicio y nombre de moto. |
| 7.7 | Como rider inscrito y aprobado a un evento, recibo una push de recordatorio 24 horas antes del evento. | Push llega entre 23h 55min y 24h 5min antes de la hora de inicio del evento. |

**Definition of done (same as prior iter-6 DoD, renumbered):**
- [ ] Design gate: Frame `qonbS` del Pencil confirmado con: botón SOS + diálogo de confirmación, barra de controles del organizador (Iniciar/Terminar rodada) condicionalmente visible, marcador rojo pulsante SOS, texto Android foreground service ("Rideglory — Rodada activa"), empty state "no tiene teléfono" para acción Llamar en story 7.2
- [ ] **Story 7.0 mergeada y `dart analyze` limpio antes de cualquier otra story**
- [ ] Cero imports `google_maps_flutter` o `geocoding` en `lib/` (verificado por grep en PR review)
- [ ] iOS Cocoapods cache actualizado en CI/CD post-merge de 7.0
- [ ] Backend: `POST /api/events/:eventId/tracking/start` y `POST /api/events/:eventId/tracking/end` en `api-gateway/src/tracking/`
- [ ] Backend: handler `sos` en `TrackingGateway` — broadcast `sos_alert` via WebSocket + FCM multicast a participantes; guard de deduplicación con `sosTriggeredAt`
- [ ] Backend: `GET /api/events/:eventId/route` en `events-ms` retornando `routeGeoJson` (GeoJSON LineString)
- [ ] Backend: scheduler entries para mantenimiento (30d fecha) y recordatorio 24h evento; timezone `America/Bogota`
- [ ] Flutter: ruta naranja dibujada con `GeoJsonSource + LineLayer` (NO `PolylineAnnotationManager`); coordenadas GeoJSON recibidas del backend
- [ ] Flutter: chip de adherencia a ruta ("En ruta ✓" / "Fuera de ruta ⚠") con lógica 200m usando Haversine client-side sobre coordenadas GeoJSON
- [ ] Flutter: botón SOS + diálogo de confirmación; banner SOS con Llamar/Localizar; marcador rojo pulsante con `mapbox_maps_flutter` annotations API
- [ ] Flutter: controles organizador Iniciar/Terminar rodada en `EventDetailPage` y `EventTrackingPage`; `LiveTrackingCubit` emite `TrackingFinished` al recibir `tracking.event.ended` via WebSocket
- [ ] Flutter: `flutter_foreground_task` en Android (foreground service isolate + `IsolateNameServer`; `configureDependencies()` llamado en `onStart()`); `geolocator` con `AppleSettings(activityType: ActivityType.automotiveNavigation)` en iOS
- [ ] Flutter: `VehicleModel` con `soatStatus` y `soatExpiryDate`; Home Dashboard badge SOAT en card de vehículo principal
- [ ] `dart analyze` sin errores; permisos `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` en `AndroidManifest.xml`
- [ ] Prueba en device físico para background GPS (Android foreground service + iOS background location) — logs adjuntos al PR
- [ ] `app_es.arb` actualizado; descripciones de uso de ubicación en `Info.plist` en español claro

---

### Iteration 8: Seguidores + Perfil Completo

**Goal:** Activar el sistema social básico de Rideglory: seguir/dejar de seguir otros riders, ver listas de seguidores/siguiendo, y completar los datos en las pantallas de perfil propio y de otro rider.

**Action item during iter-8 (hard prerequisite for iter-9):** Provisionar el dominio para Android App Links e iOS Universal Links. Esto incluye: elegir y configurar el dominio (`links.rideglory.app` u otro), obtener certificado TLS válido, desplegar `/.well-known/assetlinks.json` y `/.well-known/apple-app-site-association`, y verificar que ambos archivos sean accesibles públicamente. Este paso debe completarse antes de cerrar iter-8 — es un bloqueante absoluto para iter-9.

> Same as prior iter-7. All stories renumbered 7.x → 8.x. Pre-flight, DoD, and risks unchanged.

**Pre-flight:**
- (Ninguno — sin reset de base de datos ni migración de SDK requerida para iter-8.)

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 8.1 | Como rider, puedo ver el perfil de otro rider y tocar "Seguir"; el contador de seguidores se incrementa inmediatamente (optimistic update) y el backend registra la relación. | Botón cambia a "Siguiendo" al instante; si el request falla, el estado revierte y muestra snackbar de error; contador correcto al refrescar el perfil. |
| 8.2 | Como rider que ya sigue a alguien, puedo tocar "Siguiendo", confirmar en un diálogo, y dejar de seguirlo; el contador disminuye de inmediato. | Flujo simétrico al de seguir; confirmación requerida para evitar toques accidentales; backend actualiza la relación. |
| 8.3 | Como rider, puedo tocar el número de "seguidores" o "siguiendo" en mi perfil y ver una lista con foto, nombre y botón rápido seguir/dejar de seguir a cada uno. | Lista pagina correctamente (>20 riders con offset/limit load-more); navegar al rider abre su perfil; empty states visibles ("Aún no tienes seguidores" / "Aún no sigues a ningún rider"). |
| 8.4 | Como rider, mi perfil muestra bio, ciudad, número de seguidores, número de siguiendo, eventos creados y motos registradas (sin datos sensibles). | Todos los campos con empty states apropiados; eventos ordenados con próximos primero. |
| 8.5 | Como rider, cuando alguien empieza a seguirme recibo una push "Te sigue {nombre}" que aparece en el centro de notificaciones. | Push en menos de 30s; centro de notificaciones muestra el ítem con badge actualizado; fila insertada en tabla `notifications`. (Navegación al tocar: iter-9.) |

**Definition of done (same as prior iter-7 DoD, renumbered):**
- [ ] Design gate: Frame `A7qDd` (Profile) actualizado a estado final en `rideglory.pen`; frames para `FollowersListPage` y `FollowingListPage` creados antes de implementación — incluyendo botón seguir en estado cargando (optimistic in-flight), quick-follow en lista, empty states
- [ ] **Dominio de deep link provisionado**: `assetlinks.json` y `apple-app-site-association` accesibles públicamente en el dominio elegido; TLS válido; verificado con `curl` antes del cierre de iter-8
- [ ] Backend: entidad `Follow` (`followerId`, `followingId`, `createdAt`, índice compuesto único) en `users-ms` Prisma; `POST /api/users/:userId/follow`, `DELETE /api/users/:userId/follow`, `GET /api/users/:userId/followers?page=&limit=`, `GET /api/users/:userId/following?page=&limit=`
- [ ] Backend: `_count.followers` y `_count.following` incluidos en respuesta de perfil de usuario
- [ ] Backend: `GET /api/vehicles?userId=:userId` retorna `PublicVehicleDto` (clase separada de `VehicleDto`, sin `licensePlate` ni campos de seguro)
- [ ] Backend: FCM push "nuevo seguidor" disparado desde `api-gateway` post-proxy; fila insertada en tabla `notifications`
- [ ] Flutter: `FollowCubit` con estado optimista (`@freezed FollowState { isFollowing, followerCount, isLoading, error }`); registrado como factory con parámetro userId en DI
- [ ] Flutter: `FollowersListPage` y `FollowingListPage` con paginación offset/limit, load-more, empty states explícitos
- [ ] Flutter: perfil completo con bio, ciudad, contadores reales, vehículos públicos (via `PublicVehicleDto`), eventos organizados
- [ ] Tipo `NEW_FOLLOWER` manejado en `NotificationsCubit`; aparece en centro de notificaciones
- [ ] **GoRouter DI assessment**: confirmar si `GoRouter` está registrado en GetIt o requiere refactoring antes de `NotificationRouteHandler` en iter-9; si es necesario, crear tarea y planificar como Story 9.0
- [ ] `dart analyze` sin errores; `app_es.arb` actualizado
- [ ] Unit tests: optimistic update + revert en error para `FollowCubit`; paginación de listas
- [ ] Widget tests: `FollowersListPage`, `FollowingListPage`

---

### Iteration 9: Deep Links + Compartir Evento + Apple Sign-In

**Goal:** Activar el flujo de compartir eventos externamente con Android App Links e iOS Universal Links, añadir Apple Sign-In (requisito App Store), y completar el routing de notificaciones push a las pantallas destino.

> Same as prior iter-8. All stories renumbered 8.x → 9.x. Pre-flight, DoD, and risks unchanged.

**Pre-flight:**
- [ ] `com.apple.developer.applesignin` entitlement añadido en Xcode; nuevo provisioning profile generado (permitir 1 día hábil para propagación)
- [ ] Apple provider habilitado en Firebase Console y Apple Developer Portal
- [ ] Dominio (provisionado en iter-8): verificar `curl https://<domain>/.well-known/assetlinks.json` y `curl https://<domain>/.well-known/apple-app-site-association` retornan 200 con contenido correcto
- [ ] GoRouter DI: si el assessment de iter-8 determinó que se requiere refactoring, completarlo como Story 9.0 antes de implementar `NotificationRouteHandler`

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 9.1 | Como rider, puedo tocar el botón de compartir en el detalle de un evento y el app abre el share sheet nativo con un link listo para enviar. | Link generado en menos de 3 segundos; share sheet nativo con preview (nombre del evento + imagen de portada) en tarjeta de WhatsApp. |
| 9.2 | Como rider que recibe un link de evento y tiene la app instalada, al tocar el link la app abre directamente el detalle de ese evento. | Navegación funciona desde cold start y background; error apropiado si evento no existe o fue cancelado. |
| 9.3 | Como persona sin la app, al tocar el link en el navegador mobile es redirigida a la Play Store (Android) o App Store (iOS). | Redirección correcta en ambas plataformas; página de fallback muestra branding mínimo de Rideglory (no es un HTTP redirect vacío). |
| 9.4 | Como usuario de iPhone, puedo iniciar sesión o registrarme con Apple Sign-In en la pantalla de login. | Flujo de auth completo; perfil creado igual que con Google Sign-In; botón solo visible en iOS. |
| 9.5 | Como rider, cuando toco cualquier notificación push la app navega directamente a la pantalla relevante sin pasar por Home. | 7 tipos de notificación enrutan correctamente: SOAT → detalle vehículo, inscripción aprobada/rechazada → detalle inscripción, nuevo inscrito → gestión inscritos, mantenimiento → detalle mantenimiento, seguidor → perfil rider. Funciona desde cold start y background. `NotificationRouteHandler` muestra error apropiado si la entidad destino ya no existe (no crash). |

**Definition of done (same as prior iter-8 DoD, renumbered):**
- [ ] Design gate: Botón de compartir en `EventDetailPage` y botón Apple Sign-In en login confirmados en frames; Apple Sign-In usa botón negro con logo Apple (HIG compliance)
- [ ] Backend: `GET /api/events/:eventId/share-metadata` con `Cache-Control: public, max-age=3600`
- [ ] Backend (o Firebase Hosting): sirve `/.well-known/assetlinks.json` y `/.well-known/apple-app-site-association`; página de redirect detecta User-Agent y redirige a Play Store / App Store con branding Rideglory mínimo
- [ ] Flutter: `app_links ^6.x` integrado; `AndroidManifest.xml` con intent-filter para App Links; iOS Associated Domains entitlement
- [ ] Flutter: `sign_in_with_apple ^6.x` integrado; botón solo en iOS (`defaultTargetPlatform == TargetPlatform.iOS`)
- [ ] Flutter: `NotificationRouteHandler` en `lib/core/services/` — `@singleton` en DI, registrado antes de `GoRouter` en `main.dart`; maneja `onMessageOpenedApp` (background) y `getInitialMessage` (cold start); graceful error si entidad destino no existe
- [ ] `dart analyze` sin errores; `app_es.arb` actualizado (botón compartir, mensajes de error)
- [ ] Privacy policy URL en `Info.plist`
- [ ] Prueba en device físico iOS: cold-start Universal Link + Apple Sign-In
- [ ] Prueba en device físico Android: cold-start App Link
- [ ] 7 tipos de notificación verificados que enrutan correctamente a pantallas destino (story 9.5 completa)

---

## Dependencies and sequencing

```
iter-5 (UI/UX Redesign — frontend only)
  |  Establishes: consistent design system baseline across all existing screens
  |  Pre-condition: gap analysis and Pencil frame inspection BEFORE any code
  |  Output: all 14 existing screens aligned with rideglory.pen
  v
iter-6 (SOAT + Notification Foundation)
  |  Establishes: FCM infrastructure, notifications table in api-gateway,
  |               notification center UI, SOAT domain, cursor pagination contract
  v
iter-7 (Tracking Completo + SOS + Maintenance Reminders)
  |  Story 7.0 (Mapbox migration) must merge before 7.1–7.7 begin
  |  Depends on iter-6: push notification infrastructure for SOS FCM multicast
  |  Establishes: Mapbox-only SDK, background GPS, GeoJSON route, SOS UI
  v
iter-8 (Seguidores + Perfil Completo)
  |  Depends on iter-6: notification center and notifications table
  |                     (follower push inserts into same table)
  |  Action item: provision deep link domain (blocker for iter-9)
  v
iter-9 (Deep Links + Apple Sign-In + Notification Routing)
     Depends on iter-6: all notification types required for routing (story 9.5)
     Depends on iter-8: follower notification type + deep link domain provisioned
```

---

## Open questions for Architect

1. **Iter-5 scope — ManageAttendeesPage**: Should `ManageAttendeesPage` (organizer view for managing registrations) be included in the redesign scope? It exists in the codebase but is not listed in the 14 screens above. Flag for Architect and Design to assess frame coverage in `rideglory.pen`.

2. **Registration form pages in iter-5**: The 4-step registration form (`pQCmS`) and `RegistrationDetailPage` (`oUv12`) exist and may have visual debt. They are listed as optional story 5.10. Architect to confirm whether these are included or deferred given the scope already covers 14 screens.

3. **`routeGeoJson` backend contract** (carried from prior plan): The Architect recommends storing the route as GeoJSON LineString (`routeGeoJson Json?`) rather than the `"polyline": "encoded_string"` in PRD §17.2. Confirm this decision before beginning iter-7.

4. **Deep link domain** (carried from prior plan): Which domain is used for Android App Links and iOS Universal Links? (`links.rideglory.app` or api-gateway serving `.well-known/`?) Must be decided before iter-8 closes.

5. **`notifications` microservice scope** (carried from prior plan): For MVP, `notifications` lives in api-gateway. Is there intent to extract it to a `notifications-ms` after MVP, or does it consolidate in api-gateway permanently?

---

## Deferred (out of MVP scope)

| Item | Reason | Candidate |
|------|--------|-----------|
| OCR auto-fill del SOAT | Alta complejidad (ML Kit / Cloud Vision); entrada manual es suficiente para MVP | post-iter-9 |
| Recordatorio de mantenimiento por km (odómetro) | Requiere sistema de tracking de odómetro no definido en el PRD | post-iter-9 |
| Dynamic Links para perfiles de riders | Bajo impacto vs. esfuerzo; eventos son el caso de uso crítico de sharing | post-iter-9 |
| Sugerencias de riders a seguir | Sin demanda validada para MVP | post-iter-9 |
| Notificaciones read/unread local-only (SharedPreferences) | Descartado — fuente de verdad es el backend | — |
| Firebase Dynamic Links | EOL agosto 2025. Reemplazado por `app_links` + Android App Links + iOS Universal Links | never — replaced |
| Pagos in-app (Wompi, MercadoPago) | Complejidad legal; cobro es externo al MVP | post-MVP |
| Verificación automática de SOAT via RUNT API | RUNT no tiene API pública | post-MVP |
| Chat interno en la app | Solo WhatsApp/llamada nativa en MVP | post-MVP |
| Feed social de publicaciones / fotos de rodadas | Fase posterior al MVP | post-MVP |
| Gamificación (logros, retos) | Fase posterior al MVP | post-MVP |
| Modo offline / descarga de mapas | No requerido para MVP | post-MVP |
| Idioma inglés | Fase posterior; MVP es solo español | post-MVP |
| Marketplace de repuestos | Fase posterior al MVP | post-MVP |
