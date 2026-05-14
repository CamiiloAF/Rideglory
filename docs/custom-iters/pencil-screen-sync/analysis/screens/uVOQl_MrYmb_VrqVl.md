# Frames uVOQl / MrYmb / VrqVl — Login / Register / Splash

**Module:** A  
**Screenshots:** ../screenshots/uVOQl.png, ../screenshots/MrYmb.png, ../screenshots/VrqVl.png

---

## Frame uVOQl — Login

**Flutter file(s):** `lib/features/authentication/login/presentation/login_view.dart` + `lib/features/authentication/login/presentation/widgets/*`

### Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| "RIDEGLORY" logo | #F98C1F | `$accent` |
| Tagline | #9CA3AF | `$text-secondary` |
| Field bg | #1A1A1F | `$bg-secondary` |
| Field border | #2A2A32 | `$border` |
| Field icon | #9CA3AF | `$text-secondary` |
| "¿Olvidaste tu contraseña?" | #F98C1F | `$accent` |
| "Iniciar sesión" button | #F98C1F | `$accent` |
| "o continúa con" divider | #2A2A32 | `$border` |
| Social button bg | #1E1E24 | `$bg-card` |
| Social button border | #2A2A32 | `$border` |
| "Regístrate" link | #F98C1F | `$accent` |

### Layout
- Frame: 390×844, clip=true, vertical layout, bg-primary
- **Status bar:** height 62, padding [22, 20, 0, 20]
- **Content:** fill_container, padding [0, 24], gap 32, vertical layout, `justifyContent: center`, `alignItems: center`
  - **Logo section:** "RIDEGLORY" (accent, Space Grotesk ~28 800) + "Connect. Ride. Explore." (text-secondary, ~14 400), gap 8, center
  - **Form fields:** vertical, gap 16, fill_container
    - Email field: height 52, bg-secondary, cornerRadius 12, border, padding [0, 16], gap 8 — envelope icon + placeholder "Correo electrónico"
    - Password field: height 52, same style — lock icon + placeholder "Contraseña" + eye-off toggle right
    - "¿Olvidaste tu contraseña?" — right-aligned text link, accent, ~12 600
  - **"Iniciar sesión" button:** fill_container, height 52, bg-accent, cornerRadius 12, text-inverse
  - **Divider:** "o continúa con" — horizontal line + text, text-tertiary, ~13 400
  - **Social buttons row:** 2 buttons, gap 12
    - Google: fill_container, height 48, bg-card, cornerRadius 12, border, "Google" label + Google logo
    - Apple: fill_container, height 48, bg-card, cornerRadius 12, border, "Apple" label + Apple icon
  - **"¿No tienes cuenta? Regístrate"** — center text, text-secondary + accent link

### Notes
- The "RIDEGLORY" logo uses ~800 weight (extra-bold) — match with `FontWeight.w800`
- Password field has show/hide toggle on right side (`eye-off` → `eye` icon)
- Form fields use cornerRadius 12, not the standard `$radius-sm` (8) — note this deviation

---

## Frame MrYmb — Register (Create Account)

**Flutter file(s):** `lib/features/authentication/signup/presentation/signup_view.dart` + `signup/widgets/*`

### Colors
Same palette as Login. Background #0D0D0F, fields #1A1A1F with border, button bg-accent.

### Layout
- Frame: 390×844, clip=true, vertical layout, bg-primary
- **Status bar:** height 62, padding [22, 20, 0, 20]
- **Header row (`L7hLm`):** height 56, padding [0, 20], gap 16
  - Back button: arrow-left icon, text-secondary
  - Title: "Crear Cuenta" — Space Grotesk ~20 700 white
- **Content (`yZJFw`):** fill_container, padding [8, 24, 40, 24], gap 24, vertical layout
  - **Subtitle:** "Únete a la comunidad motera." — text-secondary, ~14 400
  - **Form fields:** vertical, gap 16
    - Nombre completo: height 52, cornerRadius 12, user icon + placeholder
    - Correo electrónico: height 52, email icon + placeholder
    - Contraseña: height 52, lock icon + placeholder + eye toggle
    - Confirmar contraseña: height 52, same pattern
  - **"Crear cuenta" button:** fill_container, height 52, bg-accent, cornerRadius 12, text-inverse
  - **"¿Ya tienes cuenta? Inicia sesión"** — center text link

### Notes
- Unlike Login, Register has a back button and page title (not the full RIDEGLORY logo)
- Only 4 fields (no social login on registration)

---

## Frame VrqVl — Splash

**Flutter file(s):** `lib/features/splash/presentation/splash_screen.dart` + `splash/widgets/*`

### Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| "RIDEGLORY" logo | #F98C1F | `$accent` |
| Tagline | #9CA3AF | `$text-secondary` |
| Progress bar track | #1E1E24 | `$bg-card` |
| Progress bar fill | #F98C1F | `$accent` |

### Layout
- Frame: 390×844, clip=true, vertical layout, bg-primary
- **Center section (`wy2Wc`):** fill_container, vertical layout, gap 12, `justifyContent: center`, `alignItems: center`
  - "RIDEGLORY" — Space Grotesk ~32 800, accent color, center-aligned
  - "Connect. Ride. Explore." — Space Grotesk ~14 400, text-secondary, center
- **Progress bar (`SPmrM`):** padding [0, 80, 60, 80], bottom area
  - Progress bar: fill_container width, height ~4, cornerRadius 2, track bg-card, fill accent

### Notes
- Very minimal screen — logo + tagline centered, progress bar at bottom
- The progress bar is a linear progress indicator (not circular)
- Bottom padding 60px keeps bar above safe area
- Background is pure `$bg-primary` — no gradient, no glow (this is different from what iter-1 HTML mockup may have invented)
