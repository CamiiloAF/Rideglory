# REVIEW CHECKLIST — home-garage-vehicle-cubit-coherence

_Generated: 2026-06-17T22:24:25Z_

Pasos manuales antes de commitear:

## Verificaciones automáticas (ya hechas por QA)
- [x] `grep -rn 'mainVehicle' lib/features/home/presentation/cubit/home_state.dart` → 0 resultados
- [x] `grep -rn 'vehicle:' lib/features/home/presentation/widgets/home_scaffold.dart` → 0 resultados
- [x] `HomeGarageSection` constructor es `const HomeGarageSection({super.key})`
- [x] `dart analyze lib/features/home/` → 0 errores, 0 warnings
- [x] `flutter test test/features/home/` → 14/14 PASS
- [x] `HomeData` y `HomeDto` conservan `mainVehicle` (contratos de red intactos)
- [x] Analytics `data.mainVehicle` en `home_cubit.dart:31` conservada

## Verificaciones manuales en dispositivo

1. **Estado frío (VehicleCubit.initial):** Abrir la app → pantalla Home muestra placeholder gris de 200px en la sección de garaje, sin crash ni salto de layout.
2. **Carga de vehículos:** Una vez que `VehicleCubit` carga → `HomeGarageCard` aparece con el vehículo principal correcto.
3. **Garaje vacío:** Sin vehículos → `HomeEmptyGarageCard` visible sin crash.
4. **Reactividad — cambio de principal:** Cambiar vehículo principal desde Garaje → volver a Home → card refleja el nuevo principal sin pull-to-refresh.
5. **Reactividad — archivado:** Archivar el vehículo principal desde Garaje → volver a Home → sección se actualiza automáticamente.

## Item de acción pendiente (no blocker)

- [ ] Confirmar si `integration_test/test_bundle.dart` es auto-generado por `patrol generate`. Si lo es, el diff es normal y no requiere acción. Si es manual, validar que la eliminación de 4 grupos de integration tests es intencional.
