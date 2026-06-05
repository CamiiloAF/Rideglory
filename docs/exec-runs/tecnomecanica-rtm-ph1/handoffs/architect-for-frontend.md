> Slim handoff — lee esto antes de docs/exec-runs/tecnomecanica-rtm-ph1/handoffs/architect.md

# Architect → Frontend — tecnomecanica-rtm-ph1

**Fecha:** 2026-06-04T16:00:53Z

## Nuevos archivos a crear (en orden)

### 1. Dominio genérico `lib/features/vehicle_documents/domain/`
```
vehicle_document_kind.dart       → enum VehicleDocumentKind { soat }
vehicle_document_status.dart     → enum VehicleDocumentStatus { valid, expiringSoon, expired, none }
vehicle_document_expiry.dart     → mixin VehicleDocumentExpiry { int get daysUntilExpiry; VehicleDocumentStatus get documentStatus }
vehicle_document_model.dart      → abstract class VehicleDocumentModel { String get id; String get vehicleId; DateTime get expiryDate }
```
Sin imports de Flutter. Dominio puro.

### 2. Cubit base `lib/features/vehicle_documents/presentation/cubit/`
```
vehicle_document_cubit.dart → abstract class VehicleDocumentCubit<T extends VehicleDocumentModel>
                               extends Cubit<ResultState<T>> {
                                 Future<void> load(String vehicleId);
                               }
```

### 3. Widgets genéricos `lib/features/vehicle_documents/presentation/widgets/`
```
validity_card.dart    → parametrizado por DateTime? startDate, DateTime? expiryDate (extraer SoatValidityCard)
detail_row.dart       → parametrizado por String label, String value, bool isLast (extraer SoatDetailRow)
section_header.dart   → cabecera genérica de sección (icon, title, trailing)
empty_state.dart      → genérico: icon, title, subtitle, AppButton CTA (parametrizado)
status_view.dart      → Scaffold + BlocBuilder<C extends VehicleDocumentCubit<T>, ResultState<T>>
data_view.dart        → hero card + lista de detail_rows parametrizado
```
**Un widget por archivo. Cero métodos `Widget _buildX()`. Cero `getIt`.**

## Cambios en archivos existentes

### ADR-E — Rename en `vehicles/`
- **Crear** `lib/features/vehicles/domain/models/vehicle_soat_form_data.dart` con `class VehicleSoatFormData` (mismo body que el actual `SoatModel` de vehicles)
- **Borrar** `lib/features/vehicles/domain/models/soat_model.dart`
- **Modificar** `lib/features/vehicles/data/dto/soat_dto.dart`: renombrar `SoatDto` → `VehicleSoatFormDataDto extends VehicleSoatFormData`; aplicar Pattern B (super-params en constructor); eliminar `toModel()`
- **9 consumidores a reapuntar** (imports + tipos):
  - `vehicle_repository_impl.dart` — `SoatModel` → `VehicleSoatFormData`; usar DTO directamente (Pattern B)
  - `vehicle_service.dart` — `SoatDto` → `VehicleSoatFormDataDto`
  - `vehicle_repository.dart` — firma `upsertSoat`/`getSoat` → `VehicleSoatFormData`
  - `vehicle_model.dart` — verificar re-export de `SoatStatus` apunte a `soat/`, no a `vehicles/` (ya lo hace correctamente via `import 'package:rideglory/features/soat/domain/models/soat_model.dart'`)
  - `vehicle_form_view.dart` — si importa `soat_model.dart` de vehicles, reapuntar
  - `vehicle_form_docs_section.dart` — reapuntar import
  - `vehicle_soat_form_slot.dart` — reapuntar import del modelo
  - `soat_dto.dart` (en vehicles/data/dto/) — es el DTO que se modifica directamente

### ADR-A — Conectar `SoatModel` al contrato
- `lib/features/soat/domain/models/soat_model.dart`:
  ```dart
  class SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel {
    // ... mismo cuerpo ...
    // NUEVO: @override de VehicleDocumentExpiry si hay conflicto con daysUntilExpiry existente
  }
  ```
  `SoatStatus get status` se preserva. `VehicleDocumentStatus get documentStatus` se añade.

### ADR-C — Refactorizar `SoatCubit`
- `lib/features/soat/presentation/cubit/soat_cubit.dart`: `extends VehicleDocumentCubit<SoatModel>`; `@override Future<void> load(String vehicleId)` ya implementado — solo añadir `@override`.

### ADR-D — Reapuntar widgets SOAT
- `soat_detail_row.dart` — thin wrapper o reexport sobre `detail_row.dart` genérico
- `soat_empty_state.dart` — usar `empty_state.dart` genérico con parámetros SOAT
- `soat_validity_card.dart` — thin wrapper sobre `validity_card.dart` genérico
- `soat_data_view.dart` — usar `detail_row.dart` genérico; la lógica SOAT-específica (delete, renew CTA) permanece en este archivo
- `soat_status_view.dart` — adaptar si aplica; el `BlocBuilder<SoatCubit, ResultState<SoatModel>>` puede quedar in-place

### ADR-F — Reemplazar `VehicleSoatCard`
- **Crear** `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart`
  - `class VehicleDocumentCard extends StatelessWidget`
  - Props: `VehicleDocumentKind kind`, `VehicleModel vehicle`
  - Internamente: `BlocProvider(create: (_) => getIt<SoatCubit>()..load(vehicle.id ?? ''), child: BlocBuilder<SoatCubit, ResultState<SoatModel>>(...))`
  - `ResultState.loading` → skeleton (mismo aspecto que `CircularProgressIndicator` actual)
  - `ResultState.data` → row con status color, label (`context.l10n.soat_status_valid` / `soat_status_expiring_soon` / `soat_status_expired` / `soat_tap_to_add`), fecha con `context.l10n.vehicle_doc_expires_on(date)`
  - `ResultState.empty/error` → estado "sin SOAT"
  - **Cero `getIt` directo en el widget body**. Cero `bool _isLoading`.
- **Borrar** `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart`
- **Modificar** `vehicle_detail_view.dart`: import + `VehicleSoatCard(vehicle: vehicle)` → `VehicleDocumentCard(kind: VehicleDocumentKind.soat, vehicle: vehicle)`

### L10N
- `lib/l10n/app_es.arb`: añadir `"vehicle_doc_expires_on": "Vence {date}"` con placeholder `date`
- Reusar `soat_status_valid` y `soat_status_expiring_soon` en el card (ya existen)
- `flutter gen-l10n` tras editar el ARB

## Code-gen
```bash
dart run build_runner build --delete-conflicting-outputs --force-jit
flutter gen-l10n
dart analyze
```

## Criterios de cierre para QA
1. `grep -n "class SoatModel" lib/` → exactamente 1 resultado (en `soat/`)
2. `grep -n "getIt" lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` → 0 resultados en el body del widget (solo en BlocProvider.create si aplica)
3. Los 3 literales `'Vigente'`, `'Por vencer'`, `'Vence '` con hardcode → 0 en el nuevo card
4. `SoatDto extends SoatModel` (en soat/) intacto
5. `dart analyze` → 0 nuevos warnings vs baseline de main

> Full detail: docs/exec-runs/tecnomecanica-rtm-ph1/handoffs/architect.md
