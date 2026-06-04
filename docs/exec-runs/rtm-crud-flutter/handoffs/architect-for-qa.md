> Slim handoff — read this before docs/exec-runs/rtm-crud-flutter/handoffs/architect.md

# Architect → QA: rtm-crud-flutter

## Comandos de validación

```bash
dart analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

## Criterios de aceptación — checklist de verificación

### CA-1: Payload vía DTO
```bash
grep -r "Map<String, dynamic>" lib/features/tecnomecanica/ | grep -v ".g.dart" | grep -v "//\|*"
```
No debe encontrar construcción de Map a mano como body de escritura. Solo `CreateTecnomecanicaRequestDto(...).toJson()`.

### CA-2: Pattern B
- `TecnomecanicaDto extends TecnomecanicaModel` — grep `class TecnomecanicaDto extends`
- `TecnomecanicaModel implements VehicleDocumentModel` — grep `implements VehicleDocumentModel`
- `tecnomecanica_dto.g.dart` existe y compila sin conflictos

### CA-3: Cubit sobre base genérica
- `class TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` — grep
- Test unitario: repo fake que devuelve `Right(null)` → cubit emite `ResultState.empty()`

### CA-4: Registrar
- Test: campos válidos → `save()` → `ResultState.data`
- Verificar que el body enviado usa `CreateTecnomecanicaRequestDto.toJson()`

### CA-5: Ver
- Test: `load()` con repo fake `Right(TecnomecanicaModel(...))` → `ResultState.data`
- `documentStatus` derivado de mixin (umbral 30 días, `<0 → expired`)

### CA-6: Editar
- Test: `TecnomecanicaManualCapturePage` recibe `existingRtm` → campos precargados
- Save → `ResultState.data` con nuevos valores

### CA-7: Borrar
- Test: `delete()` con repo fake `Right(unit)` → `ResultState.empty()`
- UI: `ConfirmationDialog` presente en el flujo (verificar widget test o grep)

### CA-8: Analytics
```bash
grep -n "tecnomecanica_" lib/core/services/analytics/analytics_events.dart
```
- `tecnomecanica_status_viewed.length <= 40` ✓ (26 chars)
- `tecnomecanica_manual_saved.length <= 40` ✓ (26 chars)
- `tecnomecanica_updated.length <= 40` ✓ (21 chars)
- `tecnomecanica_deleted.length <= 40` ✓ (21 chars)

### CA-9: Exención no bloqueante
- Test: vehículo con `purchaseDate` reciente (<2 años) → `TecnomecanicaExemptionNotice` presente
- El botón "Guardar" sigue habilitado (`onPressed != null`)

### CA-10: Sin OCR
```bash
grep -rn "autofill_banner\|ScanSoat\|UploadCubit\|image_picker\|file_picker\|pdfx\|ml_kit\|mlkit\|firebase_ml" lib/features/tecnomecanica/
```
Resultado esperado: sin matches.

### CA-11: Copy legal propio
```bash
grep -A1 "tecnomecanica_expired_warning" lib/l10n/app_es.arb
grep -A1 "soat_expired_warning" lib/l10n/app_es.arb
```
Los valores no deben ser idénticos.

### CA-12: Clean Architecture + estándares
```bash
grep -rn "BuildContext\|Widget\|StatelessWidget\|StatefulWidget" lib/features/tecnomecanica/domain/ lib/features/tecnomecanica/data/
```
Resultado esperado: sin matches.

```bash
grep -rn "Widget _build\b" lib/features/tecnomecanica/
```
Resultado esperado: sin matches (prohibido).

```bash
grep -rn "\"[A-Za-z ]\{3,\}\"" lib/features/tecnomecanica/presentation/ | grep -v ".dart:.*//\|l10n\|AppColors\|const\|key\|name:\|path:\|field\|label\|hint\|json"
```
Auditoría manual de strings hardcodeados.

### CA-13: Regresión SOAT
```bash
flutter test test/features/soat/ 2>/dev/null || flutter test  # todos los tests existentes verdes
grep -c '"soat_' lib/l10n/app_es.arb  # mismo número que antes
grep -c 'soat' lib/core/services/analytics/analytics_events.dart  # mismo número que antes
```

## Tests a escribir (mínimos)

| Test | Tipo | Archivo |
|------|------|---------|
| `TecnomecanicaCubit.load()` → `empty()` cuando repo devuelve `Right(null)` | unit | `test/features/tecnomecanica/cubit/tecnomecanica_cubit_test.dart` |
| `TecnomecanicaCubit.load()` → `data()` cuando repo devuelve `Right(model)` | unit | mismo |
| `TecnomecanicaCubit.save()` → `data()` con modelo actualizado | unit | mismo |
| `TecnomecanicaCubit.delete()` → `empty()` | unit | mismo |
| `VehicleDocumentExpiry.documentStatus` expired/expiringSoon/valid | unit | `test/features/vehicle_documents/` (puede ya existir) |

> Full detail: docs/exec-runs/rtm-crud-flutter/handoffs/architect.md
