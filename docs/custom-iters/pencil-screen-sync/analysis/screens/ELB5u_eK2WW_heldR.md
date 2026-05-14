# Frames ELB5u / eK2WW / heldR — Maintenance Form Step 2 (3 variants)

**CRITICAL CORRECTION:** These frames are named "Registrar — Paso 2 Formulario" in Pencil but the screenshot content clearly shows **"Nuevo Mantenimiento"** / **"Paso 2 de 2"** with tabs **Completado** and **Programado**. These are **Maintenance Form Step 2 variants**, NOT event registration.

**Flutter file(s):** `lib/features/maintenance/presentation/form/maintenance_form_page.dart` + `lib/features/maintenance/presentation/form/widgets/*`  
**Module:** E  
**Screenshots:** ../screenshots/ELB5u.png, ../screenshots/eK2WW.png, ../screenshots/heldR.png

---

## Architect Open Question — Q5 (ELB5u / eK2WW / heldR)

**Answer:** These three frames do NOT map to `registration_detail_page.dart`. They are Maintenance Form Step 2, controlled by a tab switch between "Completado" and "Programado" states.

The correct mapping:
- `eK2WW` → **Completado tab** (recording a past maintenance)
- `ELB5u` → **Programado tab** (scheduling a future maintenance)
- `heldR` → **Programado tab (partial/variant)** — same as ELB5u but with fewer fields (used when only date/notes are set, no mileage)

The tab/state control is a **tab selector chip row** ("Completado" | "Programado") in the `grpEstado` section of the form scroll content. This maps to an enum (e.g., `MaintenanceStatus.completed` vs `MaintenanceStatus.scheduled`).

---

## Common Layout & Spacing (all three)
- Frame: 391px wide, 1200px tall, clip=true, vertical layout, bg-primary
- **Status bar:** height 44, padding [0, 20]
- **Nav header:** height 52, padding [0, 20], `space_between`
  - Back button: 36×36, bg-card, cornerRadius 18, border
  - Center: title (maintenance type name, e.g. "Cambio de aceite") + subtitle icon chip (accent icon on accent-subtle bg)
  - Save button: cornerRadius 20, bg-accent, padding [8, 16] — "Guardar"
- **Scroll content:** padding [8, 20, 32, 20], gap 20, fill_container height
  - **Context card (`contextCard`):** cornerRadius 12, bg-accent-subtle (#2D2117), border 1px `$accent`, padding 14, gap 12
    - Shows vehicle + maintenance type info
  - **Status group (`grpEstado`):** tab chips "Completado" | "Programado"
  - Additional field groups vary by tab (see per-variant below)
- **CTA bar:** padding [16, 20, 32, 20], gap 10, border top 1px `$border`, bg-primary
  - Primary CTA: "Guardar mantenimiento" — height 52, bg-accent, cornerRadius 12, gap 8
  - Secondary link: "Descartar" — height 40, cornerRadius 12, text-tertiary

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Context card bg | #2D2117 | `$accent-subtle` |
| Context card border | #F98C1F | `$accent` |
| Card bg | #1E1E24 | `$bg-card` |
| Active tab chip | #F98C1F | `$accent` |
| Inactive tab chip | #242429 | `$bg-tertiary` |
| Field bg | #1A1A1F | `$bg-secondary` |
| Field border | #2A2A32 | `$border` |
| Next maintenance card border | #2A2A32 | `$border` |
| Date field icon | #F98C1F | `$accent` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Maintenance type title | Space Grotesk | ~16 | 700 | #FFFFFF |
| "Paso 2 de 2" | Space Grotesk | ~12 | 400 | #9CA3AF |
| Group label | Space Grotesk | ~12 | 600 | #9CA3AF |
| Tab chip text | Space Grotesk | ~13 | 600 | #FFFFFF / #6B7280 |
| Field label | Space Grotesk | ~12 | 600 | #9CA3AF |
| Field value | Space Grotesk | ~14 | 400 | #FFFFFF |
| "Guardar mantenimiento" | Space Grotesk | ~15 | 600 | #0D0D0F |
| "Descartar" | Space Grotesk | ~14 | 400 | #6B7280 |

---

## Variant: eK2WW — Completado tab (recording past maintenance)

**Scroll content sections:**
1. **Context card** — shows vehicle name + maintenance type icon
2. **grpEstado** — tab row: [Completado ✓ active] [Programado]
3. **grpFechaKm** — "Fecha del servicio" date picker + "Kilometraje al momento del servicio" number field
4. **grpCostoTaller** — "Costo total" field + "Taller / Mecánica" text field
5. **grpNotas** — "Notas u Observaciones" multiline text area
6. **grpProximo** — "Próximo mantenimiento" section: date + km fields
7. **proxCard** — "Próxima revisión" summary card (cornerRadius 12, border `$border`, gap 14, padding 14)

Screenshot: shows date "12 May 2024", mileage "41,040", taller "BEL203", notes section, next review card with date and km.

---

## Variant: ELB5u — Programado tab (scheduling)

**Scroll content sections:**
1. **Context card** — vehicle + type
2. **grpEstado** — tab row: [Completado] [Programado ✓ active]
3. **grpNotas** — "Descripción / Observaciones" multiline
4. **grpProximo** — "Próximo servicio estimado" with km field + date picker

Screenshot: shows mileage target "2,000 km", next date "12 Jun 2026", 30 días label.

---

## Variant: heldR — Programado (partial, no km yet)

Same as ELB5u but with fewer fields visible — just context card, estado tabs (Programado active), notes section, and próximo with date only. Represents the initial state before user enters km.

---

## Notes for Frontend
- The active tab chip has bg-accent fill; inactive has bg-tertiary
- The "Guardar mantenimiento" CTA is the same across all variants — just the form fields differ
- The context card always shows: vehicle thumbnail/icon + maintenance type name chip
- Date fields use a calendar date picker triggered on tap
- "Descartar" is a ghost button (no bg, no border) — text-tertiary, centered
- This maps entirely to `maintenance_form_page.dart` — one page, tab-controlled state
