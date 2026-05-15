# Design Handoff — Iteration 3

**Date:** 2026-05-15
**Agent:** design
**Status:** done
**Iteration goal:** Tracking Completo + SOS + Maintenance Reminders — complete the real-time tracking UX with SOS, organizer controls, background GPS notification copy, and Home SOAT badge.

---

## Design system baseline

All tokens from iter-1 remain locked. No new tokens introduced except SOS-specific additions (documented below).

| Token | Value | Flutter mapping |
|-------|-------|----------------|
| Background | `#0A0A0A` | `AppColors.darkBackground` |
| Surface 1 | `#161616` | `AppColors.darkSurface` |
| Surface 2 | `#1F1F1F` | `AppColors.darkSurfaceHighest` |
| Border | `#2D2D2D` | `AppColors.darkBorder` |
| Primary orange | `#f98c1f` | `colorScheme.primary` |
| Primary dim | `rgba(249,140,31,0.12)` | `colorScheme.primary.withValues(alpha: 0.12)` |
| Text primary | `#F4F4F5` | `colorScheme.onSurface` |
| Text secondary | `#71717A` | `AppColors.darkTextSecondary` |
| Success | `#22C55E` | `AppColors.success` |
| Error / SOS red | `#EF4444` | `AppColors.error` |
| Warning | `#F59E0B` | `AppColors.warning` |
| Font | Space Grotesk | `AppTextStyles` (auto via theme) |
| Border radius — inputs/buttons | 8px | `AppRadius.sm` |
| Border radius — cards | 12px | `AppRadius.md` |
| Border radius — large cards | 16px | `AppRadius.lg` |
| Border radius — bottom sheets | 24px | `AppRadius.xl` |

**New iter-3 design additions (not new tokens — new usage patterns):**
- `SOS FAB` — 56×56px, `AppColors.error` fill, 3px white border (0.25 alpha), `box-shadow: 0 4px 20px rgba(239,68,68,0.5)`
- `SOS Rider Marker` — `AnimationController` pulsing ring using `AppColors.error`; ring animates from 0.8→1.8 scale, 0→0 opacity, 1.5s
- `SOS Banner` — full-width `AppColors.error` bg container, anchor at top of map overlay stack (non-blocking to map interaction)
- `Organizer Control Bar` — `AppColors.darkSurface` with 96% opacity + `backdropFilter blur(12px)`, anchored top of map

---

## Story classification

| Story | Title | UI type | Screens affected |
|-------|-------|---------|-----------------|
| US-3-0 | Mapbox SDK migration | UPDATE | `live_map_widget`, `live_map_page`, `route_map_preview` — invisible to user if done right |
| US-3-1 | SOS button + alert | EXTEND | Tracking map — new SOS FAB, confirmation dialog, SOS sent state |
| US-3-2 | SOS banner actions | EXTEND | Tracking map — SOS banner with Llamar/Localizar, SOS rider marker |
| US-3-3 | Iniciar rodada | EXTEND | Event detail page — "Iniciar rodada" button (organizer-only) + confirmation dialog |
| US-3-4 | Terminar rodada | EXTEND | Tracking map — organizer control bar with "Terminar rodada" + confirmation dialog + finish overlay |
| US-3-5 | Background GPS | NEW (system) | Android foreground service notification text; iOS Info.plist strings (no app UI) |
| US-3-6 | Maintenance reminder push | NEW (system) | Push notification copy only (no new screen) |
| US-3-7 | Event reminder push | NEW (system) | Push notification copy only (no new screen) |
| US-3-10* | VehicleModel SOAT + Home badge | EXTEND | Home dashboard — SOAT badge on main vehicle card (4 states) |

*Note: Story 3.10 from task list (T-3-10) is numbered as US-3-10 in architect handoff scope.

---

## Screens and states

| Screen name | Story | Type | Mockup file | Status |
|-------------|-------|------|-------------|--------|
| Tracking Map — Normal (rider) | 3.0, 3.1, 3.2 | EXTEND | `tracking-map.html` | done |
| Tracking Map — Off Route | 3.9 | EXTEND | `tracking-map.html` | done |
| Tracking Map — Organizer View | 3.3, 3.4 | EXTEND | `tracking-map.html` | done |
| SOS Confirmation Dialog | 3.1 | EXTEND | `sos-flow.html` | done |
| SOS Sent — Sender confirmation | 3.1 | EXTEND | `sos-flow.html` | done |
| SOS Banner — Received by riders | 3.2 | EXTEND | `sos-flow.html` | done |
| SOS Banner — No phone number | 3.2 | EXTEND | `sos-flow.html` | done |
| Event Detail — Organizer (scheduled) | 3.3 | EXTEND | `organizer-controls.html` | done |
| Iniciar Rodada — Confirmation Dialog | 3.3 | EXTEND | `organizer-controls.html` | done |
| Event Detail — Rider (in_progress) | 3.3 | EXTEND | `organizer-controls.html` | done |
| Terminar Rodada — Confirmation Dialog | 3.4 | EXTEND | `organizer-controls.html` | done |
| Ride Finished Overlay | 3.4 | EXTEND | `organizer-controls.html` | done |
| Android Foreground Service Notification | 3.5 | NEW (system) | `notifications-push.html` | done |
| iOS Background Location Info.plist strings | 3.5 | NEW (system) | `notifications-push.html` | done |
| SOS FCM Push (lock screen) | 3.1 | NEW (system) | `notifications-push.html` | done |
| Push Copy Reference Card | 3.5, 3.6, 3.7 | NEW (doc) | `notifications-push.html` | done |
| Home Dashboard — SOAT vigente | 3.10 | EXTEND | `home-soat-badge.html` | done |
| Home Dashboard — SOAT por vencer | 3.10 | EXTEND | `home-soat-badge.html` | done |
| Home Dashboard — SOAT vencido | 3.10 | EXTEND | `home-soat-badge.html` | done |
| Home Dashboard — SOAT sin registrar | 3.10 | EXTEND | `home-soat-badge.html` | done |

---

## Component hierarchy

| Screen | Components reused | New components needed |
|--------|-------------------|-----------------------|
| Tracking Map | `MapWidget` (Mapbox), `AppAppBar`, existing overlay stack | `SosBannerWidget`, `OrganizerControlBar`, `RouteAdherenceChip`, `SosMarkerAnnotation` (overlay wrapper) |
| SOS Confirmation Dialog | `AppDialog` / `ConfirmationDialog` | No new dialog widget — use `ConfirmationDialog` with red primary action |
| SOS Banner | — | `SosBannerWidget` — new widget in `lib/features/events/presentation/tracking/widgets/sos_banner.dart` |
| Organizer Control Bar | — | `OrganizerControlBar` — new widget in `lib/features/events/presentation/tracking/widgets/organizer_control_bar.dart` |
| Event Detail — Iniciar rodada | `AppButton`, `ConfirmationDialog`, existing detail page | Conditionally rendered `AppButton` in `EventDetailPage` CTA bar |
| Ride Finished Overlay | `AppButton` | `RideFinishedOverlay` — overlay widget in `LiveMapPage` |
| Route Adherence Chip | — | `RouteAdherenceChip` — in `lib/features/events/presentation/tracking/widgets/route_adherence_chip.dart` |
| Home SOAT badge | `DocumentSlotPill` (iter-1 molecule) | No new widget — reuse `DocumentSlotPill` in main vehicle card |
| Push notifications | — | System-level only (FCM payload + flutter_local_notifications config) |

**Key reuse decisions:**
- SOS dialog reuses `ConfirmationDialog` — pass `isDestructive: true` to make primary button red
- `DocumentSlotPill` (created in iter-1) is reused directly for Home SOAT badge — no new widget needed
- `AppButton` for "Iniciar rodada" / "Terminar rodada" — rendered conditionally based on `currentUser.id == event.ownerId`
- Rider marker with SOS state is an overlay `AnimationController` widget wrapping the existing `PointAnnotation` — no new base widget, just a conditional wrapper

---

## UX flow specs

### SOS Button flow (US-3-1)
1. Rider sees SOS FAB (56×56 red circle) anchored bottom-right of map, above zoom controls
2. Tap → `ConfirmationDialog` appears (overlay, map visible blurred behind)
   - Icon: 🚨 red dim background
   - Title: "¿Enviar alerta SOS?"
   - Body: "Todos los participantes serán notificados de tu emergencia. Esta acción no se puede deshacer."
   - Primary: "🚨 Enviar SOS" (red/danger button)
   - Secondary: "Cancelar" (surface button)
3. On confirm → `LiveTrackingCubit.triggerSos()` → WS publish → `hasSentSos = true`
4. Sender sees: green success snackbar "SOS enviado — los riders han sido notificados" + SOS FAB border turns red (transparent fill, red border pulsing)
5. Sender's entry in riders panel shows "SOS activo" chip (error style)

### SOS Banner flow (US-3-2, received by others)
1. `LiveTrackingCubit` receives `sos_alert` WS event → `sosAlertResult = Data(sosAlert)`
2. `SosBannerWidget` renders at **top of map overlay stack**, above route adherence chip
3. Banner: red background, 🚨 icon, rider name, subtitle "Toca para ver acciones"
4. Actions row:
   - "📞 Llamar" → `url_launcher` `tel:+57XXXXXXXX` — **only if `sosAlert.riderPhone != null`**
   - "📍 Localizar" → `url_launcher` Google Maps (Android) / Apple Maps (iOS) deep link with rider's last coords
5. Rider's `PointAnnotation` on map gains red pulsing `AnimationController` overlay
6. Riders panel shows "🚨 SOS activo" badge on that rider's row

### "Sin teléfono" empty state (US-3-2)
- If `sosAlert.riderPhone == null`: **only "📍 Localizar" button visible** in banner
- No error message — just the single action button
- Banner subtitle changes to "Sin teléfono registrado"

### Iniciar Rodada flow (US-3-3)
1. `EventDetailPage` CTA bar: conditionally shows "🏁 Iniciar rodada" button when `currentUser.id == event.ownerId && event.state == 'scheduled'`
2. Tap → `ConfirmationDialog`:
   - Icon: 🏁 orange dim background
   - Title: "¿Iniciar rodada?"
   - Body: "Los {count} riders aprobados recibirán acceso al mapa de rastreo en tiempo real."
   - Primary: "🏁 Iniciar rodada" (primary/orange button)
   - Secondary: "Cancelar"
3. On confirm → `EventDetailCubit.startRide()` → backend transitions event to `in_progress`
4. All riders: event state refreshes; CTA bar changes to "📍 Ver rastreo" button

### Terminar Rodada flow (US-3-4)
1. Organizer's tracking screen shows `OrganizerControlBar` at top (persistent, above map, blur bg)
   - Badge "Organizador", label "Control de rodada", "Terminar rodada" button (outline-danger)
2. Tap → `ConfirmationDialog`:
   - Icon: 🏁 red dim background
   - Title: "¿Terminar rodada?"
   - Body: "La pantalla de rastreo se cerrará para todos los riders conectados."
   - Primary: "Terminar rodada" (red/danger)
   - Secondary: "Cancelar"
3. On confirm → `EndRideUseCase` → backend event transitions to `finished`
4. All riders: WS `tracking.event.ended` received → `LiveTrackingCubit` emits `isFinished = true` → `LiveMapPage` shows `RideFinishedOverlay` then auto-pops

### Ride Finished Overlay (US-3-4)
- Semi-opaque dark overlay (blur) over map with:
  - 🏁 large emoji
  - "¡La rodada ha terminado!" title
  - Event name + completion message
  - Stats row: km, duración, riders
  - "Volver al inicio" primary button → `context.goAndClearStack(RoutePaths.home)`

---

## Component hierarchy — new widgets

```
lib/features/events/presentation/tracking/widgets/
  sos_banner.dart                ← NEW — SosBannerWidget
  organizer_control_bar.dart     ← NEW — OrganizerControlBar
  route_adherence_chip.dart      ← NEW — RouteAdherenceChip
  ride_finished_overlay.dart     ← NEW — RideFinishedOverlay (inline in LiveMapPage or separate)
```

---

## UI copy (Spanish)

All new keys go in `lib/l10n/app_es.arb` with prefix matching feature.

| l10n key | Spanish text | Context |
|----------|-------------|---------|
| `sos_button_label` | `SOS` | SOS FAB label |
| `sos_confirm_title` | `¿Enviar alerta SOS?` | Confirmation dialog title |
| `sos_confirm_body` | `Todos los participantes serán notificados de tu emergencia. Esta acción no se puede deshacer.` | Confirmation dialog body |
| `sos_confirm_action` | `Enviar SOS` | Primary dialog button |
| `sos_sent_confirmation` | `SOS enviado — los riders han sido notificados` | Snackbar on sender |
| `sos_banner_subtitle_with_phone` | `Toca para ver acciones` | SOS banner subtitle |
| `sos_banner_subtitle_no_phone` | `Sin teléfono registrado` | SOS banner — no phone |
| `sos_call_action` | `Llamar` | Banner action button |
| `sos_locate_action` | `Localizar` | Banner action button |
| `sos_banner_title` | `{riderName} necesita ayuda` | SOS banner title (parameterized) |
| `tracking_start_ride` | `Iniciar rodada` | Event detail CTA button |
| `tracking_start_ride_confirm_title` | `¿Iniciar rodada?` | Confirmation dialog title |
| `tracking_start_ride_confirm_body` | `Los {count} riders aprobados recibirán acceso al mapa de rastreo en tiempo real.` | Dialog body |
| `tracking_end_ride` | `Terminar rodada` | Organizer control bar button |
| `tracking_end_ride_confirm_title` | `¿Terminar rodada?` | Confirmation dialog title |
| `tracking_end_ride_confirm_body` | `La pantalla de rastreo se cerrará para todos los riders conectados. Esta acción no se puede deshacer.` | Dialog body |
| `tracking_route_on_route` | `En ruta ✓` | Route adherence chip — on route |
| `tracking_route_off_route` | `Fuera de ruta ⚠` | Route adherence chip — off route |
| `tracking_ride_finished` | `¡La rodada ha terminado!` | Finished overlay title |
| `tracking_ride_finished_body` | `{eventName} ha finalizado exitosamente.` | Finished overlay body |
| `tracking_back_to_home` | `Volver al inicio` | Finished overlay CTA |
| `tracking_organizer_badge` | `Organizador` | Organizer control bar badge |
| `tracking_organizer_label` | `Control de rodada` | Organizer control bar label |
| `tracking_riders_count` | `Riders en la rodada · {count}` | Riders panel title |
| `tracking_rider_status_on_route` | `En ruta` | Rider row status |
| `tracking_rider_status_sos` | `🚨 SOS activo` | Rider row status — SOS |
| `tracking_fg_service_title` | `Rideglory — Rodada activa` | Android foreground service notif title |
| `tracking_fg_service_body` | `Tu ubicación se está compartiendo con los riders de la rodada.` | Android foreground service notif body |
| `sos_push_title` | `¡Alerta de emergencia!` | FCM push title |
| `sos_push_body` | `{riderName} ha activado el SOS en {eventName}.` | FCM push body |
| `maintenance_push_title` | `Mantenimiento próximo` | FCM push title |
| `maintenance_push_body` | `El {serviceType} de tu {vehicleName} está programado en 30 días.` | FCM push body |
| `event_reminder_push_title` | `¡Tu rodada es mañana!` | FCM push title |
| `event_reminder_push_body` | `{eventName} comienza mañana a las {startTime}. ¡Prepara tu moto!` | FCM push body |
| `tracking_ride_ended_push_title` | `La rodada ha terminado` | FCM push title |
| `tracking_ride_ended_push_body` | `{eventName} ha finalizado. ¡Hasta la próxima!` | FCM push body |
| `vehicle_soat_badge_label` | `SOAT` | Home SOAT badge label |
| `vehicle_soat_tap_to_add` | `Sin registrar · Agregar →` | SOAT empty state on home card |
| `vehicle_soat_update` | `Actualizar →` | SOAT expired CTA on home card |

**Info.plist location usage descriptions (iOS — written in English keys but Spanish values):**
- `NSLocationWhenInUseUsageDescription`: "Rideglory usa tu ubicación para compartirla con los riders de la rodada en tiempo real."
- `NSLocationAlwaysAndWhenInUseUsageDescription`: "Rideglory usa tu ubicación en segundo plano para continuar compartiendo tu posición durante la rodada cuando la app no está en primer plano."

---

## Error messages

| Error situation | User-facing message (ES) | Screen |
|-----------------|--------------------------|--------|
| SOS WS publish fails | `No se pudo enviar el SOS. Verifica tu conexión.` | Snackbar on tracking map |
| Start ride fails (network) | `No se pudo iniciar la rodada. Inténtalo de nuevo.` | Snackbar on event detail |
| End ride fails (network) | `No se pudo terminar la rodada. Inténtalo de nuevo.` | Snackbar on tracking map |
| Locate action — no coords | `No se pudo obtener la ubicación del rider.` | Snackbar on tracking map |
| Route GeoJSON load fails | `No se pudo cargar la ruta. Continuando sin ruta.` | Non-blocking banner on map |
| Background GPS permission denied | `Para continuar la rodada, activa el permiso de ubicación en Configuración.` | Dialog before tracking starts |

---

## SOS marker animation spec (Flutter)

The SOS marker uses a Mapbox `PointAnnotation` for positioning. The pulsing ring effect is achieved via an `AnimationController` positioned as a Flutter overlay widget above the map:

```
SosMarkerPulse:
  outer ring: 56×56 transparent circle, border 2px error
  animation: scale 0.8→1.8, opacity 0.8→0, duration 1.5s, curve Curves.easeOut, repeat
  inner dot: 36×36 rider avatar circle, filled error red
  rider initials: white 13px font-weight 700
```

If `mapbox_maps_flutter` annotation animation is not available natively, use an `AnimatedBuilder` widget positioned over the map canvas.

---

## Organizer Control Bar — visibility rules

```
OrganizerControlBar shows when:
  currentUser.id == event.ownerId
  AND event.state == 'in_progress'

OrganizerControlBar hides when:
  currentUser is not the organizer (all riders)
  OR event.state != 'in_progress'
```

Always rendered as the topmost item in the map overlay stack, below the status bar, above route adherence chip and SOS banner.

---

## SOS Banner — layering order (top to bottom in overlay stack)

```
1. OrganizerControlBar  (organizer only, state == in_progress)
2. SosBannerWidget      (all participants, when sosAlertResult is Data)
3. RouteAdherenceChip   (all participants, always visible when in_progress)
4. [map canvas]
5. MapWidget (Mapbox)
```

All overlays anchor to `Stack` in `LiveMapPage`. Map remains interactive below all overlays.

---

## Home Dashboard SOAT badge — implementation note

The SOAT badge on the main vehicle card uses the existing `DocumentSlotPill` molecule (created in iter-1):

```dart
DocumentSlotPill(
  state: vehicle.soatStatus.toDocumentSlotState(), // extension on SoatStatus
  stateLabel: context.l10n.vehicle_soat_state_label, // per state
  onTap: () => context.pushNamed(RoutePaths.soatDetail, params: {...}),
)
```

Rendered below the main vehicle hero card in `home_garage_card.dart`. 4 states map to `DocumentSlotState`: `none → empty`, `valid → valid`, `expiringSoon → expiringSoon`, `expired → expired`.

---

## Accessibility notes

1. SOS FAB: minimum 56×56px (exceeds 44px minimum). Semantics label: "Enviar alerta de emergencia".
2. SOS Banner: all action buttons 32px height (below 44px minimum) — **add `SizedBox(height: 44)` wrapper or increase padding to meet 44px minimum touch target**.
3. SOS dialog primary button: full-width, 48px height. Meets contrast ratio (white on #EF4444 = 4.6:1, AA pass).
4. Organizer control bar "Terminar rodada": minimum 44px touch target — use `minHeight: 44` on `OutlinedButton`.
5. Route adherence chip: non-interactive (display only). No touch target required.
6. SOAT badge row: full-row tappable, 44px min height.
7. SOS pulsing animation: add `MediaQuery.disableAnimations` check — if animations disabled (accessibility), show static red marker without pulse.

---

## Pencil (rideglory.pen) — frame update list

Pencil MCP was not available during this session. The following frames must be verified/updated before frontend implementation:

**Frame `qonbS` — Event Tracking Map (MUST update before T-3-6):**
- Add SOS FAB position spec (bottom-right, above zoom controls)
- Add SOS banner position (top of overlay stack, below app bar)
- Add organizer control bar position (top, conditional)
- Add red pulsing SOS marker variant for rider in SOS state
- Add route adherence chip position (top left, below organizer bar)
- Confirm riders panel handle + scroll behavior

**Frame `kAubW` — Event Detail (MUST update before T-3-7):**
- Add "Iniciar rodada" button to CTA bar (organizer-only variant)
- Confirm "Ver rastreo" CTA variant for `in_progress` state

**New frames to CREATE:**
- `Tracking — SOS — Confirmation Dialog`
- `Tracking — SOS — Banner (with Llamar + Localizar)`
- `Tracking — SOS — Banner (Localizar only, no phone)`
- `Tracking — Organizer — Control Bar`
- `Tracking — Ride Finished Overlay`
- `Event Detail — Iniciar Rodada Dialog`

---

## Design tool artifacts

### HTML mockups
Location: `docs/design/html-mockups/iter-3/`

| File | Screens covered |
|------|----------------|
| `styles.css` | Shared design tokens + SOS-specific additions |
| `tracking-map.html` | Tracking map (normal, off-route, organizer view) |
| `sos-flow.html` | SOS dialog, SOS sent state, SOS banner (with/without phone) |
| `organizer-controls.html` | Iniciar rodada (event detail), confirmation dialogs, ride finished overlay |
| `notifications-push.html` | Android foreground service notif, iOS background indicator + Info.plist strings, push copy reference |
| `home-soat-badge.html` | Home SOAT badge — all 4 states (vigente, por vencer, vencido, sin registrar) |

---

## Change log

- 2026-05-15: Iter-3 design phase complete. 20 screen states designed across 5 HTML mockups. SOS flow, organizer controls, background GPS notification copy, push notification copy, and Home SOAT badge (4 states) all specified. Story classification completed. New widget list defined. Component hierarchy documented. All UI copy in Spanish captured with l10n keys. Pencil frame update list specified.
