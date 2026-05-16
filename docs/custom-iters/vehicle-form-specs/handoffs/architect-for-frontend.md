> Slim handoff for /custom-iter vehicle-form-specs. Full detail in architect.md (read only if ambiguous).

# Frontend Handoff — vehicle-form-specs

## What to do
1. Add 4 spec fields to domain model + DTO + form cubit + repository request builder
2. Redesign the vehicle form to match Pencil frame `EqnMm` exactly — split monolithic `vehicle_form.dart` into per-section widget files
3. Update vehicle form page nav header and add delete link for edit mode

## Implementation Order

### Step 1 — Domain model (`lib/features/vehicles/domain/models/vehicle_model.dart`)
Add 4 nullable fields using the existing `_unset` sentinel pattern for copyWith:
```dart
final String? engine;
final String? horsepower;
final String? torque;
final String? weight;
```
Add to constructor, equality/hashCode, toString, and copyWith (using `Object? engine = _unset` pattern).

### Step 2 — DTO (`lib/features/vehicles/data/dto/vehicle_dto.dart`)
Add 4 nullable fields to `VehicleDto` constructor and `toModel()`. Regenerate `.g.dart`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 3 — Form field constants (`lib/features/vehicles/constants/vehicle_form_fields.dart`)
Add:
```dart
static const String engine = 'engine';
static const String horsepower = 'horsepower';
static const String torque = 'torque';
static const String weight = 'weight';
```

### Step 4 — Repository request (`lib/features/vehicles/data/repository/vehicle_repository_impl.dart`)
In `_vehicleRequest()`, add:
```dart
'engine': vehicle.engine,
'horsepower': vehicle.horsepower,
'torque': vehicle.torque,
'weight': vehicle.weight,
```
(existing `removeWhere((_, value) => value == null)` handles omitting null values)

### Step 5 — Form cubit (`lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart`)
In `buildVehicleToSave()`, add:
```dart
engine: formData[VehicleFormFields.engine] as String?,
horsepower: formData[VehicleFormFields.horsepower] as String?,
torque: formData[VehicleFormFields.torque] as String?,
weight: formData[VehicleFormFields.weight] as String?,
```

### Step 6 — l10n (`lib/l10n/app_es.arb`)
Add new keys:
```json
"vehicle_form_specs_section": "ESPECIFICACIONES",
"vehicle_form_specs_engine_label": "Motor",
"vehicle_form_specs_horsepower_label": "Potencia",
"vehicle_form_specs_torque_label": "Torque",
"vehicle_form_specs_weight_label": "Peso",
"vehicle_form_specs_engine_hint": "Ej. 689cc · Paralelo 2 cil.",
"vehicle_form_specs_horsepower_hint": "Ej. 73 hp",
"vehicle_form_specs_torque_hint": "Ej. 68 Nm",
"vehicle_form_specs_weight_hint": "Ej. 179 kg",
"vehicle_form_nav_cancel": "Cancelar",
"vehicle_form_nav_save": "Guardar",
"vehicle_form_delete_vehicle": "Eliminar vehículo",
"vehicle_form_placa_required_badge": "Obligatorio",
"vehicle_form_vin_optional_label": "Opcional"
```
Run `flutter gen-l10n` (or `dart run build_runner build`) after editing ARB.

### Step 7 — Widget split + redesign
**IMPORTANT: 1 widget per file rule is MANDATORY.**

Delete `lib/features/vehicles/presentation/widgets/vehicle_form.dart`.
Create directory `lib/features/vehicles/presentation/form/widgets/`.
Create these widget files:

| File | Widget | Description |
|------|--------|-------------|
| `vehicle_form_nav_header.dart` | `VehicleFormNavHeader` (PreferredSizeWidget) | "Cancelar" / title / "Guardar" nav bar |
| `vehicle_form_cover_section.dart` | `VehicleFormCoverSection` | Cover photo + upload/take photo buttons |
| `vehicle_scan_banner.dart` | `VehicleScanBanner` | Scan property card banner (placeholder) |
| `vehicle_form_basic_section.dart` | `VehicleFormBasicSection` | INFORMACIÓN BÁSICA section |
| `vehicle_form_id_section.dart` | `VehicleFormIdSection` | IDENTIFICACIÓN section (Placa + VIN with monospace) |
| `vehicle_form_specs_section.dart` | `VehicleFormSpecsSection` | ESPECIFICACIONES section with 4 inline-editable rows |
| `vehicle_specs_row.dart` | `VehicleSpecsRow` | Single spec row (label + value/input + pencil icon) |
| `vehicle_form_docs_section.dart` | `VehicleFormDocsSection` | DOCUMENTOS section |
| `vehicle_form_cta.dart` | `VehicleFormCta` | Guardar button + delete link |

Each of these must be a StatelessWidget (or StatefulWidget for `VehicleSpecsRow` since it has inline editing state) in its own file.

The main form orchestrator becomes `lib/features/vehicles/presentation/form/vehicle_form_body.dart` — a `StatelessWidget` (or `StatefulWidget` if needed) that composes all section widgets in a `SingleChildScrollView > Column`.

### Step 8 — Form page (`lib/features/vehicles/presentation/form/vehicle_form_page.dart`)
- Replace `AppAppBar` with `VehicleFormNavHeader` (implement as `PreferredSizeWidget` with `preferredSize = Size.fromHeight(56)`)
- Add spec fields to `_buildInitialValues()`:
  ```dart
  VehicleFormFields.engine: state.vehicle!.engine,
  VehicleFormFields.horsepower: state.vehicle!.horsepower,
  VehicleFormFields.torque: state.vehicle!.torque,
  VehicleFormFields.weight: state.vehicle!.weight,
  ```
- "Guardar" button in nav header calls `_saveVehicle()`
- "Cancelar" calls `context.pop()`

## Design Tokens (from Pencil frame EqnMm)
- Background: `AppColors.darkBgPrimary` (Pencil `$bg-primary`)
- Card background: `AppColors.darkCard` (Pencil `$bg-card`)
- Accent: `AppColors.primary` (Pencil `$accent`)
- Accent subtle: `AppColors.primarySubtle` (Pencil `$accent-subtle`)
- Border: `AppColors.darkBorderPrimary` (Pencil `$border`)
- Border light: `AppColors.darkBorderLight` (Pencil `$border-light`)
- Text primary: `AppColors.textOnDarkPrimary`
- Text secondary: `AppColors.textOnDarkSecondary`
- Text tertiary: `AppColors.textOnDarkTertiary`
- Monospace font: `'Space Mono'` (already in pubspec)
- Section header: fontSize 11, fontWeight w600, letterSpacing 1.2, `AppColors.textOnDarkTertiary`

## Placa + VIN monospace implementation
Use `AppTextField` with `style: const TextStyle(fontFamily: 'Space Mono', letterSpacing: 2)` for Placa and `letterSpacing: 0.5` for VIN. The label row uses a Row with the label + a chip/text.

Since `AppTextField` may not support prefix label rows directly, create `VehicleFormIdSection` that uses `FormBuilderField` or a custom label row + `AppTextField`.

## VehicleSpecsRow inline edit
`VehicleSpecsRow` is a `StatefulWidget`. It has:
- `_isEditing` state (default false)
- When `_isEditing = false`: show label + value text + pencil icon; entire row is tappable → sets `_isEditing = true`
- When `_isEditing = true`: show label + `FormBuilderTextField` inline + check/done icon

## Coding Rules Reminder
- Zero `Widget _buildXxx()` methods — every UI piece is a widget class
- Use `context.l10n.<key>` for all strings
- Use `AppColors` for colors, not raw hex
- Use `AppTextField` / `AppButton` from shared widgets — never raw `TextField` or `ElevatedButton`
- `dart analyze` must pass before declaring done

## Hard Rules
- NO git commits
- NO modification of backend files
