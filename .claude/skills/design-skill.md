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
