# Design Handoff — event-creation-fixes-custom-routes-drafts

## Tool used

- **Design file:** `docs/custom-iters/event-creation-fixes-custom-routes-drafts/analysis/design/event-creation-v2.pen`
- **Screenshots:** `docs/custom-iters/event-creation-fixes-custom-routes-drafts/analysis/design/`
  - `01-autocomplete-field.png` — Screen 1: Autocomplete field all states
  - `02-route-type-selector.png` — Screen 2: Route type segmented control
  - `03-custom-route-builder.png` — Screen 3: Custom route builder with map + waypoints
  - `04-cupos-manual-input.png` — Screen 4: Cupos stepper with text input
  - `05-save-as-draft-bottombar.png` — Screen 5: Form bottom bar + draft confirmation sheet
  - `06-mis-borradores-page.png` — Screen 6: Mis borradores page (with cards + empty state)
  - `07-draft-event-card-badge.png` — Screen 7: Badge variants + event card with BORRADOR tag
  - `08-event-detail-draft-owner.png` — Screen 8: Event detail — draft owner view + Publicar CTA

---

## Touched screens

| # | Screen | Type | Notes |
|---|--------|------|-------|
| 1 | `AppPlaceAutocompleteField` | UPDATE | Activate from disabled stub; add overlay dropdown with all states |
| 2 | `EventFormLocationsSection` — Route type selector | EXTEND | Add segmented `Ruta simple / Ruta personalizada` control above meeting point field |
| 3 | Custom route builder section | NEW | New `CustomRouteBuilderSection` widget with Mapbox map + waypoint list |
| 4 | `EventFormMaxParticipantsSection` — cupos stepper | UPDATE | Replace static count Text with editable inline field; keep ± buttons |
| 5 | `EventFormBottomBar` — draft link + confirmation sheet | UPDATE | Wire `_DraftLink` to `saveDraft()`; add confirmation bottom sheet before saving |
| 6 | `MyDraftsPage` | NEW | Full page listing creator's draft events; accessible from profile |
| 7 | `EventCardMyEventBadge` + `EventCard` | UPDATE | Add `isDraft` variant; orange-outline "BORRADOR" badge |
| 8 | `EventDetailOwnerLifecycleBar` — draft state | EXTEND | Add `EventState.draft` branch with "Publicar evento" full-width CTA |

---

## UX flows

### Screen 1 — Autocomplete field (`AppPlaceAutocompleteField`)

| State | Behavior |
|-------|----------|
| **Idle** | Standard `AppTextField` with place icon; placeholder "Buscar lugar..." |
| **Focused / typing (< 3 chars)** | Orange border; no dropdown yet |
| **Loading (debounce fired, awaiting response)** | Orange border; spinner inside field (trailing) |
| **Results** | Dropdown below field; list of place-name strings; each row has pin_drop icon + place name; tapping a row fills the field and closes dropdown |
| **Empty** | Dropdown shows search_off icon + "No se encontraron resultados" |
| **Error** | Dropdown shows error row with warning icon + "Error al buscar. Intenta de nuevo." in `error` color; does NOT crash |
| **Selected** | Field shows selected value; orange border fades to normal; dropdown closed |

Debounce: 400 ms. Trigger at 3+ characters. Overlay closes on selection or tap-outside.

### Screen 2 — Route type selector

| State | Behavior |
|-------|----------|
| **Simple (default)** | "Ruta simple (A→B)" pill is orange-filled; "Ruta personalizada" is unselected |
| **Custom selected** | "Ruta personalizada" pill becomes orange; `CustomRouteBuilderSection` slides in below destination field |

Segmented control height: 48px. Radius: 10. Background: `darkTertiary`. Selected pill: orange fill, dark text. Inactive: transparent, secondary text.

### Screen 3 — Custom route builder

| State | Behavior |
|-------|----------|
| **Empty (0 waypoints)** | Map shows "Toca el mapa para agregar puntos"; "Agregar punto" button active |
| **Waypoints added (1–8)** | Each waypoint shows as numbered card (orange badge) + place name + delete icon; counter shows `n / 9`; "Agregar punto" button active |
| **Max reached (9 waypoints)** | "Agregar punto" replaced by disabled "Límite alcanzado (9/9)" button |
| **Waypoint search** | Tapping "Agregar punto" opens an autocomplete overlay (same as Screen 1) |
| **Confirm** | "Continuar" CTA at bottom navigates back to form with waypoints committed to `EventFormCubit` state |

Map area: 200px height, `#0C1018` fill, `cornerRadius: 12`. Waypoint pins on map: 28px orange circles with pin_drop icon. Waypoint card: 52px height, `BG_CARD`, numbered badge, place name, close icon.

### Screen 4 — Cupos stepper with manual input

| State | Behavior |
|-------|----------|
| **Null (—)** | Center area shows "—" in tertiary color; minus button is no-op; plus activates at 5 |
| **Value set** | Shows integer in primary color; both ± buttons active |
| **Editing (keyboard open)** | Center area becomes text field with orange border and orange text; shows cursor; subtitle becomes "Ingresa un valor entre 5 y 500"; card border becomes orange |
| **Validation error** | Red error row below card: "El valor debe estar entre 5 y 500." Value reverts to previous valid on focus loss |

Center input area: 70px wide, 40px height. ± buttons remain active (they still do +5/−5 steps). Editing activates via tap on count display.

### Screen 5 — Save as draft bottom bar

| State | Behavior |
|-------|----------|
| **Idle** | Primary orange "Publicar evento" button (h=56, radius=28); below it, a small "Guardar como borrador" text link with bookmark icon in tertiary color |
| **Draft link tapped** | Bottom sheet slides up: title "Guardar como borrador" + explanation text + "Cancelar" (dark) + "Guardar borrador" (orange outline) buttons |
| **Saving draft** | "Guardar borrador" button shows loading spinner; background overlay dims |
| **Draft saved** | Sheet dismisses; form navigates back; toast or page-level feedback |

Bottom sheet corner radius: 16px top-left + top-right. Handle: 40×4 pill, `BORDER` fill. Sheet background: `BG_CARD`.

### Screen 6 — Mis borradores page

| State | Behavior |
|-------|----------|
| **Loading** | Standard `PageLoadingStateWidget` |
| **Data (drafts exist)** | List of draft event cards; each card has BORRADOR badge overlay on image, Editar + Publicar action buttons |
| **Empty** | draft icon + "Sin borradores" + explanation text |
| **Error** | Standard `PageErrorStateWidget` with retry |

Entry point: Profile page → settings section → new "Mis borradores" menu item (icon: draft/bookmark). Navigation: `context.pushNamed(AppRoutes.myDrafts)`.

Draft card layout:
- Image area: 160px (with BORRADOR badge overlay at top-left)
- Content area: title + date chip + location row + action row
- Action row: "Editar" (dark fill, border) + "Publicar" (orange fill), each `fill_container` width

### Screen 7 — Draft badge variants

**`EventCardMyEventBadge` — two modes:**

| Mode | Visual |
|------|--------|
| `isDraft: false` (existing) | Gradient fill (`ACCENT → primaryLight`), verified icon, "MI EVENTO", dark text |
| `isDraft: true` (new) | Transparent fill, 1.5px orange stroke, draft icon, "BORRADOR", orange text |

**Event card with BORRADOR badge:**
- State badge (Próximo / En curso / etc.) stays at top-left
- BORRADOR badge appears at top-right of image area (absolute position)
- Both badges coexist; BORRADOR is only shown when `isOwner && event.state == EventState.draft`

### Screen 8 — Event detail — draft owner

| State | Behavior |
|-------|----------|
| **Viewing draft (owner)** | BORRADOR badge in hero; draft info banner ("Solo tú puedes verlo"); Publicar CTA bar at bottom |
| **Publishing (loading)** | Publicar button shows spinner; other interactions disabled |
| **Published (success)** | CTA bar switches to `_OwnerStartBar` (existing scheduled flow); BORRADOR badge disappears from hero |

Owner lifecycle bar for `EventState.draft`:
- Top hint row: lock icon + "Solo visible para ti · Borrador" in tertiary
- Full-width "Publicar evento" orange pill button (h=56, same as other lifecycle bars)
- Loading state: button opacity 60%, circular progress indicator

---

## Components

### Reused (no changes needed)

| Component | Path |
|-----------|------|
| `AppTextField` | `lib/shared/widgets/form/app_text_field.dart` |
| `AppButton` | `lib/shared/widgets/form/app_button.dart` |
| `FormSectionHeader` | `lib/design_system/molecules/layout/form_section_header.dart` |
| `PageLoadingStateWidget` | `lib/shared/widgets/states/page_loading_state_widget.dart` |
| `PageErrorStateWidget` | `lib/shared/widgets/states/page_error_state_widget.dart` |
| `EmptyStateWidget` | `lib/shared/widgets/` |
| `AppAppBar` | `lib/design_system/` |
| `ConfirmationDialog` / `AppBottomSheet` | `lib/design_system/molecules/modals/` |
| `RouteMapPreview` | `lib/design_system/organisms/map/route_map_preview.dart` |

### Modified

| Component | File | Change |
|-----------|------|--------|
| `AppPlaceAutocompleteField` | `lib/shared/widgets/form/app_place_autocomplete.dart` | Rewrite to `StatefulWidget`; add overlay dropdown; keep public API |
| `EventFormMaxParticipantsSection` | `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | Replace static count Text with editable field |
| `EventFormBottomBar` | `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` | Wire `_DraftLink`; add confirmation sheet |
| `EventCardMyEventBadge` | `lib/features/events/presentation/list/widgets/event_card_my_event_badge.dart` | Add `isDraft` flag; orange-outline variant |
| `EventCard` | `lib/features/events/presentation/list/widgets/event_card.dart` | Add `EventState.draft` case in switches; render BORRADOR badge |
| `EventDetailOwnerLifecycleBar` | `lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart` | Add `draft` case → `_OwnerDraftBar` |
| `EventFormLocationsSection` | `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` | Add route type selector + conditional custom builder |

### New

| Component | File |
|-----------|------|
| `EventRouteTypeSelector` | `lib/features/events/presentation/form/widgets/sections/event_route_type_selector.dart` |
| `CustomRouteBuilderSection` | `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart` |
| `WaypointItemCard` | `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` |
| `MyDraftsPage` | `lib/features/events/presentation/drafts/my_drafts_page.dart` |
| `_OwnerDraftBar` | inside `event_detail_owner_lifecycle_bar.dart` (private widget, same file as `_OwnerStartBar`) |

---

## Copy (all Spanish UI text)

### Autocomplete field (`AppPlaceAutocompleteField`)

| Key | Text |
|-----|------|
| `event_autocomplete_searching` | `Buscando resultados...` |
| `event_autocomplete_no_results` | `No se encontraron resultados` |
| `event_autocomplete_error` | `Error al buscar. Intenta de nuevo.` |
| `event_autocomplete_placeholder` | `Buscar lugar...` |

### Route type selector

| Key | Text |
|-----|------|
| `route_simpleLabel` | `Ruta simple (A→B)` |
| `route_customLabel` | `Ruta personalizada` |
| `route_simpleHint` | `Define el punto de inicio y destino final del evento.` |
| `route_customHint` | `Con ruta personalizada, puedes agregar hasta 9 puntos intermedios.` |
| `route_sectionTitle` | `RUTA DEL EVENTO` |

### Custom route builder

| Key | Text |
|-----|------|
| `route_waypointsTitle` | `PUNTOS INTERMEDIOS` |
| `route_addWaypoint` | `Agregar punto` |
| `route_limitReached` | `Límite alcanzado (9/9)` |
| `route_mapTapHint` | `Toca el mapa para agregar puntos` |
| `route_continueButton` | `Continuar` |
| `route_waypointCounter` | `{count} / 9` |

### Cupos stepper

| Key | Text |
|-----|------|
| `event_form_cupos_editing_hint` | `Ingresa un valor entre 5 y 500` |
| `event_form_cupos_validation_error` | `El valor debe estar entre 5 y 500.` |

_(Existing keys `event_form_max_participants_section_title`, `event_form_max_participants_label`, `event_form_max_participants_subtitle`, `event_form_max_participants_hint` remain unchanged.)_

### Draft bottom bar & confirmation sheet

| Key | Text |
|-----|------|
| `event_saveDraft` | `Guardar como borrador` _(key already exists; confirm it maps to link text)_ |
| `event_saveDraftSheetTitle` | `Guardar como borrador` |
| `event_saveDraftSheetBody` | `El evento se guardará como borrador. Solo tú podrás verlo. Podrás publicarlo cuando quieras.` |
| `event_saveDraftConfirm` | `Guardar borrador` |
| `event_publishEvent` | `Publicar evento` _(key already exists)_ |
| `cancel` | `Cancelar` _(shared key, already exists)_ |

### Draft badge

| Key | Text |
|-----|------|
| `event_draftBadge` | `BORRADOR` |

### Mis borradores page

| Key | Text |
|-----|------|
| `event_myDraftsTitle` | `Mis borradores` |
| `event_myDraftsEmpty` | `Sin borradores` |
| `event_myDraftsEmptySubtitle` | `Tus eventos guardados como borrador aparecerán aquí.` |
| `event_draftEditAction` | `Editar` |
| `event_draftPublishAction` | `Publicar` |
| `event_draftNoDate` | `Sin fecha` |

### Profile menu entry

| Key | Text |
|-----|------|
| `profile_myDrafts` | `Mis borradores` |

### Event detail — draft owner bar

| Key | Text |
|-----|------|
| `event_draftOwnerHint` | `Solo visible para ti · Borrador` |
| `event_draftInfoBanner` | `Este evento es un borrador. Solo tú puedes verlo. Publícalo para que otros puedan inscribirse.` |
| `event_publishEvent` | `Publicar evento` _(shared with form bottom bar)_ |

---

## Accessibility checklist

- [ ] All tappable elements (buttons, dropdown rows, waypoint delete icons, ± stepper buttons, draft link) have minimum 44×44 touch targets
- [ ] Autocomplete overlay results use semantic list structure; each item label is meaningful ("Parque Norte, Medellín")
- [ ] Route type segmented control describes selected state visually (fill color) AND semantically (Flutter `Semantics` selected: true on active option)
- [ ] Waypoint counter "3 / 9" reads as "3 de 9 puntos" for screen readers — use `semanticsLabel` override
- [ ] Cupos text field uses `TextInputType.number` and `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`; `keyboardAppearance: Brightness.dark`
- [ ] Draft badge contrast: ACCENT `#F98C1F` on transparent background with 1.5px stroke — ensure contrast ratio is sufficient; add a semi-transparent dark backing on image overlays
- [ ] BORRADOR badge on event card image: the badge has `#00000080` fill behind it when placed over hero image to ensure legibility
- [ ] "Publicar evento" CTA: ensure it does not share identical label with the form's "Publicar evento" in the same screen flow
- [ ] Empty states (Mis borradores, autocomplete no-results) include icon + text; not icon-only
- [ ] Bottom sheet confirmation has explicit cancel action (not just swipe-to-dismiss) for users relying on assistive technology

---

## Design decisions (resolved open questions)

### "Mis borradores" placement
**Decision: Profile page entry, NOT a tab in EventsPage.**

Rationale (matches architect recommendation):
- `EventsPage` has no tab bar today; adding one risks structural disruption.
- Profile page already has a `ProfileActionsList` with `_ProfileMenuItem` pattern — adding "Mis borradores" there is additive and consistent.
- Entry: new `_ProfileMenuItem` with icon `Icons.bookmark_border` (or Material `draft`) between "Mis inscripciones" and "Mantenimientos".

### Route type selector UI
**Decision: Segmented pill control (inline in form).**

A segmented 2-option control inside the locations section (not a modal/bottom sheet) keeps the user in context. Height 48px, same container style as `BG_TERTIARY` used throughout the form.

### Waypoint card — drag reorder
**Out of scope per PRD §5.** Cards only show numbered badge + place name + delete icon. No drag handle.

### Cupos — multiples of 5 only?
**Decision: Any integer 5–500.**

The PRD explicitly states "+5/−5 buttons OR manual typing". Free-form integer in range [5, 500]. No modulo-5 constraint enforced on text input; buttons still step by 5.

### Autocomplete — where to inject `PlaceService`
**Decision: via `getIt<PlaceService>()` inside the stateful widget.**

This is consistent with how other widgets in the codebase access singletons. For testability, tests can register a mock in `GetIt` (precedent: `EventFiltersBottomSheet` tests already do this with `PlaceService`).

### Draft `findOne` auth guard
**Decided by Architect.** Gateway uses `findOneEventForViewer` RPC (id + authUserId). Design has no UI impact.

---

## Notes for Frontend

### `AppPlaceAutocompleteField` — overlay positioning
Use `OverlayPortal` + `LayerLink` / `CompositedTransformFollower` to position the dropdown below the field. The overlay must clip to screen bounds (the form is scrollable). Dispose both the `Timer` and the `OverlayController` in `dispose()`. Wrap with a real `FormBuilderField<String>` so `formKey.currentState.value[name]` keeps working for `RouteMapPreview`.

### `EventRouteTypeSelector` — FormBuilderField vs cubit
Use `FormBuilderField<RouteType>` keyed `EventFormFields.routeType` for the selector itself. The waypoints list is cubit-managed (`EventFormCubit.addWaypoint`, `removeWaypoint`). On `buildEventToSave()`: if `routeType == RouteType.simple`, force `waypoints = []`; else use cubit state.

### `CustomRouteBuilderSection` — map interaction
The map widget is `RouteMapPreview`-style Mapbox; waypoint markers are added via `addAnnotations` on the map controller as each waypoint is added. No polyline needed (PRD §5: polyline is out of scope). The section is a `StatelessWidget` reading from `EventFormCubit` state; mutations go through cubit methods.

### `WaypointItemCard` — one widget per file rule
Must be its own file `waypoint_item_card.dart`. Props: `index`, `label`, `onDelete`. The orange numbered badge is `BG_TERTIARY` backing + ACCENT text. No drag handle.

### Cupos stepper text input
Change `_MaxParticipantsStepper` center area: replace the `SizedBox(width:52)` + `Text` with a `TextEditingController`-backed `TextField` (styled to match existing text, no border, `textAlign: center`). Use `FocusNode` to detect focus change → clamp on `onEditingComplete` and focus lost. The `_MaxParticipantsStepper` becomes `StatefulWidget`.

### Draft link confirmation sheet
Use `showModalBottomSheet` (or `AppBottomSheet` if it exists). Do NOT use the existing `ConfirmationDialog` (modal dialog, not bottom sheet). Confirmation sheet is opened by `_DraftLink.onTap`; on confirm, calls `cubit.saveDraft(...)`.

### `_OwnerDraftBar` — new private widget in same file as `_OwnerStartBar`
OK to define as a private class in `event_detail_owner_lifecycle_bar.dart`. Follows existing pattern (`_OwnerStartBar`, `_OwnerLiveBar` are private in same file).

### Profile menu — "Mis borradores" entry
Add to `ProfileActionsList` between "Mis inscripciones" and "Mantenimientos". Use `Icons.bookmark_border` as icon. `onTap: () => context.pushNamed(AppRoutes.myDrafts)`.

### `EventState.draft` exhaustive switches — DO NOT MISS
The Architect identified 4 Flutter files with exhaustive `EventState` switches that will break compilation when `EventState.draft` is added. These MUST be patched in the same change set:
1. `event_dto_converters.dart` — `EventStateConverter.toJson`
2. `event_card.dart` — `_badgeLabel`, `_badgeColor`
3. `event_detail_view.dart` — `_EventHeaderSection._badgeLabel` / `_badgeColor`
4. `event_detail_owner_lifecycle_bar.dart` — `build` switch

### `app_es.arb` — localization key list
All keys in the Copy section above must be added to `lib/l10n/app_es.arb` before any widget references them. Use `event_` prefix for event-specific keys and `route_` prefix for route/waypoint keys.
