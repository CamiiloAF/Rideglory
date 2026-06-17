> Slim handoff — read this before handoffs/architect.md

# Architect → QA

**Feature:** flutter-permanent-delete-vehicle
**Date:** 2026-06-17T17:06:23Z

---

## Comandos de verificación

```bash
# 1. Análisis estático — debe dar 0 errores (ignorar lints de shouldUseLocalApi per MEMORY.md)
dart analyze

# 2. Tests — deben pasar todos, incluyendo los 3 TCs nuevos
flutter test

# 3. Grep de código eliminado — 0 hits esperados
grep -rn 'VehicleDeleteCubit\|deleteVehicleLocally' lib/ --include='*.dart' | grep -v '.g.dart\|.freezed.dart'

# 4. Grep de ruta obsoleta — 0 hits esperados
grep -rn 'hard-delete' lib/ --include='*.dart'
```

---

## Tests existentes que deben estar en verde

| Archivo | TCs |
|---------|-----|
| `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` | TC-perm-A: diálogo muestra nombre del vehículo y usa `danger` style |
| | TC-perm-B: guard anti doble-tap — use case llamado exactamente 1 vez |
| | TC-perm-C: cancelar NO dispara el use case |
| `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` | Tests existentes de opciones de garaje — no deben romperse |
| `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` | El grupo `deleteVehicleLocally` debe estar eliminado (no debe aparecer) |

---

## Criterios de aceptación a trazar

| CA | Verificación |
|----|-------------|
| CA-1: tile visible solo en archivados | TC-perm-A: el bottom sheet para vehículo archivado muestra "Eliminar permanentemente"; para activo no |
| CA-3: flujo de confirmación | TC-perm-A: verifyNever en dialog abierto; TC-perm-C: cancelar no llama use case |
| CA-4: guard anti doble-tap | TC-perm-B: use case llamado exactamente 1 vez con dos llamadas concurrentes |
| CA-8: contrato Retrofit | `grep -rn 'hard-delete' lib/` → 0 hits |
| CA-9: renombrado completo | grep de `VehicleDeleteCubit` y `deleteVehicleLocally` → 0 hits |
| CA-10: tests en verde | `flutter test` pasa |
| CA-12: form limpio | `grep -rn 'VehicleDeleteCubit\|onDelete' lib/features/vehicles/presentation/form/` → 0 hits |

---

## Superficie de regresión a validar manualmente

- Garaje: tiles de vehículo activo (Editar, Mantenimiento, Principal, Archivar) siguen funcionando.
- Garaje: tile "Restaurar" para archivados sigue funcionando.
- Formulario de vehículo (agregar y editar): carga y guarda sin errores; sin botón de eliminar.
- DI global: app arranca sin excepciones de GetIt.

> Full detail: handoffs/architect.md
