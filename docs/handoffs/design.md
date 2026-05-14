# Design handoff — Iteration 1

**Date:** 2026-05-14
**Agent:** design
**Iteration goal:** Bring 15 existing screens into full visual alignment with `rideglory.pen` — no new features, no backend changes.
**Pencil status:** Pencil desktop app not running during this session. HTML mockups serve as the design gate. Pencil frames to be verified by frontend agent before implementation.

---

## Design system baseline

All tokens are locked. Frontend must use these exclusively — no inline `Color(0xFF...)` or `Colors.<named>` (except `Colors.transparent`, `Colors.black`, `Colors.white`).

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

**Touch targets:** Minimum 44×44px on all interactive elements.

---

## Screens and states

### Module 1 — Splash + Auth (PR 1/5)

#### Splash (US-1-2)
**Pencil frame:** None in inventory — create `Auth — Splash — Loading` and `Auth — Splash — Error`.
| State | Visual |
|-------|--------|
| Loading | Logo (80×80 rounded, primary orange bg), app name, radial glow, progress bar (primary, animates 0→85%) |
| Error | Same as loading + error banner with "Reintentar" button below progress track |

**Gap:** `AppColors.darkBackground` already correct on splash_screen.dart. Glow animation present.

#### Login (US-1-3)
**Pencil frame:** Create `Auth — Login — Default`, `Auth — Login — Error`, `Auth — Login — Loading`.
| State | Visual |
|-------|--------|
| Default | Centered app name in AppBar, greeting heading, AppTextField (email), AppPasswordTextField (password), forgot password link, AppButton primary, divider, Google social button |
| Error | Error banner + red border on fields |
| Loading | AppButton shows loading indicator |

**Gaps:**
- `login_view.dart:38` — `Colors.green` → `AppColors.success`
- AppBar uses `AppColors.darkBackground` explicitly — acceptable, already semánticamente correcto

#### Signup (US-1-3)
**Pencil frame:** Create `Auth — Signup — Default`, `Auth — Signup — Error`.
| State | Visual |
|-------|--------|
| Default | Back button, 4 AppTextField fields, terms checkbox, AppButton, Google social button, login link |
| Error | Error messages below each invalid field |

#### Password Recovery (US-1-3)
**Pencil frame:** Create `Auth — PasswordRecovery — Email`, `Auth — PasswordRecovery — Sent`.
| State | Visual |
|-------|--------|
| Email entry | Single AppTextField email, AppButton "Enviar enlace" |
| Confirmation | Success icon (green circle), "Correo enviado" title, email shown, "Volver al inicio" button |

---

### Module 2 — Home Dashboard (PR 2/5)

#### Home (US-1-4)
**Pencil frame:** `dyWWs` (home dashboard) + `VMmN0` (bottom nav pill bar).
| State | Visual |
|-------|--------|
| Loading | Skeleton shimmer for header, vehicle card, stats row, events section |
| With data | Greeting header, main vehicle hero card (full-width, 180px, gradient overlay), stats chips row (km, rodadas, pendientes), "Próximas rodadas" section (horizontal scroll of event cards), "Acceso rápido" 2×2 grid |
| No vehicle | Dashed empty vehicle slot card with "Agregar moto" CTA, events empty state |
| No events | Events section shows `EmptyStateWidget` with "Ver eventos" secondary button |
| Error | Error banner with "Reintentar" — no spinner, no blank screen |

**Bottom nav pill bar (VMmN0):**
- Container: `AppColors.darkSurface`, 1px border `AppColors.darkBorder`, 24px border radius, 60px height, 16px margin left/right, 20px margin bottom
- Nav items: 5 items (Inicio, Eventos, + FAB, Garaje, Taller)
- Active: `colorScheme.primary`; inactive: `AppColors.darkTextSecondary`
- FAB (+): 44×44px, `colorScheme.primary` bg, 14px radius

**Gaps:**
- `home_event_default_background.dart:14` — `Color(0xFF2D1A0A)`, `Color(0xFF1A0D05)` → `AppColors.darkSurface` / `AppColors.darkSurfaceHighest`

---

### Module 3 — Events (PR 3/5)

#### Events List (US-1-5)
**Pencil frame:** `Neipf`.
| State | Visual |
|-------|--------|
| Loading | Skeleton for search bar, filter chips, 2 event cards |
| With data | AppSearchBar, filter chips (Todos / On road / Off road / Exposición / Filtros with count badge), event cards vertical (140px image, badges overlay, organizer avatar, title, meta row) |
| Empty | `EmptyStateWidget` with "Crear evento" CTA |
| No search results | `NoSearchResultsEmptyWidget` |
| Error | Error banner with "Reintentar" |

**Event card structure:** Image (140px, gradient overlay) → badges (AppEventBadge top-left) → organizer avatar (bottom-right) → body: title, date, location, capacity.

#### Event Detail (US-1-5)
**Pencil frame:** `kAubW`.
| State | Visual |
|-------|--------|
| Loading | Skeleton for hero, organizer, metrics, map |
| With data | 220px hero image, back+overflow buttons overlay, badges overlay, title, date, organizer row (avatar + name + follow button), 2×2 metrics grid (cupos, distancia, dificultad, costo), description, route map preview (120px), allowed brands chips |
| Error | Error banner |

**CTA bar variants (frame PMuA4):**
| Variant | CTA content |
|---------|------------|
| `canRegister` | Spots remaining + primary "Inscribirse" button |
| `registered` | `badge-success` "Inscrito" + secondary "Ver inscripción" |
| `pending` | `badge-warning` "Pendiente" + ghost "Cancelar" (red text) |
| `full` | "Sin cupos disponibles" (error text) + disabled "Inscribirse" |
| `closed` | `badge-error` "Cerrado" only |

#### Create/Edit Event Form (US-1-6)
**Pencil frame:** `zbCa0`.
- Cover image upload zone (140px dashed border + "generar con IA" text link — preserve AI cover generation widget)
- Section groups with primary orange uppercase section labels
- AppTextField for all inputs
- Difficulty selector: 3 chips (Baja / Media / Alta)
- Map route preview widget (preserved, no changes)
- AppButton primary "Publicar evento"

**New atom pre-condition (US-1-5):**
`AppEventBadge` — `lib/design_system/atoms/badges/app_event_badge.dart`
- Variants: `scheduled`, `inProgress`, `finished`, `cancelled`, `free`, `paid`
- Height 24px, 6px border radius, Space Grotesk 11px font-weight 700

---

### Module 4 — Garage (PR 4/5)

#### Garage List (US-1-7)
**Pencil frame:** `KCf6W`.
| State | Visual |
|-------|--------|
| Loading | Skeleton for hero card, quick actions, other vehicles list |
| With data | Main vehicle hero card (full-width, 200px, gradient overlay, plate tag, name, main badge), quick actions row (Taller / Detalle / Editar), "Otras motos" section with compact list items (56px thumb, name, plate) |
| Empty | `EmptyStateWidget` with "Agregar moto" CTA |
| Error | Error banner + "Reintentar" |

#### Vehicle Detail (US-1-7)
**Pencil frame:** `P1GSzZ`.
- 180px hero image (no border radius, full width), back + overflow buttons overlay
- Stats chips row (km, year, cc, type)
- Spec table (Marca, Modelo, Año, Cilindraje, Kilometraje, Color)
- Document slots section (2 DocumentSlotPill molecules: SOAT + tech review)
- "Ver mantenimientos" primary + "Editar moto" secondary buttons

#### Add/Edit Vehicle Form (US-1-8)
**Pencil frame:** `EqnMm`.
- Image upload banner (160px, dashed border, icon)
- Fields: marca dropdown, modelo, año, cilindraje, color, placa, kilometraje
- Document slots section (2 DocumentSlotPill, non-functional stubs in iter-1)
- Informational note "se configuran luego"
- AppButton "Guardar moto"

**New molecule during US-1-7 (pre-condition for PR 4):**
`DocumentSlotPill` — `lib/design_system/molecules/feedback/document_slot_pill.dart`
- States: `empty`, `valid`, `expiringSoon`, `expired`
- Height: auto (44px min), 8px border radius
- Colors: success/warning/error per state; `AppColors.darkSurfaceHighest` bg

---

### Module 5 — Maintenance + Registration (PR 5/5)

#### Maintenance Dashboard (US-1-9)
**Pencil frame:** `Ako7u`.
| State | Visual |
|-------|--------|
| Loading | Skeleton for vehicle selector, donut, items |
| With data | Vehicle selector dropdown (44px), donut chart health indicator + legend (Urgente/Próximo/Al día with counts), maintenance items list |
| Empty | `EmptyStateWidget` + "Registrar mantenimiento" FAB |
| Error | Error banner |

**Donut chart — color-only update (iter-1 scope decision):**
- Urgent segment: `AppColors.error` (`#EF4444`)
- Warning segment: `AppColors.warning` (`#F59E0B`)
- OK segment: `AppColors.success` (`#10B981`)
- Track (empty): `AppColors.darkSurfaceHighest`
- NO geometry or animation changes in iter-1.

#### Maintenance History (US-1-9)
**Pencil frame:** `SykjL`.
- Search bar + filter icon
- Year group headers (orange label + cost summary right-aligned)
- Chronological list items (type icon, name, date+km, cost, status badge)
- Pull-to-refresh

#### Maintenance Form — Step 1 (US-1-9)
**Pencil frame:** `J5h6P`.
- Step indicator (2 dots, active = 24px pill)
- Vehicle info pill (non-editable)
- 2×4 grid of service type cards (icon + label, 13px, 2 columns)
- Selected card: primary-dim bg + primary border

#### Maintenance Form — Step 2 (US-1-9)
**Pencil frame:** `eK2WW` (Completado), `ELB5u` (Programado).
- Tab bar: "Completado" | "Programado"
- **Completado:** fecha, km, costo, lugar, notas, next-maintenance block (km + fecha)
- **Programado:** fecha programada, km estimado, lugar, notas, reminder note (orange tinted)

#### Maintenance Filters Bottom Sheet (US-1-9)
**Pencil frame:** `v6RqaX`.
- 24px top border radius, handle
- Vehicle section (radio buttons)
- Estado section (chips: Todos / Completados / Programados / Urgentes)
- Período section (date range grid)
- Limpiar + Aplicar buttons

#### My Registrations (US-1-10)
**No dedicated frame in inventory** — use `oUv12` context + list layout from `registration list`.
| State | Visual |
|-------|--------|
| Loading | Skeleton cards |
| With data | Filter chips (Todas / Pendientes / Aprobadas / Rechazadas), registration cards (event name, date, status badge, vehicle + location meta) |
| Empty | `EmptyStateWidget` with "Explorar eventos" CTA |

#### Registration Detail (US-1-10)
**Pencil frame:** `oUv12`.
- 120px event hero mini image
- Event name + status badge
- Rider info section (nombre, teléfono, contacto de emergencia)
- Vehicle section (compact vehicle card with plate)
- Notes section
- CTA bar: "Cancelar inscripción" (secondary, error-colored, only when pending/approved)

---

## Component hierarchy

### New primitives (create before consuming PR)

```
lib/design_system/
  atoms/
    badges/
      app_event_badge.dart         ← NEW (PR 3 pre-condition)
  molecules/
    feedback/
      document_slot_pill.dart      ← NEW (PR 4 pre-condition)
```

### Existing components — usage map

| Component | Used in |
|-----------|---------|
| `AppButton` | All primary/secondary actions across all 5 modules |
| `AppTextButton` | Ghost actions (links, cancel, retry text) |
| `AppTextField` | All text inputs (event form, vehicle form, maintenance form) |
| `AppPasswordTextField` | Login + signup password fields |
| `AppLoadingIndicator(variant: page)` | Full-page loading states |
| `EmptyStateWidget` | All empty list states |
| `NoSearchResultsEmptyWidget` | Events list + maintenance history search empty |
| `AppDialog` / `ConfirmationDialog` | Exit dialogs, delete confirmations |
| `AppSearchBar` | Events list, maintenance history |
| `AppFilterChip` | Events filter chips, maintenance status chips |
| `AppCard` | Cards (already correct radius 12px) |
| `AppAppBar` | All feature app bars |
| `HomeBottomNavigationBar` | All shell screens |
| `VehicleListItem` | Other vehicles list in garage |
| `DetailPill` / `InfoChip` | Metric chips in event/vehicle detail |
| `AppBottomSheet` | All bottom sheets (24px top radius) |
| `FormSectionHeader` | Section labels in forms |
| `ContainerPullToRefresh` | All pull-to-refresh screens |

### Widget replacement map

| Current (wrong) | Replace with |
|-----------------|-------------|
| `ElevatedButton` (1 file: mileage_info_dialog.dart) | `AppButton` |
| `TextFormField` (1 file: event_form_multi_brand_section.dart:184) | `AppTextField` |
| Raw `AlertDialog` (0 files) | — no action needed |

---

## UI copy

All copy in Spanish (Colombian). Sentence case for buttons.

### Splash
| Key | Copy |
|-----|------|
| `app_tagline` | Rodadas. Comunidad. Aventura. |
| `splash_error_message` | No se pudo conectar. Verifica tu conexión a internet. |
| `splash_retry` | Reintentar |

### Auth
| Key | Copy |
|-----|------|
| `auth_welcome_title` | Bienvenido |
| `auth_welcome_subtitle` | Inicia sesión para continuar |
| `auth_email_label` | Correo electrónico |
| `auth_email_placeholder` | tu@correo.com |
| `auth_password_label` | Contraseña |
| `auth_password_placeholder` | Mínimo 8 caracteres |
| `auth_forgot_password` | ¿Olvidaste tu contraseña? |
| `auth_sign_in` | Iniciar sesión |
| `auth_continue_with_google` | Continuar con Google |
| `auth_no_account` | ¿No tienes cuenta? |
| `auth_register_link` | Regístrate |
| `auth_create_account_title` | Crear cuenta |
| `auth_join_community` | Únete a la comunidad |
| `auth_full_name_label` | Nombre completo |
| `auth_confirm_password_label` | Confirmar contraseña |
| `auth_terms_text` | Acepto los Términos de uso y la Política de privacidad de Rideglory |
| `auth_create_account_btn` | Crear cuenta |
| `auth_already_have_account` | ¿Ya tienes cuenta? |
| `auth_sign_in_link` | Inicia sesión |
| `auth_recovery_title` | Recuperar contraseña |
| `auth_recovery_heading` | ¿Olvidaste tu contraseña? |
| `auth_recovery_subtitle` | Ingresa tu correo y te enviaremos un enlace para restablecerla. |
| `auth_recovery_send` | Enviar enlace |
| `auth_recovery_back` | ← Volver al inicio de sesión |
| `auth_recovery_sent_title` | Correo enviado |
| `auth_recovery_sent_body` | Revisamos tu correo en {email}. El enlace expira en 15 minutos. |
| `auth_recovery_back_home` | Volver al inicio |
| `auth_recovery_resend` | No recibí el correo — reenviar |

### Home
| Key | Copy |
|-----|------|
| `home_greeting_morning` | Buenos días, |
| `home_greeting_afternoon` | Buenas tardes, |
| `home_greeting_evening` | Buenas noches, |
| `home_main_vehicle_badge` | ⭐ Principal |
| `home_no_vehicle_title` | Agrega tu primera moto |
| `home_no_vehicle_subtitle` | Lleva el control de tu garaje y mantenimientos |
| `home_no_vehicle_cta` | Agregar moto |
| `home_upcoming_rides` | Próximas rodadas |
| `home_quick_access` | Acceso rápido |
| `home_my_registrations` | Mis inscripciones |
| `home_view_all_events` | Ver todas |
| `home_no_events_title` | No tienes rodadas próximas |
| `home_no_events_subtitle` | Explora los eventos disponibles y únete a la comunidad |
| `home_explore_events` | Ver eventos |
| `home_error_message` | No se pudieron cargar tus datos. Verifica tu conexión e inténtalo de nuevo. |

### Events
| Key | Copy |
|-----|------|
| `event_badge_scheduled` | Programado |
| `event_badge_inProgress` | En curso |
| `event_badge_finished` | Finalizado |
| `event_badge_cancelled` | Cancelado |
| `event_badge_free` | Gratis |
| `event_badge_paid` | De pago |
| `event_search_placeholder` | Buscar eventos… |
| `event_filter_all` | Todos |
| `event_filter_on_road` | On road |
| `event_filter_off_road` | Off road |
| `event_filter_exhibition` | Exposición |
| `event_filter_btn` | Filtros |
| `event_no_events_title` | No hay eventos disponibles |
| `event_no_events_subtitle` | Sé el primero en crear un evento para la comunidad |
| `event_create_cta` | Crear evento |
| `event_filter_modal_title` | Filtrar eventos |
| `event_filter_type_label` | Tipo |
| `event_filter_type_all` | Todos los tipos |
| `event_filter_cost_label` | Costo |
| `event_filter_cost_all` | Gratuitos y de pago |
| `event_filter_cost_free` | Solo gratuitos |
| `event_filter_cost_paid` | Solo de pago |
| `event_filter_clear` | Limpiar |
| `event_filter_apply` | Aplicar filtros |
| `event_cta_register` | Inscribirse |
| `event_cta_view_registration` | Ver inscripción |
| `event_cta_cancel` | Cancelar |
| `event_cta_no_spots` | Sin cupos disponibles |
| `event_cta_closed` | Cerrado |
| `event_organizer_label` | Organizador |
| `event_spots_remaining` | Quedan {count} cupos |
| `event_allowed_brands` | Marcas permitidas |
| `event_detail_description` | Descripción |
| `event_detail_route` | Ruta |
| `event_detail_share` | Compartir |
| `event_form_name_label` | Nombre del evento |
| `event_form_name_placeholder` | Ej: Páramo del Sumapaz 2025 |
| `event_form_description_label` | Descripción |
| `event_form_description_placeholder` | Describe el recorrido, punto de encuentro, etc. |
| `event_form_date_label` | Fecha |
| `event_form_time_label` | Hora |
| `event_form_city_label` | Ciudad de inicio |
| `event_form_max_participants_label` | Máx. participantes |
| `event_form_cost_label` | Costo (COP) |
| `event_form_cost_placeholder` | 0 = gratis |
| `event_form_difficulty_low` | Baja |
| `event_form_difficulty_medium` | Media |
| `event_form_difficulty_high` | Alta |
| `event_form_cover_upload_label` | Toca para subir imagen de portada |
| `event_form_cover_ai_label` | o generar con IA |
| `event_form_publish` | Publicar evento |
| `event_form_save` | Guardar |

### Garage / Vehicles
| Key | Copy |
|-----|------|
| `vehicle_garage_title` | Mi garaje |
| `vehicle_main_badge` | ⭐ Principal |
| `vehicle_empty_title` | Tu garaje está vacío |
| `vehicle_empty_subtitle` | Agrega tu primera moto para llevar el control de mantenimientos y documentos |
| `vehicle_empty_cta` | Agregar moto |
| `vehicle_other_vehicles` | Otras motos |
| `vehicle_add_cta` | + Agregar |
| `vehicle_quick_taller` | Taller |
| `vehicle_quick_detail` | Detalle |
| `vehicle_quick_edit` | Editar |
| `vehicle_detail_specs_marca` | Marca |
| `vehicle_detail_specs_modelo` | Modelo |
| `vehicle_detail_specs_anio` | Año |
| `vehicle_detail_specs_cc` | Cilindraje |
| `vehicle_detail_specs_km` | Kilometraje |
| `vehicle_detail_specs_color` | Color |
| `vehicle_detail_documents` | Documentos |
| `vehicle_doc_soat_label` | SOAT |
| `vehicle_doc_techreview_label` | Técnico-mecánica |
| `vehicle_doc_state_empty` | Sin registrar |
| `vehicle_doc_state_valid` | Vigente |
| `vehicle_doc_state_expiringSoon` | Por vencer |
| `vehicle_doc_state_expired` | Vencido |
| `vehicle_view_maintenances` | Ver mantenimientos |
| `vehicle_edit` | Editar moto |
| `vehicle_form_title_add` | Agregar moto |
| `vehicle_form_title_edit` | Editar moto |
| `vehicle_form_brand_label` | Marca |
| `vehicle_form_model_label` | Modelo |
| `vehicle_form_year_label` | Año |
| `vehicle_form_cc_label` | Cilindraje (cc) |
| `vehicle_form_color_label` | Color |
| `vehicle_form_plate_label` | Placa |
| `vehicle_form_km_label` | Kilometraje actual |
| `vehicle_form_photo_label` | Foto de la moto (opcional) |
| `vehicle_form_photo_upload` | Toca para subir |
| `vehicle_form_docs_section` | Documentos |
| `vehicle_form_docs_note` | Los documentos se configuran luego desde el detalle de la moto |
| `vehicle_form_save` | Guardar moto |

### Maintenance
| Key | Copy |
|-----|------|
| `maintenance_maintenances` | Mantenimientos |
| `maintenance_dashboard_title` | Mantenimientos |
| `maintenance_history_title` | Historial |
| `maintenance_form_new_title` | Nuevo mantenimiento |
| `maintenance_form_step_select` | Selecciona el tipo de servicio |
| `maintenance_form_step_continue` | Continuar → |
| `maintenance_form_tab_done` | Completado |
| `maintenance_form_tab_scheduled` | Programado |
| `maintenance_form_date_done_label` | Fecha de realización |
| `maintenance_form_km_done_label` | Kilometraje al realizar |
| `maintenance_form_cost_label` | Costo (COP) |
| `maintenance_form_place_label` | Lugar / taller |
| `maintenance_form_notes_label` | Notas (opcional) |
| `maintenance_form_next_section` | Próximo mantenimiento |
| `maintenance_form_next_km_label` | En km |
| `maintenance_form_next_date_label` | O en fecha |
| `maintenance_form_save_done` | Guardar mantenimiento |
| `maintenance_form_date_scheduled_label` | Fecha programada |
| `maintenance_form_km_estimated_label` | Kilometraje estimado |
| `maintenance_form_reminder_note` | 🔔 Recibirás un recordatorio 30 días antes de la fecha programada. |
| `maintenance_form_save_scheduled` | Guardar recordatorio |
| `maintenance_history_search_placeholder` | Buscar mantenimiento… |
| `maintenance_filters_title` | Filtrar mantenimientos |
| `maintenance_filter_vehicle_label` | Moto |
| `maintenance_filter_status_label` | Estado |
| `maintenance_filter_status_all` | Todos |
| `maintenance_filter_status_done` | Completados |
| `maintenance_filter_status_scheduled` | Programados |
| `maintenance_filter_status_urgent` | Urgentes |
| `maintenance_filter_period_label` | Período |
| `maintenance_filter_from` | Desde |
| `maintenance_filter_to` | Hasta |
| `maintenance_filter_clear` | Limpiar |
| `maintenance_filter_apply` | Aplicar |
| `maintenance_legend_urgent` | Urgente |
| `maintenance_legend_warning` | Próximo |
| `maintenance_legend_ok` | Al día |
| `maintenance_status_overdue` | atrasado |
| `maintenance_km_remaining` | faltan |
| `maintenance_maintenanceDeletedSuccessfully` | (already exists) |

### Registrations
| Key | Copy |
|-----|------|
| `registration_my_registrations_title` | Mis inscripciones |
| `registration_filter_all` | Todas |
| `registration_filter_pending` | Pendientes |
| `registration_filter_approved` | Aprobadas |
| `registration_filter_rejected` | Rechazadas |
| `registration_empty_title` | No tienes inscripciones |
| `registration_empty_subtitle` | Explora los eventos disponibles e inscríbete |
| `registration_explore_events` | Explorar eventos |
| `registration_detail_rider_section` | Datos del rider |
| `registration_detail_vehicle_section` | Vehículo |
| `registration_detail_notes_section` | Notas |
| `registration_detail_cancel` | Cancelar inscripción |
| `registration_status_approved` | Aprobada |
| `registration_status_pending` | Pendiente |
| `registration_status_rejected` | Rechazada |

---

## Error messages (must match API error codes)

| API error code / situation | User-facing message (Spanish) |
|---------------------------|-------------------------------|
| `auth/wrong-password` | Correo o contraseña incorrectos. Verifica tus datos e intenta de nuevo. |
| `auth/user-not-found` | Correo o contraseña incorrectos. Verifica tus datos e intenta de nuevo. |
| `auth/email-already-in-use` | Este correo ya está registrado. Intenta iniciar sesión. |
| `auth/weak-password` | La contraseña debe tener al menos 8 caracteres. |
| `auth/invalid-email` | Ingresa un correo electrónico válido. |
| `auth/too-many-requests` | Demasiados intentos fallidos. Espera unos minutos e inténtalo de nuevo. |
| `auth/network-request-failed` | No se pudo conectar. Verifica tu conexión a internet. |
| Network timeout / no connection | No se pudo conectar. Verifica tu conexión e inténtalo de nuevo. |
| `DioException` 500 | Ocurrió un error en el servidor. Intenta más tarde. |
| `DioException` 403 | No tienes permiso para realizar esta acción. |
| `DioException` 404 (event) | Este evento ya no está disponible. |
| `DioException` 404 (vehicle) | Este vehículo no se encontró. |
| `DioException` 409 (already registered) | Ya estás inscrito en este evento. |
| Vehicle form — required field empty | Este campo es obligatorio. |
| Maintenance form — invalid km | El kilometraje debe ser un número mayor a cero. |
| Generic fallback | Ocurrió un error inesperado. Intenta de nuevo. |

---

## Accessibility notes

1. **Touch targets:** All interactive elements (buttons, list items, chips, bottom nav items) must be ≥ 44×44px. Use `SizedBox` wrapper if needed.
2. **Color contrast:** Primary orange (#f98c1f) on dark background (#111111) passes WCAG AA. Text secondary (#94A3B8) on dark background passes AA at 14px bold. Do not use text-muted (#64748B) for actionable labels.
3. **Loading states:** Use shimmer skeletons (`Skeleton` pattern) instead of spinners on full-page loads. `AppLoadingIndicator(variant: page)` is acceptable for transition moments only.
4. **Error states:** Never show only red text. Always include a "Reintentar" or actionable button. Use `ErrorBanner` widget pattern (colored border container with button).
5. **Empty states:** Never show a blank screen. Always render `EmptyStateWidget` with icon, title, subtitle, and optional CTA button.
6. **Screen reader:** Wrap interactive image overlays with `Semantics(button: true, label: '...')`. License plate tags should include `Semantics(label: 'Placa: $plate')`.
7. **Progress indicators:** Multi-step forms show step dots — current step must have larger (24px pill) visual indicator, not just color change.
8. **Font:** Space Grotesk loaded via `google_fonts`. Fallback: system sans-serif. Do not hardcode `fontFamily` strings.

---

## Design tool artifacts

### Pencil (rideglory.pen)
Pencil MCP was unavailable during this session (desktop app not running). The following frames require verification/creation before frontend implementation begins:

**Frames to verify (should exist):**
- `dyWWs` — Home Dashboard
- `Neipf` — Events List
- `kAubW` — Event Detail
- `PMuA4` — CTA State Variants
- `zbCa0` — Create Event
- `KCf6W` — Garage
- `P1GSzZ` — Vehicle Detail
- `EqnMm` — Add/Edit Vehicle
- `aGqnv` — Document Slot Pill
- `Ako7u` — Maintenance Dashboard
- `SykjL` — Maintenance History
- `v6RqaX` — Maintenance Filters
- `J5h6P` — Maintenance Step 1
- `eK2WW` — Maintenance Step 2 (Completed)
- `ELB5u` — Maintenance Step 2 (Scheduled)
- `oUv12` — Registration Detail
- `VMmN0` — Tab Bar
- `zKkmE` — Event Badge

**Frames to CREATE (auth frames gate):**
- `Auth — Splash — Loading`
- `Auth — Splash — Error`
- `Auth — Login — Default`
- `Auth — Login — Error`
- `Auth — Signup — Default`
- `Auth — Signup — Error`
- `Auth — PasswordRecovery — Email`
- `Auth — PasswordRecovery — Sent`

**Auth frames gate:** These 8 frames must exist in rideglory.pen before Story US-1-3 (Task T-1-3) implementation begins. Stories US-1-2, US-1-4 through US-1-10 are NOT blocked.

### HTML mockups
Location: `docs/design/html-mockups/iter-1/`

| File | Screens covered |
|------|----------------|
| `styles.css` | Shared design tokens (CSS variables matching Flutter AppColors) |
| `splash-auth.html` | Splash (loading, error) · Login (default, error) · Signup · Password recovery (email, sent) |
| `home.html` | Home dashboard (loading, with data, no vehicle, error) · Bottom nav VMmN0 |
| `events.html` | Events list (loading, data, empty) · Event detail + CTA variants · Filter bottom sheet · Create event form |
| `garage.html` | Garage list (loading, data, empty) · Vehicle detail · Add/Edit form · DocumentSlotPill 4 states |
| `maintenance-registration.html` | Maintenance dashboard (loading, data) · History · Step 1 · Step 2 (completed, scheduled) · Filters · Registration list · Registration detail |

---

## Change log

- 2026-05-14: Iter-1 design phase complete. Gap analysis performed via codebase inspection (Pencil MCP unavailable — desktop app not running). 5 HTML mockup files produced covering all 15 screens + auth frames + new primitives. Component hierarchy, UI copy, error messages, and accessibility notes documented. Auth frames gate established. Donut chart scoped to color-only for iter-1.
