# Frame EqnMm — Agregar / Editar Moto (Vehicle Form)

**Flutter file(s):** `lib/features/vehicles/presentation/form/vehicle_form_page.dart`  
**Module:** D  
**Screenshot:** ../screenshots/EqnMm.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Section bg | #1E1E24 | `$bg-card` |
| Field bg | #1A1A1F | `$bg-secondary` |
| Field border | #2A2A32 | `$border` |
| Accent | #F98C1F | `$accent` |
| Placeholder | #6B7280 | `$text-tertiary` |
| "Guardar" button | #F98C1F | `$accent` |
| Photo placeholder bg | #1A1A1F | `$bg-secondary` |
| Photo placeholder icon | #6B7280 | `$text-tertiary` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title | Space Grotesk | ~18 | 700 | #FFFFFF |
| Section label | Space Grotesk | ~11 | 700 | #9CA3AF (uppercase) |
| Field label | Space Grotesk | ~12 | 600 | #9CA3AF |
| Field value | Space Grotesk | ~14 | 400 | #FFFFFF |
| Field placeholder | Space Grotesk | ~14 | 400 | #6B7280 |
| "Guardar moto" button | Space Grotesk | ~15 | 600 | #0D0D0F |

## Layout & Spacing
- Frame: 390px, 1975px tall (two sections: TopSection 1318px + BottomSection 750px)
- Vertical layout, clip=true, bg-primary
- **Header:** back button + title centered + (empty right)
- **Photo area:** top section — large placeholder/image area (circular or square), tap to change
- **Form sections:** vertical layout, gap 16–24, padding [0, 20, 32, 20]
  - Each field: bg-secondary, cornerRadius 8, border 1px `$border`, height 52, padding [0, 14]
  - Fields: Marca (brand), Modelo, Año, Color, Cilindraje (cc), Placa, Kilometraje inicial
  - Select fields: right-side chevron-down icon
- **Bottom section:** Notas / descripción (multiline), Documentos section
- **CTA bar:** "Guardar moto" full-width, height 52, bg-accent, cornerRadius 12

## Components used
- `AppTextField` — all form fields
- Lucide icons: `arrow-left`, `camera`, `chevron-down`, `bike`

## States / Variants
- **Add mode:** empty fields, title "Agregar Moto", CTA "Guardar moto"
- **Edit mode:** pre-filled fields, title "Editar Moto", CTA "Guardar cambios"

## Notes for Frontend
- Photo area is a large tap-to-upload zone at top of form (uses `ImageStorageService`)
- Brand/model selectors use bottom sheet pickers
- Cilindraje and year use numeric keyboards
