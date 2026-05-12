# Design handoff — Iteration 3

**Date:** 2026-05-12
**Status:** done
**Iteration:** 3 (Track P — Design System in Pencil)

---

## Design system tokens

Tokens are set as Pencil variables in `pencil-new.pen` and used as `$variable-name` references in all frames.

| Pencil variable | Value | Role |
|-----------------|-------|------|
| `primary-orange` | `#f98c1f` | Primary action color, badges, icons |
| `background-dark` | `#0D0D0D` | Screen background |
| `surface-dark` | `#111111` | Card / bottom nav background |
| `text-primary` | `#FFFFFF` | Headings, body text |
| `text-secondary` | `rgba(255,255,255,0.6)` | Subtitles, meta labels |
| `border-color` | `rgba(255,255,255,0.12)` | Borders, dividers |
| `border-radius` | `8` | Standard corner radius |
| `font-family` | `Space Grotesk` | All typography |
| `error-color` | `#CF6679` | Error states, SOAT expired badge |

Additional legacy tokens (from iter-1 styles.css, still valid):
- `#34c77b` — success green (SOAT vigente badge)
- `#3d2a00` — SOAT expiring badge background
- `#2d1219` — SOAT expired badge background
- `#0d2b1a` — SOAT valid badge background / success circle background

---

## Screen inventory — 8 flows

### Flow 1: Authentication (splash → login → signup)
**Pencil section:** `01 — Onboarding` (frame `Tu1AC`)

| Screen | Flutter file | Pencil frame |
|--------|-------------|--------------|
| Splash screen | `splash_screen.dart` | `j7D4A` — Splash |
| Login | `login_view.dart` | `h0duSD` — Login |
| Signup | `signup_view.dart` | `K6MsqT` — Registro |

**Visual patterns (from stitch refs):**
- `login_screen_final.png`: Pure black bg, large bold heading "Bienvenido de nuevo", dark surface fields (no border), primary orange button full-width "Entrar", Google/Apple secondary buttons in dark surface, orange link text
- `splash_screen_con_logo_oficial.png`: Dark brown gradient bg, Rideglory logo centered, "RIDERHUB / CONNECT. RIDE. EXPLORE." tagline, orange progress bar at bottom
- `registro_v1.png`: Same dark bg, motorcycle hero image top, form below, primary orange "Registrarse" button

**Stitch references used:** `login_screen_final.png`, `splash_screen_con_logo_oficial.png`, `registro_v1.png`, `login_v1_1.png`

---

### Flow 2: Home / Dashboard
**Pencil section:** `02 — Home` (frame `Mrrbl`)

| Screen | Flutter file | Pencil frame |
|--------|-------------|--------------|
| Home / Dashboard | `home_page.dart` | `OlzPM` — Home |

**Visual patterns:**
- `dashboard_principal_3.png`: Greeting "HOLA, RIDER / Alex Rivera", vehicle cards "Mis Motos" with 2 vehicles showing maintenance status, "Próximas Rodadas" event list with difficulty flames, orange FAB (+)
- `dashboard_principal_1.png`: Vehicle header with thumbnail, "PRÓXIMO CAMBIO DE ACEITE EN 500KM" alert chip, event cards with cover images (horizontal scroll), "VER DETALLES" button
- Bottom nav: Inicio (active), Garaje, Eventos, Perfil

**Stitch references used:** `dashboard_principal_1.png`, `dashboard_principal_3.png`, `dashboard_principal_ktm_890.png`

---

### Flow 3: Events list & filters
**Pencil section:** `03 — Eventos` (frame `zwwtt`)

| Screen | Flutter file | Pencil frame |
|--------|-------------|--------------|
| Events list | `events_page.dart` | `gQhXh` — Explorar eventos |
| Event detail | `event_detail_page.dart` | `XCB47` — Detalle de evento |
| Create/edit event | `event_form_page.dart` | `ACmdw` — Crear evento |

**Visual patterns:**
- `explorar_eventos_v1.png`: Dark cards with cover image, event name, location/date meta, price chip (orange), "Ver detalles" outline button; filter row: Todos / Rutas / Off-Road / Track Day pills
- `detalle_de_evento_minimalista_1.png`: Hero image top, tags (EXPEDICIÓN 2024), large bold name, stats row (DIFICULTAD / TIPO / INVERSIÓN), map section, rich text description, admitted brands chips, CHECKLIST, sticky "RESERVAR PLAZA" button with price
- `nuevo_evento_ajustado.png`: Multi-step form with dark surface fields, AI cover generation button, rich text description (flutter_quill), location autocomplete

**Stitch references used:** `explorar_eventos_v1.png`, `detalle_de_evento_minimalista_1.png`, `nuevo_evento_ajustado.png`, `detalle_evento_solo_punto_de_encuentro_1.png`

---

### Flow 4: Event registration & approval
**Pencil section:** `04 — Inscripciones` (frame `Q7bSuN`)

| Screen | Flutter file | Pencil frame |
|--------|-------------|--------------|
| My registrations | `my_registrations_page.dart` | `WgIcg` — Mis inscripciones |
| Registration detail | `registration_detail_page.dart` | `clMVd` — Detalle inscripción |

**Visual patterns:**
- `mis_inscripciones_detallado_1.png`: Filter tabs (Todos / Pendiente / Aprobado / Cancelado), featured card with cover image + status badge (APROBADO green / PENDIENTE orange), grid of smaller event cards below
- `gesti_n_de_inscritos_actualizada_1.png` (organizer view): "Participantes" list, "NUEVAS SOLICITUDES" section with pending riders, Llamar/WhatsApp action buttons, approve/reject icons, "YA PROCESADOS" section below
- `detalle_de_inscripci_n_estructurado.png`: Registration detail with vehicle info, payment status, QR code

**Stitch references used:** `mis_inscripciones_detallado_1.png`, `gesti_n_de_inscritos_actualizada_1.png`, `detalle_de_inscripci_n_estructurado.png`

---

### Flow 5: Vehicles / Garage
**Pencil section:** `05 — Vehículos` (frame `e3Bgk3`)

| Screen | Flutter file | Pencil frame |
|--------|-------------|--------------|
| Garage (vehicle list) | `garage_page.dart` | `dyzPT` — Mi garaje |

**Visual patterns:**
- `mis_veh_culos_1.png`: "My Garage" title, All/Recent filter tabs, + Add New button, vehicle cards with thumbnail + status chip (LOW FUEL / RECENT RIDE / SERVICE DUE), plate + mileage footer, Garage Overview stats at bottom
- `mi_garaje_y_mantenimiento_1.png`: Vehicle header (thumbnail, name, km, plate), SOAT warning banner ("SOAT vence en 15 días" in dark orange on #3d2a00 bg), maintenance timeline list with category icons
- `detalle_veh_culo_info_expandible_v1.png`: Swipeable vehicle image, name + menu (⋮), license plate + mileage chips, "TECHNICAL SPECS" expandable section, GARAGE OVERVIEW stats

**Stitch references used:** `mis_veh_culos_1.png`, `mi_garaje_y_mantenimiento_1.png`, `detalle_veh_culo_info_expandible_v1.png`, `nuevo_veh_culo_v1.png`

---

### Flow 6: Maintenance
**Pencil section:** `06 — Mantenimiento` (frame `GPsZu` — empty, to be populated)

| Screen | Flutter file | Pencil frame |
|--------|-------------|--------------|
| Maintenance list | `maintenances_page.dart` | (empty frame `GPsZu`) |
| Maintenance detail | `maintenance_detail_page.dart` | — |
| Maintenance form | `maintenance_form_page.dart` | — |

**Visual patterns:**
- `historial_de_mantenimiento_listado_v1_1.png`: Dark app bar "Historial de Mantenimiento", search bar, filter chips (Todo / Rutina / Reparación), vehicle filter dropdowns, chronological sections by month (OCTUBRE 2023), timeline list items with category icon, service name, date + km, orange FAB
- `detalle_de_mantenimiento_1.png`: Service detail with icon, name, date, mileage, cost, notes, delete/edit actions
- `nuevo_mantenimiento_1.png`: Multi-field form: service type selector, date, mileage, cost, notes

**Stitch references used:** `historial_de_mantenimiento_listado_v1_1.png`, `detalle_de_mantenimiento_1.png`, `nuevo_mantenimiento_1.png`

---

### Flow 7: Profile & Rider profile
**Pencil section:** `08 — Perfil` (frame `XaOZT` — empty, to be populated)

| Screen | Flutter file | Pencil frame |
|--------|-------------|--------------|
| My profile | `profile_page.dart` | (empty frame `XaOZT`) |
| Rider profile (other user) | `users/` feature | — |

**Visual patterns:**
- `perfil_de_piloto_1.png`: "Piloto Profile" header, large avatar with verified badge, username (@handle), location, bio quote, stats row (DISTANCE / EVENTS / RIDES), Garage section (vehicle cards), Achievement Badges row
- `perfil_con_editar_v1.png`: My profile variant with Edit button, same layout as rider profile
- `editar_perfil_minimalista.png`: Edit form with photo upload circle, name/bio fields, save button

**Stitch references used:** `perfil_de_piloto_1.png`, `perfil_con_editar_v1.png`, `editar_perfil_minimalista.png`

---

### Flow 8: Live tracking
**Pencil section:** `07 — Rastreo en vivo` (frame `AB3pd` — empty, to be populated)

| Screen | Flutter file | Pencil frame |
|--------|-------------|--------------|
| Live map | `live_map_page.dart` | (empty frame `AB3pd`) |
| Participants | `participants_placeholder_page.dart` | — |

**Visual patterns:**
- `rastreo_en_grupo_mapa_vivo.png`: Google Maps full-screen base with rider avatar pins, distance stats bar top (DIST TO MARC 0.8 KM / GROUP AVG SPEED 85 KM/H), Riders in Group list (4 riders, speed + status), "End Sharing Session" red button, bottom tab bar (MAP / GROUP / ROUTES / CHAT / PROFILE)
- `telemetr_a_y_mapa_de_grupo_1.png`: Split view variant with telemetry overlay

**Stitch references used:** `rastreo_en_grupo_mapa_vivo.png`, `telemetr_a_y_mapa_de_grupo_1.png`, `evento_en_curso_bot_n_principal.png`

---

## SOAT upload flow (NEW — Iteration 3b hard gate)

### Flow overview
6-screen flow triggered by "Subir SOAT" button on a vehicle card.

```
Vehicle Card (badge) → Upload Entry (bottom sheet) → AI Progress → AI Confirmation → [Success]
                                                    ↘ Manual Entry → [Success]
```

### Screen 1 — Vehicle card with SOAT badge
**Pencil frame:** `Na3V5` (in section `MOMzL`)
**HTML mockup:** `docs/design/html-mockups/iter-3/soat-vehicle-card.html`

**Component hierarchy:**
- `AppBar` — "Mi garaje" + back + notifications icon
- `VehicleCard` (surface-dark bg, 12px radius)
  - `VehicleImage` — 180px gradient placeholder with bike icon
  - `CardBody` (16px padding, 12px gap)
    - Name row — vehicle name (20px bold) + ⋮ menu
    - Meta — plate + mileage (14px text-secondary)
    - **SOAT badge** (inline in card) — pill with icon + text
    - "Subir SOAT" button (primary orange, 44px, full-width)
- `BadgeVariants` section — all 3 states shown for reference
- `BottomNav` (absolute, y=732)

**SOAT badge states:**
| State | Background | Color | Icon | Text |
|-------|-----------|-------|------|------|
| Valid | `#0d2b1a` | `#34c77b` | `check_circle` | SOAT vigente |
| Expiring | `#3d2a00` | `#f98c1f` | `warning` | Vence en {N} días |
| Expired | `#2d1219` | `#CF6679` | `cancel` | SOAT vencido |

---

### Screen 2 — File picker entry (bottom sheet)
**Pencil frame:** `wzejY`
**HTML mockup:** `docs/design/html-mockups/iter-3/soat-upload-entry.html`

**Component hierarchy:**
- Background dim overlay (rgba black 60%)
- `BottomSheet` (surface-dark, 16px top radius)
  - Handle bar (40×4px, border-color fill)
  - Title — "Subir SOAT" (20px bold)
  - Subtitle — instructions (14px text-secondary)
  - `CurrentSOATCard` (shown if SOAT already exists)
    - PDF icon (32px primary-orange) + file name + meta + check icon
  - "Seleccionar PDF" button (primary, 52px)
  - "Ingresar manualmente" button (outline, 44px)

---

### Screen 3 — Upload + AI extraction progress
**Pencil frame:** `ATME9`
**HTML mockup:** `docs/design/html-mockups/iter-3/soat-upload-progress.html`

**Component hierarchy:**
- `AppBar` — "Subir SOAT" + back
- Centered body column (padding 32px)
  - Animated ring (120px, primary-orange border, spinning)
    - Inner circle (96px surface-dark) with `smart_toy` icon (48px primary)
  - Title — "Extrayendo información con IA..." (20px bold, centered)
  - Subtitle — description (14px text-secondary, centered)
  - `StepsCard` (surface-dark, 12px radius)
    - Step 1: check_circle (green) + "Archivo cargado correctamente"
    - Step 2: check_circle (green) + "PDF procesado"
    - Step 3: spinner circle (primary border) + "Extrayendo datos con IA..." (primary bold)
- "Cancelar" text button (text-secondary)

---

### Screen 4 — AI confirmation form
**Pencil frame:** `N2jvyA`
**HTML mockup:** `docs/design/html-mockups/iter-3/soat-confirmation.html`

**Component hierarchy:**
- `AppBar` — "Confirmar datos del SOAT" (16px)
- Scroll body (20px horizontal padding)
  - AI banner (dark amber bg, primary border, smart_toy icon)
  - Field group × 3 (each: label → input)
    - "Fecha de vencimiento" — focused border (primary) + calendar icon + pre-filled date
    - "Número de póliza" — normal border + pre-filled
    - "Aseguradora" — normal border + pre-filled
  - Warning note (dark red bg, error color, info icon)
  - "Confirmar datos" primary button (52px)
  - "Ingresar manualmente" text link (centered)

---

### Screen 5 — Manual entry fallback
**Pencil frame:** `Q1cZ7g`
**HTML mockup:** `docs/design/html-mockups/iter-3/soat-manual-entry.html`

**Component hierarchy:**
- `AppBar` — "Registrar SOAT"
- Scroll body
  - Heading — "Ingresa los datos manualmente" (18px bold)
  - Subheading (14px text-secondary)
  - Field group × 3 (all empty / placeholder text)
    - "Fecha de vencimiento" — placeholder "dd/mm/aaaa" + calendar icon
    - "Número de póliza" — placeholder
    - "Aseguradora" — placeholder
  - "Guardar" primary button (52px)

---

### Screen 6 — Success
**Pencil frame:** `DMXj1`
**HTML mockup:** `docs/design/html-mockups/iter-3/soat-success.html`

**Component hierarchy:**
- `AppBar` — close (×) icon only
- Centered body
  - Success circle (96px, success-bg bg) with check_circle (56px green)
  - Title — "SOAT registrado exitosamente" (22px bold, centered)
  - Subtitle — notification note (14px text-secondary, centered)
  - `SummaryCard` (surface-dark, border, 3 rows with dividers)
    - Fecha de vencimiento → value
    - Aseguradora → value
    - Número de póliza → value
  - "SOAT vigente" badge pill (success-bg, shield icon, green text)
  - "Listo" primary button (52px)

---

## UI copy (Spanish, all keys)

| l10n key | Text | Screen |
|----------|------|--------|
| `vehicle_soatBadgeValid` | SOAT vigente | Vehicle card badge |
| `vehicle_soatBadgeExpiring` | Vence en {days} días | Vehicle card badge |
| `vehicle_soatBadgeExpired` | SOAT vencido | Vehicle card badge |
| `vehicle_uploadSoat` | Subir SOAT | Vehicle card button |
| `soat_selectPdf` | Seleccionar PDF | Upload entry sheet |
| `soat_enterManually` | Ingresar manualmente | Upload entry + confirmation |
| `soat_aiLoading` | Extrayendo información con IA... | Progress screen |
| `soat_confirmData` | Confirmar datos | Confirmation screen CTA |
| `soat_save` | Guardar | Manual entry CTA |
| `soat_success` | SOAT registrado exitosamente | Success screen title |
| `soat_expiryDate` | Fecha de vencimiento | Form field label |
| `soat_policyNumber` | Número de póliza | Form field label |
| `soat_insurer` | Aseguradora | Form field label |

---

## Pencil document structure

**File:** `pencil-new.pen`

| Frame ID | Name | Content |
|----------|------|---------|
| `Tu1AC` | 01 — Onboarding | Splash, Login, Signup |
| `Mrrbl` | 02 — Home | Dashboard |
| `zwwtt` | 03 — Eventos | Events list, Detail, Create form |
| `Q7bSuN` | 04 — Inscripciones | My registrations, Registration detail |
| `e3Bgk3` | 05 — Vehículos | Garage (vehicle list + detail) |
| `GPsZu` | 06 — Mantenimiento | (empty — to fill in later iteration) |
| `AB3pd` | 07 — Rastreo en vivo | (empty — to fill in later iteration) |
| `XaOZT` | 08 — Perfil | (empty — to fill in later iteration) |
| `MOMzL` | 09 — SOAT Upload Flow | 6 new SOAT screens |

**SOAT screen IDs:**
- Screen 1 (Vehicle + badge): `Na3V5`
- Screen 2 (Upload entry): `wzejY`
- Screen 3 (AI progress): `ATME9`
- Screen 4 (Confirmation): `N2jvyA`
- Screen 5 (Manual entry): `Q1cZ7g`
- Screen 6 (Success): `DMXj1`

---

## HTML mockups

| File | Screen | Path |
|------|--------|------|
| `soat-vehicle-card.html` | Vehicle card + all 3 SOAT badge variants | `docs/design/html-mockups/iter-3/soat-vehicle-card.html` |
| `soat-upload-entry.html` | File picker bottom sheet | `docs/design/html-mockups/iter-3/soat-upload-entry.html` |
| `soat-upload-progress.html` | Upload + AI extraction progress | `docs/design/html-mockups/iter-3/soat-upload-progress.html` |
| `soat-confirmation.html` | AI-extracted fields confirmation form | `docs/design/html-mockups/iter-3/soat-confirmation.html` |
| `soat-manual-entry.html` | Manual entry fallback form | `docs/design/html-mockups/iter-3/soat-manual-entry.html` |
| `soat-success.html` | Success confirmation + summary | `docs/design/html-mockups/iter-3/soat-success.html` |

Shared base styles: `docs/design/html-mockups/iter-1/shared/styles.css` (iter-1 baseline, still valid)

---

## Hard gate status

✅ SOAT flow designed — Iteration 3b (Flutter UI) can proceed.

- All 6 SOAT screens designed in Pencil (`pencil-new.pen`, section `09 — SOAT Upload Flow`)
- All 6 HTML mockups written to `docs/design/html-mockups/iter-3/`
- All component hierarchies, UI copy, color tokens, and interaction states documented above
- l10n keys defined with `vehicle_soat*` and `soat_*` prefixes

---

## Stitch reference index

| Flow | Key stitch files used |
|------|-----------------------|
| Auth | `login_screen_final.png`, `splash_screen_con_logo_oficial.png`, `registro_v1.png` |
| Home | `dashboard_principal_1.png`, `dashboard_principal_3.png`, `dashboard_principal_ktm_890.png` |
| Events | `explorar_eventos_v1.png`, `detalle_de_evento_minimalista_1.png`, `nuevo_evento_ajustado.png` |
| Registration | `mis_inscripciones_detallado_1.png`, `gesti_n_de_inscritos_actualizada_1.png` |
| Vehicles | `mis_veh_culos_1.png`, `mi_garaje_y_mantenimiento_1.png`, `detalle_veh_culo_info_expandible_v1.png` |
| Maintenance | `historial_de_mantenimiento_listado_v1_1.png`, `detalle_de_mantenimiento_1.png` |
| Profile | `perfil_de_piloto_1.png`, `perfil_con_editar_v1.png` |
| Tracking | `rastreo_en_grupo_mapa_vivo.png`, `telemetr_a_y_mapa_de_grupo_1.png` |

---

## Change log

- 2026-05-12: Iteration 1 design handoff — Profile page, 4 states, styles.css baseline.
- 2026-05-12 (iter 3): Design System in Pencil — 8 flows documented in existing pencil-new.pen frames, design tokens set as 9 Pencil variables, SOAT upload flow designed (6 new screens in Pencil + 6 HTML mockups), hard gate for Iteration 3b cleared.
