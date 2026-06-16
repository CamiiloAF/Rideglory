# Fase 5 — Flutter: vehículo principal siempre coherente

_Generated: 2026-06-16T16:24:06Z_
_Plan: archive-vehicle-soft-delete_
_Nivel rg-exec: lite_

---

## Objetivo

Hacer que `HomeGarageSection` lea siempre de `VehicleCubit` como única fuente de verdad, eliminando el campo `mainVehicle` de `HomeLoaded` y el prop `vehicle` de `HomeGarageSection`. Esto elimina el estado stale que puede ocurrir cuando el vehículo principal cambia (por archivado, restauración o cambio de principal) sin que `HomeCubit` se entere. Tras esta fase, la sección de garaje en Home reacciona inmediatamente a cualquier cambio en `VehicleCubit` sin requerir un re-fetch HTTP de home data.

---

## Alcance (entra / no entra)

### Entra
- Eliminar `mainVehicle` de `HomeLoaded` (sealed class manual en `home_state.dart`).
- Eliminar el import de `VehicleModel` de `home_state.dart` si queda huérfano tras el cambio.
- Actualizar los 4 consumidores de `current.mainVehicle` / `data.mainVehicle` en `home_cubit.dart` (líneas 32, 37, 52, 63).
- Actualizar `HomeScaffold` para no pasar `state.mainVehicle` a `HomeGarageSection` (línea 54).
- Eliminar el parámetro `vehicle` del constructor de `HomeGarageSection` y su lógica de fallback.
- Añadir manejo explícito de los estados `Initial` y `Loading` de `VehicleCubit` dentro de `HomeGarageSection` (placeholder/skeleton sin crash).
- Widget tests mínimos para `HomeGarageSection` cubriendo los estados `Initial`, `Loading`, `Data` (con y sin vehículo principal), y reactividad ante cambio de main sin re-fetch HTTP.
- Eliminar el import de `VehicleModel` de `home_cubit.dart` si queda sin uso tras el cambio.

### No entra
- Modificar `HomeData` (domain model) ni `HomeDto` (data DTO) — ambos mantienen `mainVehicle` porque la API los devuelve; son contratos de datos, no de estado UI.
- Modificar `GetHomeDataUseCase` ni `HomeRepository`.
- Modificar `HomeCubit.loadHomeData` más allá de quitar el campo `mainVehicle` de `HomeLoaded` y su uso en Analytics (ver paso 3).
- Cambiar la lógica de Analytics `hasMainVehicle` a algo funcional en esta fase — se simplifica con el dato disponible en `data` (que sigue llegando del backend).
- Modificar `HomeData`, `HomeDto`, ni el endpoint de la API.
- Añadir skeleton animado complejo — un `SizedBox` con altura fija o `CircularProgressIndicator` pequeño es suficiente.
- Tocar features fuera de `home/presentation/`.

---

## Que se debe hacer (pasos concretos y ordenados)

### Pre-flight: confirmar consumidores

```bash
grep -rn 'mainVehicle\|HomeLoaded' lib/
```

Verificar que los únicos consumidores son los identificados en el scan:
- `home_state.dart`: campo `mainVehicle` en `HomeLoaded` (línea 18).
- `home_cubit.dart`: 4 referencias — Analytics `data.mainVehicle != null` (línea 32), constructor `mainVehicle: data.mainVehicle` (línea 37), `mainVehicle: current.mainVehicle` en `updateEvent` (línea 52) y en `removeEvent` (línea 63).
- `home_scaffold.dart`: prop `vehicle: state.mainVehicle` pasado a `HomeGarageSection` (línea 54).
- `home_garage_section.dart`: parámetro `vehicle` del constructor y fallback `vehicleState is Data ... : vehicle` (líneas 14–24).

Si `grep` revela consumidores adicionales fuera de estos archivos, detener y escalar antes de continuar.

---

### Paso 1 — Actualizar `HomeGarageSection` (fuente de verdad única)

**Archivo:** `lib/features/home/presentation/widgets/home_garage_section.dart`

1. Eliminar el parámetro `vehicle` del constructor y la field declaration.
2. Reemplazar la lógica de resolución de `mainVehicle`:

   **Antes:**
   ```dart
   final vehicleState = context.watch<VehicleCubit>().state;
   final mainVehicle = vehicleState is Data<List<VehicleModel>>
       ? (vehicleState.data.where((v) => v.isMainVehicle).firstOrNull ??
           vehicleState.data.firstOrNull)
       : vehicle;
   ```

   **Después:** manejar todos los estados del cubit sin fallback al prop eliminado:
   ```dart
   final vehicleState = context.watch<VehicleCubit>().state;
   ```

3. En el `build`, bifurcar por estado del cubit:
   - `Initial` / `Loading`: mostrar un placeholder de altura fija (p. ej. `SizedBox(height: 80)` o un `LinearProgressIndicator` delgado) dentro del mismo `Padding` existente para no romper el layout.
   - `Data<List<VehicleModel>>`: lógica actual — buscar `isMainVehicle == true`, fallback a `firstOrNull`, mostrar `HomeGarageCard` o `HomeEmptyGarageCard`.
   - `Empty` / `Error`: mostrar `HomeEmptyGarageCard` (mismo comportamiento que "sin vehículos").

4. Eliminar el import de `VehicleModel` si ya no es necesario en el archivo (lo usa solo como tipo de lista en el cast, verificar).

---

### Paso 2 — Actualizar `HomeScaffold`

**Archivo:** `lib/features/home/presentation/widgets/home_scaffold.dart`

1. En la línea 54, cambiar:
   ```dart
   child: HomeGarageSection(vehicle: state.mainVehicle),
   ```
   por:
   ```dart
   child: const HomeGarageSection(),
   ```
2. Verificar que el import de `VehicleModel` en este archivo (si lo hubiera) se elimine si queda sin uso. Revisar el archivo: actualmente no importa `VehicleModel` directamente, solo via `HomeState`. No debe quedar import huérfano.

---

### Paso 3 — Actualizar `home_cubit.dart`

**Archivo:** `lib/features/home/presentation/cubit/home_cubit.dart`

1. **Línea 32 — Analytics `hasMainVehicle`:** El campo `data.mainVehicle` sigue disponible en `HomeData` (el domain model no cambia). La línea puede mantenerse tal cual usando `data.mainVehicle`, ya que `HomeData` conserva el campo. No requiere cambio funcional.

2. **Línea 37 — constructor `HomeLoaded`:** Eliminar `mainVehicle: data.mainVehicle,` del constructor de `HomeLoaded`.

3. **Línea 52 — `updateEvent`:** Cambiar:
   ```dart
   HomeLoaded(mainVehicle: current.mainVehicle, upcomingEvents: updated),
   ```
   por:
   ```dart
   HomeLoaded(upcomingEvents: updated),
   ```

4. **Línea 63 — `removeEvent`:** Cambiar:
   ```dart
   HomeLoaded(mainVehicle: current.mainVehicle, upcomingEvents: updated),
   ```
   por:
   ```dart
   HomeLoaded(upcomingEvents: updated),
   ```

5. Verificar el import de `VehicleModel` en `home_cubit.dart` (línea 8). Si `data.mainVehicle` en Analytics sigue requiriéndolo a través de `HomeData`, el import sigue siendo necesario. Si no, eliminarlo. **Nota:** `HomeData` ya importa `VehicleModel` en su propio archivo; `home_cubit.dart` importa `VehicleModel` directamente (`package:rideglory/features/vehicles/domain/models/vehicle_model.dart`). Después del cambio, si `data.mainVehicle` sigue en la línea de Analytics, el tipo `VehicleModel` se infiere del resultado — el import directo puede quedar si lo necesita el análisis estático, o eliminarse si `dart analyze` no lo requiere. Ejecutar `dart analyze` para confirmar.

---

### Paso 4 — Actualizar `home_state.dart`

**Archivo:** `lib/features/home/presentation/cubit/home_state.dart`

1. Eliminar el campo `mainVehicle` de `HomeLoaded`:

   **Antes:**
   ```dart
   final class HomeLoaded extends HomeState {
     const HomeLoaded({this.mainVehicle, required this.upcomingEvents});

     final VehicleModel? mainVehicle;
     final List<EventModel> upcomingEvents;
   }
   ```

   **Después:**
   ```dart
   final class HomeLoaded extends HomeState {
     const HomeLoaded({required this.upcomingEvents});

     final List<EventModel> upcomingEvents;
   }
   ```

2. Eliminar el import de `VehicleModel` si no hay otro uso en el archivo. Verificar que `part of 'home_cubit.dart'` y el import de `EventModel` permanezcan intactos.

---

### Paso 5 — Verificar con dart analyze

```bash
dart analyze lib/features/home/
```

Resolver cualquier error de compilación antes de escribir los tests. Los errores esperados son únicamente los de referencias a `mainVehicle` que hayan quedado sin actualizar (no debería haber ninguno tras los pasos anteriores).

---

### Paso 6 — Escribir widget tests

**Archivo nuevo:** `test/features/home/presentation/widgets/home_garage_section_test.dart`

Tests requeridos (ver sección "Pruebas" para detalle).

---

### Paso 7 — Ejecutar la suite

```bash
flutter test test/features/home/
```

Verde obligatorio antes de entregar la fase.

---

## Archivos a crear/modificar (rutas reales)

| Acción | Ruta | Qué cambia |
|--------|------|------------|
| Modificar | `lib/features/home/presentation/cubit/home_state.dart` | Eliminar campo `mainVehicle: VehicleModel?` de `HomeLoaded` y su import si queda huérfano |
| Modificar | `lib/features/home/presentation/cubit/home_cubit.dart` | Eliminar `mainVehicle: data.mainVehicle` del constructor (línea 37); eliminar `mainVehicle: current.mainVehicle` de `updateEvent` (línea 52) y `removeEvent` (línea 63); verificar import `VehicleModel` |
| Modificar | `lib/features/home/presentation/widgets/home_scaffold.dart` | Cambiar `HomeGarageSection(vehicle: state.mainVehicle)` → `HomeGarageSection()` (línea 54) |
| Modificar | `lib/features/home/presentation/widgets/home_garage_section.dart` | Eliminar parámetro `vehicle`; manejar estados `Initial`/`Loading`/`Empty`/`Error` del cubit con placeholder; eliminar fallback al prop |
| Crear | `test/features/home/presentation/widgets/home_garage_section_test.dart` | Widget tests para los estados `Initial`, `Loading`, `Data` (con y sin main), y reactividad sin HTTP |

---

## Contratos / API rideglory-api

Ninguno. Esta fase no modifica endpoints, DTOs de red ni contratos entre Flutter y el backend. `HomeData` y `HomeDto` conservan su campo `mainVehicle` — son contratos de datos, no se tocan.

---

## Cambios de datos / migraciones

Ninguno. Es un refactor puramente de estado UI en memoria.

---

## Criterios de aceptación

1. **`HomeGarageSection` no tiene parámetro `vehicle`:** El constructor es `const HomeGarageSection({super.key})`. Ningún caller le pasa un `VehicleModel`.

2. **`HomeLoaded` no tiene campo `mainVehicle`:** `grep -rn 'mainVehicle' lib/features/home/presentation/` devuelve cero resultados.

3. **Estado `Initial` de `VehicleCubit` no crashea:** Cuando `VehicleCubit` está en `Initial`, `HomeGarageSection` muestra un placeholder (no lanza `Null check operator used on null value` ni `LateInitializationError`).

4. **Estado `Loading` de `VehicleCubit` no crashea:** Cuando `VehicleCubit` está en `Loading`, `HomeGarageSection` muestra el mismo placeholder que `Initial` o un indicador de carga, sin crash.

5. **Cambio de vehículo principal se refleja sin re-fetch HTTP:** Si `VehicleCubit` emite un nuevo estado `Data` con un vehículo diferente marcado como `isMainVehicle: true`, `HomeGarageSection` actualiza su UI sin que `HomeCubit.loadHomeData()` sea llamado.

6. **Sin vehículos muestra `HomeEmptyGarageCard`:** Cuando `VehicleCubit` emite `Data([])` o `Empty`, `HomeGarageSection` muestra el estado vacío existente.

7. **`dart analyze` en verde:** `dart analyze lib/features/home/` no reporta errores ni warnings nuevos tras el cambio.

8. **`flutter test` en verde:** `flutter test test/features/home/` pasa sin fallos.

9. **`HomeScaffold` compila sin warnings:** No hay referencias a `state.mainVehicle` en `home_scaffold.dart`.

---

## Pruebas (unitarias/widget/integración)

### Widget tests — `HomeGarageSection`

**Archivo:** `test/features/home/presentation/widgets/home_garage_section_test.dart`

**Setup común:** Los tests usan un `MockVehicleCubit` (mocktail o implementación manual con `StreamController`) y montan `HomeGarageSection` dentro de un `BlocProvider<VehicleCubit>` con el cubit mockeado. No se necesita `HomeCubit` en estos tests.

#### Test 1 — Estado `Initial`: muestra placeholder, no crashea
```
Dado: VehicleCubit en ResultState.initial()
Cuando: HomeGarageSection se renderiza
Entonces: no hay RenderFlex overflow, no hay exception,
          HomeGarageCard NO está en el árbol,
          HomeEmptyGarageCard NO está en el árbol
```

#### Test 2 — Estado `Loading`: muestra placeholder, no crashea
```
Dado: VehicleCubit en ResultState.loading()
Cuando: HomeGarageSection se renderiza
Entonces: no hay exception, HomeGarageCard NO está en el árbol
```

#### Test 3 — Estado `Data` con vehículo principal: muestra `HomeGarageCard`
```
Dado: VehicleCubit en ResultState.data([vehicleA(isMainVehicle:true), vehicleB(isMainVehicle:false)])
Cuando: HomeGarageSection se renderiza
Entonces: HomeGarageCard está en el árbol
          (verificar que el widget se construyó con vehicleA,
           p. ej. chequeando el nombre/placa si HomeGarageCard los expone)
```

#### Test 4 — Estado `Data` sin ningún vehículo marcado como main: usa `firstOrNull`
```
Dado: VehicleCubit en ResultState.data([vehicleA(isMainVehicle:false)])
Cuando: HomeGarageSection se renderiza
Entonces: HomeGarageCard está en el árbol (fallback a firstOrNull)
```

#### Test 5 — Estado `Data` vacío: muestra `HomeEmptyGarageCard`
```
Dado: VehicleCubit en ResultState.data([])
Cuando: HomeGarageSection se renderiza
Entonces: HomeEmptyGarageCard está en el árbol
```

#### Test 6 — Reactividad sin HTTP: cambio de main se refleja sin rellamar loadHomeData
```
Dado: VehicleCubit emite Data([vehicleA(isMainVehicle:true), vehicleB(isMainVehicle:false)])
      HomeGarageSection renderiza (muestra vehicleA)
Cuando: VehicleCubit emite Data([vehicleA(isMainVehicle:false), vehicleB(isMainVehicle:true)])
        (simulado con cubit mock que emite segundo estado)
Entonces: HomeGarageSection refleja vehicleB como principal
          sin que HomeCubit.loadHomeData haya sido llamado
```

### Tests de integración

No requeridos para esta fase. La cobertura de widget tests es suficiente dado el alcance del cambio.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R-1 | Consumidor oculto de `mainVehicle` fuera de los 4 archivos identificados (p. ej. un test existente o widget no escaneado) | Baja | Medio | Pre-flight `grep -rn 'mainVehicle\|HomeLoaded' lib/` antes de tocar código; si aparece consumidor nuevo, analizarlo antes de continuar |
| R-2 | `HomeGarageSection` crashea en estado `Initial`/`Loading` si el widget test no cubre esos paths | Baja | Medio | Tests 1 y 2 cubren explícitamente estos estados; el placeholder previene el crash |
| R-3 | El import de `VehicleModel` en `home_cubit.dart` se elimina cuando aún es necesario para Analytics, causando error de compilación | Baja | Bajo | `dart analyze` tras cada cambio detecta esto inmediatamente; la línea de Analytics puede conservar el campo `data.mainVehicle` porque `HomeData` no cambia |
| R-4 | `home_state.dart` usa `part of` y la eliminación del campo rompe la coherencia con el `part` de `home_cubit.dart` | Muy baja | Bajo | No se usa build_runner aquí; `part of` es manual. Verificar que `home_cubit.dart` siga siendo el host del `part` |
| R-5 | Placeholder en `Initial`/`Loading` cambia el layout del scroll en `HomeScaffold` | Baja | Bajo | Usar altura equivalente al card existente (~200px o la altura real de `HomeGarageCard`) para evitar saltos de layout |

---

## Dependencias (fases prerequisito y por qué)

**Ninguna.** Esta fase es completamente independiente de las demás fases del plan. El scan confirma que `HomeGarageSection` ya lee de `VehicleCubit` en el path de datos exitosos (líneas 20–24 del archivo actual); esta fase solo elimina el fallback al prop stale y completa el manejo de estados no-Data.

El orden recomendado en la síntesis (Fase 5 → Fase 3 → Fase 4) es por conveniencia de riesgo creciente, no por dependencia técnica. Esta fase puede ejecutarse antes o después de Fases 1, 2, 3, 4 sin conflictos.

---

## Ejecucion recomendada (nivel rg-exec: lite)

**Nivel: lite**

**Por qué lite:** Refactor de estado puro en 3 archivos de producción (`home_state.dart`, `home_cubit.dart`, `home_scaffold.dart`) más `home_garage_section.dart` (eliminación de prop + manejo de estados). Sin nueva UI diseñable, sin contratos de API, sin migraciones de base de datos, sin code-gen (`HomeLoaded` es una sealed class manual — no freezed, no build_runner). Completamente reversible con un `git revert`. Los consumidores están mapeados explícitamente con números de línea verificados por grep. 1 implementador + 1 ronda de auditor es suficiente para el riesgo. El único riesgo no trivial (crash en Initial/Loading) queda cubierto por los widget tests del paso 6.

**Comando sugerido:**
```
/rg-exec docs/plans/archive-vehicle-soft-delete/phases/phase-05-flutter-vehiculo-principal-siempre-coherente.md --mode lite
```
