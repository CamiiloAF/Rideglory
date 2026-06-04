> Slim handoff — lee esto antes de docs/exec-runs/tecnomecanica-rtm-ph1/handoffs/architect.md

# Architect → QA — tecnomecanica-rtm-ph1

**Fecha:** 2026-06-04T16:00:53Z

## Comandos de verificación

```bash
# 1. Análisis estático
dart analyze

# 2. Tests completos (no debe haber ninguna regresión)
flutter test

# 3. Code-gen sin conflictos
dart run build_runner build --delete-conflicting-outputs --force-jit

# 4. L10n
flutter gen-l10n
```

## Checklist de criterios de aceptación

| # | Verificación | Comando / método |
|---|--------------|-----------------|
| 1 | Suite SOAT verde sin editar assertions | `flutter test test/features/soat/` → 100% pass |
| 2 | `dart analyze` sin nuevos warnings | `dart analyze` → solo 2 lints preexistentes de `api_base_url_resolver.dart` |
| 3 | `build_runner` sin conflictos | ver salida sin errores; `soat_dto.g.dart` (soat/) no cambia de forma |
| 4 | Cero literales hardcodeados en nuevo card | `grep -n "'Vigente'\|'Por vencer'\|'Vence " lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` → 0 |
| 5 | Cero `getIt` en el body del card | `grep -n "getIt" lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` → 0 en widget body |
| 6 | Cero `bool _isLoading` en card | `grep -n "_isLoading" lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` → 0 |
| 7 | Abstracción compila | `flutter build apk --debug` sin errores (o `flutter analyze`) |
| 8 | Colisión eliminada | `grep -rn "class SoatModel" lib/` → exactamente 1 resultado |
| 9 | `VehicleSoatFormData` no implementa `VehicleDocumentModel` | `grep -n "VehicleSoatFormData" lib/features/vehicles/domain/models/vehicle_soat_form_data.dart` → no contiene `implements VehicleDocumentModel` |
| 10 | `SoatStatus` preservado | `grep -rn "enum SoatStatus" lib/` → 1 resultado en `soat/domain/models/soat_model.dart` |
| 11 | `VehicleSoatCard` eliminado | `grep -rn "VehicleSoatCard(" lib/` → 0 resultados |
| 12 | `VehicleDocumentCard` instanciado en `vehicle_detail_view.dart` | `grep -n "VehicleDocumentCard" lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` → ≥ 1 resultado |
| 13 | `home_garage_soat_badge.dart` intacto | `git diff lib/features/home/presentation/widgets/home_garage_soat_badge.dart` → sin cambios |
| 14 | Pattern B intacto (soat/) | `grep -n "class SoatDto extends SoatModel" lib/features/soat/data/dto/soat_dto.dart` → 1 resultado |
| 15 | Analytics SOAT intactos | `grep -n "soat_status_viewed\|soat_updated\|soat_manual_saved\|soat_deleted" lib/features/soat/presentation/cubit/soat_cubit.dart` → mismos eventos que en main |

## Tests existentes a proteger (no modificar assertions)

- `test/features/soat/data/parser/soat_parser_test.dart`
- `test/features/soat/domain/models/soat_model_test.dart`
- `test/features/soat/domain/usecases/scan_soat_usecase_test.dart`
- `test/features/soat/presentation/cubit/soat_cubit_test.dart`
- `test/features/vehicles/presentation/cubit/vehicle_form_cubit_soat_test.dart`

## Regresiones que terminan la fase

- Cualquier assertion existente en los tests anteriores que falle → regresión, la fase no cierra
- `dart analyze` con warnings nuevos (excluyendo los 2 de `api_base_url_resolver.dart`)
- `SoatDto.fromJson` que cambia la forma de deserialización (verificar `soat_dto.g.dart` en `soat/` idéntico a main)

> Full detail: docs/exec-runs/tecnomecanica-rtm-ph1/handoffs/architect.md
