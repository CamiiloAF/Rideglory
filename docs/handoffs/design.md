# Design handoff — Iteration 2

**Date:** 2026-05-14
**Agent:** design
**Status:** done
**Iteration goal:** SOAT registration flow (upload + manual + 4-state badge), notification center rebuild, ManageAttendeesPage refinement (Story 2.9). Design gate for all iter-2 frontend work.

---

## Design system baseline

All tokens locked from iter-1. No new tokens introduced this iteration.

| Token | Value | Flutter mapping |
|-------|-------|----------------|
| Background | `#111111` | `AppColors.darkBackground` |
| Surface 1 | `#1C1209` | `AppColors.darkSurface` |
| Surface 2 | `#261A0E` | `AppColors.darkSurfaceHighest` |
| Border | `#3D2810` | `AppColors.darkBorder` |
| Primary orange | `#f98c1f` | `colorScheme.primary` |
| Primary dim | `rgba(249,140,31,.12)` | `AppColors.primary.withValues(alpha:.12)` |
| Text primary | `#F1F5F9` | `colorScheme.onSurface` |
| Text secondary | `#94A3B8` | `AppColors.darkTextSecondary` |
| Success | `#10B981` | `AppColors.success` |
| Error | `#EF4444` | `AppColors.error` |
| Warning | `#F59E0B` | `AppColors.warning` |
| Font | Space Grotesk | `AppTextStyles` (auto via theme) |
| Border radius — inputs/buttons | 8px | `AppRadius.sm` |
| Border radius — cards | 12px | `AppRadius.md` |
| Border radius — large cards | 16px | `AppRadius.lg` |
| Border radius — bottom sheets | 24px | `AppRadius.xl` |

**Changed this iteration:** none — tokens locked from iter-1.

---

## Screens and states

| Screen name | Story | Type | Mockup file | Status |
|-------------|-------|------|-------------|--------|
| SoatUploadPage — default | US-2-1 | NEW | `soat.html` | done |
| SoatUploadPage — file uploading | US-2-1 | NEW | `soat.html` | done |
| SoatUploadPage — upload error | US-2-1 | NEW | `soat.html` | done |
| SoatManualFormPage — default | US-2-2 | NEW | `soat.html` | done |
| SoatManualFormPage — validation errors | US-2-2 | NEW | `soat.html` | done |
| SoatStatusPage — Vigente | US-2-3 | NEW | `soat.html` | done |
| SoatStatusPage — Por vencer | US-2-3 | NEW | `soat.html` | done |
| SoatStatusPage — Vencido | US-2-3 | NEW | `soat.html` | done |
| Vehicle Detail — 4-state SOAT badge integration | US-2-3 | EXTEND | `soat.html` | done |
| Home — Bell icon with unread badge | US-2-7 | EXTEND | `notifications.html` | done |
| NotificationCenterPage — Loading (skeleton) | US-2-7 | EXTEND | `notifications.html` | done |
| NotificationCenterPage — With data | US-2-7 | EXTEND | `notifications.html` | done |
| NotificationCenterPage — Empty state | US-2-7 | EXTEND | `notifications.html` | done |
| NotificationCenterPage — Error state | US-2-7 | EXTEND | `notifications.html` | done |
| Notification row templates (6 types) | US-2-5/2-6 | NEW | `notifications.html` | done |
| AttendeesPage — Loading | US-2-9 | UPDATE | `attendees.html` | done |
| AttendeesPage — Pending filter | US-2-9 | UPDATE | `attendees.html` | done |
| AttendeesPage — All tab (mixed) | US-2-9 | UPDATE | `attendees.html` | done |
| AttendeesPage — Empty | US-2-9 | UPDATE | `attendees.html` | done |
| AttendeesPage — Error | US-2-9 | UPDATE | `attendees.html` | done |
| AttendeesPage — Confirm dialog | US-2-9 | UPDATE | `attendees.html` | done |
| AttendeesPage — Filter bottom sheet | US-2-9 | UPDATE | `attendees.html` | done |

### Story 2.9 scope decision (frame dUc9h)

**Verdict: list + edit is already implemented.** Inspecting `attendees_page.dart`, `attendees_view.dart`, `attendees_data_view.dart`, `attendees_list.dart` confirms the page already has:
- Search bar
- Status filter chips
- List of attendee cards with approve/reject actions
- Filter bottom sheet

**Story 2.9 scope = UPDATE (component-swap + color tokenization + state polish)**. The full list+edit layout is already present. Design work is:
1. Verify all action buttons use `AppButton` (not ElevatedButton)
2. Verify all dialogs use `AppDialog` / `ConfirmationDialog`
3. Verify loading, empty, and error states match iter-1 standards
4. Ensure no hardcoded `Color(0x...)` literals

No layout rework required.

---

## Component hierarchy

| Screen | Components used | New components needed |
|--------|-----------------|-----------------------|
| SoatUploadPage | `AppButton`, `AppTextField`, `AppAppBar` | `SoatSourceSelector` widget (2×2 grid, local to feature) |
| SoatManualFormPage | `AppButton`, `AppTextField`, `AppAppBar`, `FormSectionHeader` | none |
| SoatStatusPage | `AppButton`, `AppCard`, `DocumentSlotPill`, `AppAppBar` | none |
| Vehicle Detail (SOAT badge) | `DocumentSlotPill` (iter-1 molecule) | none |
| NotificationCenterPage | `AppButton`, `AppAppBar`, `NotificationItem` widget | `NotificationBellButton` (replaces HomeNotificationButton) |
| AttendeesPage | `AppButton`, `AppDialog`/`ConfirmationDialog`, `AppSearchBar`, `AppFilterChip`, `AppAppBar`, `AppBottomSheet` | none |

### DocumentSlotPill → SoatStatus mapping (1:1)

| SOAT state | DocumentSlotState | Badge label | Border color |
|------------|-------------------|-------------|--------------|
| `noSoat` | `empty` | `soat_status_no_soat` | `AppColors.darkBorder` |
| `valid` (>30d) | `valid` | `soat_status_valid` | `AppColors.success` |
| `expiringSoon` (≤30d) | `expiringSoon` | `soat_status_expiring_soon` | `AppColors.warning` |
| `expired` (past) | `expired` | `soat_status_expired` | `AppColors.error` |

The `DocumentSlotPill` molecule from iter-1 maps directly to SOAT badge states.
**Caller contract:** always pass `stateLabel: context.l10n.soat_status_<state>` — never rely on hardcoded fallback strings.

### NotificationBellButton spec

- Position: `AppBar.actions[]` on `HomeShell` (top right)
- Size: 44×44px tap target
- Icon: `Icons.notifications_outlined` (inactive) / `Icons.notifications` (active — has unread)
- Badge: circular red badge `AppColors.error`, `border: 2px solid AppColors.darkBackground` (avoids overlap bleed), 16×16px, shows count up to 99+
- `unreadCount` sourced from `NotificationsCubit.state.unreadCount`

---

## UI copy (Spanish)

### SOAT (`soat_` prefix)

| Key | Text | Context |
|-----|------|---------|
| `soat_page_upload_title` | Subir SOAT | AppBar title |
| `soat_page_manual_title` | Ingresar SOAT | AppBar title — manual form |
| `soat_page_status_title` | Mi SOAT | AppBar title — status page |
| `soat_upload_subtitle` | Selecciona cómo quieres subir tu SOAT para {vehicleName}. | Page subtitle |
| `soat_manual_subtitle` | Ingresa los datos del SOAT para {vehicleName}. Puedes subir el documento más adelante. | Page subtitle |
| `soat_source_camera` | Cámara | Source option label |
| `soat_source_gallery` | Galería | Source option label |
| `soat_source_pdf` | Archivo PDF | Source option label |
| `soat_source_manual` | Ingresar manualmente | Source option label |
| `soat_upload_zone_title` | Toca para tomar foto | Upload drop zone title |
| `soat_upload_zone_subtitle` | o arrastra la imagen aquí | Upload drop zone subtitle |
| `soat_upload_zone_link` | Seleccionar archivo | Upload drop zone link |
| `soat_section_data` | Datos del SOAT | Form section header |
| `soat_field_policy_number` | N.° de póliza | Field label |
| `soat_field_policy_placeholder` | Ej: SOAT-2024-123456 | Placeholder |
| `soat_field_insurer` | Aseguradora | Field label |
| `soat_field_insurer_placeholder` | Ej: Sura, Allianz, AXA Colpatria… | Placeholder |
| `soat_field_start_date` | Fecha inicio | Field label |
| `soat_field_expiry_date` | Fecha vencimiento | Field label |
| `soat_field_date_format` | DD/MM/AAAA | Date placeholder |
| `soat_field_expiry_required` | La fecha de vencimiento es obligatoria. | Validation error |
| `soat_field_date_invalid` | Fecha inválida. Usa el formato DD/MM/AAAA. | Validation error |
| `soat_field_required` | Este campo es obligatorio. | Generic required error |
| `soat_save_btn` | Guardar SOAT | Primary button |
| `soat_save_data_btn` | Guardar datos | Manual form primary button |
| `soat_update_btn` | Actualizar SOAT | Update action button |
| `soat_saving` | Guardando… | Disabled button state |
| `soat_retry` | Reintentar | Retry button |
| `soat_manual_note` | Puedes subir el documento físico más adelante desde el detalle del vehículo. | Info note |
| `soat_switch_to_upload` | Subir documento en cambio | Link below manual form save button |
| `soat_section_document` | Documento | Section header on status page |
| `soat_document_attached` | Adjunto | Badge on document slot |
| `soat_status_no_soat` | Sin registrar | DocumentSlotPill label — noSoat |
| `soat_status_valid` | Vigente | DocumentSlotPill label — valid |
| `soat_status_expiring_soon` | Por vencer | DocumentSlotPill label — expiringSoon |
| `soat_status_expired` | Vencido | DocumentSlotPill label — expired |
| `soat_valid_title` | Tu SOAT está al día | Status page hero title |
| `soat_expiring_title` | Tu SOAT vence pronto | Status page hero title |
| `soat_expired_title` | Tu SOAT está vencido | Status page hero title |
| `soat_valid_days_remaining` | {count} días restantes | Days chip |
| `soat_expiring_days_remaining` | {count} días restantes | Days chip (warning color) |
| `soat_expired_days_ago` | Venció hace {count} días | Days chip (error color) |
| `soat_expiring_warning` | Te notificaremos 7 días antes del vencimiento. Renueva tu SOAT con anticipación para evitar multas. | Warning callout |
| `soat_expired_warning` | Circular sin SOAT vigente es una infracción. Renueva tu seguro lo antes posible. | Error callout |
| `soat_renew_btn` | Registrar nuevo SOAT | CTA on expired status page |
| `soat_view_document` | Ver documento | Secondary action |
| `soat_edit_btn` | Editar | AppBar action on status page |
| `soat_uploading` | Subiendo… | File upload progress label |
| `soat_upload_error` | Error al subir. Archivo demasiado grande (máx. 10 MB). | Snackbar: file too large |
| `soat_save_error` | No se pudo guardar el SOAT. Verifica tu conexión e intenta de nuevo. | Error banner |
| `soat_upload_error_label` | Error al subir | File status label (error state) |

### Notifications (`notification_` prefix — extending iter-1 stub)

| Key | Text | Context |
|-----|------|---------|
| `notification_centerTitle` | Notificaciones | AppBar title (already exists in stub) |
| `notification_markAllRead` | Marcar leídas | AppBar action (already exists) |
| `notification_emptyTitle` | Aún no tienes notificaciones | Empty state title (already exists) |
| `notification_emptySubtitle` | Aquí aparecerán los avisos sobre tus SOAT, inscripciones y rodadas. | Empty state subtitle |
| `notification_sectionUnread` | No leídas | Section label (already exists) |
| `notification_sectionRead` | Anteriores | Section label (already exists) |
| `notification_loadMore` | Cargar más notificaciones | Pagination link |
| `notification_loadError` | No se pudieron cargar las notificaciones | Error title |
| `notification_loadErrorSubtitle` | Verifica tu conexión a internet e intenta de nuevo. | Error subtitle |
| `notification_retry` | Reintentar | Error retry button |
| `notification_soat30d_title` | SOAT vence en 30 días | SOAT_30D notification title |
| `notification_soat7d_title` | Tu SOAT vence en 7 días | SOAT_7D notification title |
| `notification_soatDayOf_title` | Tu SOAT vence hoy | SOAT_DAY_OF notification title |
| `notification_soat_subtitle` | {vehicleName} · Renuévalo para evitar multas | SOAT notification subtitle |
| `notification_soatDayOf_subtitle` | {vehicleName} · Renueva antes de salir | SOAT day-of subtitle |
| `notification_newRegistration_title` | Nueva inscripción | NEW_REGISTRATION notification title |
| `notification_newRegistration_subtitle` | {riderName} quiere unirse a "{eventName}" | Subtitle |
| `notification_approved_title` | Inscripción aprobada | REGISTRATION_APPROVED title |
| `notification_approved_subtitle` | Estás inscrito a "{eventName}" | Subtitle |
| `notification_rejected_title` | Inscripción rechazada | REGISTRATION_REJECTED title |
| `notification_rejected_subtitle` | Tu solicitud para "{eventName}" no fue aprobada | Subtitle |
| `notification_timeAgo_hours` | Hace {count} hora{s} | Relative time |
| `notification_timeAgo_days` | Hace {count} día{s} | Relative time |
| `notification_timeAgo_weeks` | Hace {count} semana{s} | Relative time |
| `notification_today` | Hoy {time} | Same-day timestamp |

### ManageAttendeesPage (extending iter-1 existing l10n keys)

All existing `event_` keys are already present. New keys:

| Key | Text | Context |
|-----|------|---------|
| `event_filter_pending` | Pendientes | Status filter chip |
| `event_filter_approved` | Aprobados | Status filter chip |
| `event_filter_rejected` | Rechazados | Status filter chip |
| `event_reject_confirm_title` | Rechazar inscripción | AppDialog title |
| `event_reject_confirm_body` | ¿Estás seguro de que quieres rechazar la inscripción de {name}? Esta acción no se puede deshacer. | AppDialog body |
| `event_reject_confirm_btn` | Sí, rechazar | Confirm button |
| `event_approve_action` | Aprobar | Attendee action button |
| `event_reject_action` | Rechazar | Attendee action button |
| `event_edit_status` | Editar estado | Attendee action for already-processed |
| `event_filters_title` | Filtrar inscritos | Bottom sheet title |
| `event_filter_status_label` | Estado | Bottom sheet section label |
| `event_filter_clear` | Limpiar | Bottom sheet clear button |
| `event_filter_apply` | Aplicar | Bottom sheet apply button |

---

## Error messages (must match API error codes)

| Error code / situation | User-facing message (ES) | Screen |
|------------------------|--------------------------|--------|
| Network timeout / no connection | No se pudo guardar el SOAT. Verifica tu conexión e intenta de nuevo. | SoatUploadPage / SoatManualFormPage |
| File too large (>10 MB) | Error al subir. Archivo demasiado grande (máx. 10 MB). | SoatUploadPage snackbar |
| `DioException` 404 (vehicle soat) | No se encontró el SOAT para este vehículo. | SoatStatusPage |
| `DioException` 500 | Ocurrió un error en el servidor. Intenta más tarde. | Any SOAT screen |
| SOAT expiry date missing | La fecha de vencimiento es obligatoria. | SoatManualFormPage inline |
| SOAT expiry date format invalid | Fecha inválida. Usa el formato DD/MM/AAAA. | SoatManualFormPage inline |
| Notifications load error | No se pudieron cargar las notificaciones | NotificationCenterPage error state |
| Attendees load error | No se pudo cargar la lista | AttendeesPage error state |
| Generic fallback | Ocurrió un error inesperado. Intenta de nuevo. | All screens |

---

## UX flow rules

### SOAT flow entry points
1. Vehicle Detail → tap DocumentSlotPill (SOAT row) → `context.pushNamed('soat-status')` if SOAT exists, or `context.pushNamed('soat-upload')` if `noSoat`
2. SoatStatusPage `Actualizar SOAT` button → `context.pushNamed('soat-upload')`
3. SoatUploadPage source option `Ingresar manualmente` → `context.pushNamed('soat-manual')`
4. SoatManualFormPage `Subir documento en cambio` link → pop back to SoatUploadPage

### SOAT upload phases (visual)
1. **Selección** — 2×2 source grid + upload zone + data form
2. **Progreso** — file card with progress bar, save button disabled (`Guardando…`)
3. **Procesando** — same UI, server processing
4. **Confirmación** — pop back to Vehicle Detail with success snackbar; DocumentSlotPill badge updates

### Notification read flow
- Tap unread notification item → calls `markRead(id)` → dot disappears, item opacity drops to 0.7
- `Marcar leídas` → calls `markAllRead()` → AppBar action disappears, unread section empties
- Bell badge updates from `NotificationsCubit.state.unreadCount`
- Load-more: tap `Cargar más notificaciones` → calls `loadMore()` → appends to list
- Pull-to-refresh: calls `load()` → full reload

### Notification bell badge
- Visible only when `unreadCount > 0`
- Shows numeric count; truncates to `99+` if over 99
- Updates on: app foreground, notification mark-read, notification center open

### SOAT Status logic (client-side)
```
if noSoat:       → "Sin registrar" (neutral badge)
if daysUntilExpiry > 30:   → "Vigente"    (green)
if daysUntilExpiry <= 30 && daysUntilExpiry >= 0: → "Por vencer" (yellow)
if daysUntilExpiry < 0:    → "Vencido"    (red)
```

---

## Accessibility notes

1. All interactive elements ≥ 44×44px (tap targets).
2. SOAT source options: 2×2 grid with 48px min height per cell — pass `Semantics(button:true, label: ...)` on each.
3. Error states: red border + inline error text (not just border change).
4. Progress bar: include `Semantics(label: 'Subiendo, ${percent}%', value: '${percent}')`.
5. Notification items: `Semantics(button: true, label: 'Notificación: ${title}, ${time}')`.
6. Bell badge: `Semantics(label: '${count} notificaciones sin leer')`.
7. Attendee action buttons: `Semantics(label: 'Aprobar inscripción de ${name}')` and `Semantics(label: 'Rechazar inscripción de ${name}')`.
8. All empty states: icons are decorative (`excludeFromSemantics: true`), title/subtitle are read.

---

## Design tool artifacts

### Pencil (rideglory.pen)
Pencil MCP not available during this session (desktop app not running). HTML mockups serve as the design gate. Frames to create in rideglory.pen before frontend implementation:

**Frames to CREATE (iter-2 gate):**
- `SOAT — Upload — Default` (frame pattern: `[Feature] — [Screen] — [State]`)
- `SOAT — Upload — Uploading`
- `SOAT — Upload — Error`
- `SOAT — Manual Form — Default`
- `SOAT — Manual Form — Errors`
- `SOAT — Status — Vigente`
- `SOAT — Status — Por vencer`
- `SOAT — Status — Vencido`
- `Vehicle Detail — SOAT Badge — 4 states` (update to frame `P1GSzZ` section)
- `Notifications — Center — Loading`
- `Notifications — Center — Data`
- `Notifications — Center — Empty`
- `Notifications — Notification Row — 6 types`
- `Home — Bell Badge` (update to frame `dyWWs` header)

**Frame dUc9h (ManageAttendeesPage):**
- Scope confirmed as **list + edit** (full layout already in codebase)
- UPDATE scope: verify component usage (AppButton, AppDialog), state polish (loading skeleton, empty EmptyStateWidget, error banner + retry)

### HTML mockups
Location: `docs/design/html-mockups/iter-2/`

| File | Screens covered |
|------|----------------|
| `styles.css` | Shared design tokens — extends iter-1 tokens, adds SOAT/notification-specific components |
| `soat.html` | SoatUploadPage (3 states) · SoatManualFormPage (2 states) · SoatStatusPage (3 states: Vigente, Por vencer, Vencido) · Vehicle Detail SOAT badge (4 states) |
| `notifications.html` | Home bell badge · NotificationCenterPage (loading, data, empty, error) · 6 notification row templates |
| `attendees.html` | AttendeesPage (loading, pending filter, all tab, empty, error, confirm dialog, filter bottom sheet) |

---

## Change log

- 2026-05-14: Iter-2 design phase complete. Pencil MCP unavailable — HTML mockups serve as gate. Story 2.9 scope confirmed as list+edit UPDATE (no layout rework, component-swap + state polish). 4 new HTML mockup files (styles.css, soat.html, notifications.html, attendees.html). 22 screens/states designed across 3 new HTML files. Full UI copy, component hierarchy, error messages, UX flow rules, and accessibility notes documented.
