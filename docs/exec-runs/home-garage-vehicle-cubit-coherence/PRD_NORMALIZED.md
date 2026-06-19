# PRD Normalizado — home-garage-vehicle-cubit-coherence

_Generated: 2026-06-17T21:46:28Z_
_Source: docs/plans/archive-vehicle-soft-delete/phases/phase-05-flutter-vehiculo-principal-siempre-coherente.md_
_Nivel rg-exec: lite_

---

## 1 Objetivo

Eliminar el campo `mainVehicle` de `HomeLoaded` y el parámetro `vehicle` de `HomeGarageSection`, haciendo que esta sección lea exclusivamente de `VehicleCubit` como única fuente de verdad. Tras el cambio, la sección de garaje en Home reacciona inmediatamente a cualquier cambio en `VehicleCubit` (archivado, restauración, cambio de principal) sin requerir un re-fetch HTTP del endpoint de home.

---

## 2 Por qué

`HomeGarageSection` actualmente tiene un fallback al prop `vehicle` que llega de `HomeCubit`/`HomeLoaded`. Cuando el vehículo principal cambia (por archivado, restauración o cambio explícito de principal), `HomeCubit` no se entera y la sección muestra datos stale. `VehicleCubit` ya es la fuente de verdad para la lista de vehículos; eliminar el estado duplicado en `HomeLoaded` cierra la brecha de coherencia sin costo de red adicional.

---

## 3 Alcance

### Entra
- Eliminar `mainVehicle: VehicleModel?` de `HomeLoaded` en `home_state.dart`.
- Eliminar el import de `VehicleModel` de `home_state.dart` si queda huérfano.
- Actualizar los 4 sitios de uso en `home_cubit.dart` (líneas 32, 37, 52, 63): quitar `mainVehicle: data.mainVehicle` / `mainVehicle: current.mainVehicle` de los constructores de `HomeLoaded`; conservar `data.mainVehicle` en la línea de Analytics (el campo sigue en `HomeData`).
- Actualizar `HomeScaffold`: cambiar `HomeGarageSection(vehicle: state.mainVehicle)` → `const HomeGarageSection()`.
- Eliminar el parámetro `vehicle` del constructor de `HomeGarageSection` y su lógica de fallback.
- Añadir manejo explícito de estados `Initial` y `Loading` de `VehicleCubit` en `HomeGarageSection` (placeholder sin crash; `SizedBox` fijo o `LinearProgressIndicator` delgado).
- Widget tests mínimos para `HomeGarageSection` cubriendo `Initial`, `Loading`, `Data` (con main, sin main, vacío) y reactividad sin HTTP.
- Verificar y eliminar imports huérfanos de `VehicleModel` en `home_cubit.dart` tras `dart analyze`.

### No entra
- Modificar `HomeData` (domain model) ni `HomeDto` (DTO de red) — conservan `mainVehicle` porque la API los devuelve.
- Modificar `GetHomeDataUseCase`, `HomeRepository` ni el endpoint de la API.
- Cambio funcional en la lógica de Analytics `hasMainVehicle` (`data.mainVehicle` sigue disponible via `HomeData`).
- Skeleton animado complejo — placeholder simple es suficiente.
- Tocar features fuera de `home/presentation/`.

---

## 4 Áreas afectadas

| Capa | Archivo | Tipo de cambio |
|------|---------|---------------|
| Presentation / State | `lib/features/home/presentation/cubit/home_state.dart` | Eliminar campo `mainVehicle` e import huérfano |
| Presentation / Cubit | `lib/features/home/presentation/cubit/home_cubit.dart` | Eliminar 3 referencias al prop; verificar import `VehicleModel` |
| Presentation / Widget | `lib/features/home/presentation/widgets/home_scaffold.dart` | Cambiar llamada a `HomeGarageSection` |
| Presentation / Widget | `lib/features/home/presentation/widgets/home_garage_section.dart` | Eliminar prop `vehicle`; manejar todos los estados del cubit |
| Tests | `test/features/home/presentation/widgets/home_garage_section_test.dart` | Archivo nuevo con 6 widget tests |

Sin cambios en: dominio, datos, API, navegación, DI, localizaciones, otros features.

---

## 5 Criterios de aceptación

1. **Constructor limpio:** `HomeGarageSection` tiene constructor `const HomeGarageSection({super.key})`. Ningún caller le pasa un `VehicleModel`.

2. **`HomeLoaded` sin `mainVehicle`:** `grep -rn 'mainVehicle' lib/features/home/presentation/` devuelve cero resultados.

3. **Estado `Initial` no crashea:** Cuando `VehicleCubit` está en `ResultState.initial()`, `HomeGarageSection` muestra un placeholder sin lanzar `Null check operator used on null value` ni `LateInitializationError`. `HomeGarageCard` y `HomeEmptyGarageCard` no aparecen en el árbol.

4. **Estado `Loading` no crashea:** Cuando `VehicleCubit` está en `ResultState.loading()`, `HomeGarageSection` muestra placeholder o indicador de carga sin crash. `HomeGarageCard` no aparece en el árbol.

5. **Reactividad sin HTTP:** Si `VehicleCubit` emite un nuevo estado `Data` con un vehículo diferente marcado `isMainVehicle: true`, `HomeGarageSection` actualiza su UI sin que `HomeCubit.loadHomeData()` sea invocado.

6. **Sin vehículos muestra vacío:** Cuando `VehicleCubit` emite `Data([])` o `Empty`, `HomeGarageSection` muestra `HomeEmptyGarageCard`.

7. **`dart analyze` en verde:** `dart analyze lib/features/home/` no reporta errores ni warnings nuevos tras los cambios.

8. **`flutter test` en verde:** `flutter test test/features/home/` pasa sin fallos. Los 6 widget tests definidos en la spec de pruebas pasan.

9. **`HomeScaffold` compila sin warnings:** No quedan referencias a `state.mainVehicle` en `home_scaffold.dart`.

---

## 6 Guardrails de regresión

- `HomeData` y `HomeDto` NO se modifican — sus campos `mainVehicle` permanecen intactos (son contratos de datos, no de estado UI).
- La línea de Analytics en `home_cubit.dart` que usa `data.mainVehicle` puede conservarse tal cual porque `HomeData` no cambia.
- Si el pre-flight `grep -rn 'mainVehicle\|HomeLoaded' lib/` revela consumidores fuera de los 4 archivos identificados, detener y escalar antes de continuar.
- El placeholder en `Initial`/`Loading` debe tener altura equivalente a `HomeGarageCard` (~200px o la altura real del card) para evitar saltos de layout en el scroll de `HomeScaffold`.
- No usar `build_runner` — `HomeLoaded` es una sealed class manual, no freezed.
- No hay cambios en contratos de API, DTOs de red ni migraciones de datos.

---

## 7 Constraints heredados

- **Un widget por archivo:** `HomeGarageSection` y sus estados deben seguir en archivos separados si se extraen nuevos widgets; no se permiten métodos que retornen `Widget`.
- **Strings en l10n:** cualquier texto en el placeholder nuevo debe ir a `app_es.arb` + `context.l10n.<key>`.
- **No commits:** el árbol de trabajo queda sucio para revisión humana; el humano commitea.
- **No tocar:** `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`, `docs/handoffs/**`, `.claude/**`, ni el archivo fuente original del plan.
- **Nivel lite:** 1 implementador, 1 ronda de auditor; sin diseño en Pencil (no hay nueva UI diseñable).
- **Imports limpios:** eliminar imports huérfanos tras `dart analyze`; no dejar `// ignore:` sin justificación.
