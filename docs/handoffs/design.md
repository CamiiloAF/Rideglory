# Design Handoff — Iteration 6 (refactor-01)

**Date:** 2026-05-27
**Status:** Stand-down
**Phase:** design → frontend
**No HTML mockups directory needed.** No new screens. No Pencil frame work.

---

## Status (Stand-down)

Iteration 6 is a pure internal Flutter refactor (17 stories). Design has no Pencil frames to inspect or create, no new UI flows, and no new copy decisions. The only design-phase obligation is to sanity-check the `AppFormNavHeader` molecule API (locked by Architect, Decision A) against visual parity requirements for its 3 callsites, and to confirm the new color tokens are non-breaking additions.

---

## Scope confirmation

- Zero new screens
- Zero new Pencil frames
- Zero new user-visible flows
- Zero new copy strings (l10n key unification is REFACTOR-15 / developer scope)
- `AppFormNavHeader` API review: completed below
- Color token review: completed below
- Visual regression checklist: issued below

---

## AppFormNavHeader visual review (3 callsites)

### API under review (Decision A, architect.md)

```dart
class AppFormNavHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AppFormNavAction? leading;
  final AppFormNavAction? trailing;
  final Widget? bottom;
  final double height;         // default 56.0
  final bool showBottomBorder;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(
    bottom != null ? height + kBottomNavigationBarHeight * 0.5 : height,
  );
}
```

### Callsite 1 — VehicleFormPage

| Property | Expected | API verdict |
|----------|----------|-------------|
| leading | text "Cancelar" | `AppFormNavAction.text(label: "Cancelar")` — PASS |
| trailing | text "Guardar" (primary-colored, semi-bold) | `AppFormNavAction.text(label: "Guardar", emphasized: true, isLoading: ...)` — PASS |
| height | 56px | default `height = 56` — PASS |
| bottom | none | `bottom: null` — PASS |
| `preferredSize` | 56px | `Size.fromHeight(56)` when bottom == null — PASS |

Visual risk: None identified. Height 56px matches existing `VehicleFormNavHeader`. `emphasized: true` produces primary-color / semi-bold styling consistent with the prior implementation.

### Callsite 2 — MaintenanceFormPage

| Property | Expected | API verdict |
|----------|----------|-------------|
| leading | icon back-pill (36x36 pill container) | `AppFormNavAction.icon(icon: backIcon, pill: true)` — PASS |
| trailing | "Listo" pill button (primary accent) | `AppFormNavAction.pillText(label: "Listo", isLoading: ...)` — PASS |
| height | 52px | `height: 52` — PASS |
| bottom | progress bar widget | `bottom: MaintenanceProgressBars(...)` — PASS |
| `preferredSize` | 52 + bottom height | `Size.fromHeight(52 + kBottomNavigationBarHeight * 0.5)` = 52 + 28 = 80px |

**Visual risk — preferredSize calculation (CRITICAL):**
`preferredSize` uses `kBottomNavigationBarHeight * 0.5` (28px) as a proxy for the bottom slot height. The maintenance progress bar's actual rendered height must be confirmed by Frontend during implementation. If the progress bar renders taller than 28px, the `Scaffold.appBar` chrome will clip it. The overall page chrome height must equal `52 + actual_progress_bar_height` — matching the current `MaintenanceFormNavHeader` sum. Any difference shifts the Scaffold content area, which is a visual regression.

Frontend action required: measure `MaintenanceProgressBars` preferred height in isolation before merging REFACTOR-14. If it exceeds 28px, the `preferredSize` calculation must be corrected to use the actual value (not the `kBottomNavigationBarHeight * 0.5` proxy).

### Callsite 3 — EventFormView

| Property | Expected | API verdict |
|----------|----------|-------------|
| leading | text "Cancelar" | `AppFormNavAction.text(label: "Cancelar")` — PASS |
| trailing | text "Publicar" (create) / "Guardar cambios" (edit), emphasized | `AppFormNavAction.text(label: ..., emphasized: true, isLoading: ...)` — PASS |
| height | 56px | `height: 56` — PASS |
| bottom | none | `bottom: null` — PASS |
| `preferredSize` | 56px | `Size.fromHeight(56)` when bottom == null — PASS |

Visual risk: None identified. Dynamic trailing label (Publicar / Guardar cambios) is passed by caller; API supports this cleanly.

---

## Color token review (Decision D, architect.md)

New tokens to add to `lib/design_system/foundation/theme/app_colors.dart`:

| Token | Hex | Tailwind reference | Existing token | Relationship |
|-------|-----|-------------------|----------------|--------------|
| `statusGreen` | `0xFF22C55E` | green-500 | `success = 0xFF10B981` (emerald-500) | Different hue — addition, not alias |
| `statusWarning` | `0xFFEAB308` | yellow-500 | `warning = 0xFFF59E0B` (amber-400) | Different hex — addition, not alias |
| `statusError` | `0xFFEF4444` | red-500 | `error = 0xFFEF4444` | Same hex — functional alias, semantically distinct |

Verdict: APPROVED as non-breaking additions.

Design rationale: `statusGreen` and `statusWarning` are Tailwind-exact palette values used for SOAT status badges. Mapping these to the existing `success`/`warning` tokens would change the rendered badge colors. The Tailwind green-500 / yellow-500 pairing is the deliberate design intent from the SOAT badge spec; these tokens preserve it. `statusError` aliasing `error` is acceptable — the separate name clarifies status-badge semantic context. All 3 coexist with the existing `success`/`warning`/`error` tokens.

`primarySubtle` already exists (`Color(0xFF2D2117)`). No new `primarySubtle` needed.

---

## Visual regression checklist — Frontend captures during REFACTOR-14

Before merging REFACTOR-14, Frontend must capture 6 screenshot pairs (before = current implementation, after = AppFormNavHeader-migrated):

| # | Screen | Mode | Before | After |
|---|--------|------|--------|-------|
| 1 | VehicleFormPage | Create (empty form) | screenshot | screenshot |
| 2 | VehicleFormPage | Edit (pre-filled) | screenshot | screenshot |
| 3 | MaintenanceFormPage | Create (step 2, progress bar visible) | screenshot | screenshot |
| 4 | MaintenanceFormPage | Edit (pre-filled, progress bar visible) | screenshot | screenshot |
| 5 | EventFormView | Create (new event) | screenshot | screenshot |
| 6 | EventFormView | Edit (existing event) | screenshot | screenshot |

Acceptance standard: header chrome (title, leading, trailing, bottom slot, bottom border) must be pixel-equivalent between before/after pairs. Any visible shift in vertical positioning, color, or typography is a blocking regression.

Special focus pairs 3/4 (Maintenance): verify progress bar is not clipped. The bottom slot must render fully within the Scaffold appBar chrome. If clipping is visible in the after screenshot, resolve the `preferredSize` height before merging.

---

## Change log

- 2026-05-27 (iter-6 refactor-01 design): Stand-down. AppFormNavHeader API approved for 3 callsites. One visual risk: MaintenanceFormPage `preferredSize` bottom-slot height proxy (kBottomNavigationBarHeight * 0.5 = 28px) must be verified against actual `MaintenanceProgressBars` height before merging REFACTOR-14. Color tokens statusGreen/statusWarning/statusError approved as non-breaking additions. 6-screenshot regression checklist issued. No mockups, no Pencil frames, no new copy.
