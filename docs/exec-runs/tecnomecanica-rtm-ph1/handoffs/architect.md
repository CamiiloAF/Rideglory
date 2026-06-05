# Architect handoff — tecnomecanica-rtm-ph1

**Date:** 2026-06-04T16:00:53Z
**Status:** done

---

## Decisiones

### ADR-E — Renombrar `SoatModel` duplicado en `vehicles/`
El modelo `lib/features/vehicles/domain/models/soat_model.dart` define un `class SoatModel` distinto al de `soat/`. El de `vehicles/` es un objeto de formulario (SOAT sin estado calculado, sin `daysUntilExpiry`, campos con diferente opcionalidad) — no es un documento de negocio, es un **form data object**. Se renombra a `VehicleSoatFormData` en el archivo `vehicle_soat_form_data.dart`.

**Impacto en Pattern B:** `lib/features/vehicles/data/dto/soat_dto.dart` actualmente tiene `class SoatDto` que **no extiende** `SoatModel` (de vehicles); en cambio tiene un `toModel()` prohibido. La corrección es renombrar `SoatDto` a `VehicleSoatFormDataDto extends VehicleSoatFormData` siguiendo Pattern B obligatorio.

`VehicleSoatFormData` **no** implementa `VehicleDocumentModel` — es form data, no un documento de vigencia. Diferencia preservada.

### ADR-A — Nueva capa `lib/features/vehicle_documents/domain/`
Crea los contratos del dominio genérico:
- `VehicleDocumentKind` (enum: `soat`, en futuro `rtm`)
- `VehicleDocumentStatus` (enum: `valid`, `expiringSoon`, `expired`, `none`)
- `mixin VehicleDocumentExpiry` (requiere `DateTime expiryDate`; provee `int get daysUntilExpiry`, `VehicleDocumentStatus get documentStatus`)
- `abstract class VehicleDocumentModel` (requiere `String id`, `String vehicleId`, `DateTime expiryDate`; puede aplicarse `VehicleDocumentExpiry`)

`SoatStatus` se preserva sin cambios. `SoatModel` añade `with VehicleDocumentExpiry implements VehicleDocumentModel`. El `status` getter de `SoatModel` (que devuelve `SoatStatus`) se preserva como capa de mapeo propia.

### ADR-C — `abstract class VehicleDocumentCubit<T extends VehicleDocumentModel>`
Base cubit en `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart`. Solo declara el contrato: `Cubit<ResultState<T>>` + abstract `Future<void> load(String vehicleId)`. `SoatCubit` extiende `VehicleDocumentCubit<SoatModel>` — la firma concreta y los eventos analytics se preservan sin cambios.

### ADR-D — Promover 6 widgets genéricos puros a `vehicle_documents/`
Los widgets `SoatDetailRow`, `SoatEmptyState`, `SoatValidityCard`, plus lógica de estado/data view de SOAT tienen equivalentes reusables. Los widgets promovidos son:
- `validity_card.dart` → parametrizado por fechas (ya es puro: `SoatValidityCard`)
- `detail_row.dart` → parametrizado por `label`/`value` (ya es puro: `SoatDetailRow`)
- `section_header.dart` → nuevo widget de cabecera de sección de documento
- `empty_state.dart` → genérico parametrizado por copy/CTA (refactor de `SoatEmptyState`)
- `status_view.dart` → genérico (scaffold + BlocBuilder sobre `ResultState<T>`) para páginas de estado
- `data_view.dart` → genérico (hero card + detalles rows parametrizados)

Los widgets SOAT (`soat_detail_row`, `soat_empty_state`, `soat_validity_card`, `soat_data_view`, `soat_status_view`) reexportan o usan los genéricos. No se promueven widgets OCR-específicos.

### ADR-F — `VehicleDocumentCard` reemplaza `VehicleSoatCard`
Nuevo widget en `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart`. Recibe `VehicleDocumentKind`, `VehicleModel` y delega carga a `SoatCubit` via `BlocProvider`/`BlocBuilder` — **sin `getIt` ni `bool _isLoading`**. El skeleton de loading usa `ResultState.loading`. `vehicle_detail_view.dart` instancia `VehicleDocumentCard(kind: VehicleDocumentKind.soat, vehicle: vehicle)`.

`vehicle_soat_card.dart` se elimina tras verificar que solo tiene 1 consumidor (`vehicle_detail_view.dart`).

**`VehicleSoatFormSlot`** también usa `getIt<GetSoatUseCase>()` directamente. El PRD no lo menciona explícitamente en ADR-F, pero es una violación idéntica al card. **Decisión:** queda fuera del alcance de Fase 1 (el PRD lo incluye en §3 solo como consumidor del modelo renombrado, no como refactor de la carga). No se toca salvo reapuntar el import del modelo renombrado.

### L10N — Nueva clave para "Vence {fecha}"
`VehicleSoatCard` tiene el literal `'Vence ${DateFormat.yMMMd('es').format(_soat!.expiryDate)}'`. Las claves `soat_status_valid` y `soat_status_expiring_soon` ya existen y se reúsan para los labels de estado. Para la línea de fecha se añade **una sola clave nueva**: `vehicle_doc_expires_on` con placeholder `{date}` (valor: `"Vence {date}"`). Se verifica primero que no existe equivalente.

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/vehicle_documents/domain/vehicle_document_kind.dart` | create | Enum `VehicleDocumentKind` (soat) — contrato genérico ADR-A | low |
| `lib/features/vehicle_documents/domain/vehicle_document_status.dart` | create | Enum `VehicleDocumentStatus` — mapeo normalizado ADR-A | low |
| `lib/features/vehicle_documents/domain/vehicle_document_expiry.dart` | create | Mixin `VehicleDocumentExpiry` con `daysUntilExpiry` + `documentStatus` — ADR-A | low |
| `lib/features/vehicle_documents/domain/vehicle_document_model.dart` | create | Abstract class `VehicleDocumentModel` — ADR-A | low |
| `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart` | create | Abstract cubit base `VehicleDocumentCubit<T>` — ADR-C | low |
| `lib/features/vehicle_documents/presentation/widgets/validity_card.dart` | create | Widget genérico de vigencia — ADR-D | low |
| `lib/features/vehicle_documents/presentation/widgets/detail_row.dart` | create | Widget genérico de fila de detalle — ADR-D | low |
| `lib/features/vehicle_documents/presentation/widgets/section_header.dart` | create | Widget genérico de cabecera de sección — ADR-D | low |
| `lib/features/vehicle_documents/presentation/widgets/empty_state.dart` | create | Widget genérico de estado vacío, parametrizado — ADR-D | low |
| `lib/features/vehicle_documents/presentation/widgets/status_view.dart` | create | Scaffold genérico `ResultState<T>` para páginas de estado — ADR-D | med |
| `lib/features/vehicle_documents/presentation/widgets/data_view.dart` | create | Vista genérica de datos de documento — ADR-D | med |
| `lib/features/vehicles/domain/models/vehicle_soat_form_data.dart` | create | Renombrado de `SoatModel` de vehicles → `VehicleSoatFormData` — ADR-E | med |
| `lib/features/vehicles/domain/models/soat_model.dart` | delete | Reemplazado por `vehicle_soat_form_data.dart` — ADR-E | med |
| `lib/features/vehicles/data/dto/soat_dto.dart` | modify | Renombrar `SoatDto` a `VehicleSoatFormDataDto extends VehicleSoatFormData`; eliminar `toModel()` prohibido — Pattern B + ADR-E | med |
| `lib/features/vehicles/data/dto/soat_dto.g.dart` | modify | Regenerado automáticamente por build_runner | low |
| `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` | modify | Reapuntar import a `VehicleSoatFormData`; reapuntar `upsertSoat`/`getSoat` a nuevo DTO — ADR-E | med |
| `lib/features/vehicles/domain/repository/vehicle_repository.dart` | modify | Reapuntar tipo `SoatModel` → `VehicleSoatFormData` en firmas `upsertSoat`/`getSoat` — ADR-E | med |
| `lib/features/vehicles/domain/models/vehicle_model.dart` | modify | Mantener import `SoatStatus` desde `soat/domain/models/soat_model.dart` (ya lo hace por re-export) — sin cambio funcional; verificar que el export `SoatStatus` no apunte a vehicles/soat_model eliminado | low |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart` | modify | Reapuntar import `SoatModel` de vehicles → `VehicleSoatFormData`; el uso de `SoatStatus` viene de `vehicle_model.dart` re-export | low |
| `lib/features/vehicles/presentation/form/widgets/vehicle_soat_form_slot.dart` | modify | Reapuntar import del modelo renombrado; `getIt` no se elimina en Fase 1 (fuera de alcance) | low |
| `lib/features/soat/domain/models/soat_model.dart` | modify | Añadir `with VehicleDocumentExpiry implements VehicleDocumentModel` — ADR-A; `SoatStatus` y firma pública preservados | med |
| `lib/features/soat/presentation/cubit/soat_cubit.dart` | modify | Cambiar `extends Cubit<ResultState<SoatModel>>` a `extends VehicleDocumentCubit<SoatModel>`; añadir `@override` en `load` — ADR-C | low |
| `lib/features/soat/presentation/widgets/soat_detail_row.dart` | modify | Reapuntar a `detail_row.dart` genérico o convertirse en thin wrapper — ADR-D | low |
| `lib/features/soat/presentation/widgets/soat_empty_state.dart` | modify | Reapuntar a `empty_state.dart` genérico — ADR-D | low |
| `lib/features/soat/presentation/widgets/soat_validity_card.dart` | modify | Reapuntar a `validity_card.dart` genérico — ADR-D | low |
| `lib/features/soat/presentation/widgets/soat_data_view.dart` | modify | Reapuntar partes genéricas a widgets `vehicle_documents/`; SOAT-specific (action tiles, delete) permanece aquí | med |
| `lib/features/soat/presentation/widgets/soat_status_view.dart` | modify | Reapuntar scaffold genérico si se extrae; SOAT-specific (edit action) permanece aquí | low |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` | create | Nuevo card genérico `VehicleDocumentCard` sin `getIt` ni `bool`, usa `BlocProvider`+`SoatCubit` — ADR-F | high |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart` | delete | Reemplazado por `vehicle_document_card.dart` — ADR-F | med |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | modify | Reapuntar import y constructor: `VehicleSoatCard` → `VehicleDocumentCard(kind: .soat, vehicle: vehicle)` | low |
| `lib/l10n/app_es.arb` | modify | Añadir `vehicle_doc_expires_on` con placeholder `{date}` para "Vence {fecha}" | low |
| `lib/l10n/app_localizations.dart` | modify | Regenerado por flutter gen-l10n | low |
| `lib/l10n/app_localizations_es.dart` | modify | Regenerado por flutter gen-l10n | low |

---

## Contratos rideglory-api

**Sin cambios.** Esta fase es puramente refactor de capa Flutter. Ningún endpoint nuevo ni modificado. Los contratos HTTP existentes:
- `GET /vehicles/{vehicleId}/soat` → sigue respondiendo `SoatDto` (del feature soat/)
- `POST /vehicles/{vehicleId}/soat` → sigue usando request manual en `vehicle_repository_impl.dart`

---

## Datos / migraciones

Ninguna migración de base de datos. No aplica `analysis/MIGRATION_PLAN.md`.

---

## Env

No hay variables de entorno nuevas ni modificadas. No aplica `analysis/ENV_DELTA.md`.

---

## Riesgos

1. **`VehicleDocumentCard` con `BlocProvider` local (HIGH):** El card debe proveer un `SoatCubit` propio (no heredado del árbol) para que cada instancia cargue su propio vehículo. El `BlocProvider` local debe crear `SoatCubit` via `context.read<SoatCubit>()` del árbol SI ya existe (evitar múltiples instancias) — o si no existe, crear una nueva. Revisar si `SoatCubit` está en el árbol global; si no, usar `BlocProvider(create: (_) => getIt<SoatCubit>(), child: ...)` para la instancia local. **Riesgo:** doble instancia de cubit si se mezclan niveles del árbol. **Mitigación:** usar `BlocProvider` local explícito con `getIt<SoatCubit>()` y llamar `cubit.load(vehicleId)` en `initState` del padre.

2. **`SoatModel with VehicleDocumentExpiry` (MED):** `SoatModel` ya tiene `daysUntilExpiry` y la lógica de cálculo. El mixin debe asegurarse de **no redefinir** esos getters — o redefinirlos como `@override` delegando al mixin. Verificar que `SoatModel.status` (retorna `SoatStatus`) y `VehicleDocumentExpiry.documentStatus` (retorna `VehicleDocumentStatus`) sean getters distintos con nombres distintos. Sin colisión de nombre.

3. **`VehicleSoatFormDataDto extends VehicleSoatFormData` (MED):** El DTO actual en vehicles usa `String startDate`/`expiryDate` (strings), mientras el modelo nuevo tendrá `DateTime`. El DTO debe adaptar la serialización en `fromJson` con las conversiones correctas. El `toModel()` prohibido se elimina y el DTO extiende el modelo directamente con super-params. Verificar coherencia de tipos.

4. **Pattern B vehicles `SoatDto` (MED):** El DTO actual en `vehicles/` no respeta Pattern B (tiene `toModel()`). Corrección en scope. El `VehicleService` devuelve este tipo en `getSoat`/`upsertSoat`; el repositorio usa `dto.toModel()`. Después del refactor, el repositorio retorna el DTO directamente como `VehicleSoatFormData` (Pattern B: DTO extends Model, es un Model).

5. **Test SOAT regresión (LOW):** Los tests `soat_cubit_test.dart` y `soat_model_test.dart` no tocan `SoatStatus` ni la firma pública de `SoatModel`. El cambio `extends VehicleDocumentCubit<SoatModel>` en el cubit es transparente (mismo tipo de estado). El mixin en `SoatModel` no cambia la construcción ni los getters existentes.

---

## Orden de implementación

1. **Dominio genérico** (`vehicle_documents/domain/` — 4 archivos nuevos)
   - `vehicle_document_kind.dart`, `vehicle_document_status.dart`, `vehicle_document_expiry.dart`, `vehicle_document_model.dart`
2. **Cubit base** (`vehicle_documents/presentation/cubit/vehicle_document_cubit.dart`)
3. **ADR-E rename** (`vehicles/domain/models/soat_model.dart` → `vehicle_soat_form_data.dart` + DTO Pattern B)
4. **Reapuntar 9 consumidores** del modelo renombrado
5. **Conectar `SoatModel`** al contrato (`with VehicleDocumentExpiry implements VehicleDocumentModel`)
6. **Refactorizar `SoatCubit`** a `extends VehicleDocumentCubit<SoatModel>`
7. **Widgets genéricos** (`vehicle_documents/presentation/widgets/` — 6 archivos)
8. **Reapuntar widgets SOAT** a los genéricos
9. **`VehicleDocumentCard`** nuevo + eliminar `vehicle_soat_card.dart`
10. **Reapuntar `vehicle_detail_view.dart`**
11. **L10N** — añadir `vehicle_doc_expires_on`; regenerar gen-l10n
12. **Code-gen** — `dart run build_runner build --delete-conflicting-outputs --force-jit`
13. **`dart analyze`** — verificar 0 nuevos warnings

---

## Superficie de regresión

- `lib/features/soat/` — todos los tests; firma pública `SoatModel`, `SoatStatus`, `SoatCubit` no cambia de comportamiento
- `lib/features/vehicles/` — `VehicleRepository` cambia firma de `upsertSoat`/`getSoat`; `vehicle_form_cubit_soat_test.dart` puede necesitar reapuntar imports
- `lib/features/home/` — `HomeGarageSoatBadge` consume `vehicle.soatStatus` (tipo `SoatStatus`) que viene de re-export en `vehicle_model.dart`; verificar que el re-export no se rompa al borrar `vehicles/domain/models/soat_model.dart`
- `lib/shared/router/app_router.dart` — usa `SoatStatus` para guard de ruta; viene del re-export de `VehicleModel`; no se toca
- Code-gen: verificar que `soat_dto.g.dart` (de `soat/`) no cambie de forma

---

## Fuera de alcance

- `home_garage_soat_badge.dart` — no se modifica
- `SoatStatus` enum — no se mueve, no se renombra
- Widgets OCR de SOAT (`soat_autofill_banner`, `soat_not_recognized_warning`, etc.)
- Backend `rideglory-api` — cero cambios
- `lib/features/tecnomecanica/` — Fase 3
- Conversión de `SoatModel` a freezed
- `toRequestJson()` en `soat_dto.dart` (soat/) — ADR-B, Fase 3
- `VehicleSoatFormSlot.getIt` — deuda conocida, Fase posterior
