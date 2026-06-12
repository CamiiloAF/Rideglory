# Frontend fix-run — event-form-stepper-fase3

**Date:** 2026-06-12T05:06:19Z
**Status:** fixed — all blockers resolved

---

## Fixes applied

### 1. `review_row.dart` — `Widget _rowContent()` inlined into `build()`

Removed the `Widget _rowContent()` helper method (zero-tolerance violation per
§Widget Rules). Content is now inlined directly in `build()` using a local
`Widget content` variable with `if/else if/else` branches. No separate file
needed because the logic is not a separate widget — it is a conditional content
assignment within one widget's build method.

Color fix: the label `Color(0xFF9CA3AF)` → `AppColors.textOnDarkSecondary`.

### 2. `navigation_row.dart` — GestureDetector replaced with AppButton

Replaced `GestureDetector + Container` for the "Atrás" button with:

```dart
AppButton(
  label: context.l10n.event_step_back,
  onPressed: isSaving ? null : cubit.prevStep,
  variant: AppButtonVariant.secondary,
  style: AppButtonStyle.filled,
  shape: AppButtonShape.pill,
  height: 52,
)
```

`cs.secondary` maps to `#242429` (darkTertiary) in the app theme, matching the
Pencil spec.

### 3. `publish_row.dart` — GestureDetector replaced with AppButton

Replaced `GestureDetector + Container` for "Guardar borrador" with:

```dart
AppButton(
  label: context.l10n.event_step_saveDraft,
  onPressed: isSaving ? null : () => _onSaveDraft(context),
  variant: AppButtonVariant.secondary,
  style: AppButtonStyle.filled,
  shape: AppButtonShape.pill,
  height: 44,
)
```

Removed the now-unused `Color(0xFF9CA3AF)` inline color.

### 4. `route_cta_bar.dart` — `// Custom:` comments added for both button states

AppButton does not support `boxShadow` (glow). Both `GestureDetector + Container`
usages are preserved with explicit justification comments:

- Active (orange glow): `// Custom: AppButton no soporta boxShadow glow requerido por Pencil spec veaGt`
- Disabled (opacity 40%): `// Custom: AppButton no soporta Opacity wrapping + estado deshabilitado visual...`

Inline colors replaced:
- `Color(0xFF242429)` → `AppColors.darkTertiary`
- `Color(0xFF9CA3AF)` → `AppColors.textOnDarkSecondary`

### 5. Inline `Color(0xFF...)` eliminated across all 7 files

All hex colors already had named equivalents in `AppColors`. No new constants
were required.

| Inline hex | AppColors constant |
|---|---|
| `Color(0xFF1A1A1F)` | `AppColors.darkBgSecondary` |
| `Color(0xFF1E1E24)` | `AppColors.darkCard` |
| `Color(0xFF2A2A32)` | `AppColors.darkBorderPrimary` |
| `Color(0xFF6B7280)` | `AppColors.textOnDarkTertiary` |
| `Color(0xFF9CA3AF)` | `AppColors.textOnDarkSecondary` |
| `Color(0xFF2D2117)` | `AppColors.primarySubtle` |
| `Color(0xFF242429)` | `AppColors.darkTertiary` |

Files fixed: `step_circle.dart` (4 instances), `route_cta_bar.dart` (2),
`review_row.dart` (1), `review_card.dart` (1), `route_search_bar.dart` (1),
`route_map_area.dart` (1), `publish_row.dart` (1).

---

## Verification

| Check | Result |
|---|---|
| `dart analyze lib/` | No issues found |
| `flutter test` | 824/824 passed, 0 failed |

---

## Files changed

| File | Change |
|---|---|
| `lib/features/events/presentation/form/widgets/steps/review_row.dart` | Inline `_rowContent()` → `build()`; fix inline color |
| `lib/features/events/presentation/form/widgets/steps/navigation_row.dart` | GestureDetector → AppButton secondary |
| `lib/features/events/presentation/form/widgets/steps/publish_row.dart` | GestureDetector → AppButton secondary; fix inline color |
| `lib/features/events/presentation/form/screens/route_cta_bar.dart` | Add `// Custom:` comments; replace inline colors with AppColors |
| `lib/features/events/presentation/form/widgets/steps/step_circle.dart` | Replace 4 inline colors with AppColors constants |
| `lib/features/events/presentation/form/widgets/steps/review_card.dart` | `Color(0xFF1E1E24)` → `AppColors.darkCard` |
| `lib/features/events/presentation/form/screens/route_search_bar.dart` | `Color(0xFF1A1A1F)` → `AppColors.darkBgSecondary` |
| `lib/features/events/presentation/form/screens/route_map_area.dart` | `Color(0xFF1E1E24)` → `AppColors.darkCard` |
