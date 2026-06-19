# Architect handoff — home-garage-vehicle-cubit-coherence

**Date:** 2026-06-17T21:47:55Z
**Status:** done

---

## Decisiones

| # | Decisión | Rationale |
|---|----------|-----------|
| 1 | No hay cambios en backend, dominio ni datos | `HomeData` y `HomeDto` conservan `mainVehicle`; la API no cambia. Solo cambia la capa de presentación. |
| 2 | `HomeLoaded` pasa de 2 campos a 1 campo | Eliminar `mainVehicle: VehicleModel?` del sealed state. El campo `upcomingEvents` permanece. |
| 3 | `HomeGarageSection` pasa a `const HomeGarageSection()` | El prop `vehicle` desaparece completamente; la sección lee solo de `context.watch<VehicleCubit>()`. |
| 4 | Placeholder de 200 px para `Initial`/`Loading` | Altura conservativa que previene layout jump al resolver `VehicleCubit`. `SizedBox(height: 200)` con `AppColors.darkCard` y `BorderRadius.circular(16)`. Sin texto (sin l10n nuevo requerido). |
| 5 | Tests en `test/features/home/presentation/widgets/` (directorio nuevo) | El directorio `cubit/` ya existe; `widgets/` debe crearse. El test existente `home_cubit_test.dart` necesita update del predicado `state.mainVehicle`. |
| 6 | `HomeScaffold` conserva posición de `HomeGarageSection` en el árbol | Solo se cambia `HomeGarageSection(vehicle: state.mainVehicle)` → `const HomeGarageSection()`. La sección sigue dentro del bloque `else if (state is HomeLoaded)`. |
| 7 | Import `VehicleModel` en `home_cubit.dart` queda huérfano tras el cambio | Eliminar; `home_state.dart` también elimina su import. Confirmar con `dart analyze` post-cambio. |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/home/presentation/cubit/home_state.dart` | modify | Eliminar campo `mainVehicle: VehicleModel?` y el `import` de `VehicleModel` | low |
| `lib/features/home/presentation/cubit/home_cubit.dart` | modify | Eliminar `mainVehicle: data.mainVehicle` / `mainVehicle: current.mainVehicle` de los 3 constructores `HomeLoaded`; eliminar import `VehicleModel` si queda huérfano | low |
| `lib/features/home/presentation/widgets/home_scaffold.dart` | modify | Cambiar `HomeGarageSection(vehicle: state.mainVehicle)` → `const HomeGarageSection()` | low |
| `lib/features/home/presentation/widgets/home_garage_section.dart` | modify | Eliminar prop `vehicle`; eliminar fallback `?: vehicle`; añadir ramas `Initial`/`Loading` → placeholder 200 px | low |
| `test/features/home/presentation/widgets/home_garage_section_test.dart` | create | 6 widget tests: `Initial`, `Loading`, `Data+main`, `Data sin main`, `Data vacío`, reactividad sin HTTP | low |
| `test/features/home/presentation/cubit/home_cubit_test.dart` | modify | Actualizar predicado TC-home-2 que verifica `state.mainVehicle` (campo ya no existe en `HomeLoaded`) | low |

---

## Contratos rideglory-api

Ninguno. Esta fase no toca ningún endpoint ni DTO de red.

---

## Datos / Migraciones

Ninguna. `HomeData` y `HomeDto` conservan `mainVehicle` intactos.

---

## Env

Ningún delta de variables de entorno.

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| `home_cubit_test.dart` TC-home-2 verifica `state.mainVehicle` — tras eliminar el campo el test falla | El Frontend debe actualizar el predicado: en lugar de comprobar `state.mainVehicle == mockVehicle`, verificar solo `state.upcomingEvents.length == 1`. |
| `HomeGarageSection` dentro de `HomeLoaded` branch de `HomeScaffold` — si `VehicleCubit` está en `Initial` cuando `HomeCubit` ya resuelve, el placeholder aparece brevemente | Comportamiento correcto: el placeholder evita crash y desaparece cuando `VehicleCubit` emite `Data`. No es regresión. |
| Grep pre-flight: si hay consumidores de `HomeLoaded.mainVehicle` fuera de los archivos identificados | Ejecutar `grep -rn 'state\.mainVehicle\|HomeLoaded' lib/` antes de editar; detener si aparecen archivos fuera de los 4 listados. |

---

## Orden de implementación

1. **`home_state.dart`** — eliminar campo `mainVehicle` e import. Primer cambio porque los siguientes dependen de que el campo no exista.
2. **`home_cubit.dart`** — eliminar las 3 referencias al prop en constructores de `HomeLoaded`; eliminar import `VehicleModel`. El cubit debe compilar con `HomeLoaded(upcomingEvents: ...)`.
3. **`home_scaffold.dart`** — cambiar `HomeGarageSection(vehicle: state.mainVehicle)` → `const HomeGarageSection()`.
4. **`home_garage_section.dart`** — eliminar prop `vehicle` y fallback; añadir ramas `Initial`/`Loading`.
5. **`dart analyze lib/features/home/`** — verificar cero errores antes de escribir tests.
6. **`home_cubit_test.dart`** — actualizar TC-home-2 para no verificar `state.mainVehicle`.
7. **`home_garage_section_test.dart`** (nuevo) — 6 widget tests.
8. **`flutter test test/features/home/`** — verde.

---

## Superficie de regresión

Solo `lib/features/home/presentation/` y `test/features/home/`. Ningún cambio en dominio, datos, API, DI, rutas, localizaciones, ni en otros features. Los únicos callers de `HomeGarageSection` son `home_scaffold.dart` (único sitio confirmado por grep).

---

## Fuera de alcance

- `HomeData`, `HomeDto`, `HomeRepository`, `GetHomeDataUseCase` — sin cambios.
- Placeholder animado / skeleton — un `SizedBox(height: 200)` con color de card es suficiente.
- Localizaciones nuevas — el placeholder no lleva texto.
- Cualquier widget fuera de `home/presentation/`.
- `build_runner` — `HomeLoaded` es sealed class manual, no freezed.
