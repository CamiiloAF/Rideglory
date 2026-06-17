> Slim handoff — read this before handoffs/architect.md

# QA handoff — Phase 03: Flutter — Archivar y restaurar vehículos

**Date:** 2026-06-16T22:42:02Z

---

## Comandos de verificación

```bash
# Análisis estático (debe pasar en verde; ignorar lint conocido de api_base_url_resolver.dart)
dart analyze

# Suite completa de tests
flutter test

# Tests específicos de esta fase
flutter test test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart
flutter test test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart
```

---

## Criterios de aceptación — trazabilidad

| CA | Descripción | Verificación |
|----|-------------|-------------|
| CA-1 | Archivar vehículo activo → desaparece de lista activa y aparece en "Archivados (N)" sin reload | Widget test + manual |
| CA-2 | Restaurar archivado → vuelve a lista activa sin `fetchMyVehicles` | Unit test + grep que `fetchMyVehicles` no se llame en el flujo |
| CA-3 | Contador "(N)" refleja `isArchived: true` actuales en estado local | Widget test (estado colapsado) |
| CA-4 | Archivar vehículo main → `_promoteNewMain` asigna nuevo main antes de emitir | Unit test `vehicle_cubit_test.dart` |
| CA-5 | Wiring de callbacks en `GarageVehiclesContent`/`GarageOptionsBottomSheet`; `VehicleCard` no llama cubits directamente | Code review (grep de `ArchiveVehicleUseCase` en widgets) |
| CA-6 | `GarageArchivedHeader` y `GarageArchivedSection` en archivos propios | `find lib/ -name "garage_archived_*.dart"` → 2 archivos distintos |
| CA-7 | Sin archivados → `GarageArchivedSection` retorna `SizedBox.shrink()` | Widget test |
| CA-8 | "Editar" y "Agregar mantenimiento" ausentes en menú de archivados | Widget test del bottom sheet |
| CA-9 | "Eliminar" ausente en menú de activos (reemplazado por "Archivar") | Widget test del bottom sheet |
| CA-10 | Cero strings hardcodeados | `grep -r "\"Archivar\"\|\"Restaurar\"\|\"ARCHIVADOS\"" lib/` → sin resultados fuera de ARB |
| CA-11 | `dart analyze` verde (excluido lint conocido) | CI / `dart analyze` |
| CA-12 | `flutter test` verde | CI / `flutter test` |
| CA-13a | Widget test: estado vacío → sección no renderizada | `garage_archived_section_test.dart` test 1 |
| CA-13b | Widget test: colapsado con contador correcto | `garage_archived_section_test.dart` test 2 |
| CA-13c | Widget test: expandido listando vehículos archivados | `garage_archived_section_test.dart` test 3 |
| CA-13d | Widget test: confirmar dispara `archiveVehicle` | `garage_archived_section_test.dart` test 4 |
| CA-13e | Widget test: cancelar no dispara `archiveVehicle` | `garage_archived_section_test.dart` test 5 |

---

## Regresión crítica a verificar

- Tests existentes en `vehicle_cubit_test.dart` deben seguir en verde.
- `VehicleFormPage` + `VehicleFormView` siguen compilando (ambos referencian `VehicleActionCubit` tras el renombrado). Verificar: `grep -r "VehicleDelete" lib/` → 0 resultados (solo archivos `.freezed.dart` y `injection.config.dart` transitorios antes de regen).
- `VehicleFormView` sigue funcionando end-to-end (delete desde edición de vehículo).
- `GarageOptionsBottomSheet` en vehículos activos: "Marcar como principal" (condicional), "Editar", "Agregar mantenimiento", "Archivar" — sin "Eliminar".
- DI: verificar en `injection.config.dart` generado que `VehicleActionCubit` no sea singleton.
- No re-fetch: confirmar que `fetchMyVehicles` no aparece en el call stack de archive/unarchive.
- L10n: `grep -r "vehicle_restoreVehicle" lib/l10n/` → 0 resultados (clave no debe existir; se usa `vehicle_unarchiveVehicle`).

> Full detail: handoffs/architect.md
