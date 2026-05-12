# Design handoff — Iteration 1

**Date:** 2026-05-12
**Status:** done

---

## Design system baseline

| Token | Value |
|-------|-------|
| Primary color | `#f98c1f` (orange) |
| Dark background | `#111111` |
| Surface | `#1C1C1C` |
| Surface alt | `#242424` |
| Border | `#2E2E2E` |
| On-surface | `#FFFFFF` |
| On-surface-variant | `#9E9E9E` |
| Error | `#CF6679` |
| Error background | `#2A1218` |
| Font | Space Grotesk |
| Border radius | 8px standard, 12px for cards |
| Touch target | 44×44px minimum |

**Changed this iteration:** Baseline established for the first time. `styles.css` created at `docs/design/html-mockups/iter-1/shared/styles.css`. No tokens modified from CLAUDE.md design system.

---

## Screens and states

| Screen name | Story | Type | Mockup file | Status |
|-------------|-------|------|-------------|--------|
| Profile — loading | US-1-4 | NEW | `iter-1/profile_loading.html` | done |
| Profile — data (with vehicle) | US-1-4 | NEW | `iter-1/profile_data.html` | done |
| Profile — data (no vehicle) | US-1-4 | NEW | `iter-1/profile_empty.html` | done |
| Profile — error | US-1-4 | NEW | `iter-1/profile_error.html` | done |

**Skipped (no UI):** US-1-1 (test infra), US-1-2 (cubit tests), US-1-3 (widget tests), US-1-5 (code review).

---

## Screen breakdown: Profile page

### Loading state
- App bar: "Mi perfil" (no actions)
- Shimmer skeleton:
  - Circle shimmer 80×80px (avatar placeholder)
  - Two text shimmer bars (name height 22px, email height 16px)
  - Divider
  - Section label shimmer
  - Block shimmer 72px tall (vehicle card placeholder)
  - Two action row shimmers 44px each
- Bottom nav: Perfil tab active (orange)

### Data state (main vehicle present)
- App bar: "Mi perfil"
- Profile header:
  - `CircleAvatar` 80×80, background `#f98c1f`, two-letter initials in `#111111` (28px bold)
  - `fullName` — 20px bold white
  - `email` — 14px `#9E9E9E`
- Divider
- Section label: "Vehículo principal"
- Vehicle chip: motorcycle icon + vehicle name + model year — surface-alt background with dashed border variant
- Section label: "Cuenta"
- List items card (surface background, 8px radius):
  - "Mis inscripciones" → chevron → `AppRoutes.myRegistrations`
  - "Cerrar sesión" → error color, no chevron → triggers `ConfirmationDialog`

### Empty state (VehicleCubit emits empty)
- Same as data state but vehicle section shows inline placeholder:
  - Dashed border container, motorcycle icon (opacity 40%), text "Sin vehículos" in `#9E9E9E`
  - No "Agregar vehículo" CTA (out of scope iter-1; defer to garage navigation)

### Error state (ProfileCubit emits error)
- Full-screen centered layout (no partial data shown):
  - Warning icon 48px (opacity 50%)
  - Title: "No pudimos cargar tu perfil" (16px bold white)
  - Subtitle: "Revisa tu conexión e intenta de nuevo." (14px `#9E9E9E`)
  - `AppButton` primary: "Reintentar" → calls `fetchProfile()` — max-width 200px centered
- Note: if error fires after a successful load (future pull-to-refresh), use error-banner style (documented in HTML comment inside `profile_error.html`)

---

## Component hierarchy

| Screen | Components used | New components needed |
|--------|-----------------|-----------------------|
| Profile — all states | `AppAppBar`, `AppColors.darkBackground`, bottom nav (existing) | `ProfileHeader` widget (avatar + name + email), `ProfileMainVehicleCard` widget, `ProfileActionsList` widget |
| Profile — loading | Shimmer skeleton (inline Flutter widgets or `shimmer` package) | None |
| Profile — data | `CircleAvatar`, `VehicleListItem` or custom chip | `ProfileMainVehicleCard` |
| Profile — empty | Inline text placeholder (not full `EmptyStateWidget`) | None (inline is sufficient for single-field empty) |
| Profile — error | `AppButton` (primary), centered column layout | None |

**Widget file mapping (per architect handoff):**
- `profile_header.dart` → name + email + initials avatar
- `profile_main_vehicle_card.dart` → reads `VehicleCubit`, renders chip or "Sin vehículos"
- `profile_actions_list.dart` → inscripciones list item + logout list item

---

## UI copy (Spanish)

| Key | Text | Context |
|-----|------|---------|
| `profile_title` | "Mi perfil" | App bar title |
| `profile_mainVehicle` | "Vehículo principal" | Section label above vehicle chip |
| `profile_noVehicle` | "Sin vehículos" | Inline placeholder when VehicleCubit is empty |
| `profile_errorRetry` | "Reintentar" | Button in error state |
| `profile_loadingError` | "No pudimos cargar tu perfil" | Error state title |
| `registration_myRegistrations` (existing) | "Mis inscripciones" | Action list item (already in ARB) |
| `auth_logout` (existing) | "Cerrar sesión" | Logout action (already in ARB) |
| `auth_logoutConfirmTitle` (existing) | (existing) | Logout confirmation dialog |
| `auth_logoutConfirmMessage` (existing) | (existing) | Logout confirmation dialog |

**Note:** Error subtitle "Revisa tu conexión e intenta de nuevo." is rendered from the `DomainException.message` — not a hardcoded string. The `profile_loadingError` key is used as the primary error label; `DomainException.message` can be appended as a subtitle if non-empty.

---

## Error messages (must match API error codes)

| Error source | User message (ES) | Screen |
|---|---|---|
| `DomainException` (network / 500) | "No pudimos cargar tu perfil" + `error.message` as subtitle | Profile — error state |
| `DomainException` (401 / auth) | Handled by `FirebaseAuthInterceptor` → redirects to login; profile never sees this | — |

---

## Avatar logic

- Extract initials using `initialsFromName(String? fullName)` from `lib/core/utils/initials.dart`
- One word name → first letter uppercase
- Two+ words → first letter of first + first letter of last, uppercase
- Null / empty → `'?'`
- `CircleAvatar` background: `#f98c1f` (primary orange); foreground: `#111111` (dark)
- Size: 80×80px on profile page, font size 28px

---

## Accessibility notes

- All touch targets ≥ 44×44px (list items, buttons)
- "Reintentar" button: full-width or min 200px — easy tap even with gloves
- Avatar contrast: `#111111` on `#f98c1f` → contrast ratio ~7:1 (passes AA)
- Error color `#CF6679` on `#2A1218` background → passes AA for large text; error message 14px bold passes
- Section labels are uppercase 11px — decorative only, not interactive; no a11y issue
- Bottom nav active state uses color only — add `semanticLabel` in Flutter for screen readers

---

## Design tool artifacts

- HTML mockups: `docs/design/html-mockups/iter-1/`
- Files:
  - `shared/styles.css` — design system tokens, shimmer, components
  - `profile_loading.html` — loading shimmer skeleton
  - `profile_data.html` — data state with vehicle
  - `profile_empty.html` — data state without vehicle ("Sin vehículos")
  - `profile_error.html` — error state with retry button

---

## Change log

- 2026-05-12: Initial design handoff for Iteration 1. Profile page — all 4 states. `styles.css` baseline established. No prior mockups existed.
