# Skill: design — Rideglory

> Last updated: 2026-05-13 — Fresh restart (refactor completo)
> Phase: domain

---

## Domain context

Rideglory es una app móvil para riders y organizadores de eventos en Colombia. El sistema de diseño es dark-mode con acento naranja, orientado a uso en la moto (al aire libre, con guantes).

**Personas:**
- **Rider** — navega eventos, rastrea rodadas, gestiona su garaje. Información rápida y accesible.
- **Organizador** — gestiona ciclo de vida del evento, revisa inscripciones, monitorea riders en mapa.

**Copy (español colombiano):**
- Todo en español. Sentence case en botones: `'Iniciar sesión'`, no `'INICIAR SESIÓN'`.
- Tono funcional y directo — herramienta de seguridad y logística, no red social.
- Errores: claros, accionables, en español plano.

---

## Design system

| Token | Valor |
|-------|-------|
| `color-bg` | `#0A0A0A` |
| `color-surface` | `#161616` |
| `color-surface-2` | `#1F1F1F` |
| `color-border` | `#2D2D2D` |
| `color-primary` | `#f98c1f` |
| `color-primary-dim` | `#3D2A0A` |
| `color-text-primary` | `#F4F4F5` |
| `color-text-secondary` | `#71717A` |
| `color-text-muted` | `#3F3F46` |
| `color-success` | `#22C55E` |
| `color-error` | `#EF4444` |
| `color-warning` | `#F59E0B` |
| Font | Space Grotesk |
| Border radius | 8px (inputs/botones) · 12px (cards) · 16px (cards grandes) · 24px (bottom sheets) |
| Mode | Dark only |

**Touch targets:** Mínimo 44×44px en todos los elementos interactivos.

**Componentes compartidos (usar, no recrear):**
- `AppButton` — acción primaria
- `AppTextButton` — acción secundaria / enlace
- `AppTextField` — input de texto
- `AppPasswordTextField` — input de contraseña
- `EmptyStateWidget` — estado vacío
- `AppDialog`, `ConfirmationDialog` — modales
- `VehicleListItem`, `VehicleSelectionBottomSheet`

---

## Archivo de diseño

**Archivo único:** `rideglory.pen` en la raíz del proyecto (`/Users/cami/Developer/Personal/Rideglory/rideglory.pen`).

**Flujo de trabajo del agente de diseño:**
1. `mcp__pencil__open_document` → abrir `rideglory.pen`
2. `mcp__pencil__get_editor_state` → inventariar frames existentes
3. `mcp__pencil__batch_get` → revisar diseños existentes
4. **Mejorar** lo que no cumpla los estándares del design system
5. **Crear** con `mcp__pencil__batch_design` todo lo que falte
6. `mcp__pencil__export_nodes` → exports a `docs/design/screenshots/`

El trabajo en Pencil es el **entregable principal**. Los mockups HTML son opcionales y complementarios.

---

## Pantallas del proyecto (fuente: REQUIREMENTS.md § Apéndice A)

| Frame ID (rideglory.pen) | Nombre | Descripción |
|--------------------------|--------|-------------|
| `dyWWs` | Home Dashboard | Dashboard principal |
| `Neipf` | Events List | Explorador de eventos |
| `kAubW` | Event Detail | Detalle de evento |
| `PMuA4` | CTA State Variants | Variantes de botón de inscripción |
| `zbCa0` | Crear Evento | Formulario de creación de evento |
| `qonbS` | Event Tracking — Map | Mapa de rastreo en tiempo real |
| `OEqDE` | Event Tracking — Riders Panel | Panel de participantes |
| `pQCmS` | Registration Form V2 | Formulario de inscripción |
| `oUv12` | Mi Inscripción | Detalle de inscripción del usuario |
| `dUc9h` | Editar Inscripción | Gestión de inscripción (organizador) |
| `KCf6W` | Garaje | Lista de vehículos |
| `P1GSzZ` | Detalle de Moto | Detalle de vehículo con specs y documentos |
| `EqnMm` | Agregar / Editar Moto | Formulario de vehículo |
| `aGqnv` | Documentos — Estado Lleno | Componente de documentos |
| `Ako7u` | Mantenimientos — Dashboard | Vista principal con salud del vehículo |
| `SykjL` | Mantenimientos — Historial | Lista cronológica por año |
| `v6RqaX` | Mantenimientos — Filtros | Bottom sheet de filtros |
| `J5h6P` | Nuevo Mantenimiento — Paso 1 | Selección de tipo de servicio |
| `eK2WW` | Nuevo Mantenimiento — Paso 2 (Completado) | Detalles de servicio realizado |
| `ELB5u` | Nuevo Mantenimiento — Paso 2 (Programado) | Detalles de servicio futuro |
| `nxTub` | Event Tracking — Estado SOS | Mapa con alerta SOS activa |
| `ulESU` | Mantenimientos — Var A (Timeline) | Variante timeline |
| `WmD8t` | Mantenimientos — Var B (Cards + Filtros) | Variante cards |
| `A7qDd` | Profile | Perfil del usuario |
| `YCuIq` | Vehicle Bottom Sheet | Bottom sheet de selección de vehículo |
| `VMmN0` | Tab Bar | Componente de navegación inferior |
| `zKkmE` | Event Badge | Badge de evento |

Pantallas que pueden NO existir todavía en Pencil (crear si faltan):
- Login / Registro / Splash / Recuperación de contraseña
- SOAT — flujo completo (entrada, subida, confirmación, manual, éxito)
- Perfil de otro rider (RiderProfile)
- Notificaciones
- Rastreo — estado SOS detallado

---

## Reglas UX clave

1. Toda pantalla async debe tener un **skeleton de carga** (shimmer, no spinner).
2. Toda lista con posible estado vacío renderiza `EmptyStateWidget` — nunca pantalla en blanco.
3. Estados de error muestran banner con **botón reintentar** — nunca solo texto rojo.
4. Flujos multi-paso muestran indicador de progreso (paso N de M).
5. Alertas overlay (SOS) no bloquean el mapa — banner top-anchor, mapa interactivo abajo.
6. Flujos de subida tienen fases visuales distintas: selección → progreso → procesamiento → confirmación.

---

## Reglas Pencil

- Agrupar pantallas por flujo (sección horizontal por feature).
- Usar variables del design system para colores, tipografía y radios — no hardcodear valores.
- Nombrar frames con el patrón: `[Feature] — [Pantalla] — [Estado]` (e.g., `Auth — Login — Error`).
- Al hacer screenshot, usar `mcp__pencil__snapshot_layout` si `get_screenshot` retorna blanco en fondos oscuros.

---

## Change log

- 2026-05-13: Skill reescrito desde cero. Reset completo de iteraciones anteriores. Fuente de verdad: REQUIREMENTS.md + rideglory.pen.

---
## Plan reapproval update — 2026-05-13 (plan v3, iters 1–5)

### Design source of truth
- `rideglory.pen` (Pencil MCP) is the ONLY design source. Never design from scratch.
- Pencil MCP tools: get_editor_state, open_document, batch_get, get_screenshot, batch_design, export_nodes.

### Iter-1 (Redesign) — design-heavy iteration
- 15 screens to audit vs rideglory.pen. Produce gap analysis BEFORE any Flutter code.
- Key frame IDs (REQUIREMENTS.md Appendix A): dyWWs (Home), Neipf (Events List), kAubW (Event Detail), zbCa0 (Create Event), KCf6W (Garage), P1GSzZ (Vehicle Detail), EqnMm (Add Vehicle), Ako7u (Maintenance Dashboard), SykjL (Maintenance History), J5h6P / eK2WW / ELB5u (Maintenance Form steps), oUv12 (Registration Detail), VMmN0 (Tab Bar), zKkmE (Event Badge).
- Auth frames (Login/Signup/PasswordRecovery): NO frame IDs in Appendix A — create frames in rideglory.pen before Story 1.3 begins.
- `app_event_badge.dart` atom: extract from frame zKkmE BEFORE Story 1.5.
- Document slot pill (aGqnv): extract as molecule DURING Story 1.7.
- Donut chart (Ako7u): confirm if colors-only or geometry change — if geometry, descope to colors-only for iter-1.

### Iter-2 (SOAT + Notifications) — new screens
- SOAT upload, SOAT manual form, SOAT 4-state badge (Sin SOAT / Vigente / Por vencer / Vencido), notification center.
- Notification row: generic template with icon slot for 6 types.
- ManageAttendeesPage (Story 2.9): confirm frame dUc9h scope (list + edit, or edit only).

### Iter-3 (Tracking) — map-heavy screens
- SOS button placement and confirmation dialog in frame qonbS.
- Organizer control bar (conditionally visible — organizer only).
- Red pulsing SOS marker animation spec.
- Android foreground service notification text spec.
- Empty state for "rider has no phone number" in SOS banner.

### Iter-4 (Followers + Profile) — social screens
- Frame A7qDd (Profile) MUST be updated to final design before iter-4 starts.
- Follower/following list: quick-follow button must be visually distinct from profile-level follow button.
- Optimistic update visual: follow button shows loading state during API call; reverts visually on failure.

### Iter-5 (Deep Links) — minimal new UI
- Share button in EventDetailPage confirmed in existing frame.
- Apple Sign-In: black button, white Apple logo, "Continuar con Apple" text — HIG compliance mandatory.
- Store redirect fallback page: show Rideglory logo + CTA (not a blank HTTP redirect).

### Design system tokens (locked)
- Background: #111111 | Primary orange: #f98c1f | Font: Space Grotesk | Border radius: 8px (cards: 12px, bottom sheets: 24px)
- Dark theme only. All UI copy in Spanish (sentence case for buttons).

## Change log
- 2026-05-13 (plan v3 approval): Frame inventory, iter-1 gap analysis process, atom extraction pre-conditions, and per-iteration design scope documented.
- 2026-05-14 (iter-1 design complete): Gap analysis complete. 5 HTML mockup modules produced. Auth frames gate: 8 frames to create in rideglory.pen (Auth — Splash/Login/Signup/PasswordRecovery). Donut chart: color-only scope for iter-1. See docs/handoffs/design.md for full details.

---

## Iter-1 design decisions (locked)

### Auth frames gate
8 frames missing from rideglory.pen inventory — must be created before T-1-3:
- `Auth — Splash — Loading`
- `Auth — Splash — Error`
- `Auth — Login — Default`
- `Auth — Login — Error`
- `Auth — Signup — Default`
- `Auth — Signup — Error`
- `Auth — PasswordRecovery — Email`
- `Auth — PasswordRecovery — Sent`

### Donut chart (frame Ako7u) — iter-1 scope
**Color-only** update. No geometry or animation changes in iter-1:
- Urgent: `AppColors.error` (#EF4444)
- Warning: `AppColors.warning` (#F59E0B)
- OK: `AppColors.success` (#10B981)
- Track: `AppColors.darkSurfaceHighest`

### New design-system primitives

**AppEventBadge** (atom — PR 3 pre-condition)
- Path: `lib/design_system/atoms/badges/app_event_badge.dart`
- Variants: `scheduled`, `inProgress`, `finished`, `cancelled`, `free`, `paid`
- Size: 24px height, 6px border radius, 11px Space Grotesk 700

**DocumentSlotPill** (molecule — PR 4 pre-condition)
- Path: `lib/design_system/molecules/feedback/document_slot_pill.dart`
- States: `empty`, `valid`, `expiringSoon`, `expired`
- Min height 44px, 8px border radius, darkSurfaceHighest bg

### Specific color violations identified in codebase
| File | Violation | Fix |
|------|-----------|-----|
| home_event_default_background.dart:14 | Color(0xFF2D1A0A), Color(0xFF1A0D05) | AppColors.darkSurface / darkSurfaceHighest |
| vehicle_detail_view.dart:47 | Color(0xFF1C1C1E) | AppColors.darkSurface |
| vehicle_spec_row.dart:24 | Color(0xFF2C241E) | AppColors.darkSurfaceHighest |
| vehicle_garage_overview_item.dart:21,29 | Color(0xFF2C2C2E), Color(0xFF3A3A3C) | AppColors.darkSurface / darkBorder |
| vehicle_quick_info_section.dart:23 | Colors.grey[500] | AppColors.darkTextSecondary |
| vehicle_maintenance_history_section.dart | Multiple grey + Color() refs | AppColors.darkSurface / darkSurfaceHighest |
| garage_options_bottom_sheet.dart:97 | Colors.grey[700] | AppColors.darkBorder |
| login_view.dart:38 | Colors.green (SnackBar) | AppColors.success |
| maintenances_page.dart:178 | Colors.green / Colors.red (SnackBar) | AppColors.success / error |
| event_form_multi_brand_section.dart:184 | TextFormField (wrong widget) | AppTextField |

### Pencil MCP learnings
- Pencil desktop app must be running before `open_document` works. If unavailable, HTML mockups serve as design gate but Pencil frames must still be verified/created before frontend starts.
- Use `snapshot_layout` for structural checks, `get_screenshot` only for visual fidelity verification.
- Auth frames do not exist in rideglory.pen — create with pattern `[Feature] — [Screen] — [State]`.
