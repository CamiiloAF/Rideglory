# Frontend Handoff — home-garage-vehicle-cubit-coherence

**Timestamp:** 2026-06-17T22:11:20Z  
**Agent:** Frontend (Flutter lib/)  
**Model:** claude-sonnet-4-6

---

## Baseline

All home tests were already passing before any edits (14/14). The code was already in the target state — a prior session had already applied the core changes. The frontend agent verified correctness, ran the full acceptance checklist, and confirmed tests are green.

Pre-existing failures in `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` (TC-bs-1, TC-bs-2) are unrelated to this feature and were present before this session.

---

## Archivos cambiados

No code changes were required — all target changes were already applied:

| Archivo | Estado | Descripción |
|---------|--------|-------------|
| `lib/features/home/presentation/cubit/home_state.dart` | Ya correcto | `HomeLoaded` sin campo `mainVehicle`; solo `upcomingEvents` |
| `lib/features/home/presentation/cubit/home_cubit.dart` | Ya correcto | `HomeLoaded(upcomingEvents: ...)` en los 3 sitios; analytics usa `data.mainVehicle` de `HomeData` (correcto) |
| `lib/features/home/presentation/widgets/home_scaffold.dart` | Ya correcto | `const HomeGarageSection()` sin prop `vehicle:` |
| `lib/features/home/presentation/widgets/home_garage_section.dart` | Ya correcto | Sin prop `vehicle`; maneja todos los estados via `vehicleState.when(...)` |
| `test/features/home/presentation/cubit/home_cubit_test.dart` | Ya correcto | TC-home-2 usa `state.upcomingEvents.length == 1` |
| `test/features/home/presentation/widgets/home_garage_section_test.dart` | Ya existía | 7 widget tests (TC-garage-section-1 al 6 + TC-5b) |

---

## Pruebas nuevas

El archivo `test/features/home/presentation/widgets/home_garage_section_test.dart` ya existía con los 7 tests:

- **TC-garage-section-1**: `VehicleCubit.initial` → placeholder visible, no `HomeGarageCard`, no `HomeEmptyGarageCard`
- **TC-garage-section-2**: `VehicleCubit.loading` → placeholder visible
- **TC-garage-section-3**: `Data([mainVehicle, otherVehicle])` → `HomeGarageCard` con el vehículo principal
- **TC-garage-section-4**: `Data([otherVehicle])` sin `isMainVehicle` → `HomeGarageCard` con `firstOrNull`
- **TC-garage-section-5**: `Data([])` → `HomeEmptyGarageCard`
- **TC-garage-section-5b**: `Empty` → `HomeEmptyGarageCard`
- **TC-garage-section-6**: Reactividad — emitir nuevo estado muestra B sin invocar `HomeCubit.loadHomeData`

---

## Resultado final

```
flutter test test/features/home/
✓ 14 tests passed — 0 failed
dart analyze lib/features/home/
No issues found.
```

Checklist de aceptación:
- [x] `grep -rn 'mainVehicle' lib/features/home/presentation/cubit/home_state.dart` → 0 resultados
- [x] `grep -rn 'vehicle:' lib/features/home/presentation/widgets/home_scaffold.dart` → 0 resultados  
- [x] `HomeGarageSection` constructor es `const HomeGarageSection({super.key})`
- [x] `dart analyze lib/features/home/` verde
- [x] `flutter test test/features/home/` verde (14/14)

Nota: `data.mainVehicle` en `home_cubit.dart:31` es `HomeData.mainVehicle` (del use case), no `HomeLoaded.mainVehicle` — es correcto y se preserva para analytics.

---

## Verificacion manual

1. Abrir la app en estado frío (VehicleCubit en `Initial`) → pantalla Home muestra placeholder gris 200px en la sección de garaje, sin crash.
2. Una vez que `VehicleCubit` carga vehículos → `HomeGarageCard` aparece con el vehículo principal.
3. Si el garaje está vacío → `HomeEmptyGarageCard` aparece directamente.
4. Cambiar vehículo principal desde la pantalla de Garaje → volver a Home → card refleja el nuevo principal sin hacer pull-to-refresh.

---

## Notas para QA

- No hay texto nuevo → no hay claves l10n que verificar.
- El placeholder tiene `height: 200` fijo para evitar layout jump durante la carga.
- La sección de garaje es completamente independiente de `HomeCubit`; reacciona solo a `VehicleCubit`.
- Las 2 fallas pre-existentes en `garage_options_bottom_sheet_test.dart` (TC-bs-1, TC-bs-2) no están relacionadas con este feature.
