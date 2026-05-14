# Frames pQCmS / f0lXw — Event Registration Form & My Registration Detail

---

## Frame pQCmS — Registration Form V2

**Flutter file(s):** `lib/features/event_registration/presentation/event_registration_page.dart` + `registration_form_content.dart` + `registration_form_view.dart` + `widgets/registration_form_section_card.dart`  
**Module:** F  
**Screenshot:** ../screenshots/pQCmS.png

### Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Section card bg | #1E1E24 | `$bg-card` |
| Section card border | #2A2A32 | `$border` |
| Accent | #F98C1F | `$accent` |
| Event context card | accent-subtle (#2D2117) + accent border | |
| Field bg | #1A1A1F | `$bg-secondary` |
| "Confirmar inscripción" button | #F98C1F | `$accent` |
| Total price | #F98C1F | `$accent` |

### Layout & Spacing
- Frame: 390px (height implicit — fill_container layout), clip=true, vertical layout
- **Status bar:** height 44, padding [0, 24]
- **Nav header (`Ui7mb`):** height 56, padding [0, 20], `space_between`
  - Back button + "Inscripción" title + (empty right)
- **Scroll content (`w2J8ZS`):** padding [16, 20], gap 16, vertical layout
  - **Event context card:** bg-accent-subtle, border 1px accent, cornerRadius 12, padding 14
    - Shows event name + date + location (quick reference for user)
  - **"Información Personal" section card:** bg-card, cornerRadius 12, border, padding 16
    - Section title: "INFORMACIÓN PERSONAL" uppercase, text-tertiary 10 700
    - Fields: Nombre completo, Correo, Teléfono (pre-filled from profile if saved)
    - "Guardar en mi perfil" checkbox row
  - **"Información Médica" section card:** blood type, emergency contact name + phone
  - **"Moto Registrada" section card:** vehicle selector chip (shows selected vehicle)
  - **Price summary:** "Subtotal + fee = total" or just total amount in accent
- **CTA bar (`TnPSZ`):** padding [16, 20, 32, 20], `justifyContent: center`
  - "Confirmar inscripción" button: fill_container, height 52, bg-accent, cornerRadius 12, text-inverse
  - Total price displayed above or inline with CTA

### Notes
- Section cards use `registration_form_section_card.dart` pattern
- "Guardar en mi perfil" checkbox uses `save_to_profile_checkbox.dart`
- This is a multi-section scroll form — NOT a stepper

---

## Frame f0lXw — Mi Inscripción (My Registration Detail)

**Flutter file(s):** `lib/features/event_registration/presentation/registration_detail_page.dart` + `widgets/*`  
**Module:** F  
**Screenshot:** ../screenshots/f0lXw.png

### Colors
Same palette. Additionally:
| Role | Hex | Variable |
|------|-----|----------|
| "Confirmada" badge | #22C55E | `$success` |
| "Confirmada" badge bg | #162A1F | success-subtle |
| Section card bg | #1E1E24 | `$bg-card` |
| Emergency section accent | #EF4444 | `$error` |
| Emergency section icon | #EF4444 | `$error` |
| "Editar Inscripción" button | #F98C1F | `$accent` |
| "Cancelar Inscripción" | #EF4444 | `$error` |

### Layout & Spacing
- Frame: 390px, 844px tall, clip=true, vertical layout, bg-primary
- **Status bar:** height 44, padding [0, 24]
- **Header (`rW6s5`):** height 52, padding [0, 20], `space_between` — back button + "Mi Inscripción" title
- **Scroll content (`uK8B8`):** padding [12, 20, 24, 20], gap 16, fill_container height, clip=true
  - **Event card:** cornerRadius 12, clip=true, image fill top ~100px, then event name + date + location, "Confirmada" badge
  - **"Datos de participación" section card:** bg-card, cornerRadius 12, padding 16
    - Info rows: "Moto registrada" / "Tipo de participación" / "Acompañantes"
    - Each row: label (text-secondary) + value (text-primary), `space_between`
  - **"Contacto de emergencia" section card:** header has emergency icon (red, 16×16) + "Contacto de emergencia" label
    - Info rows: Nombre + Teléfono
- **CTA bar (`NenbG`):** padding [16, 20, 32, 20], gap 10, bg-primary, border top `$border`
  - "Editar Inscripción" — fill_container, height 52, bg-card, border 1px `$accent`, cornerRadius 12, text-accent — ghost style
  - "Cancelar Inscripción" — fill_container, height 40, cornerRadius 12, text-error, no bg — text-only link

### States / Variants (this + registration_detail_page.dart)
The `registration_detail_page.dart` handles these states:
- `f0lXw` = own registration detail (attendee perspective) — most common case
- Any additional states (pending, cancelled) controlled by `RegistrationStatus` enum and conditional rendering

### Notes for Frontend
- `f0lXw` is the correct frame for `registration_detail_page.dart` (NOT ELB5u/eK2WW/heldR which are maintenance)
- The "Contacto de emergencia" section uses a red heart/alert icon for the section header icon
- "Cancelar Inscripción" is a text-only ghost link (no background, no border) — just text in error red
- The event card at the top is non-interactive (display only)
