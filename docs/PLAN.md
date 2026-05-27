# Rideglory — Iteration Plan

> Status: APPROVED
> Generated: 2026-05-13
> Run mode: FEEDBACK_REPLAN (redesign-first)
> Completed iterations: 2 (Event Discovery Filters), 4 (AI Cover Image)

---

## What changed from prior plan

| Change | Prior plan | This plan |
|--------|-----------|-----------|
| New Iteration 1 | SOAT + Notifications | UI/UX Redesign (15 screens) |
| Former iter-1 | SOAT + Notifications | → iter-2 |
| Former iter-2 | Tracking + SOS | → iter-3 |
| Former iter-3 | Seguidores + Perfil | → iter-4 |
| Former iter-4 | Deep Links | → iter-1 (retitled) |
| ManageAttendeesPage | not in scope | → added to iter-2 as Story 2.9 |
| Iter-1 title | "Deep Links + Compartir Evento + Apple Sign-In" | → "Deep Links + Apple Sign-In + Notification Routing" |

---

## Summary

Five sequential iterations complete Rideglory's MVP. **Iter-1** is a pure UI/UX Redesign pass covering 15 existing screens — no new features, no backend changes. This establishes a consistent design system baseline before any new capabilities are layered on top. **Iter-2** delivers SOAT registration, FCM notification infrastructure, and the ManageAttendeesPage redesign (Story 2.9). **Iter-3** completes real-time tracking with SOS, organizer controls, background GPS, and the Mapbox SDK migration (Story 3.0). **Iter-4** activates the social layer with the follow system and complete public profiles, and provisions the deep link domain for iter-1. **Iter-1** closes the release gate with Android App Links + iOS Universal Links event sharing, Apple Sign-In, and full notification tap routing.

Critical path: iter-1 → iter-2 → iter-3 → iter-4 → iter-1. No parallelization possible.

---

## Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| **Frontend** | Flutter — BLoC/Cubit + ResultState\<T\>, Clean Architecture | Existing stack; no refactoring needed |
| **Maps** | `mapbox_maps_flutter ^2.2.0` | `google_maps_flutter` removed in Story 3.0; route rendered via GeoJsonSource + LineLayer |
| **Backend** | NestJS microservices (api-gateway, events-ms, vehicles-ms, users-ms, maintenances-ms) | FCM dispatch and notifications table in api-gateway |
| **Push** | Firebase Cloud Messaging (`firebase_messaging ^15.x`, `firebase-admin ^13.x`) | Background isolate DI re-init pattern established in iter-2 |
| **Scheduler** | `@nestjs/schedule` (new in api-gateway) | SOAT reminders, maintenance reminders, 24h event reminders |
| **Database** | PostgreSQL per microservice via Prisma Migrate | api-gateway gets Prisma for the first time in iter-2 |
| **Deep links** | `app_links ^2.x` + Android App Links + iOS Universal Links | Firebase Dynamic Links is EOL — not used |
| **Apple auth** | `sign_in_with_apple ^2.x` | iOS only; iter-1 |

---

## Iterations

---

### Iter-1: UI/UX Redesign

**Goal:** Bring 15 existing screens into alignment with rideglory.pen design — no new features, no backend changes.

**Pre-flight (before any code):**
- [ ] Designer inspects all relevant rideglory.pen frames via Pencil MCP; produces gap analysis document listing every screen with specific mismatches (component, spacing, color, typography) before any Flutter code is touched
- [ ] Auth frames gate: Designer confirms or creates Login/Signup/PasswordRecovery frames in rideglory.pen via Pencil MCP before Story 1.3 implementation begins. Stories 1.2, 1.4–1.10 may proceed in parallel.
- [ ] Identify and list all hardcoded `Color()` literals in `lib/features/` (scope: features tree only)
- [ ] `dart analyze` baseline run on `main` branch — all pre-existing violations documented; violation count must not grow during iter-1

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 1.1 | As a designer reviewing existing screens, I can identify all visual gaps between the current implementation and rideglory.pen frames, documented in a gap analysis. | Gap analysis document lists every screen (all 15) with specific mismatches: component name, spacing value, color token, typography rule. Document reviewed and approved before any Flutter code changes begin. |
| 1.2 | As a rider opening the app, I see the splash screen with the correct logo, loading state indicator, and overall layout matching the rideglory.pen design. | Splash screen layout, logo sizing, background color, and loading indicator match the Pencil frame exactly. All loading states (loading, error, success) handled visually. No hardcoded colors. |
| 1.3 | As a rider on the auth screens (login, signup, password recovery), the pages use `AppButton`, `AppTextField`, `AppPasswordTextField`, correct typography, and the exact color tokens from the design system. | No `ElevatedButton`, no `TextFormField` direct usage, no hardcoded color literals on any auth screen. `AppButton` used for all primary and secondary actions. Space Grotesk applied. Password recovery confirmation screen matches design. Auth frames gate must be satisfied before this story begins. |
| 1.4 | As a rider on the Home Dashboard, the layout matches the rideglory.pen frame `dyWWs` — including the greeting header, garage card (main vehicle + empty state), upcoming rides section (horizontal scroll + empty state), and bottom navigation pill bar. | Frame `dyWWs` matched: correct spacing, correct card border radius (12px cards, 24px bottom sheets), correct color tokens. Bottom nav pill bar matches frame `VMmN0`. SOAT badge placeholder not included (iter-2). No layout regressions vs. current behavior. |
| 1.5 | As a rider browsing Events, the events list page and event detail page match the rideglory.pen frames `Neipf` and `kAubW` — including event cards, badges (`zKkmE`), filter chips, the filter bottom sheet, and the CTA bar on event detail. Pre-condition: `lib/design_system/atoms/app_event_badge.dart` must be extracted/created from frame `zKkmE` before this story's implementation begins. | Event list: search bar, filter chips, event cards (image overlay, badge, organizer avatar, chips) match frame `Neipf`. Event detail: hero image, metric chips, map preview, allowed brands chips, CTA bar match frame `kAubW`. Filter bottom sheet layout correct. `app_event_badge.dart` used in all event card contexts. |
| 1.6 | As a rider creating an event, the Create/Edit Event form matches the rideglory.pen frame `zbCa0` — correct input fields, layout sections, difficulty selector, and button styles. | Form layout matches frame `zbCa0`. AI cover generation widget (iter-4 feature) is preserved and functional. Mapbox route preview widget unchanged. All inputs use `AppTextField`. `AppButton` used for primary actions. |
| 1.7 | As a rider viewing the Garage, the vehicle list page and vehicle detail page match rideglory.pen frames `KCf6W` and `P1GSzZ` — including the main vehicle card, "other vehicles" list, spec chips, and document slots. Note: document slot pill (`aGqnv`) should be extracted as a design system molecule during this story for reuse in iter-2 SOAT badge. | Vehicle list matches frame `KCf6W`: main vehicle card with full-width image, stats chips, quick-access buttons; compact other-vehicles list. Vehicle detail matches frame `P1GSzZ`: specs, document badges, action buttons. All states (loading, empty, data, error) visually correct. |
| 1.8 | As a rider adding or editing a vehicle, the Add/Edit vehicle form matches rideglory.pen frame `EqnMm` — correct field layout, image upload UI, and step structure. | Form fields, image upload banner, and section layout match frame `EqnMm`. Document slot section (SOAT, tech review) UI is present but non-functional pending iter-2. `AppTextField` and `AppButton` used throughout. |
| 1.9 | As a rider viewing Maintenance, the dashboard, history list, and new maintenance forms match rideglory.pen frames `Ako7u` (dashboard), `SykjL` (history), `J5h6P` (step 1), `eK2WW` (step 2 — completed), and `ELB5u` (step 2 — scheduled). | All 5 maintenance frames matched. Dashboard: donut chart health indicator, urgency color coding (red/yellow/green) correct. History: year grouping, cost summary, chronological order. Filters bottom sheet (frame `v6RqaX`) layout correct. Step 1 grid 2×4 card layout correct. Step 2 tab (Completado / Programado) layout correct. |
| 1.10 | As a rider viewing their registrations, the My Registrations list and Registration Detail pages match rideglory.pen frames `oUv12` and the registration list layout. | Registration list and detail pages use design system components throughout; no hardcoded colors; empty and loading states correct. |

**Definition of done:**
- [ ] Design gate: all 15 screen frames inspected/confirmed in rideglory.pen via Pencil MCP before any Flutter code changes begin; gap analysis document complete and reviewed
- [ ] Auth frames gate satisfied: Pencil frames for Login, Signup, Password Recovery confirmed or created in rideglory.pen before Story 1.3 implementation begins
- [ ] Implementation split into 5–6 module-scoped PRs (max 40 files each): splash+auth, home, events, garage, maintenance, registration. Each module PR requires `dart analyze` + `flutter test` green before merge into feature branch
- [ ] No single PR exceeds 40 files changed
- [ ] All `Color(0x...)` and `Colors.<named>` hardcoded literals in `lib/features/` replaced with `Theme.of(context).colorScheme.<property>` or `AppColors` constants
- [ ] All `ElevatedButton` → `AppButton`; raw `TextFormField` → `AppTextField`; raw `AlertDialog` → `AppDialog`
- [ ] `dart analyze` passes with zero new violations on the final feature branch
- [ ] All 10 existing `flutter test` cases pass — zero regressions
- [ ] `app_event_badge.dart` atom extracted from frame `zKkmE` before Story 1.5 implementation begins
- [ ] Document slot pill (`aGqnv`) extracted as design system molecule during Story 1.7
- [ ] AI cover generation widget (iter-4) remains functional — mandatory smoke test: generate cover → select image → save event → confirm functional
- [ ] 5 manual smoke tests passed before final merge: (a) AI cover generation, (b) Event detail CTA state variants (registered / pending / closed / full), (c) Maintenance donut chart rendering, (d) Home bottom nav pill bar, (e) Mapbox route preview in event form
- [ ] Bottom navigation pill bar (`VMmN0`) verified to match frame exactly across all shell screens
- [ ] All 3 events widget tests updated in the same PR that swaps their widgets — no test-rot merges
- [ ] `app_es.arb` updated for any UI copy changes during redesign; `flutter gen-l10n` run and generated files committed
- [ ] No new backend endpoints; no new domain models; no new use cases; no new routes introduced

---

### Iter-2: SOAT + Notification Foundation

**Goal:** Allow riders to register and track their SOAT per vehicle, and receive push notifications for critical lifecycle events. Establishes the FCM infrastructure and persistent notification backend that every later iteration depends on. Also includes ManageAttendeesPage redesign (Story 2.9) deferred from iter-1.

**Pre-flight (before any code):**
- [ ] Create `seed.ts` in `vehicles-ms` with at least 2 test vehicles; add `"prisma": { "seed": "ts-node prisma/seed.ts" }` to `package.json`
- [ ] Create `seed.ts` in `events-ms` with at least 1 test event in `scheduled` state and 1 test registration
- [ ] Create `seed.ts` stubs in `users-ms` and `maintenances-ms` (empty, with comments for future data)
- [ ] Run `npx prisma migrate reset --force` in `events-ms`, `vehicles-ms`, `users-ms`, `maintenances-ms` — drops and recreates schemas; `npx prisma db seed` runs automatically post-reset
- [ ] Run `npx prisma migrate status` in each of the 4 services to verify migration history is clean
- [ ] In `api-gateway/` (FIRST-TIME setup, not reset): run `npx prisma init`, create `schema.prisma` with `Notification` model, configure `DATABASE_URL`, run `npx prisma migrate dev --name init_notifications`, generate client
- [ ] Add `@nestjs/schedule` to `api-gateway/package.json`: `npm install @nestjs/schedule`
- [ ] Verify `GET /api/vehicles` returns 200 with empty list in local environment

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 2.1 | Como rider, puedo subir el documento de mi SOAT (foto o PDF desde galería/cámara) para un vehículo de mi garaje y guardar los datos (número de póliza, fechas, aseguradora) en el backend. | El documento queda guardado; el badge del vehículo cambia a "Vigente" o "Por vencer" según la fecha de vencimiento. |
| 2.2 | Como rider, puedo ingresar manualmente los datos de mi SOAT (número de póliza, fecha inicio, fecha vencimiento, aseguradora) cuando no quiero subir el documento. | El formulario valida que la fecha de vencimiento sea obligatoria; al guardar el estado SOAT refleja la lógica de vigencia correcta. |
| 2.3 | Como rider, veo en el detalle de mi vehículo un badge de estado SOAT (Sin SOAT / Vigente / Por vencer / Vencido) y puedo tocar el badge para ir al flujo de SOAT. | Los cuatro estados se calculan correctamente con base en la fecha de vencimiento vs. hoy; el badge es tap-able y navega al flujo correcto. |
| 2.4 | Como rider, recibo una notificación push 30 días antes, 7 días antes y el día del vencimiento de mi SOAT con el nombre de la moto afectada. | Las tres notificaciones llegan al dispositivo en las fechas correctas y se muestran en el centro de notificaciones. (Navegación al tocar la notificación: iter-1.) |
| 2.5 | Como organizador de evento, recibo una notificación push cuando un nuevo rider se inscribe a mi evento. | La notificación aparece en el centro de notificaciones; el badge de no leídas en el ícono de campana se incrementa. (Navegación al tocar la notificación: iter-1.) |
| 2.6 | Como rider inscrito, recibo una notificación push cuando mi inscripción es aprobada o rechazada. | La notificación llega dentro de los 30 segundos de la acción del organizador; el estado en "Mis inscripciones" ya refleja el cambio al abrir la pantalla. (Navegación al tocar la notificación: iter-1.) |
| 2.7 | Como rider, puedo abrir el centro de notificaciones desde el ícono de campana del Home y ver todas mis notificaciones, diferenciando las no leídas (punto naranja) de las leídas. Al tocar una notificación o usar "Marcar todas como leídas", el estado se persiste en el backend. | La lista muestra notificaciones cargadas desde el backend con paginación cursor (`?cursor=<lastId>&limit=20`, respuesta `{ data, nextCursor }`); marcar como leído llama a `PATCH /api/notifications/:id/read`; "Marcar todas" llama a `PATCH /api/notifications/read-all`; badge del ícono refleja conteo de no leídas desde backend; empty state "Aún no tienes notificaciones" visible. |
| 2.8 | Como desarrollador, el backend persiste todas las notificaciones en una tabla `notifications` en api-gateway y expone endpoints para listarlas, marcarlas como leídas y registrar el token FCM. | `GET /api/notifications?cursor=<lastId>&limit=20` retorna `{ data: Notification[], nextCursor: string | null }` del usuario autenticado, ordenadas por `createdAt desc`; `PATCH /api/notifications/:id/read` actualiza `isRead = true`; `PATCH /api/notifications/read-all` actualiza todas las no leídas del usuario; `POST /api/notifications/fcm-token` recibe `{ fcmToken: string }`, actualiza el campo `fcmToken String?` en el modelo User de `users-ms`, es llamado desde `AuthCubit` post-login; los cuatro endpoints requieren Bearer token con guard de Firebase Auth; tabla `notifications` con campos `id`, `userId`, `type`, `payload` (JSON), `isRead`, `createdAt`. |
| 2.9 | As an event organizer, the attendees management page (frame `dUc9h`) matches rideglory.pen design — using design system components, correct color tokens, and consistent loading/empty states. | ManageAttendeesPage uses `AppButton`, `AppTextField`, `AppDialog` throughout; no hardcoded color literals; loading, empty, and error states visually correct per Pencil frame. Frame `dUc9h` must be confirmed to cover list + edit or descoped to component-swap-only if ambiguous. |

**Definition of done:**
- [ ] Design gate: Pantallas SOAT upload, SOAT manual form, SOAT status detail y notification center tienen frame en `rideglory.pen` antes de comenzar implementación — incluyendo vehicle detail page actualizada con badge de 4 estados y plantilla genérica de fila de notificación con slot de ícono por tipo; frame `dUc9h` confirmed for Story 2.9 before implementation
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
- [ ] **Scope reduction rule**: si 2.7 ("marcar como leído" en backend) está en riesgo al final de la iteración, el badge reset puede simplificarse a local (SharedPreferences) como medida provisional; los endpoints backend (2.8) deben estar completos
- [ ] **Home Dashboard SOAT badge NO incluido en esta iteración** — se agrega en iter-3

---

### Iter-3: Tracking Completo + SOS + Maintenance Reminders

**Goal:** Completar la experiencia de rastreo en tiempo real con botón SOS, controles del organizador, GPS en background con notificación persistente, recordatorios de mantenimiento por fecha, y migración completa a Mapbox como único SDK de mapas.

**Pre-flight (before any code):**
- (None — the Mapbox SDK migration is Story 3.0, the first story of this iteration. Stories 3.1–3.7 are blocked on 3.0's PR being merged and `dart analyze` passing cleanly.)

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 3.0 | Como desarrollador, el proyecto usa `mapbox_maps_flutter` como único SDK de mapas. `google_maps_flutter` y `geocoding` han sido eliminados completamente. | `pubspec.yaml` declara `mapbox_maps_flutter ^2.2.0`; `google_maps_flutter` y `geocoding` eliminados. `dart analyze` pasa con cero errores o warnings en `lib/`. Sin imports de `google_maps_flutter` o `geocoding` en `lib/`. `live_map_widget.dart`, `live_map_page.dart`, `initials_marker_icon.dart` y `route_map_preview.dart` compilan y renderizan correctamente en device físico. `route_map_preview.dart` usa `PlaceService` (Retrofit async) para lookup de dirección; estados loading y error manejados con patrón `ResultState`. `AndroidManifest.xml` contiene Mapbox token meta-data; `Info.plist` contiene `MBXAccessToken`; ninguna API key de Google Maps permanece en native config. iOS Cocoapods install completado; app builds en simulator. |
| 3.1 | Como rider en una rodada activa, puedo presionar el botón SOS rojo visible en el mapa, confirmar la alerta en un diálogo, y todos los demás riders de la rodada reciben una notificación push de emergencia con mi nombre y ubicación. | La alerta SOS se procesa en menos de 5 segundos; el marcador en el mapa de todos los participantes cambia a rojo pulsante; aparece un banner rojo con el nombre del rider en crisis. |
| 3.2 | Como rider que ve una alerta SOS en el mapa, puedo tocar el banner del rider en crisis y acceder a Llamar (dialer nativo) y Localizar (Google Maps / Apple Maps con navegación). | Las dos acciones funcionales en iOS y Android; el teléfono del rider solo aparece si lo tiene registrado; si no tiene teléfono, solo se muestra Localizar. |
| 3.3 | Como organizador de un evento, puedo iniciar la rodada desde la pantalla de detalle del evento, cambiando el estado a `in_progress` y habilitando el rastreo para todos los inscritos aprobados. | Botón "Iniciar rodada" solo visible para el organizador; al confirmar, estado actualizado en backend; riders ven CTA "Ver rastreo" en detalle del evento. |
| 3.4 | Como organizador de un evento activo, puedo terminar la rodada desde la pantalla de rastreo, cambiando el estado a `finished` y cerrando la pantalla para todos. | Estado cambia a `finished`; pantalla de rastreo cierra en todos los dispositivos conectados al WebSocket; push "La rodada ha terminado" llega en menos de 10s. |
| 3.5 | Como rider en una rodada activa con app en background, el app sigue enviando mi ubicación al WebSocket cada 5 segundos. Android: notificación persistente no descartable "Rideglory — Rodada activa". iOS: indicador de ubicación azul del sistema. | Android: ubicación actualiza con app en background, foreground service visible y no descartable (device físico requerido). iOS: ubicación actualiza, indicador sistema visible (comportamiento nativo, device físico requerido). |
| 3.6 | Como rider con un mantenimiento programado, recibo una push 30 días antes de la fecha programada. (Solo fecha — sin km.) | Push generada al guardar mantenimiento con fecha futura; texto incluye tipo de servicio y nombre de moto. |
| 3.7 | Como rider inscrito y aprobado a un evento, recibo una push de recordatorio 24 horas antes del evento. | Push llega entre 23h 55min y 24h 5min antes de la hora de inicio del evento. |

**Definition of done:**
- [ ] Design gate: Frame `qonbS` del Pencil confirmado con: botón SOS + diálogo de confirmación, barra de controles del organizador (Iniciar/Terminar rodada) condicionalmente visible, marcador rojo pulsante SOS, texto Android foreground service ("Rideglory — Rodada activa"), empty state "no tiene teléfono" para acción Llamar en story 3.2
- [ ] **Story 3.0 mergeada y `dart analyze` limpio antes de cualquier otra story**
- [ ] Cero imports `google_maps_flutter` o `geocoding` en `lib/` (verificado por grep en PR review)
- [ ] iOS Cocoapods cache actualizado en CI/CD post-merge de 3.0
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

### Iter-4: Seguidores + Perfil Completo

**Goal:** Activar el sistema social básico de Rideglory: seguir/dejar de seguir otros riders, ver listas de seguidores/siguiendo, y completar los datos en las pantallas de perfil propio y de otro rider.

**Action item during iter-4 (hard prerequisite for iter-1):** Provisionar el dominio para Android App Links e iOS Universal Links. Esto incluye: elegir y configurar el dominio (`links.rideglory.app` u otro), obtener certificado TLS válido, desplegar `/.well-known/assetlinks.json` y `/.well-known/apple-app-site-association`, y verificar que ambos archivos sean accesibles públicamente. Este paso debe completarse antes de cerrar iter-4 — es un bloqueante absoluto para iter-1.

**Pre-flight (before any code):**
- (Ninguno — sin reset de base de datos ni migración de SDK requerida para iter-4.)

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 4.1 | Como rider, puedo ver el perfil de otro rider y tocar "Seguir"; el contador de seguidores se incrementa inmediatamente (optimistic update) y el backend registra la relación. | Botón cambia a "Siguiendo" al instante; si el request falla, el estado revierte y muestra snackbar de error; contador correcto al refrescar el perfil. |
| 4.2 | Como rider que ya sigue a alguien, puedo tocar "Siguiendo", confirmar en un diálogo, y dejar de seguirlo; el contador disminuye de inmediato. | Flujo simétrico al de seguir; confirmación requerida para evitar toques accidentales; backend actualiza la relación. |
| 4.3 | Como rider, puedo tocar el número de "seguidores" o "siguiendo" en mi perfil y ver una lista con foto, nombre y botón rápido seguir/dejar de seguir a cada uno. | Lista pagina correctamente (>20 riders con offset/limit load-more); navegar al rider abre su perfil; empty states visibles ("Aún no tienes seguidores" / "Aún no sigues a ningún rider"). |
| 4.4 | Como rider, mi perfil muestra bio, ciudad, número de seguidores, número de siguiendo, eventos creados y motos registradas (sin datos sensibles). | Todos los campos con empty states apropiados; eventos ordenados con próximos primero. |
| 4.5 | Como rider, cuando alguien empieza a seguirme recibo una push "Te sigue {nombre}" que aparece en el centro de notificaciones. | Push en menos de 30s; centro de notificaciones muestra el ítem con badge actualizado; fila insertada en tabla `notifications`. (Navegación al tocar: iter-1.) |

**Definition of done:**
- [ ] Design gate: Frame `A7qDd` (Profile) actualizado a estado final en `rideglory.pen`; frames para `FollowersListPage` y `FollowingListPage` creados antes de implementación — incluyendo botón seguir en estado cargando (optimistic in-flight), quick-follow en lista, empty states
- [ ] **Dominio de deep link provisionado**: `assetlinks.json` y `apple-app-site-association` accesibles públicamente en el dominio elegido; TLS válido; verificado con `curl` antes del cierre de iter-4
- [ ] Backend: entidad `Follow` (`followerId`, `followingId`, `createdAt`, índice compuesto único) en `users-ms` Prisma; `POST /api/users/:userId/follow`, `DELETE /api/users/:userId/follow`, `GET /api/users/:userId/followers?page=&limit=`, `GET /api/users/:userId/following?page=&limit=`
- [ ] Backend: `_count.followers` y `_count.following` incluidos en respuesta de perfil de usuario
- [ ] Backend: `GET /api/vehicles?userId=:userId` retorna `PublicVehicleDto` (clase separada de `VehicleDto`, sin `licensePlate` ni campos de seguro)
- [ ] Backend: FCM push "nuevo seguidor" disparado desde `api-gateway` post-proxy; fila insertada en tabla `notifications`
- [ ] Flutter: `FollowCubit` con estado optimista (`@freezed FollowState { isFollowing, followerCount, isLoading, error }`); registrado como factory con parámetro userId en DI
- [ ] Flutter: `FollowersListPage` y `FollowingListPage` con paginación offset/limit, load-more, empty states explícitos
- [ ] Flutter: perfil completo con bio, ciudad, contadores reales, vehículos públicos (via `PublicVehicleDto`), eventos organizados
- [ ] Tipo `NEW_FOLLOWER` manejado en `NotificationsCubit`; aparece en centro de notificaciones
- [ ] **GoRouter DI assessment**: confirmar si `GoRouter` está registrado en GetIt o requiere refactoring antes de `NotificationRouteHandler` en iter-1; si es necesario, crear tarea y planificar como Story 1.0
- [ ] `dart analyze` sin errores; `app_es.arb` actualizado
- [ ] Unit tests: optimistic update + revert en error para `FollowCubit`; paginación de listas
- [ ] Widget tests: `FollowersListPage`, `FollowingListPage`

---

### Iter-1: Deep Links + Apple Sign-In + Notification Routing

**Goal:** Activar el flujo de compartir eventos externamente con Android App Links e iOS Universal Links, añadir Apple Sign-In (requisito App Store), y completar el routing de notificaciones push a las pantallas destino.

**Pre-flight (before any code):**
- [ ] `com.apple.developer.applesignin` entitlement añadido en Xcode; nuevo provisioning profile generado (permitir 1 día hábil para propagación)
- [ ] Apple provider habilitado en Firebase Console y Apple Developer Portal
- [ ] Dominio (provisionado en iter-4): verificar `curl https://<domain>/.well-known/assetlinks.json` y `curl https://<domain>/.well-known/apple-app-site-association` retornan 200 con contenido correcto
- [ ] GoRouter DI: si el assessment de iter-4 determinó que se requiere refactoring, completarlo como Story 1.0 antes de implementar `NotificationRouteHandler`

**Stories:**

| ID | Story | Acceptance |
|----|-------|-----------|
| 1.1 | Como rider, puedo tocar el botón de compartir en el detalle de un evento y el app abre el share sheet nativo con un link listo para enviar. | Link generado en menos de 3 segundos; share sheet nativo con preview (nombre del evento + imagen de portada) en tarjeta de WhatsApp. |
| 1.2 | Como rider que recibe un link de evento y tiene la app instalada, al tocar el link la app abre directamente el detalle de ese evento. | Navegación funciona desde cold start y background; error apropiado si evento no existe o fue cancelado. |
| 1.3 | Como persona sin la app, al tocar el link en el navegador mobile es redirigida a la Play Store (Android) o App Store (iOS). | Redirección correcta en ambas plataformas; página de fallback muestra branding mínimo de Rideglory (no es un HTTP redirect vacío). |
| 1.4 | Como usuario de iPhone, puedo iniciar sesión o registrarme con Apple Sign-In en la pantalla de login. | Flujo de auth completo; perfil creado igual que con Google Sign-In; botón solo visible en iOS. |
| 1.5 | Como rider, cuando toco cualquier notificación push la app navega directamente a la pantalla relevante sin pasar por Home. | 7 tipos de notificación enrutan correctamente: SOAT → detalle vehículo, inscripción aprobada/rechazada → detalle inscripción, nuevo inscrito → gestión inscritos, mantenimiento → detalle mantenimiento, seguidor → perfil rider. Funciona desde cold start y background. `NotificationRouteHandler` muestra error apropiado si la entidad destino ya no existe (no crash). |

**Definition of done:**
- [ ] Design gate: Botón de compartir en `EventDetailPage` y botón Apple Sign-In en login confirmados en frames; Apple Sign-In usa botón negro con logo Apple (HIG compliance)
- [ ] Backend: `GET /api/events/:eventId/share-metadata` con `Cache-Control: public, max-age=3600`
- [ ] Backend (o Firebase Hosting): sirve `/.well-known/assetlinks.json` y `/.well-known/apple-app-site-association`; página de redirect detecta User-Agent y redirige a Play Store / App Store con branding Rideglory mínimo
- [ ] Flutter: `app_links ^2.x` integrado; `AndroidManifest.xml` con intent-filter para App Links; iOS Associated Domains entitlement
- [ ] Flutter: `sign_in_with_apple ^2.x` integrado; botón solo en iOS (`defaultTargetPlatform == TargetPlatform.iOS`)
- [ ] Flutter: `NotificationRouteHandler` en `lib/core/services/` — `@singleton` en DI, registrado antes de `GoRouter` en `main.dart`; maneja `onMessageOpenedApp` (background) y `getInitialMessage` (cold start); graceful error si entidad destino no existe
- [ ] `dart analyze` sin errores; `app_es.arb` actualizado (botón compartir, mensajes de error)
- [ ] Privacy policy URL en `Info.plist`
- [ ] Prueba en device físico iOS: cold-start Universal Link + Apple Sign-In
- [ ] Prueba en device físico Android: cold-start App Link
- [ ] 7 tipos de notificación verificados que enrutan correctamente a pantallas destino (story 1.5 completa)

---

## Dependencies and sequencing

```
iter-1 (UI/UX Redesign — frontend only)
  |  Establishes: consistent design system baseline across all existing screens
  |  Pre-condition: gap analysis and Pencil frame inspection BEFORE any code
  |  Output: all 15 existing screens aligned with rideglory.pen
  v
iter-2 (SOAT + Notification Foundation)
  |  Establishes: FCM infrastructure, notifications table in api-gateway,
  |               notification center UI, SOAT domain, cursor pagination contract
  |               ManageAttendeesPage redesign (Story 2.9)
  v
iter-3 (Tracking Completo + SOS + Maintenance Reminders)
  |  Story 3.0 (Mapbox migration) must merge before 3.1–3.7 begin
  |  Depends on iter-2: push notification infrastructure for SOS FCM multicast
  |  Establishes: Mapbox-only SDK, background GPS, GeoJSON route, SOS UI
  v
iter-4 (Seguidores + Perfil Completo)
  |  Depends on iter-2: notification center and notifications table
  |                     (follower push inserts into same table)
  |  Action item: provision deep link domain (blocker for iter-1)
  v
iter-1 (Deep Links + Apple Sign-In + Notification Routing)
     Depends on iter-2: all notification types required for routing (story 1.5)
     Depends on iter-4: follower notification type + deep link domain provisioned
```

---

## Risks

| Rank | Risk | Iter | Mitigation |
|------|------|------|------------|
| 1 | Pre-flight takes longer than expected (auth frames missing, donut chart ambiguity, 15-screen gap analysis) — delays code start | 5 | Enforce design gate strictly: no Flutter code until gap analysis is complete and reviewed. Parallelize: Designer inspects Pencil while Developer runs `dart analyze` baseline on main. |
| 2 | Iter-4 AI cover generation widget breaks during event form refactor (Story 1.6) | 5 | Mandatory smoke test case: generate cover → select image → save event → confirm widget functional. Treat as a blocking acceptance criterion, not advisory. |
| 3 | 95–135 file PR is unreviewable as a single diff | 5 | Split into 5–6 module-scoped PRs merged into a feature branch. Each PR requires `dart analyze` + `flutter test` green before merge. |
| 4 | Iter-1 redesign causes regressions in existing functionality (iter-4 AI cover, event form, maintenance donut chart) | 5 | 5 mandatory smoke tests before final merge to main. All existing widget tests must pass green after each module PR. |
| 5 | Background GPS Android foreground service fails on battery-restricted devices (Xiaomi, Samsung) — untestable in emulator | 7 | Physical device test mandatory from day 1 of iter-3. Separate Android/iOS test plans. |
| 6 | Deep link domain unresolved — iter-1 cannot start without `assetlinks.json` and `apple-app-site-association` live | 9 | Explicit iter-4 action item. Must be provisioned and verified before iter-4 closes. Hard stop. |
| 7 | api-gateway Prisma first-time setup (Docker Compose DB network, DATABASE_URL, port conflicts) more complex than estimated | 6 | Allot full pre-flight day. Document exact `DATABASE_URL` and Docker Compose changes in pre-flight runbook. |
| 8 | Story 3.0 (Mapbox migration) consumes full iter-3 sprint | 7 | 3.0 is already gated as iter-blocking. Widget test for `route_map_preview.dart` required before 3.0 PR can merge. |
| 9 | GoRouter not registered in GetIt — `NotificationRouteHandler` needs router reference | 9 | Assessment in iter-4 DoD. If refactoring needed, scope as Story 1.0 pre-flight. |

---

## Deferred

| Item | Reason | Candidate |
|------|--------|-----------|
| OCR auto-fill del SOAT | Alta complejidad (ML Kit / Cloud Vision); entrada manual es suficiente para MVP | post-iter-1 |
| Recordatorio de mantenimiento por km (odómetro) | Requiere sistema de tracking de odómetro no definido en el PRD | post-iter-1 |
| Dynamic Links para perfiles de riders | Bajo impacto vs. esfuerzo; eventos son el caso de uso crítico de sharing | post-iter-1 |
| Sugerencias de riders a seguir | Sin demanda validada para MVP | post-iter-1 |
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

---

## Open questions (max 3)

1. **`routeGeoJson` backend contract**: El Architect recomienda almacenar la ruta como GeoJSON LineString (`routeGeoJson Json?`) en lugar del campo `"polyline": "encoded_string"` del PRD §17.2. Confirmar esta decisión antes de comenzar iter-3.

2. **Deep link domain**: ¿Cuál es el dominio a usar para Android App Links e iOS Universal Links? ¿`links.rideglory.app` (subdomain + Firebase Hosting), o api-gateway sirve los archivos `.well-known/`? Este dominio debe estar decidido durante iter-4 action-item phase.

3. **`notifications` microservice scope futuro**: Para MVP, `notifications` vive en api-gateway. ¿Existe intención de extraerlo a un `notifications-ms` independiente después del MVP, o se consolida en api-gateway permanentemente?

---

## Refactor-01 — Refactor & Cleanup Extremo

> Status: AWAITING HUMAN APPROVAL
> Generated: 2026-05-27
> Run mode: FRESH (new PRD)
> Type: REFACTORING ONLY — zero new features, zero API changes

### Summary

This iteration eliminates the technical debt accumulated across 68+ feature files during recent product iterations. The work is pure internal refactoring: consolidate the duplicated SOAT implementation, extract one widget class per file, replace raw Flutter primitives with design system components, tokenize all hardcoded color literals, migrate navigation to go_router, and fix one confirmed UX bug. When the iteration closes, `dart analyze` reports 0 errors and 0 warnings, every feature file contains at most one widget class, and all shared-component adoption rules are mechanically verifiable by grep — with zero functional or visual changes for end users.

---

### Stories

---

#### REFACTOR-01: Fix SOAT loading-button bug

**Violation type:** UX bug — when `_openingDocument = true`, the "Ver documento" button changes its label to `soat_downloading` instead of passing `isLoading: true` to `AppButton`, breaking the design system's loading-spinner contract.

**Files affected:**
- `lib/features/soat/presentation/widgets/soat_data_view.dart`

**Acceptance criteria:**
- [ ] Before coding: verify `lib/shared/widgets/form/app_button.dart` — when `isLoading: true`, `AppButton` must disable `onPressed` internally. If it does not guard the callback, the correct fix is `isLoading: _openingDocument` AND `onPressed: _openingDocument ? null : _openDocument` (both conditions simultaneously).
- [ ] `grep "soat_downloading" lib/features/soat/presentation/widgets/soat_data_view.dart` returns 0 results
- [ ] `grep "isLoading: _openingDocument" lib/features/soat/presentation/widgets/soat_data_view.dart` returns 1 result
- [ ] `AppButton.isLoading=true` disables `onPressed` — confirmed in `app_button.dart` before implementation or guarded with null-onPressed fallback
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — single-file change, no logic change, only button prop swap.
**Effort:** S (<1h)
**Depends on:** none

---

#### REFACTOR-02: Consolidate SOAT feature (move + router + DI regen)

**Violation type:** Code duplication — two active SOAT implementations convive; `vehicles/presentation/soat/` is partially dead code but several pages/cubits are still imported by the new `features/soat/` implementation and the router. Naive deletion causes compile errors.

**Files affected — MOVE (not delete):**
- `vehicles/presentation/soat/soat_manual_capture_page.dart` → `features/soat/presentation/pages/soat_manual_capture_page.dart`
- `vehicles/presentation/soat/soat_confirmation_page.dart` → `features/soat/presentation/pages/soat_confirmation_page.dart`
- `vehicles/presentation/soat/cubit/soat_form_cubit.dart` + `soat_form_cubit.freezed.dart` → `features/soat/presentation/cubit/`
- `vehicles/presentation/soat/widgets/soat_document_section.dart` → `features/soat/presentation/widgets/`
- `vehicles/presentation/soat/widgets/soat_validity_card.dart` → `features/soat/presentation/widgets/`
- `vehicles/presentation/soat/widgets/vehicle_soat_options_sheet.dart` → `features/soat/presentation/widgets/soat_vehicle_options_sheet.dart`

**Files affected — DELETE outright** (superseded, not imported externally):
- `vehicles/presentation/soat/soat_upload_page.dart` (legacy — replaced by new `soat_upload_page.dart`)
- `vehicles/presentation/soat/cubit/soat_upload_cubit.dart` (marked `@injectable` — regen DI after deletion)
- `vehicles/presentation/soat/widgets/soat_upload_option_card.dart`
- `vehicles/presentation/soat/widgets/soat_manual_option_card.dart`
- `vehicles/presentation/soat/widgets/soat_upload_question_header.dart`
- `vehicles/presentation/soat/widgets/soat_vehicle_info_card.dart`
- `vehicles/presentation/soat/widgets/soat_doc_preview.dart`
- `vehicles/presentation/soat/widgets/soat_confirm_cta_bar.dart`
- `vehicles/presentation/soat/widgets/soat_valid_alert.dart`

**Files affected — update imports + blast perimeter:**
- `lib/shared/router/app_router.dart` — remove legacy alias import; rewire `/vehicles/soat` route builder to use new `SoatUploadPage`; add named `GoRoute` for `AppRoutes.soatManualCapture`
- `lib/shared/router/app_routes.dart` — add `static const String soatManualCapture = '/soat/manual-capture'`
- `lib/features/soat/presentation/pages/soat_manual_capture_params.dart` — NEW: simple params class (`VehicleModel?`, `SoatModel?`, `String? initialLocalImagePath`)
- `lib/features/soat/presentation/widgets/soat_status_view.dart` — update import; migrate `Navigator.of(context).push<bool>(SoatManualCapturePage)` → `context.push<bool>(AppRoutes.soatManualCapture, extra: SoatManualCaptureParams(...))`; migrate page-level `Navigator.of(context).pop(true)` → `context.pop(true)`
- `lib/features/soat/presentation/widgets/soat_source_grid.dart` — update import; migrate `Navigator.of(context).push<bool>(SoatManualCapturePage)` → `context.push<bool>(AppRoutes.soatManualCapture, extra: SoatManualCaptureParams(...))`
- `lib/features/vehicles/presentation/form/vehicle_form_docs_section.dart` — update imports; migrate `Navigator.of(context).push<PendingManualSoat>(SoatManualCapturePage)` → `context.push<PendingManualSoat>(AppRoutes.soatManualCapture, extra: SoatManualCaptureParams(...))`
- `lib/features/vehicles/presentation/form/vehicle_form_page.dart` — update import path for `SoatConfirmationPage`; annotate `Navigator.of(context).pushReplacement(...)` with `// Custom: pushReplacement — VehicleFormPage must not remain in back stack after SOAT confirmation`
- `soat_manual_capture_page.dart` (after move) — annotate 3× `Navigator.of(sheetCtx).pop(0/1/2)` calls inside `showModalBottomSheet` builder with `// Custom: sheetCtx.pop() — required pattern for showModalBottomSheet typed result return`; migrate page-level `Navigator.of(context).pop()` (line 262) → `context.pop()`
- Run `dart run build_runner build --delete-conflicting-outputs` after deleting `soat_upload_cubit.dart`

**Acceptance criteria:**
- [ ] `find lib/features/vehicles/presentation/soat -name "*.dart" 2>/dev/null | wc -l` returns 0
- [ ] `grep -r "vehicles/presentation/soat" lib/ --include="*.dart"` returns 0 results
- [ ] `grep "\/vehicles\/soat" lib/shared/router/app_router.dart` still returns 1 result (route kept, wired to new `SoatUploadPage`)
- [ ] `grep "soatManualCapture" lib/shared/router/app_routes.dart` returns 1 result
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions
- [ ] Manual smoke test: vehicle detail SOAT badge → upload page → manual capture form → save → back — all steps navigate correctly
- [ ] Manual smoke test: vehicle creation → SOAT photo section → photo attachment → confirmation page — works end to end
- [ ] Manual smoke test: SOAT status view → "Edit" button → manual capture form → save → status refreshes
- [ ] Manual smoke test: all 6 `vehicleSoat` callers (vehicle detail, vehicle form, SOAT data view, SOAT empty state, etc.) still navigate to the upload page correctly

**Risk:** High — 5 external files import from the legacy folder; 6 active callers use `AppRoutes.vehicleSoat`; a new named route for `SoatManualCapturePage` must be created; DI must be regenerated after deleting `SoatUploadCubit`; 3 typed-result `Navigator.of().push<bool>()` calls must be migrated.
**Effort:** M (2–3h)
**Depends on:** REFACTOR-01

---

#### REFACTOR-10: Fix `context.goNamed` navigation violations

**Violation type:** `context.goNamed()` used for navigation where `context.pushNamed()` or `context.pop()` is required.

**Files affected:**
- `lib/features/profile/presentation/profile_page.dart` — `context.goNamed(AppRoutes.home)` in `PopScope`
- `lib/features/vehicles/presentation/garage/garage_page.dart` — `context.goNamed(AppRoutes.home)` in `PopScope`
- `lib/features/events/presentation/list/events_page.dart` — `context.goNamed(AppRoutes.home)` in `PopScope`
- `lib/features/authentication/login/presentation/forgot_password_view.dart` — `context.goNamed(AppRoutes.login)` ×2

**Decision rules (confirmed by Architect):**
- `profile_page.dart`, `garage_page.dart`, `events_page.dart` in `PopScope`: **keep as `context.goNamed`** — shell-tab navigation must replace the stack or the `StatefulShellRoute` state machine breaks. Annotate each with `// Intentional: shell-tab navigation resets stack to prevent back-stack accumulation in StatefulShellRoute`.
- `forgot_password_view.dart` ×2: the view is pushed via `context.pushNamed(AppRoutes.forgotPassword)`, so returning should use `context.pop()`. Change both calls to `context.pop()`.

**Acceptance criteria:**
- [ ] `grep -rn "context\.goNamed" lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results
- [ ] All 3 shell-tab `context.goNamed` calls annotated with `// Intentional: shell-tab navigation resets stack to prevent back-stack accumulation in StatefulShellRoute`
- [ ] Both `context.goNamed(AppRoutes.login)` calls in `forgot_password_view.dart` replaced with `context.pop()`
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — 5 isolated navigation calls. Shell-tab calls remain as-is with annotation.
**Effort:** S (1h)
**Depends on:** REFACTOR-02 (clean baseline)

---

#### REFACTOR-08: Replace FormBuilderTextField with AppTextField

**Violation type:** Prohibited use of `FormBuilderTextField` where `AppTextField` exists.

**Files affected (5 occurrences in 4 files):**
- `lib/features/vehicles/presentation/form/widgets/vehicle_specs_row.dart` — 1 instance
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_id_section.dart` — 2 instances
- `lib/features/maintenance/presentation/form/widgets/maintenance_next_km_pill.dart` — 1 instance
- `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` — 1 instance

**Acceptance criteria:**
- [ ] `grep -rn "FormBuilderTextField" lib/features/ --include="*.dart"` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — `AppTextField` is a direct wrapper around `FormBuilderTextField`; verify each instance's `name` prop and validators map correctly.
**Effort:** S (1h)
**Depends on:** REFACTOR-02 (clean baseline)

---

#### REFACTOR-07: Replace raw Flutter buttons with AppButton/AppTextButton

**Violation type:** Prohibited use of `ElevatedButton`, `TextButton`, `OutlinedButton` directly in feature files.

**Files affected (8 instances across 6 files):**
- `lib/features/users/presentation/widgets/rider_profile_content.dart` — 1× `ElevatedButton`
- `lib/features/events/presentation/form/widgets/event_form_view.dart` — 3× `TextButton`
- `lib/features/events/presentation/form/screens/event_route_config_screen.dart` — 1× `TextButton`
- `lib/features/events/presentation/tracking/widgets/end_ride_confirm_dialog.dart` — 1× `TextButton`
- `lib/features/events/presentation/tracking/widgets/sos_active_overlay.dart` — 1× `OutlinedButton`
- `lib/features/events/presentation/tracking/widgets/sos_confirm_dialog.dart` — 1× `TextButton`

**Note:** `sos_active_overlay.dart` OutlinedButton may require `// Custom: SOS overlay requires OutlinedButton — AppButton does not expose outline variant with this styling` if `AppButton` does not cover the required style. Verify before replacing.

**Pre-condition for REFACTOR-07:** Inspect `test/features/users/rider_profile_page_test.dart` — if it uses `find.byType(ElevatedButton)`, it will fail after replacement. Update the test in the same commit.

**Acceptance criteria:**
- [ ] `grep -rn "ElevatedButton\|OutlinedButton\|TextButton" lib/features/ --include="*.dart" | grep -v "// Custom:"` returns 0 results
- [ ] Any retained raw button is annotated with `// Custom: <reason>` on the same line
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — `AppButton` and `AppTextButton` cover all required variants. SOS overlay may need annotation.
**Effort:** S (1–2h)
**Depends on:** REFACTOR-02 (clean baseline)

---

#### REFACTOR-11: Tokenize hardcoded colors (all 25 files)

**Violation type:** `Color(0x...)` and `Colors.*` literals used directly in feature `build()` methods.

**Pre-condition — color value decision (must be committed first):**

Before touching any color literal, audit `lib/core/theme/app_colors.dart` and document the decision:
- For `Color(0xFF22C55E)` (Tailwind green-500) and `Color(0xFFEAB308)` (Tailwind yellow-500): add `AppColors.statusGreen = Color(0xFF22C55E)` and `AppColors.statusWarning = Color(0xFFEAB308)` as new tokens — this preserves the exact rendered color vs. mapping to the existing (different) `AppColors.success`/`AppColors.warning` tokens.
- For `Color(0x66F98C1F)` (primary at 40% opacity): add `AppColors.primarySubtle` or use `colorScheme.primary.withValues(alpha: 0.4)`.
- For `Color(0xFFEF4444)` (Tailwind red-500): add `AppColors.statusError` if not already present.
- Verify `AppColors.success` (#10B981), `AppColors.warning` (#F59E0B), `AppColors.error` (#EF4444) exist; add missing ones.
- `surfaceTintColor: Colors.transparent` — acceptable Flutter Material3 idiom; annotate `// Intentional: remove Material3 surface tint`.
- Gradient overlay stops with `Colors.transparent` — annotate `// Intentional: gradient stop`.
- `Colors.white` / `Colors.black` inside dark-mode containers: prefer `colorScheme.onSurface`, `colorScheme.onPrimary`, or `colorScheme.surface` where semantically correct.

**Files affected — `Color(0x...)` literals (7 confirmed + 18 additional):**
- `lib/features/home/presentation/widgets/home_vehicle_info_row.dart`
- `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart`
- `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart`
- `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart`
- `lib/features/profile/presentation/edit_profile_page.dart`
- `lib/features/profile/presentation/widgets/profile_header.dart`
- `lib/features/users/presentation/widgets/rider_profile_content.dart`
- `lib/features/maintenance/presentation/widgets/maintenance_type_style.dart`
- `lib/features/maintenance/presentation/detail/widgets/maintenance_next_service_card.dart`
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_status_toggle.dart`
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_next_date_pill.dart`
- `lib/features/maintenance/presentation/form/widgets/maintenance_next_km_pill.dart`
- `lib/features/maintenance/presentation/detail/maintenance_type_card.dart`
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart`
- `lib/features/maintenance/presentation/list/maintenances/maintenances_data_widget.dart`
- `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart`
- `lib/features/maintenance/presentation/widgets/item_card/modern_maintenance_card.dart`
- `lib/features/events/presentation/detail/event_detail_view.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_cta_bar.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart`
- `lib/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart`
- `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart`

**Files affected — `Colors.*` literals:**
- `lib/features/home/presentation/widgets/home_event_view_details_button.dart`
- `lib/features/home/presentation/widgets/home_view_all_events_button.dart`
- `lib/features/home/presentation/widgets/home_event_card.dart`
- `lib/features/home/presentation/widgets/home_event_gradient_overlay.dart`
- `lib/features/home/presentation/widgets/home_event_difficulty_badge.dart`
- `lib/features/event_registration/presentation/registration_detail_page.dart`
- `lib/features/event_registration/presentation/my_registrations_view.dart`
- `lib/features/event_registration/presentation/widgets/inscription_card.dart`
- `lib/features/event_registration/presentation/widgets/my_registrations_filter_bottom_sheet.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_specs_row.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_cover_section.dart`

**Note:** Color tokenization for files shared with widget-extraction stories (e.g., `garage_vehicles_content.dart`, `event_detail_view.dart`) should be done in the same commit as the widget extraction to avoid double-editing.

**Acceptance criteria:**
- [ ] New color tokens (`AppColors.statusGreen`, `AppColors.statusWarning`) committed to `lib/core/theme/app_colors.dart` as the first commit of this story
- [ ] `grep -rn "Color(0x" lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results
- [ ] `grep -rn "Colors\." lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results (or ≤5 annotated exceptions)
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low-Medium — purely cosmetic; status colors require new tokens (not blind mapping to existing ones) to preserve exact rendered color.
**Effort:** M (2–3h)
**Depends on:** REFACTOR-03a, REFACTOR-06a (do color work after files are split to avoid double-editing)

---

#### REFACTOR-13: Fix direct `showDialog` call — use AppDialog wrapper

**Violation type:** `showDialog(...)` called directly instead of using the `AppDialog`/`ConfirmationDialog` wrapper. Rule: coding standards §Components — "Prohibido llamar `showDialog(...)` directamente."

**Files affected:**
- `lib/features/maintenance/presentation/widgets/item_card/info_chip_tooltip.dart`

**Decision for developer:** `MileageInfoDialog` is an info-only tooltip with no CTA buttons. If `AppDialog` requires action buttons and does not support an info-only variant, annotate with `// Custom: MileageInfoDialog is an info-only tooltip — AppDialog requires action buttons`. Otherwise migrate to use `AppDialog`.

**Acceptance criteria:**
- [ ] `grep -rn "showDialog(" lib/features/ --include="*.dart" | grep -v "// Custom:\|AppDialog\|ConfirmationDialog"` returns 0 results
- [ ] `Colors.black.withValues` usage in `info_chip_tooltip.dart` also replaced with `AppColors.*` or `colorScheme.*`
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — single-file change.
**Effort:** S (<1h)
**Depends on:** REFACTOR-02 (clean baseline)

---

#### REFACTOR-04: Widget extraction — Authentication feature

**Violation type:** Multiple widget classes per file. `forgot_password_view.dart` (9 widgets), `login_view.dart` (8 widgets), `signup_view.dart` (6 widgets).

**Files affected (extract FROM):**
- `lib/features/authentication/login/presentation/forgot_password_view.dart`
- `lib/features/authentication/login/presentation/login_view.dart`
- `lib/features/authentication/signup/presentation/signup_view.dart`

**Extraction strategy:** Auth screens are typically stateless forms — straightforward extraction. Create a `widgets/` subdirectory when extracting 4+ widgets from a single file.

**Acceptance criteria:**
- [ ] `find lib/features/authentication -name "*.dart" | while read f; do count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null); if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi; done` returns 0 lines
- [ ] `grep "Widget _build\|Widget _[a-z]" lib/features/authentication/ --include="*.dart" -rn | grep -v "//"` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions
- [ ] Manual smoke test: Login → Forgot Password → back to Login; Signup flow start to end

**Risk:** Low — auth screens are stateless forms; no complex shared state.
**Effort:** M (3–4h)
**Depends on:** REFACTOR-10 (both touch `forgot_password_view.dart`)

---

#### REFACTOR-03a: Widget extraction — Vehicles (garage content + vehicle detail)

**Violation type:** Multiple widget classes per file. `garage_vehicles_content.dart` (16 widgets + 2 widget-returning methods), `vehicle_detail_view.dart` (13 widgets). These are the highest-risk extractions in the entire iteration.

**Files affected (extract FROM):**
- `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart`
- `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart`

**Extraction strategy (mandatory approach for `garage_vehicles_content.dart`):**
1. Audit: classify each of the 16 classes as pure-display (all data via constructor), state-consumer (calls `context.read<VehicleCubit>()`), or state-mutator (triggers cubit methods).
2. Extract pure-display classes first, one per commit; run `dart analyze && flutter test` after each.
3. State consumers: extract with `BlocBuilder` encapsulated inside the new widget file — do NOT pass `BuildContext` as a constructor param.
4. State mutators: pass typed callback as constructor param — extracted widget never calls cubit directly.
5. `_buildPlaceholderIcon()` → extract as `GaragePlaceholderIcon` (pure leaf).
6. `_buildContainer()` → extract as `GarageVehicleCard`, passing all data as constructor params.
7. Color literals (`Color(0xFF22C55E)`, `Color(0xFFEAB308)` in `_MaintenanceCard`) must be replaced with `AppColors.statusGreen`/`AppColors.statusWarning` in the same commit as extraction.

**Acceptance criteria:**
- [ ] `find lib/features/vehicles/presentation/garage -name "*.dart" | while read f; do count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null); if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi; done` returns 0 lines
- [ ] `grep "Widget _build\|Widget _[a-z]" lib/features/vehicles/presentation/garage/ --include="*.dart" -rn | grep -v "//"` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** High — `garage_vehicles_content.dart` has 16 classes; `_MaintenanceWidget` calls `getIt<GetMaintenancesByVehicleIdUseCase>()` (correct, preserve). Extract one widget per commit and run `flutter test` after each.
**Effort:** L (5–6h)
**Depends on:** REFACTOR-08

---

#### REFACTOR-03b: Widget extraction — Vehicles (form + docs + soat section)

**Violation type:** Multiple widget classes per file. `vehicle_form.dart` (9 widgets), `vehicle_document_upload_slot.dart` (4 widgets), `vehicle_form_page.dart` (2 widgets), `vehicle_form_cover_section.dart` (4 widgets), `vehicle_form_id_section.dart` (3 widgets), `vehicle_form_docs_section.dart` (2 widgets), `vehicle_card.dart` (widget-returning method `_buildPlaceholderIcon()`).

**Files affected (extract FROM):**
- `lib/features/vehicles/presentation/widgets/vehicle_form.dart`
- `lib/features/vehicles/presentation/widgets/vehicle_document_upload_slot.dart`
- `lib/features/vehicles/presentation/form/vehicle_form_page.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_cover_section.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_id_section.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart`
- `lib/features/vehicles/presentation/widgets/vehicle_card.dart`

**Note:** `vehicle_form_page.dart`'s `Navigator.of(context).pushReplacement(...)` and modal bottom sheet `pop()` calls are JUSTIFIED EXCEPTIONS — they are already annotated with `// Custom:` per REFACTOR-02. Do NOT migrate them here.

**Extraction strategy:** Each section receives `GlobalKey<FormBuilderState>` via constructor (existing pattern); maintain this pattern for safe extraction.

**Acceptance criteria:**
- [ ] `find lib/features/vehicles/presentation -name "*.dart" | while read f; do count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null); if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi; done` returns 0 lines
- [ ] `grep "Widget _build\|Widget _[a-z]" lib/features/vehicles/presentation/ --include="*.dart" -rn | grep -v "//"` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Medium — multi-step form with `GlobalKey<FormBuilderState>` shared across sections. Maintain constructor-injection pattern.
**Effort:** M (3–4h)
**Depends on:** REFACTOR-03a

---

#### REFACTOR-05a: Widget extraction — Events (detail + CTA bar)

**Violation type:** Multiple widget classes per file. `event_detail_view.dart` (9 widgets + 1 widget-returning method `_shell()`), `event_detail_cta_bar.dart` (8 widgets + `Widget _buildContent()` method), `event_detail_owner_lifecycle_bar.dart` (4 widgets), `event_detail_meeting_point_section.dart` (4 widgets), `event_detail_header.dart` (2 widgets), `event_detail_header_background_image.dart` (2 widgets), `event_detail_by_id_page.dart` (widget-returning method).

**Files affected (extract FROM):**
- `lib/features/events/presentation/detail/event_detail_view.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_cta_bar.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_meeting_point_section.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_header.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_header_background_image.dart`
- `lib/features/events/presentation/detail/event_detail_by_id_page.dart`

**Critical patterns to preserve:**
- `EventDetailViewState.currentEvent` is mutable local state — inner widgets receive `event` as constructor params (confirmed safe). After extraction, `onEdit` must remain as a typed callback; `setState(() => currentEvent = result)` must stay in `EventDetailViewState`.
- `event_detail_cta_bar.dart`: `_buildContent` method → extract as `EventDetailCtaBarContent extends StatelessWidget`. Each of the ~8 variants (e.g. `EventDetailRegisteredBanner`, `EventDetailPendingBanner`) becomes its own file in `detail/widgets/cta/`.
- `event_detail_meeting_point_section.dart` line 275: `Navigator.of(context).push(MaterialPageRoute(...EventRouteMapScreen...))` — `EventRouteMapScreen` has no named route. Developer must choose: (a) add `AppRoutes.eventRouteMap` to router and migrate, or (b) annotate `// Custom: EventRouteMapScreen has no go_router named route — anonymous push preserved`.

**Acceptance criteria:**
- [ ] `find lib/features/events/presentation/detail -name "*.dart" | while read f; do count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null); if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi; done` returns 0 lines
- [ ] `grep "Widget _build\|Widget _shell\|Widget _[a-z]" lib/features/events/presentation/detail/ --include="*.dart" -rn | grep -v "//"` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions
- [ ] Manual smoke test: Event detail CTA bar renders correctly in all 4 state variants (registered / pending / closed / full) — hard AC, no widget tests exist for this component

**Risk:** High — `event_detail_cta_bar.dart` has 8 state-variant widgets with no existing widget tests; extraction failures are silent at compile time.
**Effort:** L (5–6h)
**Depends on:** REFACTOR-07, REFACTOR-09

---

#### REFACTOR-05b: Widget extraction — Events (form + list + tracking + drafts)

**Violation type:** Multiple widget classes per file across events form, list, tracking, and drafts subsections.

**Files affected (extract FROM):**
- `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` (7 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` (6 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` (4 widgets)
- `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` (3 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart` (3 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_form_difficulty_section.dart` (3 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart` (3 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart` (3 widgets)
- `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` (2 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_route_type_selector.dart` (2 widgets)
- `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` (2 widgets)
- `lib/features/events/presentation/form/screens/event_route_config_screen.dart` (4 widgets)
- `lib/features/events/presentation/tracking/participants/participants_placeholder_page.dart` (3 widgets + 2 widget-returning methods)
- `lib/features/events/presentation/tracking/widgets/live_map_app_bar.dart` (4 widgets)
- `lib/features/events/presentation/list/widgets/event_card.dart` (5 widgets)
- `lib/features/events/presentation/list/widgets/events_data_view.dart` (4 widgets)
- `lib/features/events/presentation/list/widgets/events_page_view.dart` (2 widgets)
- `lib/features/events/presentation/list/widgets/event_card_header.dart` (widget-returning method `_buildPopupMenu()`)
- `lib/features/events/presentation/drafts/my_drafts_page.dart` (2 widgets)

**Note:** `event_form_locations_section.dart` contains `Navigator.of(context).push(MaterialPageRoute(...EventRouteConfigScreen...))` — same decision as REFACTOR-05a for unnamed routes.

**Acceptance criteria:**
- [ ] `find lib/features/events/presentation/form lib/features/events/presentation/tracking lib/features/events/presentation/list lib/features/events/presentation/drafts -name "*.dart" | while read f; do count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null); if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi; done` returns 0 lines
- [ ] `grep "Widget _buildEmptyState\|Widget _buildRiderList\|Widget _buildPopupMenu" lib/features/events/ --include="*.dart" -rn` returns 0 results
- [ ] All event_form_*_section.dart files: each returns ≤1 on the widget-class check
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions (widget tests for `event_filters_bottom_sheet`, `events_page_view`, `attendees_list_navigation` must continue to pass)

**Risk:** Medium — 19 source files; form sections are tightly coupled but pattern of explicit constructor params is consistent.
**Effort:** L (5–7h)
**Depends on:** REFACTOR-05a

---

#### REFACTOR-06a: Widget extraction — Maintenance feature + showDialog fix

**Violation type:** Multiple widget classes per file in maintenance feature + direct `showDialog` call.

**Files affected (extract FROM):**
- `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` (12 widgets — `StatefulWidget` using `setState` for `_filters` local state; keep outer `StatefulWidget` + `State` pair in one file; extract only stateless sub-components: filter chips, section headers, type selectors)
- `lib/features/maintenance/presentation/list/maintenances/maintenances_page.dart` (3 widgets)
- `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart` (3 widgets)
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_summary_widget.dart` (2 widgets)
- `lib/features/maintenance/presentation/detail/widgets/maintenance_next_service_card.dart` (2 widgets)
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart` (widget-returning method `_rightBadge()`)
- `lib/features/maintenance/presentation/widgets/item_card/info_chip_tooltip.dart` — `showDialog` violation (see REFACTOR-13); may be combined with this story if REFACTOR-13 is not done first

**Note:** `maintenance_filters_bottom_sheet.dart:95` has `Navigator.pop(context, _filters)` — this is a pop-with-result that must be migrated to `context.pop(_filters)` in this story or REFACTOR-09.

**Acceptance criteria:**
- [ ] `find lib/features/maintenance -name "*.dart" | while read f; do count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null); if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi; done` returns 0 lines
- [ ] `grep "Widget _rightBadge\|Widget _build\|Widget _[a-z]" lib/features/maintenance/ --include="*.dart" -rn | grep -v "//"` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions
- [ ] Manual smoke test: Maintenance list → open filters → select type → apply → list filters correctly

**Risk:** Medium — `maintenance_filters_bottom_sheet.dart` (12 classes) holds local selection state in `StatefulWidget`; extract only stateless sub-components.
**Effort:** M (3–4h)
**Depends on:** REFACTOR-04

---

#### REFACTOR-06b: Widget extraction — Home + Profile + Registration features

**Violation type:** Multiple widget classes per file across home, profile, users, and event_registration features.

**Files affected (extract FROM):**
- `lib/features/home/presentation/widgets/home_event_card.dart` (5 widgets)
- `lib/features/home/presentation/home_page.dart` (2 widgets)
- `lib/features/home/presentation/widgets/home_garage_section.dart` (2 widgets)
- `lib/features/profile/presentation/edit_profile_page.dart` (3 widgets)
- `lib/features/profile/presentation/widgets/profile_stats_row.dart` (3 widgets)
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` (3 widgets)
- `lib/features/profile/presentation/widgets/profile_header.dart` (2 widgets)
- `lib/features/profile/presentation/widgets/profile_garage_section.dart` (2 widgets)
- `lib/features/profile/presentation/widgets/profile_content.dart` (2 widgets)
- `lib/features/users/presentation/widgets/rider_profile_content.dart` (4 widgets)
- `lib/features/event_registration/presentation/event_registration_page.dart` (2 widgets)
- `lib/features/event_registration/presentation/registration_detail_page.dart` (2 widgets)
- `lib/features/event_registration/presentation/widgets/inscription_card.dart` (2 widgets)

**Acceptance criteria:**
- [ ] `find lib/features/home lib/features/profile lib/features/users lib/features/event_registration -name "*.dart" | while read f; do count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null); if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi; done` returns 0 lines
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low-Medium — profile and registration files are small and isolated; `home_event_card.dart` (5 classes) is the heaviest file.
**Effort:** M (3–4h)
**Depends on:** REFACTOR-06a

---

#### REFACTOR-09: Migrate Navigator.of → go_router (remaining)

**Violation type:** Prohibited use of `Navigator.of(context).push*` / `.pop()` and `Navigator.pop(context)` form where go_router should be used.

**Files affected — `Navigator.of(context).` simple pops (safe to replace with `context.pop()`):**
- `lib/features/maintenance/presentation/form/maintenance_form_page.dart` (2 calls; one returns `List<MaintenanceModel>` — verify caller reads future)
- `lib/features/maintenance/presentation/form/widgets/change_vehicle_mileage_bottom_sheet.dart` (2 calls)
- `lib/features/maintenance/presentation/form/widgets/maintenance_form_content.dart` (1 call)
- `lib/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart` (2 calls)
- `lib/features/events/presentation/form/screens/event_route_config_screen.dart` (2 calls)
- `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` (1 call)
- `lib/features/events/presentation/detail/event_detail_view.dart` (1 call)
- `lib/features/events/presentation/detail/event_route_map_screen.dart` (1 call)
- `lib/features/events/presentation/attendees/widgets/attendees_filter_bottom_sheet.dart` (1 call)
- `lib/features/event_registration/presentation/widgets/my_registrations_filter_bottom_sheet.dart` (2 calls)
- `lib/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart` (2 calls)
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart` (1 simple back navigation call)
- `lib/features/soat/presentation/widgets/soat_source_grid.dart` (1 call — if not already migrated in REFACTOR-02)

**Files affected — `Navigator.pop(context)` form (additional 6 calls not caught by `Navigator\.of(context)\.` grep):**
- `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` (3 simple pops: archive, delete, set-main — verify all 3 actions function post-migration)
- `lib/features/maintenance/presentation/detail/widgets/maintenance_options_bottom_sheet.dart` (2 pops with typed result `MaintenanceAction.*` — verify caller reads future)
- `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` (1 pop with result `_filters` — verify `showModalBottomSheet` caller reads returned future; may be already done in REFACTOR-06a)

**Justified exceptions (annotate, do not migrate):**
- `vehicle_form_page.dart`: `Navigator.of(context).pushReplacement(...)` → already annotated in REFACTOR-02 with `// Custom: pushReplacement — VehicleFormPage must not remain in back stack after SOAT confirmation`
- `soat_manual_capture_page.dart`: 3× `Navigator.of(sheetCtx).pop(0/1/2)` inside `showModalBottomSheet` builder → already annotated in REFACTOR-02 with `// Custom: sheetCtx.pop() — required pattern for showModalBottomSheet typed result return`

**Decision required before implementation:** For `EventRouteConfigScreen` and `EventRouteMapScreen` (no named routes in `app_routes.dart`): choose Option A (add named routes) or Option B (annotate `// Custom: screen has no go_router named route — anonymous push preserved`). Document the choice.

**Acceptance criteria:**
- [ ] `grep -rn "Navigator\.of(context)\." lib/features/ --include="*.dart" | grep -v "// Custom:"` returns 0 results
- [ ] `grep -rn "Navigator\.pop(context" lib/features/ --include="*.dart" | grep -v "SystemNavigator\|// Custom:"` returns 0 results
- [ ] All remaining `Navigator.of`/`Navigator.pop` calls annotated with `// Custom: <reason>`
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions
- [ ] Manual smoke test: Maintenance list → open filters → apply → list filters correctly (verifies `maintenance_filters_bottom_sheet.dart` pop-with-result)
- [ ] Manual smoke test: Garage → vehicle options (archive / delete / set main) — all three actions function after migration

**Risk:** Medium — `Navigator.pop(context)` form not caught by standard grep; pop-with-result cases must be verified individually.
**Effort:** M (3–4h)
**Depends on:** REFACTOR-02, REFACTOR-05a, REFACTOR-06a

---

#### REFACTOR-14: Centralizar header de navegación de forms (AppFormNavHeader)

**Violation type:** Duplicación de UI — el patrón "header de form con acción izquierda + título centrado + acción derecha + borde inferior" está re-implementado ad-hoc en al menos 3 features (vehículos, mantenimiento, eventos) con pequeñas variaciones de estilo, tipografía, alturas y colores. No existe un componente compartido y cualquier cambio de diseño requiere editar N archivos.

**Inventario actual (auditado):**

| Archivo | Tipo | Altura | Izq. | Centro | Der. | Notas |
|---|---|---|---|---|---|---|
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_nav_header.dart` | `PreferredSizeWidget` | 56 | "Cancelar" texto | título dinámico (add/edit) | "Guardar" texto, opacity loading | borde inferior, dark bg |
| `lib/features/maintenance/presentation/form/widgets/maintenance_form_nav_header.dart` | `PreferredSizeWidget` | 52 | back icon en pill 36×36 | título + 2 barras de progreso | "Listo" en pill primary | BLoC-aware loading |
| `lib/features/events/presentation/form/widgets/event_form_view.dart` (AppBar embebido, líneas ~77-130) | `AppBar` | kToolbar | `TextButton` "Cancelar" | título dinámico (new/edit) | `TextButton` "Publicar" + loading | no es PreferredSize custom |

**Out of scope (variantes distintas — no se incluyen en este refactor):**
- `lib/features/events/presentation/tracking/widgets/live_map_app_bar.dart` — `LiveMapSimpleAppBar` y `LiveMapOverlayAppBar` son overlays transparentes sobre mapa con badge live; patrón visual distinto.
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenances_page_app_bar.dart` — ya usa `AppAppBar` del design system, no es form header.

**Files affected — CREATE:**
- `lib/design_system/molecules/app_form_nav_header.dart` — NEW: widget parametrizable que implementa `PreferredSizeWidget`.

**API propuesta (a confirmar por design durante implementación):**
```dart
class AppFormNavHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppFormNavHeader({
    super.key,
    required this.title,
    this.leading,           // AppFormNavAction (text o icon)
    this.trailing,          // AppFormNavAction (text, pill o icon) — soporta isLoading
    this.bottom,            // Widget opcional para slot inferior (ej: progress bars de maintenance)
    this.height = 56,
    this.showBottomBorder = true,
    this.centerTitle = true,
  });
  // ...
}

// Sealed class para variantes de acción:
sealed class AppFormNavAction {
  const factory AppFormNavAction.text({required String label, required VoidCallback onTap, bool emphasized, bool isLoading}) = _TextAction;
  const factory AppFormNavAction.icon({required IconData icon, required VoidCallback onTap, bool pill}) = _IconAction;
  const factory AppFormNavAction.pillText({required String label, required VoidCallback onTap, bool isLoading}) = _PillTextAction;
}
```

**Files affected — MIGRATE & DELETE:**
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_nav_header.dart` → usar `AppFormNavHeader` con `leading: text("Cancelar")`, `trailing: text("Guardar", emphasized: true, isLoading: ...)`. Archivo eliminado tras migrar callers.
- `lib/features/maintenance/presentation/form/widgets/maintenance_form_nav_header.dart` → `AppFormNavHeader` con `leading: icon(back, pill: true)`, `trailing: pillText("Listo", isLoading: ...)`, `bottom: MaintenanceFormProgressBars(...)` (extraer barras de progreso como widget separado). Altura ajustada a 52 vía param; archivo eliminado tras migrar.
- `lib/features/events/presentation/form/widgets/event_form_view.dart` (AppBar interno) → reemplazar `AppBar` por `AppFormNavHeader` montado en `Scaffold.appBar` (acepta `PreferredSizeWidget`).

**Callers a actualizar (inventario rápido — confirmar con grep durante implementación):**
- `lib/features/vehicles/presentation/form/vehicle_form_page.dart` (usa `VehicleFormNavHeader`)
- `lib/features/maintenance/presentation/form/maintenance_form_page.dart` (usa `MaintenanceFormNavHeader`)
- `lib/features/events/presentation/form/widgets/event_form_view.dart` (AppBar inline)

**Acceptance criteria:**
- [ ] `lib/design_system/molecules/app_form_nav_header.dart` existe y exporta `AppFormNavHeader` + `AppFormNavAction` sealed class
- [ ] `find lib/features -name "*_form_nav_header.dart" -o -name "*_nav_header.dart" | xargs grep -l "class.*extends StatelessWidget.*PreferredSizeWidget"` retorna 0 resultados (todos los headers viejos eliminados)
- [ ] `grep -rn "VehicleFormNavHeader\|MaintenanceFormNavHeader" lib/` retorna 0 resultados
- [ ] `event_form_view.dart` usa `AppFormNavHeader` en lugar de `AppBar` con `TextButton` leading/actions
- [ ] Cero regresiones visuales: las 3 pantallas (vehicle form, maintenance form, event form) renderizan idénticamente a antes — verificado por smoke test manual con screenshots antes/después
- [ ] `dart analyze lib/` pasa con 0 errores
- [ ] `flutter test` pasa con 0 regresiones
- [ ] Strings localizados — si los labels actuales tienen claves específicas por feature (ej: `vehicle_form_nav_cancel`, `event_form_nav_cancel`), evaluar unificación contra REFACTOR-15 (mismo ciclo)
- [ ] Smoke test manual: (a) abrir vehicle form (crear y editar) → header renderiza correctamente, loading state al guardar funciona; (b) abrir maintenance form → progress bars visibles en slot `bottom`, pill "Listo" funciona; (c) abrir event form (crear y editar) → ambas variantes "Nuevo Evento" / "Editar Evento" funcionan, loading state visible al publicar

**Risk:** Medium — 3 features dependen del header; cambio simultáneo en widget compartido. Maintenance tiene la variación más rica (altura 52, slot inferior con progress bars, pill-style buttons). Riesgo de regresión visual mitigado con screenshots y verificación pantalla por pantalla.
**Effort:** M (3–4h)
**Depends on:** REFACTOR-03b (vehicles form extraction), REFACTOR-05b (events form extraction), REFACTOR-06a (maintenance extraction) — todos los archivos involucrados deben haber pasado por widget-extraction antes para evitar doble edición.

---

#### REFACTOR-15: Limpieza de `app_es.arb` (unused keys + duplicados)

**Violation type:** Deuda de localización — `lib/l10n/app_es.arb` tiene 1357 entradas acumuladas a lo largo de múltiples iteraciones; muchas son legacy de pantallas eliminadas o variantes que pueden unificarse (ej: "Cancelar", "Guardar", "Volver", "Confirmar", "Continuar" repetidas bajo prefijos distintos como `vehicle_*`, `event_*`, `maintenance_*`, `auth_*`). Cada key extra inflama los generated files y dificulta encontrar la clave correcta al implementar nuevas pantallas.

**Files affected:**
- `lib/l10n/app_es.arb` (audit + delete + rename)
- `lib/l10n/app_localizations.dart` y `app_localizations_es.dart` (regenerados por `flutter gen-l10n`)
- Cualquier archivo en `lib/features/` que use una key renombrada (refactor mecánico via search-and-replace)

**Estrategia (3 fases, secuenciales):**

**Fase 1 — Auditoría de keys no usadas:**
1. Extraer todas las keys del ARB: `jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_es.arb > /tmp/arb_keys.txt`
2. Para cada key, verificar uso con `grep -rn "\.<key>" lib/ --include="*.dart"` (filtrando `app_localizations*.dart`)
3. Producir lista de keys con 0 referencias → candidatas a eliminación
4. Revisar manualmente la lista (algunas keys pueden referenciarse dinámicamente via `intl` o concatenación; en tal caso anotar y conservar)
5. Eliminar keys confirmadas como muertas, junto con sus metadata `@<key>`

**Fase 2 — Identificación de duplicados unificables:**
1. Extraer pares `(key, value)` del ARB; agrupar por value normalizado (lowercase, sin tildes finales, sin signos)
2. Producir reporte de grupos con value idéntico/cuasi-idéntico (ej: `vehicle_cancel`, `event_cancel`, `auth_cancel`, `common_cancel`, todas = "Cancelar")
3. Decisión por grupo:
   - **Unificar a `common_*` o `shared_*`** cuando el value es genuinamente neutro (Cancelar, Guardar, Volver, Continuar, Aceptar, Confirmar, Eliminar, Editar, Cerrar, Listo, Atrás, Sí, No, Reintentar)
   - **Conservar separadas** cuando el contexto de género/tono/pantalla justifica versiones distintas (ej: "Eliminar evento" vs "Eliminar vehículo" — son strings completos, no botones)
4. Listar el plan de unificación final antes de aplicar

**Fase 3 — Aplicación:**
1. Añadir las nuevas keys `common_*` al ARB
2. Reemplazo masivo en `lib/features/`: `context.l10n.<old_key>` → `context.l10n.<new_key>` (script + revisión manual)
3. Eliminar las keys viejas (las que ya no están referenciadas)
4. Ejecutar `flutter gen-l10n`; commitear los `app_localizations*.dart` regenerados
5. `dart analyze lib/` → 0 errores
6. `flutter test` → 0 regresiones

**Acceptance criteria:**
- [ ] Reporte de auditoría commiteado en `docs/handoffs/iteration_checkpoint.md` (o adjunto al PR): (a) total de keys antes/después, (b) listado de keys eliminadas, (c) listado de unificaciones aplicadas con su key destino
- [ ] Reducción mínima esperada: ≥10% de keys (de 1357 a ≤1220) — si la auditoría revela menos deuda, documentar y ajustar; si revela más, aprovechar
- [ ] Nuevas keys neutras documentadas con metadata `@<key>` y descripción en el ARB
- [ ] `grep -r "context\.l10n\." lib/features/ --include="*.dart" | awk -F'context.l10n.' '{print $2}' | awk -F'[^a-zA-Z0-9_]' '{print $1}' | sort -u` produce un conjunto que es subconjunto de las keys actuales del ARB (sin referencias a keys eliminadas)
- [ ] `flutter gen-l10n` ejecutado y archivos generados commiteados
- [ ] `dart analyze lib/` pasa con 0 errores
- [ ] `flutter test` pasa con 0 regresiones
- [ ] Smoke test manual: navegar las 15 pantallas principales y confirmar que todos los textos siguen apareciendo (sin "missing translation" strings)
- [ ] No se introducen strings hardcoded en este refactor — la limpieza es 100% sobre el ARB y referencias existentes

**Risk:** Medium — eliminar una key referenciada dinámicamente causa runtime error (no compile-time). Mitigación: ejecutar `flutter gen-l10n` después de cada paso y correr la app en debug antes de eliminar masivamente. Mantener un commit-por-fase para rollback fácil.
**Effort:** M (3–4h)
**Depends on:** REFACTOR-14 (si REFACTOR-14 introduce strings nuevos, deben armonizarse con la limpieza). Conviene ejecutar último para capturar todas las claves recién añadidas/eliminadas durante el resto del refactor.

---

#### REFACTOR-12: Document `bool isLoadingMore` exception in NotificationsState

**Violation type:** Primitive boolean flag for a loading state in a `@freezed` state class, where `ResultState<T>` is the required pattern.

**Files affected:**
- `lib/features/notifications/presentation/cubit/notifications_state.dart`

**Decision (Option A — recommended for this iteration):** Keep `bool isLoadingMore` and add the exception comment: `// Exception: isLoadingMore is a secondary loading indicator for cursor-based pagination append. It cannot be replaced by a second ResultState<List> because listResult must remain in Data state while additional pages are loading.`

**Acceptance criteria:**
- [ ] `notifications_state.dart` contains the `// Exception:` comment on the `isLoadingMore` field
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — Option A is a single comment addition.
**Effort:** S (<1h)
**Depends on:** REFACTOR-02 (clean baseline)

---

### Definition of Done

- [ ] `dart analyze lib/` returns 0 errors, 0 warnings
- [ ] `flutter test` passes — all pre-existing tests pass, 0 new failures

- [ ] Widget-class check (macOS-compatible):
  ```bash
  find lib/features -name "*.dart" | while read f; do
    count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null)
    if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi
  done
  # Must return 0 lines
  ```

- [ ] `grep -rn "Widget _build\|Widget _[a-z]" lib/features/ --include="*.dart" | grep -v "//"` returns 0 results (no widget-returning methods)

- [ ] `grep -rn "ElevatedButton\|OutlinedButton\|TextButton" lib/features/ --include="*.dart" | grep -v "// Custom:"` returns 0 results

- [ ] `grep -rn "FormBuilderTextField" lib/features/ --include="*.dart"` returns 0 results

- [ ] `grep -rn "Navigator\.of(context)\." lib/features/ --include="*.dart" | grep -v "// Custom:"` returns 0 results

- [ ] `grep -rn "Navigator\.pop(context" lib/features/ --include="*.dart" | grep -v "SystemNavigator\|// Custom:"` returns 0 results

- [ ] `grep -rn "context\.goNamed" lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results

- [ ] `grep -rn "Color(0x" lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results

- [ ] `grep -rn "Colors\." lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results (or ≤5 annotated exceptions)

- [ ] `find lib/features/vehicles/presentation/soat -name "*.dart" 2>/dev/null | wc -l` returns 0 (legacy SOAT folder deleted)

- [ ] `grep -r "vehicles/presentation/soat" lib/ --include="*.dart"` returns 0 results

- [ ] `grep -rn "showDialog(" lib/features/ --include="*.dart" | grep -v "// Custom:\|AppDialog\|ConfirmationDialog"` returns 0 results

---

### Smoke tests required

1. **SOAT upload → confirmation → status flow** (REFACTOR-02): vehicle detail SOAT badge → upload page → manual capture form → save → status page refreshes. Verify all 6 `vehicleSoat` callers navigate to the correct upload page.
2. **SOAT vehicle creation flow** (REFACTOR-02): create new vehicle → SOAT photo section → photo attachment → confirmation page renders correctly.
3. **Login → Forgot Password → back to Login** (REFACTOR-04, REFACTOR-10): navigation works correctly in both directions; no stack accumulation.
4. **Event detail CTA bar — all 4 state variants** (REFACTOR-05a): registered / pending / closed / full variants all render the correct CTA.
5. **Maintenance filters** (REFACTOR-06a, REFACTOR-09): Maintenance list → open filters → select type → apply → list updates correctly.
6. **Garage vehicle options** (REFACTOR-09): Garage → vehicle options menu → archive / delete / set main — all three actions function after Navigator migration.
7. **Signup end-to-end** (REFACTOR-04): full signup flow from start to home screen.

---

### Risks

- **SOAT consolidation blast perimeter (REFACTOR-02):** Five external files import from the legacy folder and 6 active callers use `AppRoutes.vehicleSoat`. A new named route for `SoatManualCapturePage`, typed-result Navigator migration, and DI regeneration must all happen in one story. Any missed step causes a compile error or silent runtime crash. Run `grep -r "vehicles/presentation/soat" lib/` before deleting and fix all results first.
- **Widget extraction with shared state (REFACTOR-03a, REFACTOR-05a):** `garage_vehicles_content.dart` (16 classes) and `event_detail_cta_bar.dart` (8 state-variant classes) are the highest-risk extractions. Extract one widget per commit, run `flutter test` after each commit (not just after each story). Never extract a widget that reads parent `State<T>` fields directly.
- **Color value mismatch (REFACTOR-11):** `Color(0xFF22C55E)` (green-500) and `Color(0xFFEAB308)` (yellow-500) differ from existing `AppColors.success`/`AppColors.warning` tokens. Replacing with existing tokens changes the rendered color. Add new `AppColors.statusGreen` and `AppColors.statusWarning` tokens as the first commit of REFACTOR-11.
- **Navigator.pop(context) form invisible to standard grep (REFACTOR-09):** Six calls in `garage_options_bottom_sheet.dart`, `maintenance_options_bottom_sheet.dart`, and `maintenance_filters_bottom_sheet.dart` use `Navigator.pop(context)` (without `.of`) — not caught by `Navigator\.of(context)\.` DoD grep. The DoD now includes a separate grep for this form.
- **Event CTA bar extraction has no widget tests (REFACTOR-05a):** Extraction failures in `event_detail_cta_bar.dart` are silent at compile time — the app builds but the wrong CTA variant may render. Manual smoke test of all 4 state variants is a hard AC, not advisory.

---

### Execution order

```
REFACTOR-01 (SOAT button bug)
  └─→ REFACTOR-02 (SOAT consolidation — expanded scope)
        ├─→ REFACTOR-10 (goNamed fixes)
        │     └─→ REFACTOR-04 (auth widget extraction)
        │           └─→ REFACTOR-06a (maintenance extraction + showDialog)
        │                 └─→ REFACTOR-06b (home + profile + registration)
        ├─→ REFACTOR-08 (FormBuilderTextField replacements)
        │     └─→ REFACTOR-07 (raw button replacements)
        │           └─→ REFACTOR-13 (showDialog fix — if not done in REFACTOR-06a)
        │                 └─→ REFACTOR-11 (color tokenization — after files split)
        │                       └─→ REFACTOR-09 (remaining Navigator.of → go_router)
        │                             ├─→ REFACTOR-03a (vehicles garage extraction)
        │                             │     └─→ REFACTOR-03b (vehicles form extraction)
        │                             └─→ REFACTOR-05a (events detail extraction)
        │                                   └─→ REFACTOR-05b (events form + list + tracking)
        ├─→ REFACTOR-14 (AppFormNavHeader — depende de 03b + 05b + 06a)
        │     └─→ REFACTOR-15 (limpieza ARB — último, captura strings de todo el refactor)
        └─→ REFACTOR-12 (isLoadingMore comment — trivial, any time after REFACTOR-02)
```

Recommended linear order: REFACTOR-01 → 02 → 10 → 08 → 07 → 13 → 11 → 04 → 03a → 03b → 05a → 05b → 06a → 06b → 09 → 14 → 15 → 12

---

### Story totals

| Stories | Total effort | Estimated days | Risk level |
|---------|-------------|----------------|------------|
| 17 stories (REFACTOR-01 through 15, with 03a/03b, 05a/05b, 06a/06b) | S×6 + M×8 + L×3 ≈ 42–58h raw work | 8 developer days | Medium-High (SOAT consolidation + large widget files + no CTA bar tests are the risk drivers; AppFormNavHeader y limpieza ARB se concentran al final) |

| ID | Title | Effort | Risk |
|----|-------|--------|------|
| REFACTOR-01 | Fix SOAT loading-button bug | S | Low |
| REFACTOR-02 | Consolidate SOAT feature (move + router + DI regen) | M | High |
| REFACTOR-10 | Fix context.goNamed violations | S | Low |
| REFACTOR-08 | Replace FormBuilderTextField → AppTextField | S | Low |
| REFACTOR-07 | Replace raw buttons → AppButton/AppTextButton | S | Low |
| REFACTOR-13 | Fix direct showDialog → AppDialog wrapper | S | Low |
| REFACTOR-11 | Tokenize hardcoded colors (all 25 files) | M | Low-Medium |
| REFACTOR-04 | Widget extraction — Authentication | M | Low |
| REFACTOR-03a | Widget extraction — Vehicles (garage + detail) | L | High |
| REFACTOR-03b | Widget extraction — Vehicles (form + docs) | M | Medium |
| REFACTOR-05a | Widget extraction — Events (detail + CTA bar) | L | High |
| REFACTOR-05b | Widget extraction — Events (form + list + tracking) | L | Medium |
| REFACTOR-06a | Widget extraction — Maintenance | M | Medium |
| REFACTOR-06b | Widget extraction — Home + Profile + Registration | M | Low-Medium |
| REFACTOR-09 | Migrate Navigator.of → go_router (remaining) | M | Medium |
| REFACTOR-14 | Centralizar header de forms (AppFormNavHeader) | M | Medium |
| REFACTOR-15 | Limpieza app_es.arb (unused + duplicados) | M | Medium |
| REFACTOR-12 | Document bool isLoadingMore exception | S | Low |
