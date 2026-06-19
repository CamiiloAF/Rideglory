# Fase 6 — QA, strings es-CO y documentación

**Timestamp:** 2026-06-19T20:13:15Z
**Slug:** `ocr-tarjeta-propiedad-autofill`
**Depende de:** Fase 5
**Nivel rg-exec:** lite

---

## Objetivo

Cerrar el feature con calidad de producción: todos los textos visibles del flow de scan de tarjeta de propiedad en `app_es.arb`, permisos de cámara/galería verificados en ambas plataformas, suite de tests (`flutter test`) y análisis estático (`dart analyze`) pasando sin errores, sin regresión en el feature SOAT, y `docs/features/vehicles.md` actualizado para reflejar el nuevo sub-flow.

---

## Alcance (entra / no entra)

### Entra
- Añadir exactamente 5 claves nuevas en `lib/l10n/app_es.arb` (ver Paso 2 para lista y verificación de no-colisión con claves existentes):
  - `vehicle_scan_loading` — texto del loader mientras OCR procesa
  - `vehicle_scan_success` — snackbar de éxito tras prefill
  - `vehicle_scan_error_low_confidence` — snackbar cuando `shouldPrefill = false` (pocos campos con confianza alta)
  - `vehicle_scan_error_technical` — snackbar cuando el OCR lanza excepción técnica
  - `vehicle_scan_sheet_instruction` — instrucción "cara frontal" mostrada en `DocumentSourceSheet` debajo del título, antes de las opciones
- Correr `flutter gen-l10n` para regenerar `app_localizations.dart` y `app_localizations_es.dart`
- Verificar (no añadir si ya existen) permisos iOS y Android para cámara y galería
- Ejecutar `dart analyze` y confirmar cero warnings en el código nuevo del feature
- Ejecutar `flutter test test/features/vehicles/data/parser/` y confirmar ≥6 fixtures pasan
- Ejecutar `flutter test test/features/soat/` y confirmar cero regresiones
- Actualizar `docs/features/vehicles.md` con una sección sobre el flow de scan de tarjeta de propiedad
- Verificar con grep (ver conjunto canónico en Paso 4) que cero strings hardcodeados en español quedan en el código nuevo del flow de scan

### No entra
- Lógica nueva de ningún tipo (ningún archivo `.dart` distinto de `app_es.arb` y `docs/features/vehicles.md`)
- Migración de SOAT a usar las nuevas claves ARB (es deuda técnica futura)
- Actualización de permisos si ya existen (solo confirmar; si faltan, añadir)
- Tests nuevos (los tests de parser se escribieron en Fase 3)
- Cambios en `rideglory-api`

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 1 — Verificar permisos de plataforma

**iOS** (`ios/Runner/Info.plist`):

Confirmar que estas dos claves ya existen (el feature SOAT las declara):
```
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
```

Estado conocido (verificado en scan de repo): **ambas existen** con texto referenciando SOAT. Actualizar el texto de `NSCameraUsageDescription` para mencionar también la tarjeta de propiedad:

- Actual: `"Rideglory necesita acceso a la cámara para tomar una foto y escanear tu SOAT."`
- Nuevo: `"Rideglory necesita acceso a la cámara para tomar fotos y escanear documentos de tu vehículo."`

**Android** (`android/app/src/main/AndroidManifest.xml`):

Confirmar que estos tres permisos ya existen:
- `android.permission.CAMERA`
- `android.permission.READ_MEDIA_IMAGES`
- `android.permission.READ_EXTERNAL_STORAGE` (con `maxSdkVersion="32"`)

Estado conocido (verificado en scan de repo): **los tres existen**. No se requiere ningún cambio en Android.

### Paso 2 — Verificar no-colisión de keys antes de insertar en `app_es.arb`

Antes de editar el ARB, confirmar que las 5 claves nuevas no existen ya en el archivo:

```bash
grep -n 'vehicle_scan_loading\|vehicle_scan_success\|vehicle_scan_error_low_confidence\|vehicle_scan_error_technical\|vehicle_scan_sheet_instruction' lib/l10n/app_es.arb
```

La salida esperada es **vacía**. Si alguna clave aparece, significa que fue insertada previamente (p. ej., en un intento parcial de esta fase) — no duplicar; editar el valor si fuera incorrecto.

También confirmar que las claves existentes `vehicle_form_scan_title` y `vehicle_form_scan_subtitle` (líneas 665-666) **no se tocan ni se duplican**. Son claves distintas del banner ya implementado en fases anteriores y `flutter gen-l10n` rechazará con error cualquier clave duplicada.

### Paso 3 — Añadir claves a `lib/l10n/app_es.arb`

Ubicar el bloque existente de claves `vehicle_form_scan_*` (líneas 665-666 del ARB) e insertar las nuevas claves inmediatamente después, agrupadas bajo el mismo bloque de scan para mantener coherencia:

```json
"vehicle_scan_loading": "Leyendo tarjeta de propiedad…",
"vehicle_scan_sheet_instruction": "Fotografía la cara frontal de la tarjeta de propiedad",
"vehicle_scan_success": "Campos completados desde la tarjeta de propiedad",
"vehicle_scan_error_low_confidence": "No pudimos leer suficientes campos, ingresa los datos manualmente",
"vehicle_scan_error_technical": "Error al leer la tarjeta, intenta de nuevo"
```

Convención de naming seguida:
- Prefijo `vehicle_scan_` (feature + sub-dominio de scan)
- Sentence case en español colombiano
- Verbos en imperativo solo en instrucciones directas al usuario

### Paso 4 — Correr `flutter gen-l10n`

```bash
flutter gen-l10n
```

Esto regenera `lib/l10n/app_localizations.dart` y `lib/l10n/app_localizations_es.dart`. Verificar que los nuevos getters aparecen en los archivos generados antes de continuar.

### Paso 5 — Verificar ausencia de strings hardcodeados

**Conjunto canónico de archivos del flow de scan a verificar** (referenciado también en el Criterio de aceptación 3):

```
lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart
lib/features/vehicles/presentation/form/vehicle_form_body.dart
lib/features/vehicles/presentation/cubit/vehicle_scan_cubit.dart
lib/shared/widgets/modals/document_source_sheet.dart
```

Ejecutar el siguiente grep sobre estos archivos:

```bash
grep -rn -E "(['\"])[A-ZÁÉÍÓÚÑa-záéíóúñ ]{4,}\1" \
  lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart \
  lib/features/vehicles/presentation/form/vehicle_form_body.dart \
  lib/features/vehicles/presentation/cubit/vehicle_scan_cubit.dart \
  lib/shared/widgets/modals/document_source_sheet.dart
```

**Nota importante:** el regex detecta strings entre comillas simples o dobles (el codebase fuerza `prefer_single_quotes`, por lo que la mayoría aparecerán con `'`). La salida puede incluir falsos positivos conocidos que el revisor debe filtrar manualmente:
- Imports (`'package:...`, `'dart:...`)
- Nombres de ruta (p. ej., `'vehicleForm'`)
- Claves de `context.l10n.<clave>` (el nombre de la clave en sí no es un string de UI)
- Valores de `VehicleFormFields.<campo>` usados como argumentos técnicos

Tras filtrar estos falsos positivos, **no debe quedar ningún match** que sea un literal de texto visible para el usuario. Si queda alguno, reemplazarlo con `context.l10n.<clave>` y añadir la clave al ARB si no existe. No confiar únicamente en "salida vacía sin filtrar"; inspeccionar cada match.

### Paso 6 — Correr `dart analyze`

```bash
dart analyze lib/features/vehicles/ lib/shared/widgets/modals/document_source_sheet.dart
```

Cero warnings en el código nuevo. Los únicos lint suprimidos permitidos son los que ya existían antes de esta fase (p. ej., `api_base_url_resolver.dart` con `shouldUseLocalApi` — no tocar).

### Paso 7 — Correr suite de tests del parser

```bash
flutter test test/features/vehicles/data/parser/property_card_parser_test.dart --reporter=expanded
```

Debe reportar ≥6 tests passing. Si algún test falla, el fallo viene de Fase 3 — no corregir lógica de parser en esta fase; escalar a re-ejecución de Fase 3.

### Paso 8 — Correr suite de tests de SOAT (no-regresión)

```bash
flutter test test/features/soat/ --reporter=expanded
```

Todos los tests deben pasar sin modificaciones. Si hay una regresión, identificar el archivo de la fase que lo causó (probable: un import circular o un cambio en `OcrService` / `OcrResult`) y revertir solo ese cambio.

### Paso 9 — Actualizar `docs/features/vehicles.md`

Añadir una nueva sección **"Scan de tarjeta de propiedad (OCR autofill)"** al final del documento, o al bloque de sub-features según la estructura existente. La sección debe cubrir:

1. Trigger del flow: botón banner `VehicleScanBanner` en `VehicleFormBody`
2. `DocumentSourceSheet` — opciones cámara / galería; instrucción de cara frontal
3. `VehicleScanCubit` — estados: `initial` → `loading` → `data(PropertyCardExtraction)` / `error`; `BlocProvider` local en `VehicleFormPage`
4. Prefill: `BlocListener` en `VehicleFormBody` llama `VehicleFormCubit.prefillFromScan()` → `didChange()` en campos con confianza `high` o `medium`
5. Telemetría: `propertyScanAttempted`, `propertyScanSuccess` (con `fieldsExtractedCount`), `propertyScanFailed` (con `failureReason`)
6. Campos prefillados: `brand`, `model`, `year` (como `String`), `licensePlate`, `vin`
7. Constante de umbral: `kMinHighConfidenceFields = 2` en `PropertyCardExtraction` — puede ajustarse con datos reales
8. Deuda técnica: `SoatAddDocumentSheet` y `SoatVehicleOptionsSheet` no migran a `DocumentSourceSheet` en v1

---

## Archivos a crear/modificar (rutas reales)

| Acción | Ruta | Qué cambia |
|--------|------|------------|
| Modificar | `lib/l10n/app_es.arb` | Añadir 5 claves `vehicle_scan_*` para loader, instrucción de cara frontal, snackbars éxito/error-bajo-confianza/error-técnico; no tocar ni duplicar `vehicle_form_scan_title`/`vehicle_form_scan_subtitle` existentes |
| Modificar | `ios/Runner/Info.plist` | Actualizar texto de `NSCameraUsageDescription` para mencionar documentos de vehículo en general (no solo SOAT) |
| Modificar (auto-generado) | `lib/l10n/app_localizations.dart` | Regenerado por `flutter gen-l10n`; nuevos getters para las 5 claves |
| Modificar (auto-generado) | `lib/l10n/app_localizations_es.dart` | Regenerado por `flutter gen-l10n`; traducciones de las 5 claves |
| Modificar | `docs/features/vehicles.md` | Nueva sección de scan de tarjeta de propiedad |

**Total: 2 archivos de código fuente editados manualmente + 2 archivos auto-generados + 1 documento.**

---

## Contratos / API rideglory-api

Ninguno. Esta fase es 100% Flutter-only. Sin cambios de backend.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptacion

1. `lib/l10n/app_es.arb` contiene exactamente las 5 claves nuevas `vehicle_scan_loading`, `vehicle_scan_sheet_instruction`, `vehicle_scan_success`, `vehicle_scan_error_low_confidence`, `vehicle_scan_error_technical` con valores en español colombiano.

2. Las claves `vehicle_form_scan_title` y `vehicle_form_scan_subtitle` (líneas 665-666 del ARB) permanecen intactas y no están duplicadas. `flutter gen-l10n` corre sin errores de clave duplicada y los getters para las 5 claves nuevas aparecen en `app_localizations_es.dart`.

3. El siguiente grep sobre el conjunto canónico de archivos del flow de scan (los mismos 4 archivos del Paso 5) no produce ningún match de texto de UI hardcodeado tras filtrar los falsos positivos conocidos (imports, rutas, claves l10n, nombres de campo técnicos):

   ```bash
   grep -rn -E "(['\"])[A-ZÁÉÍÓÚÑa-záéíóúñ ]{4,}\1" \
     lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart \
     lib/features/vehicles/presentation/form/vehicle_form_body.dart \
     lib/features/vehicles/presentation/cubit/vehicle_scan_cubit.dart \
     lib/shared/widgets/modals/document_source_sheet.dart
   ```

   Resultado esperado: todos los matches corresponden a imports, claves técnicas o nombres de campo — ninguno es un literal de texto visible para el usuario. El revisor debe inspeccionar cada match; no basta con que la salida sea vacía sin verificar.

4. `ios/Runner/Info.plist` contiene `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` con texto presente. El texto de `NSCameraUsageDescription` menciona documentos de vehículo (no solo SOAT).

5. `android/app/src/main/AndroidManifest.xml` contiene `android.permission.CAMERA` y `android.permission.READ_MEDIA_IMAGES`.

6. `dart analyze lib/features/vehicles/ lib/shared/widgets/modals/document_source_sheet.dart` reporta cero errors y cero warnings sobre código nuevo (no pre-existente).

7. `flutter test test/features/vehicles/data/parser/property_card_parser_test.dart --reporter=expanded` pasa con ≥6 fixtures (resultado: `All tests passed`).

8. `flutter test test/features/soat/ --reporter=expanded` pasa sin ninguna modificación en los archivos de test o de dominio SOAT.

9. `docs/features/vehicles.md` tiene una sección nueva que documenta el flow de scan de tarjeta de propiedad con los 8 puntos especificados (trigger, sheet, cubit, prefill, telemetría, campos, umbral, deuda técnica).

---

## Pruebas

### Unitarias
- **`flutter test test/features/vehicles/data/parser/`** — suite creada en Fase 3; esta fase solo la ejecuta para confirmar que pasa. No se añaden fixtures nuevos salvo que un bug de integración se descubra durante el grep de strings.
- **`flutter test test/features/soat/`** — suite existente; se corre como gate de no-regresión. No se modifica.

### Widget / integración
No se escriben tests nuevos en esta fase. La verificación de la UI del banner y del prefill se hace manualmente en Fase 5.

### Verificación manual de strings
El grep del Paso 5 (con inspección manual de cada match) reemplaza un test automatizado de strings; es suficiente para una fase lite de este alcance.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R1 | Un string hardcodeado en el `BlocListener` de `VehicleFormBody` (snackbar) se escapó en Fase 5 | Media | Bajo | El grep del Paso 5 lo detecta; corrección es reemplazar el literal por `context.l10n.vehicle_scan_*` |
| R2 | `flutter gen-l10n` falla por clave duplicada (inserción accidental de `vehicle_form_scan_title` o `vehicle_form_scan_subtitle`) | Baja | Bajo | El Paso 2 exige verificar no-colisión con grep antes de insertar |
| R3 | `flutter gen-l10n` falla por una clave ARB con formato JSON incorrecto (comillas anidadas, coma faltante) | Baja | Bajo | Validar JSON del ARB antes de correr gen-l10n con un linter o `dart run build_runner build` |
| R4 | `flutter test test/features/soat/` descubre una regresión introducida por un cambio en `OcrService` o `OcrResult` durante las fases anteriores | Baja | Medio | Identificar el commit/archivo de la fase causante; el fix es aislado (los contratos `OcrService` y `OcrResult` son de solo lectura en este feature) |
| R5 | El grep del Paso 5 produce falsos positivos que confunden al revisor | Media | Bajo | Falsos positivos conocidos documentados en el Paso 5; el revisor debe inspeccionarlos uno a uno, no delegar en "salida vacía" |
| R6 | `dart analyze` reporta un warning en código generado (`.g.dart` o `.freezed.dart`) | Baja | Ninguno | Los archivos generados están excluidos en `analysis_options.yaml`; ignorar si el path del warning es `*.g.dart` o `*.freezed.dart` |
| R7 | El texto de `NSCameraUsageDescription` actualizado requiere re-aprobación de Apple en revisión de App Store | Baja | Bajo | El cambio es aditivo (amplía el scope del permiso, no lo restringe); Apple acepta mensajes genéricos de documentos |

---

## Dependencias (fases prerequisito y por qué)

| Fase | Por qué es prerrequisito |
|------|--------------------------|
| Fase 5 — Presentación: banner activo + prefill | Esta fase verifica strings en el código de UI (banner, sheet, snackbars) que se implementan en Fase 5. Sin Fase 5, los greps del Paso 5 no tienen código que analizar y los tests de presentación no existen. |
| Fases 3 y 4 (transitivas via Fase 5) | Los tests del parser (`test/features/vehicles/data/parser/`) se crean en Fase 3; esta fase solo los ejecuta. Los eventos de telemetría verificados en Fase 4 ya tienen sus strings en `AnalyticsEvents` — esta fase no los toca. |

---

## Ejecucion recomendada (nivel rg-exec: lite)

**Nivel: lite**

**Por qué lite:** Fase de verificación y l10n. Sin lógica nueva. Los cambios son mecánicos y completamente reversibles:

1. Verificar no-colisión de keys (grep de 1 línea) y añadir 5 entradas de texto a un archivo JSON (`app_es.arb`) — el diff es ≤10 líneas.
2. Actualizar 1 cadena en `Info.plist`.
3. Correr `flutter gen-l10n` (herramienta determinista sin efectos secundarios).
4. Ejecutar grep con inspección manual, `dart analyze` y `flutter test` como gates de calidad.
5. Añadir una sección de texto a `docs/features/vehicles.md`.

El blast radius es exclusivamente el feature recién construido en las fases 1-5; ningún sistema existente (SOAT, eventos, autenticación) se ve afectado. Si algo falla, el rollback es un `git restore` de los archivos modificados. No hay code-gen de modelos, no hay DI changes, no hay contratos de API.

El implementador puede ejecutar esta fase completa en una sola pasada, confirmando cada criterio de aceptación en orden y parando solo si el `dart analyze` o el `flutter test test/features/soat/` reporta un fallo (en ese caso escalar a la fase causante, no intentar corregir la lógica aquí).
