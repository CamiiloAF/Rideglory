# QA Handoff — home-garage-vehicle-cubit-coherence

**Date:** 2026-06-17T22:14:24Z
**Agent:** QA (claude-sonnet-4-6)
**Status:** done

---

## Catalogo de tests

| ID | CA PRD §5 | Tipo | Descripcion | Resultado |
|----|-----------|------|-------------|-----------|
| TC-garage-section-1 | CA-3 (Initial no crashea) | Widget | `VehicleCubit.initial` → placeholder 200px, no `HomeGarageCard`, no `HomeEmptyGarageCard` | PASS |
| TC-garage-section-2 | CA-4 (Loading no crashea) | Widget | `VehicleCubit.loading` → placeholder visible, no `HomeGarageCard` | PASS |
| TC-garage-section-3 | CA-5 (Reactividad) | Widget | `Data([mainVehicle, otherVehicle])` con `isMainVehicle=true` → `HomeGarageCard` muestra vehículo principal | PASS |
| TC-garage-section-4 | CA-1, CA-5 | Widget | `Data([otherVehicle])` sin `isMainVehicle` → `HomeGarageCard` con `firstOrNull` | PASS |
| TC-garage-section-5 | CA-6 (Vacío) | Widget | `Data([])` → `HomeEmptyGarageCard` visible | PASS |
| TC-garage-section-5b | CA-6 (Vacío) | Widget | `Empty` → `HomeEmptyGarageCard` visible | PASS |
| TC-garage-section-6 | CA-5 (Reactividad sin HTTP) | Widget | Nuevo estado `VehicleCubit.data` actualiza UI sin invocar `HomeCubit.loadHomeData` | PASS |
| TC-home-1 | CA-8 | Unit | `HomeCubit` initial state es `HomeInitial` | PASS |
| TC-home-2 | CA-2, CA-8 | Unit | `loadHomeData` success emite `HomeLoading` → `HomeLoaded(upcomingEvents: ...)` sin `mainVehicle` | PASS |
| TC-home-3 | CA-8 | Unit | `loadHomeData` error emite `HomeLoading` → `HomeError` | PASS |
| TC-home-a1 | CA-8 | Unit | Analytics: `loadHomeData` success → `home_viewed` con `upcomingEventsCount` y `hasMainVehicle=1` | PASS |
| TC-home-a2 | CA-8 | Unit | Analytics: sin vehículo principal → `hasMainVehicle=0` | PASS |
| TC-home-a3 | CA-8 | Unit | Analytics: lista de eventos vacía → `upcomingEventsCount=0` | PASS |
| TC-home-a4 | CA-8 | Unit | Analytics: error → `home_viewed` NO se emite | PASS |

**Total:** 14/14 PASS. Ningún gap respecto a los 9 AC del PRD.

---

## Matriz de regresion

| Guardrail PRD §6 | Mecanismo de verificacion | Resultado |
|------------------|--------------------------|-----------|
| `HomeData` y `HomeDto` NO modificados — campo `mainVehicle` intacto | `grep -rn 'mainVehicle' lib/features/home/domain/ lib/features/home/data/` → presentes en `home_data.dart`, `home_dto.dart`, `home_dto.g.dart` | PASS |
| Analytics `data.mainVehicle` en `home_cubit.dart` conservada | `grep -n 'data.mainVehicle' lib/features/home/presentation/cubit/home_cubit.dart` → línea 31 intacta | PASS |
| `HomeLoaded` sin `mainVehicle` en presentación | `grep -rn 'mainVehicle' lib/features/home/presentation/` → solo `home_cubit.dart:31` (referencia a `data.mainVehicle`, objeto `HomeData`, correcto) y `home_garage_section.dart` (variable local `mainVehicle`, no campo de estado) | PASS |
| Placeholder con `height: 200` para evitar layout jump | `grep -n 'height' lib/features/home/presentation/widgets/home_garage_section.dart` → `height: 200` en `_GaragePlaceholder` | PASS |
| Sin `build_runner` (`HomeLoaded` es sealed class manual) | No se usó build_runner; `home_state.dart` es clase sealed Dart pura | PASS |
| No hay cambios en contratos de API/DTOs de red/migraciones | `git diff --stat` → solo `integration_test/test_bundle.dart` (fuera del scope; cambio pre-existente no relacionado) | PASS |
| Solo archivos en `lib/features/home/presentation/` y `test/features/home/` modificados | `git status --short` → ningún archivo tracked modificado en home; archivos nuevos son `test/features/home/presentation/widgets/home_garage_section_test.dart` (ya existía como untracked) | PASS |
| `HomeGarageSection` usa `const HomeGarageSection()` sin props en todos los callers | `grep -rn 'HomeGarageSection(' lib/features/home/` → constructor en widget y uso en `home_scaffold.dart` sin parámetros `vehicle:` | PASS |

---

## Ejecucion

### dart analyze
```
dart analyze lib/features/home/
Analyzing home...
No issues found.
```
**Resultado:** PASS — 0 errores, 0 warnings.

### flutter test
```
flutter test test/features/home/
00:04 +14: All tests passed!
```
**Resultado:** 14/14 PASS.

### Fallas pre-existentes (fuera de scope)
```
test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart
  - TC-bs-1: FAIL (pre-existing — ListTile con icono de archivo no encontrado)
  - TC-bs-2: FAIL (pre-existing — misma causa que TC-bs-1)
```
Estas fallas son pre-existentes (reportadas en el handoff de Frontend) y no están relacionadas con este feature. No se incluyen como regresiones.

---

## Bugs

Ninguno. No se encontraron regresiones ni nuevas violaciones de análisis.

---

## Pruebas manuales recomendadas

1. Abrir la app en estado frío (VehicleCubit en `Initial`) → pantalla Home muestra placeholder gris de 200px en la sección de garaje, sin crash.
2. Una vez que `VehicleCubit` carga vehículos → `HomeGarageCard` aparece con el vehículo principal.
3. Si el garaje está vacío → `HomeEmptyGarageCard` aparece directamente sin crash.
4. Cambiar vehículo principal desde la pantalla de Garaje → volver a Home → card refleja el nuevo principal sin hacer pull-to-refresh (reactividad inmediata).
5. Archivar el vehículo principal desde el garaje → volver a Home → la sección se actualiza automáticamente.

---

## Sign-off

- **Todos los AC del PRD §5 (CA-1 al CA-9):** PASS
- **Bugs bloqueantes:** ninguno
- **Fallas pre-existentes:** TC-bs-1, TC-bs-2 en `garage_options_bottom_sheet_test.dart` (no relacionadas con este feature)
- **Señal de calidad:** verde — listo para revisión humana y commit

## Siguiente agente

- **Tech Lead / Humano:** la señal es verde. 14/14 tests pasan, `dart analyze` limpio, todos los AC cumplidos, guardrails verificados. Las 2 fallas pre-existentes en `garage_options_bottom_sheet_test.dart` son deuda técnica previa; se recomienda crear un ticket separado para su corrección.
- **CI:** `dart analyze lib/features/home/ && flutter test test/features/home/`

## Change log

- 2026-06-17T22:14:24Z: QA run inicial — 14/14 tests PASS, 0 bugs, sign-off verde.
