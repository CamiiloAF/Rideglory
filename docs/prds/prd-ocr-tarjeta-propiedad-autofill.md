# PRD — Autocompletar vehículo escaneando la tarjeta de propiedad (OCR on-device)

**Tipo:** Feature (mejora UX sobre el formulario de vehículo)
**Prioridad:** Media (acelera el alta de vehículos; no bloqueante)
**Estimado:** 1 iteración corta (~2–3 días)
**Fecha de creación:** 2026-06-04
**Reutiliza:** toda la infraestructura OCR del feature SOAT (ver `prd-ocr-soat-autofill.md`).

---

## 1. Problema

Al crear/editar un vehículo, el rider escribe a mano marca, línea, año, placa, VIN, color y cilindraje. El formulario ya tiene un banner **"Escanear tarjeta de propiedad"** (`VehicleScanBanner`) con la promesa *"Autocompleta marca, modelo, año, placa y VIN automáticamente"*, pero su `onTap` es un `// TODO: implement scan property card` — está muerto.

La **tarjeta de propiedad / licencia de tránsito** colombiana es un documento RUNT de formato **muy estable** (etiquetas fijas: PLACA, MARCA, LÍNEA, MODELO, CILINDRAJE, COLOR, VIN, Nº MOTOR, Nº CHASIS…), ideal para un parser por reglas.

Además, ya existe en el repo **toda la cadena de OCR on-device** construida para el SOAT (`OcrService` + ML Kit, `OcrResult`/`OcrBlock`, patrón parser, patrón use case, telemetría anónima), por lo que el costo real de esta feature es **solo el parser nuevo + el wiring**.

---

## 2. Objetivo

Que el rider tome una foto (o elija de galería) de la tarjeta de propiedad y el formulario de vehículo se **prellene** con los campos extraídos. El usuario siempre revisa antes de guardar.

**No-objetivos:**
- No reemplaza la entrada manual; conviven.
- **Sin PDF en v1** (a diferencia del SOAT): solo cámara + galería → no se usa `SoatPdfRasterizer`.
- No se hace OCR en backend ni en la nube — todo on-device, **costo $0**.
- No se sube la imagen al servidor solo para OCR.
- No se modela el número de motor/chasis (no hay campo en `VehicleModel`).

---

## 3. Solución técnica

### 3.1 Reuso (sin cambios)

| Pieza | Origen | Notas |
|---|---|---|
| `OcrService` / `MlKitOcrService` | `lib/core/services/ocr/` | Genérico, on-device, sin red. Se inyecta tal cual |
| `OcrResult` / `OcrBlock` | `lib/core/services/ocr/ocr_result.dart` | Texto + bloques con bounding box |
| Captura cámara/galería | `image_picker` (ya en uso) | Sin PDF |
| Patrón parser, use case, telemetría | feature `soat/` | Se clona el patrón, no el código |

### 3.2 Piezas nuevas (feature `vehicles/`)

**Domain** (`lib/features/vehicles/domain/`)
- `PropertyCardExtraction`: modelo puro con campos nullable + confianza por campo
  (`brand`, `model`, `year`, `licensePlate`, `vin`, `color`, `engine`, y `*Confidence`).
  Incluye `shouldPrefill` y `extractedFieldsCount` (mismo contrato que `SoatExtraction`).
- `ParsePropertyCardTextUseCase`: función pura `OcrResult → PropertyCardExtraction`.
- `ScanPropertyCardUseCase`: orquesta `OcrService.recognizeText()` → parse → telemetría
  (espejo de `ScanSoatUseCase`, sin la rama de rasterizado PDF).

**Data** (`lib/features/vehicles/data/parser/`)
- `PropertyCardParser`: Dart puro, reglas + regex sobre etiquetas RUNT. Stateless y testeable con fixtures.

**Presentation** (`lib/features/vehicles/presentation/form/`)
- `VehicleScanCubit extends Cubit<ResultState<PropertyCardExtraction>>`: escanear → procesar → entregar.
- `VehicleScanBanner.onTap` (existente) → abre el bottom sheet de origen (cámara/galería) → corre el scan → al volver, inyecta el resultado al `VehicleFormCubit`.
- `VehicleFormCubit`: nuevo método `prefillFromScan(PropertyCardExtraction)` (espejo de `storePendingManualSoat`).

### 3.3 Mapeo tarjeta de propiedad → `VehicleModel`

| Campo tarjeta (etiqueta RUNT) | Campo `VehicleModel` | Tipo |
|---|---|---|
| MARCA | `brand` | String |
| LÍNEA | `model` | String |
| MODELO (año) | `year` | int (4 dígitos, 1950–año actual+1) |
| PLACA | `licensePlate` | String (normalizar: mayúsculas, sin espacios; patrón moto `AAA00A`/`AAA00`) |
| VIN / Nº SERIE | `vin` | String (17 chars cuando aplica) |
| COLOR | `color` | String |
| CILINDRAJE | `engine` | String (ej. "150 c.c.") |

> Nº MOTOR y Nº CHASIS se ignoran (sin campo en el modelo). Documentar como ampliación futura.

### 3.4 Flujo de usuario

1. En el formulario, el rider toca el banner **"Escanear tarjeta de propiedad"**.
2. Bottom sheet: **Tomar foto** / **Elegir de galería**.
3. Pantalla/overlay intermedio con spinner "Leyendo documento…".
4. ML Kit corre on-device; `PropertyCardParser` mapea texto → campos.
5. El usuario vuelve al formulario **prellenado**, con banner sutil "Datos extraídos — revisa antes de guardar". Cada campo autocompletado muestra indicador de origen OCR.
6. **Política de relleno:** solo se rellenan campos **vacíos**; si un campo ya tiene valor escrito por el usuario, **no se pisa** (se descarta el del OCR para ese campo). Los de baja confianza se marcan "revisar".
7. Si el OCR falla o extrae <2 campos con confianza alta, **no se prellena nada** y se cae al flujo manual con toast: "No pudimos leer el documento, ingresa los datos manualmente".

### 3.5 El parser — núcleo de valor

- **Etiqueta→valor por proximidad:** para cada etiqueta conocida (`PLACA`, `MARCA`, `LÍNEA`, `MODELO`, `CILINDRAJE`, `COLOR`, `VIN`, `SERIE`), buscar el valor en el mismo `centerY` (línea) o en el bloque inmediatamente a la derecha/abajo, usando los bounding boxes de `OcrResult`.
- **Placa:** regex de placa colombiana (moto `^[A-Z]{3}\d{2}[A-Z]?$`, carro `^[A-Z]{3}\d{3}$`); normalización de mayúsculas y O↔0 cuando el contexto lo indique.
- **Año (modelo):** 4 dígitos en rango válido; si hay varios, el más cercano a la etiqueta MODELO.
- **VIN:** 17 alfanuméricos sin I/O/Q; fallback al valor junto a SERIE.
- **Confianza:** `high` (valor con etiqueta de contexto explícita), `medium` (por regex sin etiqueta cercana), `low` (no se prellena).
- **Regla global:** <2 campos `high` → no se prellena nada.

### 3.6 Limpieza de código muerto (incluida en esta feature)

El refactor `iter-6 REFACTOR-03b` (`fa082b6`) dejó un **set duplicado del formulario viejo NO cableado** en `lib/features/vehicles/presentation/widgets/`. El formulario real vive en `presentation/form/`. Borrar los archivos huérfanos (verificando que nadie los importe):

- `widgets/vehicle_form.dart`
- `widgets/vehicle_form_scan_banner.dart` (`VehicleFormScanBanner`)
- `widgets/vehicle_form_add_more_doc_slot.dart`, `widgets/vehicle_form_cover_photo_section.dart`, `widgets/vehicle_form_documents_section.dart`, `widgets/vehicle_form_empty_cover_state.dart`, `widgets/vehicle_form_image_preview.dart`, `widgets/vehicle_form_outline_button.dart`, `widgets/vehicle_form_section_label.dart`

> Verificar con `grep` que cada archivo no tenga referencias fuera del propio set antes de borrar.

---

## 4. Criterios de aceptación

- [ ] `VehicleScanCubit` registrado en DI; `VehicleScanBanner.onTap` funcional.
- [ ] Flujo escanear → procesar → prellenar funciona con **cámara y galería** (sin PDF).
- [ ] `PropertyCardParser` extrae correctamente marca, línea, año, placa, VIN, color, cilindraje desde fixtures reales de tarjetas (moto y carro).
- [ ] Solo se rellenan campos vacíos; no se pisa lo escrito por el usuario.
- [ ] Si <2 campos `high confidence`, no se prellena nada + toast informativo.
- [ ] Campos prellenados muestran indicador visual de origen OCR.
- [ ] Tests unitarios del parser con ≥6 fixtures (motos y carros + casos negativos).
- [ ] **Código muerto del form viejo eliminado** (set `presentation/widgets/vehicle_form*`), `dart analyze` sin warnings nuevos, `flutter test` al 100%.
- [ ] `app_es.arb`: reutilizar/añadir strings (banner ya existe: `vehicle_form_scan_title/subtitle`; añadir loader, toasts, sheet de origen).
- [ ] Permisos cámara + galería ya presentes (confirmar en `AndroidManifest.xml` / `Info.plist`).
- [ ] `docs/features/` (vehicles) actualizado con el sub-flujo OCR.

---

## 5. Telemetría (anónima, sin enviar imágenes ni texto)

- `property_card_scan_attempted`
- `property_card_scan_success` con `fields_extracted_count`
- `property_card_scan_failed` con `failure_reason` (`no_text_detected`, `low_confidence`, `permission_denied`, `unknown_error`)

---

## 6. Riesgos

| Riesgo | Mitigación |
|---|---|
| Calidad de la foto (luz, ángulo) | Instrucciones UI + caída silenciosa a manual si confianza baja |
| Variantes de layout (moto vs carro, tarjeta vieja vs RUNT digital) | Parser por reglas + fixtures por variante; agregar reglas como tests |
| Confusión O↔0 / I↔1 en placa/VIN | Normalización contextual + regex estricta de placa |
| Crecimiento del APK por ML Kit | Ya asumido por el feature SOAT (modelo compartido); sin costo adicional |

---

## 7. Fuera de alcance (futuro)

- PDF de la tarjeta digital del RUNT (reusar `SoatPdfRasterizer` cuando se priorice).
- Nº de motor/chasis (requiere ampliar `VehicleModel`).
- Overlay guía sobre la cámara para enmarcar el documento.

---

## 8. Brief plan (fases)

1. **Limpieza previa** — borrar el set duplicado del form viejo en `presentation/widgets/`; `dart analyze` limpio. *(Pre-flight, sin riesgo funcional: nadie lo importa.)*
2. **Domain + parser** — `PropertyCardExtraction`, `ParsePropertyCardTextUseCase`, `PropertyCardParser` + tests con fixtures.
3. **Use case + scan** — `ScanPropertyCardUseCase` (clonar patrón SOAT sin PDF) + telemetría.
4. **Presentation** — `VehicleScanCubit`, bottom sheet de origen, wiring `VehicleScanBanner` → cubit → `VehicleFormCubit.prefillFromScan`, indicadores de origen y política de "no pisar".
5. **QA + docs** — strings es-CO, permisos, `flutter test`/`dart analyze`, doc del feature.
