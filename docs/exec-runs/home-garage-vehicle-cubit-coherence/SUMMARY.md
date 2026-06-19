# SUMMARY — home-garage-vehicle-cubit-coherence

_Generated: 2026-06-17T22:24:25Z_

---

## Objetivo

Eliminar el campo `mainVehicle` de `HomeLoaded` y el parámetro `vehicle` de `HomeGarageSection`, haciendo que la sección de garaje en Home lea exclusivamente de `VehicleCubit` como única fuente de verdad. Elimina el estado UI duplicado que causaba datos stale cuando el vehículo principal cambiaba por archivado, restauración o cambio explícito.

---

## Qué cambió por área

### Frontend (`lib/features/home/presentation/`)

| Archivo | Cambio |
|---------|--------|
| `cubit/home_state.dart` | `HomeLoaded` solo tiene `upcomingEvents`; `mainVehicle` eliminado |
| `cubit/home_cubit.dart` | `HomeLoaded(upcomingEvents: ...)` en los 3 sitios de construcción; `data.mainVehicle` conservado solo para Analytics vía `HomeData` |
| `widgets/home_scaffold.dart` | `const HomeGarageSection()` — sin prop `vehicle:` |
| `widgets/home_garage_section.dart` | Sin prop `vehicle`; `BlocBuilder<VehicleCubit>` con `vehicleState.when(...)` cubre `initial`, `loading`, `data`, `empty`, `error`; placeholder `_GaragePlaceholder` de 200px |

### Tests (`test/features/home/`)

| Archivo | Cambio |
|---------|--------|
| `presentation/widgets/home_garage_section_test.dart` | 7 widget tests cubriendo todos los estados del cubit y reactividad sin HTTP |
| `presentation/cubit/home_cubit_test.dart` | Tests existentes verificados; `TC-home-2` usa `state.upcomingEvents.length` sin `mainVehicle` |

### integration_test

| Archivo | Cambio |
|---------|--------|
| `test_bundle.dart` | Eliminados imports/grupos de `app_test`, `events_patrol_test`, `home_patrol_test`, `profile_patrol_test`; solo queda `vehicles_patrol_test`. Fuera del scope del PRD — ver Riesgos. |

---

## Archivos

- `lib/features/home/presentation/cubit/home_state.dart`
- `lib/features/home/presentation/cubit/home_cubit.dart`
- `lib/features/home/presentation/widgets/home_scaffold.dart`
- `lib/features/home/presentation/widgets/home_garage_section.dart`
- `test/features/home/presentation/widgets/home_garage_section_test.dart`
- `test/features/home/presentation/cubit/home_cubit_test.dart`
- `integration_test/test_bundle.dart` _(fuera del scope del PRD — ver Riesgos)_

---

## Pruebas

- `flutter test test/features/home/` → **14/14 PASS**
- `dart analyze lib/features/home/` → **No issues found**
- Fallas pre-existentes en `garage_options_bottom_sheet_test.dart` (TC-bs-1, TC-bs-2) — no relacionadas con este cambio.

---

## Riesgos / Watchlist

1. **`integration_test/test_bundle.dart` fuera del scope**: El diff muestra la eliminación de 4 grupos de integration tests (`app_test`, `events_patrol_test`, `home_patrol_test`, `profile_patrol_test`). El PRD no menciona este archivo. Verificar si el bundle es auto-generado por `patrol generate` (en cuyo caso no hay riesgo) o si fue editado manualmente.

2. **`_GaragePlaceholder` sin `const` constructor**: Lint menor (prefer_const_constructors). No es blocker.

3. **Fallas pre-existentes en garaje**: TC-bs-1 y TC-bs-2 en `garage_options_bottom_sheet_test.dart` son deuda técnica previa; crear ticket separado.

---

## Mensaje de commit sugerido

```
refactor(home): VehicleCubit como única fuente de verdad para HomeGarageSection

Elimina mainVehicle de HomeLoaded y el prop vehicle de HomeGarageSection.
La sección de garaje ahora reacciona directamente a VehicleCubit (archivado,
restauración, cambio de principal) sin requerir re-fetch HTTP de HomeCubit.
Añade 7 widget tests cubriendo todos los estados del cubit y reactividad.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```
