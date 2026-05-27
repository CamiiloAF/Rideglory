# Architect Review — Refactor & Cleanup (Refactor-01)

> Generated: 2026-05-27
> Author: Architect Agent
> Input: PRD `docs/prd-refactor-cleanup.md`, PO proposal `01-po-proposal.md`, system scan `00-existing-system-scan.md`
> Codebase snapshot: branch `main`

---

## Stack validation

No new packages are required. All tooling already in pubspec.yaml covers this work:

- `go_router 17.0.0` — `context.pop(result)` is available (GoRouter 5+); no need for `Navigator.of` for simple pops.
- `flutter_bloc 9.1.1` — cubit pattern fully covers state needs.
- `freezed 3.2.3` — no regeneration needed unless REFACTOR-12 Option B is chosen.
- `dart analyze` — baseline run needed before story 1 to confirm current warning count (PRD claims 2 warnings in `api_base_url_resolver.dart`).

One tooling note: `SoatUploadCubit` in the legacy folder is marked `@injectable`. Deleting it requires verifying that GetIt's generated DI file (`injection.config.dart`) is regenerated after deletion. Run `dart run build_runner build --delete-conflicting-outputs` as part of REFACTOR-02 after deleting the cubit file.

---

## SOAT consolidation plan

### Current cross-reference map

The following external files (outside `vehicles/presentation/soat/`) import from the legacy folder. These are the **blast perimeter** — all must be updated before the legacy folder is deleted.

| File importing from legacy | What it imports | Purpose |
|---------------------------|-----------------|---------|
| `lib/shared/router/app_router.dart:43` | `vehicle_soat.SoatUploadPage` (aliased import) | Powers the `/vehicles/soat` route |
| `lib/features/soat/presentation/widgets/soat_status_view.dart:12` | `SoatManualCapturePage` | "Edit SOAT" action button in the new status view |
| `lib/features/soat/presentation/widgets/soat_source_grid.dart:5` | `SoatManualCapturePage` | All source options funnel into the manual capture form |
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart:20` | `SoatConfirmationPage` | Post-vehicle-creation SOAT photo confirmation flow |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart:10,11` | `SoatManualCapturePage`, `VehicleSoatOptionsSheet` | Vehicle form SOAT slot navigation |

Additionally, these files use `AppRoutes.vehicleSoat` to navigate to `/vehicles/soat` (which currently renders the legacy `SoatUploadPage`):

| File | Navigation call |
|------|-----------------|
| `lib/features/vehicles/presentation/form/widgets/vehicle_soat_form_slot.dart:53` | `context.pushNamed(AppRoutes.vehicleSoat, ...)` |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart:170` | `context.pushNamed(AppRoutes.vehicleSoat, ...)` |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart:50` | `context.pushNamed(AppRoutes.vehicleSoat, ...)` |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart:55` | `context.pushNamed(AppRoutes.vehicleSoat, ...)` |
| `lib/features/soat/presentation/widgets/soat_data_view.dart:232` | `context.pushNamed(AppRoutes.vehicleSoat, ...)` (renew action) |
| `lib/features/soat/presentation/widgets/soat_empty_state.dart:60` | `context.pushNamed(AppRoutes.vehicleSoat, ...)` |

**Critical finding:** `AppRoutes.vehicleSoat` (`/vehicles/soat`) is used by **6 active callers** across the app, including inside the *new* `features/soat/` widgets. The PO proposal says to delete this route, but `context.pushNamed()` with an unregistered name throws at runtime (not compile time) — this would be a silent production breakage. The route must be redirected, not deleted. See the Router changes section below.

**Critical finding — `SoatManualCapturePage` is actively used by the new implementation.** This page already imports from the `soat` domain layer (`SaveSoatUseCase`, `SoatModel`, `ImageStorageService`) but is stranded in the legacy folder. It is **not dead code** — it is the canonical manual entry form used by both the new upload flow and the status view. It must be **moved** to `features/soat/presentation/pages/`, not deleted.

**Critical finding — `SoatConfirmationPage` is used by `vehicle_form_page.dart`.** This page handles the post-vehicle-creation SOAT photo attachment flow and uses `SoatFormCubit` from the legacy folder. Both must be moved to `features/soat/`, not deleted.

**Critical finding — `VehicleSoatOptionsSheet` is referenced by `vehicle_form_docs_section.dart`.** This widget must be moved to `features/soat/presentation/widgets/`, not deleted.

### Proposed post-consolidation structure (file tree)

```
lib/features/soat/
├── domain/                                        (unchanged)
├── data/                                          (unchanged)
└── presentation/
    ├── cubit/
    │   ├── soat_cubit.dart                        (unchanged)
    │   └── soat_form_cubit.dart                   (MOVED from vehicles/presentation/soat/cubit/)
    ├── pages/
    │   ├── soat_upload_page.dart                  (unchanged — new impl)
    │   ├── soat_status_page.dart                  (unchanged — new impl)
    │   ├── soat_manual_capture_page.dart          (MOVED from vehicles/presentation/soat/)
    │   └── soat_confirmation_page.dart            (MOVED from vehicles/presentation/soat/)
    └── widgets/
        ├── soat_status_view.dart                  (unchanged — import updated)
        ├── soat_data_view.dart                    (unchanged — bug fix in REFACTOR-01)
        ├── soat_source_grid.dart                  (unchanged — import updated)
        ├── soat_source_option.dart                (unchanged)
        ├── soat_empty_state.dart                  (unchanged)
        ├── soat_detail_row.dart                   (unchanged)
        ├── soat_document_section.dart             (MOVED from vehicles/presentation/soat/widgets/)
        ├── soat_validity_card.dart                (MOVED from vehicles/presentation/soat/widgets/)
        └── soat_vehicle_options_sheet.dart        (MOVED from vehicles/presentation/soat/widgets/vehicle_soat_options_sheet.dart)
```

**Legacy files safe to DELETE outright** (not referenced externally, superseded by new implementation):
- `vehicles/presentation/soat/soat_upload_page.dart` — replaced by new `soat_upload_page.dart`
- `vehicles/presentation/soat/cubit/soat_upload_cubit.dart` — `@injectable`; regen DI after deletion
- `vehicles/presentation/soat/widgets/soat_upload_option_card.dart`
- `vehicles/presentation/soat/widgets/soat_manual_option_card.dart`
- `vehicles/presentation/soat/widgets/soat_upload_question_header.dart`
- `vehicles/presentation/soat/widgets/soat_vehicle_info_card.dart`
- `vehicles/presentation/soat/widgets/soat_doc_preview.dart`
- `vehicles/presentation/soat/widgets/soat_confirm_cta_bar.dart`
- `vehicles/presentation/soat/widgets/soat_valid_alert.dart`

**Legacy files that must be MOVED (not deleted):**
- `vehicles/presentation/soat/soat_manual_capture_page.dart` → `features/soat/presentation/pages/`
- `vehicles/presentation/soat/soat_confirmation_page.dart` → `features/soat/presentation/pages/`
- `vehicles/presentation/soat/cubit/soat_form_cubit.dart` + `.freezed.dart` → `features/soat/presentation/cubit/`
- `vehicles/presentation/soat/widgets/soat_document_section.dart` → `features/soat/presentation/widgets/`
- `vehicles/presentation/soat/widgets/soat_validity_card.dart` → `features/soat/presentation/widgets/`
- `vehicles/presentation/soat/widgets/vehicle_soat_options_sheet.dart` → `features/soat/presentation/widgets/soat_vehicle_options_sheet.dart`

### Files to move / delete / create — ordered execution

1. **Move** all files listed above to their new locations (update package import paths in each file)
2. **Update imports** in the 5 external blast-perimeter files
3. **Update app_router.dart** — remove the `vehicle_soat` alias import; change the `/vehicles/soat` route builder to use the new `SoatUploadPage`
4. **Add** `AppRoutes.soatManualCapture = '/soat/manual-capture'` to `app_routes.dart`
5. **Add** a named `GoRoute` for `soatManualCapture` to `app_router.dart`
6. **Update** `soat_source_grid.dart` and `soat_status_view.dart` to use the new named route instead of `Navigator.of(context).push` (see Navigator section)
7. **Run** `dart run build_runner build --delete-conflicting-outputs` to regen DI
8. **Delete** the 9 legacy files listed above
9. **Delete** now-empty `vehicles/presentation/soat/` directory

### Router changes required

**Decision: keep `/vehicles/soat` or eliminate it?**

The route `AppRoutes.vehicleSoat` (`/vehicles/soat`) is called by 6 active callers. The new implementation has `AppRoutes.soatUpload` (`/soat/upload`). Both accept `VehicleModel` as `extra` and render an upload page.

**Recommendation:** Keep `AppRoutes.vehicleSoat` as a constant and keep the `/vehicles/soat` route in the router, but change its builder to render the **new** `SoatUploadPage` instead of the legacy one. Remove only the legacy import alias. This approach:
- Requires zero changes to the 6 callers
- Eliminates the legacy code wiring
- Preserves backward compat for any deep links already in the wild

```dart
// BEFORE (app_router.dart):
import '../../features/vehicles/presentation/soat/soat_upload_page.dart' as vehicle_soat;
// ...
GoRoute(
  path: AppRoutes.vehicleSoat,
  name: AppRoutes.vehicleSoat,
  builder: (context, state) {
    final vehicle = state.extra as VehicleModel;
    return vehicle_soat.SoatUploadPage(vehicle: vehicle);  // legacy
  },
),

// AFTER (same import already exists for soatUpload route):
GoRoute(
  path: AppRoutes.vehicleSoat,
  name: AppRoutes.vehicleSoat,
  builder: (context, state) {
    final vehicle = state.extra as VehicleModel;
    return SoatUploadPage(vehicle: vehicle);  // new impl, same import
  },
),
```

**New route for `SoatManualCapturePage`:** The `soat_source_grid.dart` and `soat_status_view.dart` currently use `Navigator.of(context).push<bool>(SoatManualCapturePage)` with typed return values. Since `SoatManualCapturePage` now belongs to `features/soat/`, it should have a named route. Add:

```dart
// app_routes.dart
static const String soatManualCapture = '/soat/manual-capture';

// app_router.dart
GoRoute(
  path: AppRoutes.soatManualCapture,
  name: AppRoutes.soatManualCapture,
  builder: (context, state) {
    final params = state.extra as SoatManualCaptureParams;
    return SoatManualCapturePage(
      vehicle: params.vehicle,
      existingSoat: params.existingSoat,
      initialLocalImagePath: params.initialLocalImagePath,
    );
  },
),
```

Where `SoatManualCaptureParams` is a simple params class:

```dart
// lib/features/soat/presentation/pages/soat_manual_capture_params.dart
class SoatManualCaptureParams {
  const SoatManualCaptureParams({this.vehicle, this.existingSoat, this.initialLocalImagePath});
  final VehicleModel? vehicle;
  final SoatModel? existingSoat;
  final String? initialLocalImagePath;
}
```

The callers then use `context.push<bool>(AppRoutes.soatManualCapture, extra: SoatManualCaptureParams(...))` and read the typed result from the returned `Future`.

---

## Widget extraction technical contracts

### Naming conventions

| Scenario | Convention | Example |
|----------|-----------|---------|
| Widget extracted from a file, used only within the same feature folder | Public class, no leading underscore | `GarageEmptyState` |
| Sub-section of a parent widget | `<Parent><Role>` suffix | `EventDetailHeaderBackground` |
| Replaces a `_buildXxx()` method | Name what it renders, not the method name | `MaintenanceBadgeChip` (not `MaintenanceRightBadge`) |
| Pure leaf display widget | Descriptive noun phrase | `SoatStatusHeroCard`, `EventDifficultyBadge` |
| Widget potentially reusable across 2+ features | Consider promoting to `shared/widgets/` | `StatusBadgeChip` |

**Subdirectory rule:** When extracting 4+ widgets from a single parent file, create or use a `widgets/` subdirectory alongside the parent. Do not flatten all extracted files into the parent directory.

**File naming:** `snake_case` matching the class name exactly. `GarageEmptyState` → `garage_empty_state.dart`.

**No barrel files:** import each widget directly by file path. This codebase has no `index.dart` pattern.

### State-sharing risk assessment (stateful widgets)

The most dangerous extractions are `StatefulWidget` files where inner private widgets access `State<T>` fields via closures or parent scope. These require converting implicit state access to explicit constructor parameters before extraction.

| File | Risk level | Reason | Extraction strategy |
|------|-----------|--------|---------------------|
| `garage_vehicles_content.dart` (16 widgets) | **HIGH** | `_buildContainer()` and `_buildPlaceholderIcon()` methods imply closure over parent state; 16-widget files almost always have implicit state sharing | Extract leaf widgets first (pure display); convert closures to explicit constructor parameters; lift mutable state to `VehicleCubit` if it currently lives in `State<>` fields |
| `event_detail_cta_bar.dart` (8 widgets + `_buildContent` method) | **HIGH** | 8 state-variant widgets sharing a CTA context strongly implies a shared state machine; `_buildContent(BuildContext context)` confirms tight coupling | Audit all 8 variants' data dependencies before extracting; each variant widget receives all discriminating data as `final` constructor params; no shared mutable state between outer bar and inner variants |
| `maintenance_filters_bottom_sheet.dart` (12 widgets) | **MEDIUM** | Filter bottom sheets often hold local `_selected*` state in `State<>`; 12 widgets is large but filter UI is mostly pure display | Read the file first — if local `State<>` holds selection state, keep the outer `StatefulWidget` + `State` pair together and extract only stateless sub-components (individual chips, section headers, etc.) |
| `vehicle_form.dart` (9 widgets) | **MEDIUM** | Multi-step form; `FormBuilder` key shared across sections | Each section already receives `GlobalKey<FormBuilderState>` via constructor; extraction is safe if that pattern is maintained |
| `forgot_password_view.dart` (9 widgets) | **LOW** | Auth forms are typically stateless or have minimal, well-contained local state | Straightforward extraction; no special risk |
| `login_view.dart` (8 widgets) | **LOW** | Same as above | Straightforward extraction |
| `event_detail_view.dart` (9 widgets) | **MEDIUM** | Detail composition reads from `EventDetailCubit` via `BlocBuilder`; extracted widgets must each do their own cubit lookup or receive data as final params | Prefer passing final data params for leaf widgets; `BlocBuilder` in intermediate composites is acceptable |

### Const preservation rules

`const` constructors can be preserved after extraction **if and only if**:
1. The widget has no `Function()` parameters (callbacks break `const`)
2. The widget has no `BlocBuilder`/`BlocConsumer` (runtime lookups break `const`)
3. All fields are themselves `const`-compatible types

In practice:
- Leaf display widgets (pure text, icons, static decorators) → `const` preserved
- Widgets with `onPressed: VoidCallback` → **cannot be const**
- Widgets with cubit access → **cannot be const**
- `const SizedBox()`, `const Padding()` inside build methods → always preserved

After each extraction: run `dart analyze` immediately. The `prefer_const_constructors` lint will flag missing `const` opportunities and incorrectly applied `const` simultaneously.

### Risky files and extraction strategy per L-effort story

#### REFACTOR-03 (Vehicles) — riskiest file: `garage_vehicles_content.dart`

This is the highest-risk file in the entire iteration (16 widgets). Mandatory approach:

1. **Audit before touching:** read the full file and classify each of the 16 classes as: (a) pure display — receives all data via constructor, (b) state consumer — calls `context.read<VehicleCubit>()`, (c) state mutator — triggers cubit methods.
2. Extract pure-display (a) classes first, one per commit; run `dart analyze && flutter test` after each.
3. For state consumers (b): extract with `BlocBuilder` encapsulated inside the new widget file — do not pass `BuildContext` as a constructor param.
4. For state mutators (c): pass `VoidCallback` or typed callback as constructor param — the extracted widget never calls the cubit directly.
5. `_buildPlaceholderIcon()` → extract as `GaragePlaceholderIcon` (pure leaf, trivially safe).
6. `_buildContainer()` → audit for closure capture; extract as `GarageVehicleCard` passing all data as params.

#### REFACTOR-05 (Events) — riskiest file: `event_detail_cta_bar.dart`

The `_buildContent(BuildContext context)` method must become `EventDetailCtaBarContent extends StatelessWidget` placed in its own file. The 8 inner variant widgets each become their own file. Strategy:

1. Replace `_buildContent` method with a class that receives the registration state (or event model) as final constructor params.
2. Each of the ~8 variants (e.g., `EventDetailRegisteredBanner`, `EventDetailPendingBanner`) becomes its own file in `detail/widgets/cta/`.
3. After extraction: verify the CTA bar renders correctly in all 4 state variants by running the app (or a widget test if one exists).

#### REFACTOR-06 (Maintenance/Home/Profile/Registration) — riskiest file: `maintenance_filters_bottom_sheet.dart`

The critical question is whether filter selection state is local (`setState`) or cubit-driven. Read the file before implementing:
- If all selection state flows through the cubit: extract all 12 widgets independently.
- If local `State<>` holds `_selectedFilters` or similar fields: the outer `StatefulWidget` + `State` pair stays in one file (this is permitted by the standard — `State<T>` may coexist with its `StatefulWidget`); extract only the stateless sub-components (individual filter chips, category headers, etc.) to separate files.

---

## Navigator.of → go_router migration analysis

### Cases where pop(result) must be preserved with care

`context.pop(result)` (go_router) passes the result back to the caller if the caller used `context.push()`. However, when the caller used `showModalBottomSheet()` (imperative push), the result must go through the `Future` returned by `showModalBottomSheet` — both `Navigator.of(sheetCtx).pop(result)` and `context.pop(result)` work correctly in that case (both go through the imperative navigator stack).

| File | Pattern | Migration recommendation |
|------|---------|--------------------------|
| `maintenance_form_page.dart:66` | `Navigator.of(context).pop(saved)` — pops with `List<MaintenanceModel>` | Replace with `context.pop(saved)`. Verify the caller reads the returned `Future` from `context.push()`. If the caller ignores the result, the replacement is functionally identical and safe. |
| `maintenance_form_page.dart:84` | `Navigator.of(context).pop()` — simple back on type-selection step | Replace with `context.pop()`. Safe. |
| `vehicle_form_page.dart:173` | `Navigator.of(context).pushReplacement(MaterialPageRoute(...SoatConfirmationPage...))` | **Justified exception.** go_router has no `pushReplacement` with `MaterialPageRoute` builders. After REFACTOR-02 moves `SoatConfirmationPage` to `features/soat/`, either: (a) annotate as `// Custom: pushReplacement needed — VehicleFormPage must not remain in back stack after SOAT confirmation` and keep as-is this iteration; or (b) add `SoatConfirmationPage` as a named route and use `context.pushReplacementNamed()`. Recommend (a) for this iteration — adding a new route is out of scope. |
| `soat_source_grid.dart:19–27` | `Navigator.of(context).push<bool>(SoatManualCapturePage)` + reads `pop(true)` result | After REFACTOR-02 adds `AppRoutes.soatManualCapture` named route: replace with `await context.push<bool>(AppRoutes.soatManualCapture, extra: SoatManualCaptureParams(vehicle: vehicle))`. The `context.push()` returns `Future<Object?>` whose value is the popped result. **This migration is part of REFACTOR-02, not REFACTOR-09.** |
| `vehicle_form_docs_section.dart:149` | `Navigator.of(context).push<PendingManualSoat>(SoatManualCapturePage)` + reads typed result | Same migration as above: `context.push<PendingManualSoat>(AppRoutes.soatManualCapture, extra: SoatManualCaptureParams(...))`. **Part of REFACTOR-02.** |
| `soat_status_view.dart:51` | `Navigator.of(context).push<bool>(SoatManualCapturePage)` + `.then(...)` | Same migration. **Part of REFACTOR-02.** |

### Safe-to-migrate cases (simple `pop()` no result)

All `Navigator.of(context).pop()` calls (no result) are safe to replace with `context.pop()` with no other changes:
- `maintenance_form_content.dart:113,128,295`
- `event_filters_bottom_sheet.dart:99,249`
- `event_route_config_screen.dart:264,632`
- `registration_detail_bottom_bar.dart:42`
- `my_registrations_filter_bottom_sheet.dart:85,143`
- `attendees_filter_bottom_sheet.dart`
- `event_form_locations_section.dart`
- `event_detail_view.dart`
- `event_route_map_screen.dart`
- `vehicle_form_docs_section.dart` (simple back navigation call)

### Justified exceptions (annotate, do not migrate)

| File | Call | Required annotation |
|------|------|---------------------|
| `vehicle_form_page.dart:173` | `Navigator.of(context).pushReplacement(MaterialPageRoute(...SoatConfirmationPage...))` | `// Custom: pushReplacement needed — VehicleFormPage must not remain in back stack after SOAT confirmation` |
| `soat_manual_capture_page.dart` (_pickImage method) | `Navigator.of(sheetCtx).pop(0/1/2)` inside `showModalBottomSheet` builder | `// Custom: sheetCtx.pop() — required pattern for showModalBottomSheet typed result return` (annotate each of the 3 calls) |

### `context.goNamed` analysis (REFACTOR-10)

- `profile_page.dart`, `garage_page.dart`, `events_page.dart` in `PopScope`: `context.goNamed(AppRoutes.home)` **is intentional** — shell-tab navigation must replace the stack or the bottom nav `StatefulShellRoute` state machine breaks and tabs accumulate in the back stack. **Keep as `goNamed`**; annotate each with `// Intentional: shell-tab navigation resets stack to prevent back-stack accumulation in StatefulShellRoute`.
- `forgot_password_view.dart` x2: the view is pushed via `context.pushNamed(AppRoutes.forgotPassword)`, so returning should use `context.pop()` (simplest, correct). Change both `context.goNamed(AppRoutes.login)` calls to `context.pop()`.

---

## Story sequencing review

| Story | Depends on | Risk | Recommendation |
|-------|-----------|------|----------------|
| REFACTOR-01 (SOAT button bug) | None | Low | Approved as-is. Single-file, 2-line change. |
| REFACTOR-02 (SOAT consolidation) | REFACTOR-01 (clean baseline) | **HIGH** | Expanded scope required (see Conditions). Must also migrate typed-result `Navigator.of` calls in `soat_source_grid.dart`, `soat_status_view.dart`, `vehicle_form_docs_section.dart` as part of this story. Must regen DI after deleting `SoatUploadCubit`. |
| REFACTOR-08 (FormBuilderTextField) | None | Low | Do before REFACTOR-03 — shares `vehicle_specs_row.dart` and `vehicle_form_id_section.dart` with REFACTOR-03. Avoids double-editing those files. |
| REFACTOR-07 (raw buttons) | None, but coordinate with REFACTOR-05 | Low | The `event_form_view.dart` and `event_route_config_screen.dart` files are also in REFACTOR-05. Do REFACTOR-07 on those files before REFACTOR-05 to avoid merge conflicts. The SOS overlay (`OutlinedButton`) likely needs `// Custom:` annotation — verify `AppButton` covers the outline style before replacing. |
| REFACTOR-10 (context.goNamed) | None | Low | Must happen before REFACTOR-04 — both touch `forgot_password_view.dart`. |
| REFACTOR-12 (isLoadingMore comment) | None | Low | Option A (add comment) is correct and sufficient. |
| REFACTOR-04 (auth widget extraction) | REFACTOR-10 | Low | Straightforward. Auth screens are stateless forms. |
| REFACTOR-06 (maintenance/home/profile/registration) | None | Low-Medium | Read `maintenance_filters_bottom_sheet.dart` first to determine local vs cubit state before extracting. |
| REFACTOR-11 (color tokenization) | REFACTOR-03, REFACTOR-06 | Low-Medium | Must come AFTER REFACTOR-03 and REFACTOR-06 — those stories touch the same files that have hardcoded colors (e.g., `garage_vehicles_content.dart`, `vehicle_detail_view.dart`). Doing color work first means re-opening those files after widget extraction. Verify `AppColors.success`, `.warning`, `.error` exist before starting. |
| REFACTOR-09 (remaining Navigator.of) | REFACTOR-02 | Medium | REFACTOR-02 handles the 3 typed-result cases. REFACTOR-09 handles the remaining simple `context.pop()` replacements. |
| REFACTOR-03 (vehicles widget extraction) | REFACTOR-08 | **HIGH** | Largest blast radius. Do REFACTOR-08 first. Extract leaf widgets first, one per commit. Run full test suite after each file. |
| REFACTOR-05 (events widget extraction) | REFACTOR-07, REFACTOR-09 | **MEDIUM** | Do REFACTOR-07 and REFACTOR-09 on event files before REFACTOR-05 to avoid merge conflicts. `event_detail_cta_bar.dart` is the highest-risk extraction. |

### Critical path (revised)

```
REFACTOR-01
    └─→ REFACTOR-02 (expanded: move files + add named route + regen DI + migrate typed-result Navigator calls)
              └─→ REFACTOR-08 (before REFACTOR-03)
                    └─→ REFACTOR-07 (before REFACTOR-05 on event files)
                          └─→ REFACTOR-10 (before REFACTOR-04)
                                └─→ REFACTOR-12 (trivial)
                                      └─→ REFACTOR-04
                                            └─→ REFACTOR-06
                                                  └─→ REFACTOR-11 (after files are split)
                                                        └─→ REFACTOR-09 (remaining pops)
                                                              ├─→ REFACTOR-03 (largest)
                                                              └─→ REFACTOR-05 (most files)
```

### Revised recommended execution order

1. **REFACTOR-01** — bug fix, immediate win
2. **REFACTOR-02** — SOAT consolidation (expanded scope; see Conditions)
3. **REFACTOR-08** — FormBuilderTextField replacements (5 files)
4. **REFACTOR-07** — raw button replacements (annotate SOS overlay if needed)
5. **REFACTOR-10** — goNamed fixes (annotate shell tabs; fix forgot-password)
6. **REFACTOR-12** — isLoadingMore comment
7. **REFACTOR-04** — auth widget extraction
8. **REFACTOR-06** — maintenance/home/profile/registration extraction
9. **REFACTOR-11** — color tokenization (on already-split files)
10. **REFACTOR-09** — remaining Navigator.of → context.pop()
11. **REFACTOR-03** — vehicles widget extraction (largest blast radius)
12. **REFACTOR-05** — events widget extraction (most files; highest test risk)

---

## Non-regression test gates

### Pre-flight (before any story)
```bash
dart analyze lib/ --no-summary
# Expect: exactly 2 warnings in api_base_url_resolver.dart (dead_code, prefer_const_declarations)
flutter test
# Expect: all green
```

### After REFACTOR-02 (highest risk story)
```bash
dart run build_runner build --delete-conflicting-outputs
# Required: DI regen after deleting SoatUploadCubit
dart analyze lib/
flutter test test/features/soat/
flutter test test/features/vehicles/
find lib/features/vehicles/presentation/soat -name "*.dart" 2>/dev/null | wc -l
# Must return 0
grep -r "vehicles/presentation/soat" lib/ --include="*.dart"
# Must return 0 results
# Manual smoke test: vehicle detail SOAT badge → upload page → manual capture → back
# Manual smoke test: vehicle creation → SOAT section → photo attachment → confirmation page
# Manual smoke test: SOAT status view → "Edit" button → manual capture form → save → status refreshes
```

### After REFACTOR-03, 04, 05, 06 (widget extraction stories)
```bash
dart analyze lib/
flutter test
# Full suite — widget extraction can silently break widget-level test assertions
flutter test test/features/events/presentation/list/widgets/event_filters_bottom_sheet_test.dart
flutter test test/features/events/presentation/list/widgets/events_page_view_test.dart
flutter test test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart
flutter test test/features/vehicles/
flutter test test/features/maintenance/
```

**Widget test stability note:** The existing widget tests use `find.text()` matchers (not `find.byType(ClassName)`), so class renames from widget extraction do **not** break them. The one exception to verify before REFACTOR-07: `rider_profile_page_test.dart` — if it uses `find.byType(ElevatedButton)`, it will fail after the `ElevatedButton` is replaced with `AppButton`. Inspect this file before REFACTOR-07.

### After REFACTOR-07, 08, 09, 10, 11 (primitive replacement stories)
```bash
dart analyze lib/
flutter test
grep -rn "ElevatedButton\|OutlinedButton\|TextButton" lib/features/ --include="*.dart" | grep -v "// Custom:"
grep -rn "FormBuilderTextField" lib/features/ --include="*.dart"
grep -rn "Navigator\.of(context)\." lib/features/ --include="*.dart" | grep -v "// Custom:"
grep -rn "context\.goNamed" lib/features/ --include="*.dart" | grep -v "// Intentional:"
grep -rn "Color(0x" lib/features/ --include="*.dart" | grep -v "// Intentional:"
```

### Definition of Done gate (final)
```bash
dart analyze lib/
# Must return 0 errors, 0 warnings

flutter test
# Must return 100% pass

find lib/features -name "*.dart" | xargs grep -lc "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" | \
  while read line; do \
    file=$(echo "$line" | cut -d: -f1); \
    count=$(echo "$line" | cut -d: -f2); \
    if [ "$count" -gt 1 ]; then echo "$count $file"; fi; \
  done
# Must return 0 lines

find lib/features/vehicles/presentation/soat -name "*.dart" 2>/dev/null | wc -l
# Must return 0
```

---

## Architect verdict

**APPROVED WITH CONDITIONS**

The PO's 12-story decomposition is architecturally sound, the story sizing is reasonable, and the violation inventory is accurate. The iteration will achieve its goal of zero `dart analyze` warnings and full standard compliance if implemented in the order above.

Two implementation gaps in REFACTOR-02 would cause a compile error or silent runtime crash if not addressed. Both are contained within the story's scope:

1. `SoatManualCapturePage` is actively imported by 3 files outside the legacy folder — it must be moved, not deleted.
2. The typed-result `Navigator.of(context).push<bool>(SoatManualCapturePage)` pattern in `soat_source_grid.dart`, `soat_status_view.dart`, and `vehicle_form_docs_section.dart` requires a named go_router route for `SoatManualCapturePage` — this route must be created in REFACTOR-02, not deferred to REFACTOR-09.

---

## Conditions / required changes

### Condition 1 — REFACTOR-02 expanded scope (REQUIRED before implementation)

Add to REFACTOR-02's files-affected list:
- Move `soat_manual_capture_page.dart` → `features/soat/presentation/pages/`
- Move `soat_confirmation_page.dart` → `features/soat/presentation/pages/`
- Move `soat_form_cubit.dart` + `.freezed.dart` → `features/soat/presentation/cubit/`
- Move `soat_document_section.dart` → `features/soat/presentation/widgets/`
- Move `soat_validity_card.dart` → `features/soat/presentation/widgets/`
- Move `vehicle_soat_options_sheet.dart` → `features/soat/presentation/widgets/soat_vehicle_options_sheet.dart`
- Add `AppRoutes.soatManualCapture = '/soat/manual-capture'` to `app_routes.dart`
- Add `SoatManualCaptureParams` class to `features/soat/presentation/pages/`
- Add `GoRoute` for `soatManualCapture` to `app_router.dart`
- Migrate `soat_source_grid.dart`, `soat_status_view.dart`, `vehicle_form_docs_section.dart` from `Navigator.of().push<bool>()` to `context.push<bool>(AppRoutes.soatManualCapture, extra: ...)`
- Run `dart run build_runner build --delete-conflicting-outputs` after deleting `soat_upload_cubit.dart`

Add to REFACTOR-02's acceptance criteria:
- `grep -r "vehicles/presentation/soat" lib/ --include="*.dart"` returns 0
- Manual smoke: "Edit SOAT" button in status view opens manual capture form correctly
- Manual smoke: vehicle creation → SOAT photo → confirmation page flow works end to end
- Manual smoke: all 6 `vehicleSoat` callers still navigate to the upload page correctly

### Condition 2 — Execution order (REQUIRED)

Change the PO's recommended execution order to the revised order above. Key changes:
- REFACTOR-08 before REFACTOR-03 (same vehicle form files)
- REFACTOR-10 before REFACTOR-04 (same `forgot_password_view.dart`)
- REFACTOR-07 before REFACTOR-05 (same event files)
- REFACTOR-11 after REFACTOR-03 and REFACTOR-06 (avoids editing same files twice)

### Condition 3 — `SoatManualCapturePage` modal bottom sheet internals (annotate-only)

In `soat_manual_capture_page.dart`, the `_pickImage()` method contains `Navigator.of(sheetCtx).pop(0/1/2)` calls inside a `showModalBottomSheet` builder. These are **not violations** — they use `sheetCtx` (the bottom sheet's `BuildContext`) and are the correct pattern for returning a typed value from `showModalBottomSheet`. Add `// Custom: sheetCtx.pop() — required pattern for showModalBottomSheet typed result` on each of the 3 calls during REFACTOR-09.

### Condition 4 — `vehicle_form_page.dart` pushReplacement (annotate-only)

`Navigator.of(context).pushReplacement(MaterialPageRoute(...SoatConfirmationPage...))` is a justified exception. After REFACTOR-02 moves `SoatConfirmationPage` to `features/soat/`, annotate this call with `// Custom: pushReplacement — VehicleFormPage must not remain in back stack after SOAT confirmation`. Do not migrate to go_router in this iteration.

### Condition 5 — AppColors audit before REFACTOR-11 (verify before execution)

Before REFACTOR-11, run:
```bash
grep -n "success\|warning\|error\|primarySubtle\|errorSubtle" lib/core/theme/app_colors.dart
```
Verify `AppColors.success` (#22C55E), `AppColors.warning` (#EAB308), `AppColors.error` (#EF4444), and `AppColors.errorSubtle` exist. If any are missing, add them to `lib/core/theme/app_colors.dart` as the first act of REFACTOR-11 before touching any literal.
