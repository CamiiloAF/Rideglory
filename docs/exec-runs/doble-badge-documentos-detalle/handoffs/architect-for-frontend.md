> Slim handoff — read this before docs/exec-runs/doble-badge-documentos-detalle/handoffs/architect.md

# Architect → Frontend: doble-badge-documentos-detalle

**Fecha:** 2026-06-04T20:49:36Z

---

## Prerequisitos confirmados (no reimplementar)

- `lib/features/vehicle_documents/domain/` completo: `VehicleDocumentModel`, `VehicleDocumentExpiry`, `VehicleDocumentStatus`, `VehicleDocumentKind`, `VehicleDocumentCubit<T>` ✓
- `SoatCubit extends VehicleDocumentCubit<SoatModel>` ✓
- `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` ✓
- `TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel` ✓
- `_SoatDocumentCardBody` en `vehicle_document_card.dart` — 4 estados completos ✓ (NO TOCAR)
- `AppRoutes.tecnomecanicaStatus` existe ✓

---

## Cambios requeridos

### 1. `lib/l10n/app_es.arb` — añadir 3 claves RTM badge

```json
"vehicle_doc_rtm_status_valid": "Vigente",
"vehicle_doc_rtm_status_expiring_soon": "Por vencer",
"vehicle_doc_rtm_status_expired": "Vencida",
```

Ejecutar `flutter gen-l10n` después.

### 2. `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` — completar `_RtmDocumentCardBody`

Reemplazar el stub estático con `BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>` que muestre los mismos 4 estados que `_SoatDocumentCardBody`:

- **Initial/Loading** → skeleton (mismas dimensiones que SOAT)
- **Empty** → label `context.l10n.tecnomecanica_status_no_rtm` + sin fecha
- **Data** → `model.documentStatus` → color/label:
  - `valid` → `AppColors.statusGreen` / `context.l10n.vehicle_doc_rtm_status_valid`
  - `expiringSoon` → `AppColors.statusWarning` / `context.l10n.vehicle_doc_rtm_status_expiring_soon`
  - `expired` → `AppColors.statusError` / `context.l10n.vehicle_doc_rtm_status_expired`
  - Fecha: `context.l10n.vehicle_doc_expires_on(DateFormat.yMMMd('es').format(model.expiryDate))`
- **Error** → mostrar `context.l10n.tecnomecanica_status_no_rtm` (fallback no-document)

Título de sección: `context.l10n.vehicle_doc_techreview_label` ("Técnico-mecánica").
El tap ya existe en `_onTap` → `context.pushNamed(AppRoutes.tecnomecanicaStatus, extra: vehicle)` → recargar cubit al volver.

`BlocProvider.create` para RTM usa `getIt<TecnomecanicaCubit>()..load(vehicle.id ?? '')` (mismo patrón que SOAT — D-2 del handoff).

**IMPORTANTE:** No modificar `_SoatDocumentCardBody` ni la lógica de `VehicleDocumentCard.build` (el switch por kind).

### 3. `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` — gate A11

Cambios exactos:
- **Eliminar** línea 11: `import 'package:rideglory/features/tecnomecanica/presentation/flow/tecnomecanica_entry_flow.dart';`
- **Reemplazar** bloque líneas 66-74 (OutlinedButton.icon placeholder):
  ```dart
  // ANTES:
  OutlinedButton.icon(
    onPressed: () => TecnomecanicaEntryFlow.start(context, vehicle),
    icon: const Icon(Icons.build_outlined, size: 16),
    label: const Text('Tecnomecánica [TEST]'),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 44),
    ),
  ),
  // DESPUÉS:
  VehicleDocumentCard(
    kind: VehicleDocumentKind.rtm,
    vehicle: vehicle,
  ),
  ```
- El spacing `SizedBox(height: 16)` entre los dos cards ya está en línea 65 — verificar que permanece.

### 4. `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart` — BORRAR

Verificar primero: `grep -rln "VehicleSoatSection" lib/` → debe devolver solo el propio archivo.
Luego eliminar el archivo.

---

## Gate A11 (ejecutar antes de cerrar)

```bash
grep -n "features/soat\|features/tecnomecanica" \
  lib/features/vehicles/presentation/detail/vehicle_detail_page.dart \
  lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart
```

Resultado esperado: **cero matches**.

---

## Reglas Flutter que aplican

- Un widget por archivo. `_SoatDocumentCardBody` y `_RtmDocumentCardBody` son clases privadas en el MISMO archivo que `VehicleDocumentCard` — esto es correcto (son partes del mismo widget compound, no widgets independientes de screen-level). No crear archivos separados.
- Cero métodos `Widget _buildX()`.
- Strings via `context.l10n.<key>`. Cero literales en UI.
- Texto oscuro sobre naranja primario si aplica.

---

## Archivos a NO tocar

- `vehicle_detail_page.dart` — sin cambios
- `vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_form_view.dart` — fuera de alcance
- `_SoatDocumentCardBody` (solo leer como referencia, no modificar)

> Full detail: docs/exec-runs/doble-badge-documentos-detalle/handoffs/architect.md
