# Frames t7MYzR / UYeeY — Forgot Password & Email Sent

**Flutter file(s):**
- `t7MYzR`: Auth feature — Forgot Password full-page screen (likely `lib/features/authentication/login/presentation/forgot_password_view.dart` or equivalent; may need to be created as an inline state of `login_view.dart`)
- `UYeeY`: Auth feature — Email Sent confirmation screen (continuation of forgot password flow)

**Module:** A  
**Screenshots:** ../screenshots/t7MYzR.png, ../screenshots/UYeeY.png

---

## Architect Open Question — Q3 (t7MYzR)

**Answer:** `t7MYzR` is a **full-page screen**, NOT a dialog or inline state of LoginView. It has:
- Full status bar (height 62)
- RIDEGLORY logo + tagline (same as login/splash branding)
- Back button (arrow left)
- Large heading "¿Olvidaste tu contraseña?"
- Body text
- Email input field
- "Enviar enlace" orange CTA button
- "¿Ya la recordaste? Inicia sesión" text link at bottom

This is a dedicated screen that requires either:
1. A new `forgot_password_view.dart` file in the auth feature, OR
2. It is already implemented as a separate state — Architect confirmed no dedicated page exists, but the frame proves one is needed

**Recommendation:** Create `lib/features/authentication/login/presentation/forgot_password_view.dart` as a separate page, or implement as a named route state from the `login_view.dart` Navigator. The human must approve if this requires a new route (since routes are normally out of scope). If it must remain inline, it should be a `PageView` or `AnimatedSwitcher` state within `login_view.dart`.

---

## Frame t7MYzR — Forgot Password

### Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Logo text "RIDEGLORY" | #F98C1F | `$accent` |
| Tagline text | #9CA3AF | `$text-secondary` |
| Back button | #9CA3AF | `$text-secondary` |
| Heading text | #FFFFFF | `$text-primary` |
| Body text | #9CA3AF | `$text-secondary` |
| Email field bg | #1A1A1F | `$bg-secondary` |
| Email field border | #2A2A32 | `$border` |
| Email field icon | #9CA3AF | `$text-secondary` |
| "Enviar enlace" button | #F98C1F | `$accent` |
| "Inicia sesión" link | #F98C1F | `$accent` |

### Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| "RIDEGLORY" logo | Space Grotesk | ~28 | 800 | #F98C1F |
| Tagline "Connect. Ride. Explore." | Space Grotesk | ~14 | 400 | #9CA3AF |
| Back arrow button | — | — | — | #9CA3AF |
| Heading "¿Olvidaste tu contraseña?" | Space Grotesk | ~24 | 700 | #FFFFFF |
| Body text | Space Grotesk | ~14 | 400 | #9CA3AF |
| Email field placeholder | Space Grotesk | ~14 | 400 | #6B7280 |
| "Enviar enlace" button | Space Grotesk | ~15 | 600 | #0D0D0F |
| "¿Ya la recordaste? Inicia sesión" | Space Grotesk | ~14 | 400 + 600 | #9CA3AF + #F98C1F |

### Layout & Spacing
- Frame: 390×844, clip=true, vertical layout, bg-primary
- **Status bar:** height 62, padding [22, 20, 0, 20]
- **Content area:** fill_container, padding [0, 24], gap 32, vertical layout, `justifyContent: center`
  - Logo section: RIDEGLORY (accent, large) + tagline (secondary, small), gap 4, center-aligned
  - Back button: left-aligned, `arrow-left` icon + spacing
  - Heading: "¿Olvidaste tu contraseña?" — large, bold, white
  - Body: explanation text, text-secondary, line-height 1.5
  - Email field: height 52, bg-secondary, cornerRadius 12, border, padding [0, 16], gap 8, envelope icon + placeholder
  - "Enviar enlace" button: fill_container, height 52, bg-accent, cornerRadius 12
  - "¿Ya la recordaste? Inicia sesión" — inline text link (mixed weight/color), center-aligned

---

## Frame UYeeY — Email Sent

This is the success screen after submitting the forgot password email.

### Visual Description
- Same layout as t7MYzR (bg-primary, full status bar, centered content)
- **Large envelope icon:** ~64×64 circle with envelope icon inside, orange/accent colored icon on subtle bg
- **Heading:** "¡Revisa tu correo!"
- **Body:** "Enviamos instrucciones para recuperar tu contraseña. Si no lo encuentras, revisa tu carpeta de spam."
- **Email display:** shows the user's email address (e.g., "tucorreo@ejemplo.com") in a field-like display (read-only)
- **CTA:** "Volver al Inicio de sesión" — orange button
- **Footer link:** "¿No recibiste el correo? Reenviar"

### Colors
Same palette as t7MYzR. Envelope icon: #F98C1F on #2D2117 (`$accent-subtle`) circle bg.

### Flutter File
This screen needs a `forgot_password_sent_view.dart` or is a state transition within the forgot password flow. It requires navigation from `t7MYzR`.

---

## Notes for Frontend
- Both screens share the same "RIDEGLORY" branding header (logo + tagline) — same as the login/signup screens
- These two screens form a 2-step flow: email input → email sent confirmation
- The human must clarify: new dedicated page files (requiring new routes) or inline states in `login_view.dart`
- If inline: use `AnimatedSwitcher` or a local `PageController` within `LoginView`'s state
