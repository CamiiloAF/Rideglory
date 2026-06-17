# Frontend Handoff — Phase 03: Flutter — Archivar y restaurar vehículos

**Generado:** 2026-06-16T23:17:41Z  
**Agente:** Frontend (Flutter lib/)

---

## Baseline

- Tests antes de cambios: **44 tests** en `test/features/vehicles/` — todos pasando.
- `dart analyze lib/` — sin issues al inicio.

---

## Archivos cambiados

### Nuevos

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart` | create | Renombrado y ampliado desde `vehicle_delete_cubit.dart`; añade `archiveVehicle` / `unarchiveVehicle`; inyecta `ArchiveVehicleUseCase` y `UnarchiveVehicleUseCase` |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_action_state.dart` | create | Amplía el estado freezed con `archiveSuccess` y `unarchiveSuccess`; conserva `success(deletedId)` idéntico |
| `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.freezed.dart` | generated | Generado por `build_runner` para `VehicleActionCubit` |
| `lib/features/vehicles/presentation/garage/widgets/garage_archived_header.dart` | create | `StatelessWidget` — label ARCHIVADOS + badge contador + chevron |
| `lib/features/vehicles/presentation/garage/widgets/garage_archived_section.dart` | create | `StatefulWidget` expansible; devuelve `SizedBox.shrink()` si vacío |
| `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` | create | 5 widget tests para `GarageArchivedSection` |

### Modificados

| Archivo | Descripción del cambio |
|---------|------------------------|
| `lib/l10n/app_es.arb` | `vehicle_unarchiveVehicle`: "Desarchivar" → "Restaurar"; 7 claves nuevas añadidas |
| `lib/l10n/app_localizations.dart` | Regenerado por `flutter gen-l10n` |
| `lib/l10n/app_localizations_es.dart` | Regenerado por `flutter gen-l10n` |
| `lib/core/services/analytics/analytics_events.dart` | Añadidas constantes `vehicleArchived` y `vehicleUnarchived` |
| `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` | Añadidos `archiveLocally`, `unarchiveLocally` y `_promoteNewMain` (createdAt desc / id asc) |
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | `VehicleDeleteCubit` → `VehicleActionCubit` en import y `BlocProvider.create` |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` | Imports y referencias a `VehicleDeleteCubit`/`VehicleDeleteState` → `VehicleActionCubit`/`VehicleActionState`; listener extendido con `archiveSuccess`/`unarchiveSuccess` (no-op) |
| `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` | Reemplaza `VehicleDeleteCubit` → `VehicleActionCubit`; bifurca árbol activo/archivado; añade flujo de confirmación de archivado con `DialogActionType.primary`; elimina `ListTile` de Eliminar de activos |
| `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` | Integra `GarageArchivedSection` al final del `SliverChildListDelegate`; separa `allVehicles` / `activeVehicles` / `archivedVehicles` |
| `lib/core/di/injection.config.dart` | Regenerado por `build_runner`; registra `VehicleActionCubit` como factory |
| `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` | +5 tests para `archiveLocally`, `unarchiveLocally`, `_promoteNewMain` (TC-veh-12 a TC-veh-16) |

---

## Pruebas nuevas

### `vehicle_cubit_test.dart` — 5 nuevos

| ID | Descripción |
|----|-------------|
| TC-veh-12 | `archiveLocally` marca vehículo como `isArchived=true` en el estado |
| TC-veh-13 | `archiveLocally` sobre el vehículo principal promueve el siguiente activo |
| TC-veh-14 | Vehículo archivado tiene `isArchived=true` y `isMainVehicle=false` en el estado completo |
| TC-veh-15 | `unarchiveLocally` restaura `isArchived=false` sin cambiar el principal |
| TC-veh-16 | `_promoteNewMain` con `createdAt` nulos usa tie-break por `id` ascendente |

### `garage_archived_section_test.dart` — 5 nuevos

| ID | Descripción |
|----|-------------|
| TC-arch-1 | `archivedVehicles.isEmpty` → no renderiza sección (sin "ARCHIVADOS") |
| TC-arch-2 | Con archivados: header muestra badge con contador correcto (count=2) |
| TC-arch-3 | Tap en header expande y muestra la lista de vehículos archivados |
| TC-arch-4 | Tap en vehículo archivado dispara `onRestoreTap` con el modelo correcto |
| TC-arch-5 | Badge muestra count=1 para un solo vehículo archivado |

---

## Resultado final

- **`dart analyze lib/`**: sin issues
- **`flutter test test/features/vehicles/`**: **54/54 passed** (44 baseline + 10 nuevos)
- **`flutter test` (suite completa)**: exit code 0 — todos los tests pasando

---

## Verificación manual

Para verificar en dispositivo/simulador:

1. **Archivar vehículo activo:**
   - En el garaje, abrir opciones de un vehículo activo (no principal) → debe aparecer opción "Archivar".
   - Confirmar diálogo → snackbar "Vehículo archivado" → vehículo desaparece de la sección activa.
   - Sección "ARCHIVADOS" aparece al final con badge `1`.

2. **Archivar vehículo principal:**
   - Archivar el vehículo principal → el siguiente activo (por fecha de creación desc) se promueve automáticamente como principal.

3. **Restaurar vehículo:**
   - Expandir sección ARCHIVADOS → tap en vehículo → bottom sheet con opción "Restaurar".
   - Tap en "Restaurar" → snackbar "Vehículo restaurado" → vehículo vuelve a la lista activa.

4. **Sección colapsable:**
   - ARCHIVADOS inicia colapsada. Chevron cambia al expandir. Badge persiste en ambos estados.

5. **Formulario de edición:**
   - Abrir "Editar" en un vehículo activo → modal carga correctamente (sin error de tipo por renombrado).

---

## Notas para QA

- `VehicleDeleteCubit` sigue existiendo en el árbol de archivos (no se eliminó) para no romper historial de código. Ya no se registra por `main.dart` pero `injection.config.dart` lo registra igualmente como factory. No causa colisión.
- El `ListTile` de "Eliminar" fue **eliminado** del menú de vehículos activos. Eliminar sigue disponible desde la pantalla de edición del vehículo (`VehicleFormView` → `_confirmDelete`).
- `onGarageListUpdatedLocally` en `GarageArchivedSection` siempre es `null` desde `GarageVehiclesContent`: las mutaciones de archivo/restaurar actualizan el estado local vía `VehicleCubit`, sin refetch.
- Texto sobre el CTA naranja de confirmación de archivado usa `colorScheme.onPrimary` (oscuro) — cumple regla de texto oscuro sobre primario.
- Los 7 strings nuevos del ARB usan el prefijo `vehicle_` y respetan la guía de naming.

---

## Corrección post-auditoría — 2026-06-16T23:33:30Z

Correcciones exigidas por el Auditor Opus aplicadas en esta corrida:

### AC #13 (d) y (e) — Tests del diálogo de confirmación de archivado

**Archivo nuevo:**
`test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart`

- **TC-bs-1:** Confirmar el `ConfirmationDialog` de "Archivar" → verifica que `ArchiveVehicleUseCase.call` es invocado.
- **TC-bs-2:** Cancelar el `ConfirmationDialog` → verifica `verifyNever` sobre `ArchiveVehicleUseCase.call`.

Estrategia: `MaterialApp.router` con `GoRouter` mínimo (rutas stub) para que `context.pop()` de go_router no falle; `VehicleActionCubit` via `GetIt.registerFactory` en setUp/tearDown; fallback value `_FakeVehicleModel` para mocktail.

### AC #11 — dart analyze verde

**Archivo modificado:**
`test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart`

Correcciones aplicadas:
- Fixtures `_archivedVehicle`, `_archivedVehicle2`: `final` → `const`.
- Constructores `GarageArchivedSection(...)` en TC-arch-2, TC-arch-3, TC-arch-5: añadido `const`.
- Lista literal `[_archivedVehicle]` en TC-arch-4: añadido `const` (el constructor no puede ser `const` por la lambda callback).

**Resultado post-corrección:**
```
dart analyze lib/ test/   → No issues found!
flutter test test/        → Exit code 0 (56 tests en feature vehicles, todos pasando)
```
