> Slim handoff for /custom-iter event-form-redesign. Full detail in architect.md (read only if ambiguous).

# Architect → Frontend

## Implementation Order (follow exactly)

### Step 1 — Domain + Data layer

1. `lib/features/events/domain/model/event_model.dart`
   - Replace EventType enum (4→6 values); see mapping table below
   - Add `final int? maxParticipants;` to EventModel
   - Update constructor, copyWith

2. `lib/features/events/data/dto/event_dto_converters.dart`
   - Replace EventTypeConverter with 6-value mapping

3. `lib/features/events/data/dto/event_dto.dart`
   - Add `@JsonKey(name: 'maxParticipants') super.maxParticipants,` to constructor

4. `lib/features/events/constants/event_form_fields.dart`
   - Add `static const maxParticipants = 'maxParticipants';`

5. Run `dart run build_runner build --delete-conflicting-outputs` → regenerates `event_dto.g.dart`

### Step 2 — Design System (fix color compile errors)

6. `lib/design_system/foundation/theme/app_colors.dart`
   - Rename: `eventOnRoad` → `eventUrban`, `eventExhibition` → `eventTourism`, `eventCharitable` → `eventCompetition`
   - Keep `eventOffRoad` as-is (reused)
   - Add: `eventSolidarity`, `eventShortDistance` (choose appropriate colors — see note)

7. `lib/design_system/foundation/theme/app_colors_extension.dart`
   - Rename same 3 fields in: class definition, `AppColorsExtension.rideglory()`, `copyWith()`, `lerp()`
   - Add `eventSolidarity` and `eventShortDistance` in all 4 places

### Step 3 — Fix existing widgets with compile errors

8. `lib/features/events/presentation/list/widgets/event_card_type_chip.dart`
   - Update switch to 6 new cases: `EventType.tourism`, `EventType.urban`, `EventType.offRoad`, `EventType.competition`, `EventType.solidarity`, `EventType.shortDistance`
   - Use renamed/new appColors fields

9. `lib/features/events/presentation/list/widgets/event_type_chip.dart`
   - Same switch update

10. `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart`
    - Change `EventType _selectedEventType = EventType.onRoad;` → `EventType.urban`
    - Update switch in `_EventTypePicker` to cover 6 cases

### Step 4 — Cubit

11. `lib/features/events/presentation/form/cubit/event_form_cubit.dart`
    - In `_getInitialValues`: change default `EventType.offRoad` → `EventType.tourism`; add `EventFormFields.maxParticipants: null,`
    - In edit mode initial values: add `EventFormFields.maxParticipants: event.maxParticipants,`
    - In `buildEventToSave()`: read `formData[EventFormFields.maxParticipants] as int?` and pass to EventModel

### Step 5 — New Section Widgets

12. Create `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart`
    - See Design handoff for exact layout
    - FormBuilderField<int?> with name `EventFormFields.maxParticipants`
    - Stepper: min=5, max=500, step=5; minus/count/plus row; bg `AppColors.darkTertiary`, cornerRadius 10
    - Section header: "MÁXIMO DE PARTICIPANTES" (11px, letterSpacing 0.8, textOnDarkTertiary) + "Opcional" badge chip (bg `AppColors.darkTertiary`, cornerRadius 10)
    - Hint row: users icon + "Una vez lleno el cupo, el evento aparece como 'Completo' automáticamente."

13. Create `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart`
    - Section header + "Opcional" badge chip
    - Price card (bg darkCard, border, cornerRadius 12, h=52): "$" (18px, w600, textOnDarkTertiary) + vertical divider + TextFormField amount
    - "Evento gratuito" checkbox row (accent checkbox, 18x18, cornerRadius 4)
    - AnimatedSize to collapse/show price card when checkbox is checked
    - On checkbox check: clear price field value + null it

14. Create `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart`
    - Extract `_FormBottomBar` from `event_form_view.dart` as public `EventFormBottomBar`

### Step 6 — Modify Existing Widgets

15. `lib/features/events/presentation/form/widgets/event_form_view.dart`
    - AppBar: leading = TextButton "Cancelar" (textOnDarkSecondary color, pops form); NO back arrow
    - AppBar: centerTitle = true, title = "Nuevo Evento"/"Editar Evento"
    - AppBar: actions = [TextButton "Publicar" (AppColors.primary color) → calls `_onPublish`]
    - Reference `EventFormBottomBar` instead of `_FormBottomBar`

16. `lib/features/events/presentation/form/widgets/event_form_content.dart`
    - Add `EventFormMaxParticipantsSection` after `EventFormMultiBrandSection`
    - Add `EventFormPriceSection` after `EventFormMaxParticipantsSection`
    - Remove the inline `AppTextField` for price
    - Fix default eventType in `_getInitialValues`: `EventFormFields.eventType: EventType.tourism`

17. `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart`
    - Change `borderRadius: 8` → `borderRadius: 20` on both chips
    - Unselected fill: `AppColors.darkCard`, border: `AppColors.darkBorderPrimary`
    - Selected fill: `AppColors.primary`, text: `Colors.white`, w600
    - Unselected text: `AppColors.textOnDarkSecondary`, w500

### Step 7 — L10n

18. `lib/l10n/app_es.arb`
    - Add keys listed in the L10n section below

### Step 8 — Generate + Analyze

19. `dart run build_runner build --delete-conflicting-outputs`
20. `dart analyze` → 0 errors

---

## EventType Enum Mapping

| New Dart name | Backend string | Display label |
|---|---|---|
| `tourism` | `TOURISM` | Turismo |
| `urban` | `URBAN` | Urbana |
| `offRoad` | `OFF_ROAD` | Off-road |
| `competition` | `COMPETITION` | Competición |
| `solidarity` | `SOLIDARITY` | Solidaria |
| `shortDistance` | `SHORT_DISTANCE` | Corta distancia |

## New L10n Keys to Add

```json
"event_form_max_participants_section_title": "MÁXIMO DE PARTICIPANTES",
"event_form_optional_badge": "Opcional",
"event_form_max_participants_subtitle": "Número máximo de participantes",
"event_form_max_participants_hint": "Una vez lleno el cupo, el evento aparece como 'Completo' automáticamente.",
"event_form_price_section_title": "PRECIO DE INSCRIPCIÓN",
"event_form_price_subtitle": "Valor de inscripción en COP",
"event_form_free_event_label": "Evento gratuito",
"event_form_publish_action": "Publicar",
"event_form_cancel_action": "Cancelar"
```

## Color Suggestions for New Types

- `eventSolidarity`: `Color(0xFF14B8A6)` (teal — charitable/humanitarian feel)
- `eventShortDistance`: `Color(0xFF8B5CF6)` (violet — casual/short)

## Rules Reminder

- One widget per file — no `_PrivateWidget` classes; extract as public or `EventFormXxx`
- No hardcoded Spanish strings — all through `context.l10n`
- No direct HTTP calls in presentation layer
- Use `AppColors.*` constants; no `Colors.grey` inline
