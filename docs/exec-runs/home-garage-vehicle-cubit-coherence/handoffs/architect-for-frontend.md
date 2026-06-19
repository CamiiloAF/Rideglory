> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend

**Fase:** home-garage-vehicle-cubit-coherence  
**Nivel:** lite — 1 implementador, 1 auditor, sin Pencil.

---

## Qué cambiar y por qué

`HomeGarageSection` tiene un prop `vehicle: VehicleModel?` que actúa como fallback cuando `VehicleCubit` no tiene datos. Eso crea estado duplicado: `HomeCubit` y `VehicleCubit` pueden divergir. La solución es eliminar ese prop y hacer que la sección maneje todos los estados de `VehicleCubit` directamente.

---

## Archivos a modificar (en orden)

### 1. `lib/features/home/presentation/cubit/home_state.dart`

Eliminar:
- La línea `final VehicleModel? mainVehicle;`
- El parámetro `this.mainVehicle,` del constructor de `HomeLoaded`
- El import de `VehicleModel` (quedará huérfano)

Resultado: `HomeLoaded({required this.upcomingEvents})` únicamente.

### 2. `lib/features/home/presentation/cubit/home_cubit.dart`

Tres sitios con `HomeLoaded(mainVehicle: ..., upcomingEvents: ...)` → cambiar a `HomeLoaded(upcomingEvents: ...)`:
- Línea ~37 (en `loadHomeData`)
- Línea ~52 (en `updateEvent`)
- Línea ~63 (en `removeEvent`)

Eliminar el import `package:rideglory/features/vehicles/domain/models/vehicle_model.dart` si queda huérfano (verificar con `dart analyze`). La línea de Analytics `data.mainVehicle != null ? 1 : 0` permanece — usa `HomeData`, no `HomeLoaded`.

### 3. `lib/features/home/presentation/widgets/home_scaffold.dart`

Cambiar:
```dart
child: HomeGarageSection(vehicle: state.mainVehicle),
```
→
```dart
child: const HomeGarageSection(),
```

### 4. `lib/features/home/presentation/widgets/home_garage_section.dart`

- Eliminar `final VehicleModel? vehicle;` y el parámetro del constructor
- Cambiar constructor a `const HomeGarageSection({super.key})`
- Eliminar import `VehicleModel` (ya se usa solo para el type param genérico `Data<List<VehicleModel>>` — conservar ese import)
- Reemplazar la lógica de fallback con manejo explícito de todos los estados de `VehicleCubit`:

```dart
// Dentro de build():
final vehicleState = context.watch<VehicleCubit>().state;

// Initial o Loading → placeholder sin crash
if (vehicleState is Initial<List<VehicleModel>> ||
    vehicleState is Loading<List<VehicleModel>>) {
  return const _HomeGaragePlaceholder();
}

// Data → buscar principal
VehicleModel? mainVehicle;
if (vehicleState is Data<List<VehicleModel>>) {
  mainVehicle = vehicleState.data.where((v) => v.isMainVehicle).firstOrNull ??
      vehicleState.data.firstOrNull;
}
// Error / Empty / Data vacío → mainVehicle == null → HomeEmptyGarageCard
```

- Crear clase `_HomeGaragePlaceholder` en el mismo archivo (es privada, no viola "un widget por archivo" porque solo existe aquí como detalle de implementación, O extráela a su propio archivo `home_garage_placeholder.dart` en el mismo directorio si prefieres seguir la regla estricta de un widget público por archivo — el auditor decidirá).

Placeholder recomendado:
```dart
class _HomeGaragePlaceholder extends StatelessWidget {
  const _HomeGaragePlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
```

---

## Archivos a modificar en tests

### 5. `test/features/home/presentation/cubit/home_cubit_test.dart`

TC-home-2 verifica `state.mainVehicle == mockVehicle` — ese campo ya no existe. Cambiar el predicado a:
```dart
state is HomeLoaded && state.upcomingEvents.length == 1,
```

### 6. `test/features/home/presentation/widgets/home_garage_section_test.dart` (NUEVO)

Crear directorio `test/features/home/presentation/widgets/` y el archivo con 6 widget tests:

- **TC-garage-1 Initial:** `VehicleCubit` en `Initial` → placeholder visible, `HomeGarageCard` ausente.
- **TC-garage-2 Loading:** `VehicleCubit` en `Loading` → placeholder visible, `HomeGarageCard` ausente.
- **TC-garage-3 Data con principal:** `VehicleCubit` en `Data([vehicleConIsMainVehicle:true, otro])` → `HomeGarageCard` visible con el vehículo marcado.
- **TC-garage-4 Data sin principal marcado:** `VehicleCubit` en `Data([vehicleSinIsMain])` → `HomeGarageCard` visible con `firstOrNull`.
- **TC-garage-5 Data vacío / Empty:** `VehicleCubit` en `Data([])` o `Empty` → `HomeEmptyGarageCard` visible.
- **TC-garage-6 Reactividad:** `VehicleCubit` emite dos estados (`Data([A])`, luego `Data([B con isMain:true])`) → UI muestra B sin que `HomeCubit.loadHomeData()` sea invocado (verificar con mock de `HomeCubit`).

Usar `MockVehicleCubit` (mocktail), `BlocProvider.value`, `pump` y `pumpAndSettle`.

---

## Constraints del PRD que el implementador DEBE respetar

- `HomeLoaded` es una sealed class manual, **no freezed** — no correr `build_runner`.
- El placeholder debe tener `height: 200` (o la altura real del card si es medible) para evitar layout jump.
- Ningún texto nuevo en el placeholder → no se necesitan claves l10n nuevas.
- `dart analyze lib/features/home/` en verde antes de escribir los tests.
- `flutter test test/features/home/` en verde al final.

---

## Checklist de aceptación rápida

- [ ] `grep -rn 'mainVehicle' lib/features/home/presentation/` → 0 resultados
- [ ] `grep -rn 'vehicle:' lib/features/home/presentation/widgets/home_scaffold.dart` → 0 resultados
- [ ] `HomeGarageSection` constructor es `const HomeGarageSection({super.key})`
- [ ] `dart analyze lib/features/home/` verde
- [ ] `flutter test test/features/home/` verde (todos los 6 tests nuevos + 4 existentes)

> Full detail: handoffs/architect.md
