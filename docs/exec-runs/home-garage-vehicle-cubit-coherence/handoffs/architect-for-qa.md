> Slim handoff — read this before handoffs/architect.md

# Architect → QA

**Fase:** home-garage-vehicle-cubit-coherence

---

## Comandos de verificación

```bash
# 1. Lint: sin errores ni warnings nuevos en home
dart analyze lib/features/home/

# 2. Pre-flight check: ninguna referencia a mainVehicle en la capa de presentación
grep -rn 'mainVehicle' lib/features/home/presentation/
# Esperado: 0 resultados

# 3. Constructor limpio
grep -rn 'HomeGarageSection(' lib/features/home/
# Esperado: solo `const HomeGarageSection()` sin parámetros extra

# 4. Tests
flutter test test/features/home/
# Esperado: todos pasan (4 cubit + 6 widget = 10 tests)
```

---

## Criterios de aceptación (trazabilidad contra PRD §5)

| CA | Verificación |
|----|-------------|
| CA-1 Constructor limpio | `grep -rn 'vehicle:' lib/features/home/presentation/widgets/home_scaffold.dart` → 0 |
| CA-2 `HomeLoaded` sin `mainVehicle` | `grep -rn 'mainVehicle' lib/features/home/presentation/` → 0 |
| CA-3 Estado `Initial` no crashea | TC-garage-1 pasa; finder `HomeGarageCard` → 0 widgets |
| CA-4 Estado `Loading` no crashea | TC-garage-2 pasa; finder `HomeGarageCard` → 0 widgets |
| CA-5 Reactividad sin HTTP | TC-garage-6 pasa; `HomeCubit.loadHomeData` no invocado |
| CA-6 Sin vehículos muestra vacío | TC-garage-5 pasa; `HomeEmptyGarageCard` visible |
| CA-7 `dart analyze` verde | Sin errores en `lib/features/home/` |
| CA-8 `flutter test` verde | 10/10 tests pasan |
| CA-9 `HomeScaffold` sin warnings | `dart analyze` no reporta nada en `home_scaffold.dart` |

---

## Guardrails que QA debe confirmar

- `HomeData` y `HomeDto` NO fueron modificados (`grep -rn 'mainVehicle' lib/features/home/domain/` debe seguir reportando resultados en `home_data.dart`)
- Ningún archivo fuera de `lib/features/home/presentation/` y `test/features/home/` fue modificado
- El import `VehicleModel` en `home_garage_section.dart` permanece (es necesario para el type param `Data<List<VehicleModel>>`)

> Full detail: handoffs/architect.md
