# 01-scan — OCR Tarjeta de Propiedad Autofill

**Timestamp:** 2026-06-19T19:49:25Z
**Slug:** `ocr-tarjeta-propiedad-autofill`

---

## Inventario Flutter

### `lib/core/`

| Archivo | Descripción |
|---|---|
| `services/ocr/ocr_service.dart` | Contrato abstracto `OcrService.recognizeText(File)` |
| `services/ocr/ocr_result.dart` | `OcrResult` (fullText + blocks) y `OcrBlock` (texto + bounding box) |
| `services/ocr/ml_kit_ocr_service.dart` | Implementación `@Injectable(as: OcrService)` con `google_mlkit_text_recognition` |
| `services/analytics/analytics_events.dart` | Catálogo de eventos GA4; contiene `soatScan*` — sin equivalente para property card |
| `services/analytics/analytics_params.dart` | Catálogo de params GA4; contiene `fieldsExtractedCount`, `failureReason`, `hadPdf` |
| `di/injection.config.dart` | Configuración autogenerada de GetIt/Injectable |

### `lib/features/soat/`

**Domain:**
- `domain/models/soat_extraction.dart` — `SoatExtraction` inmutable con 4 campos + `OcrFieldConfidence` enum (`high`/`medium`/`low`); helpers `shouldPrefill` (≥2 high), `extractedFieldsCount`, `isFieldAutofilled`
- `domain/models/soat_scan_result.dart` — wrapper `SoatScanResult { extraction }` con `SoatScanException`/`SoatScanFailureReason`
- `domain/usecases/scan_soat_usecase.dart` — orquesta OCR→parse→telemetría; rama PDF via `SoatPdfRasterizer`; lanza `SoatScanException` si no cumple `shouldPrefill`
- `domain/usecases/parse_soat_text_usecase.dart` — wrapper `call(OcrResult) → SoatExtraction` alrededor de `SoatParser`

**Data:**
- `data/parser/soat_parser.dart` — parser stateless con 3 estrategias por campo (label, insurer-specific regex, generic regex); heurísticas de bounding box para labels/values
- `data/parser/soat_insurer_rules.dart` — reglas de aseguradoras colombianas (nombre canónico + aliases)
- `data/parser/soat_pdf_rasterizer.dart` — rasteriza PDF a imagen para OCR (NO se reutiliza en property card)

**Presentation:**
- `presentation/scan/soat_document_picker.dart` — `abstract final class SoatDocumentPicker` con `pickImageFromGallery()` y `pickPdf()`; galería a 100% quality sin compresión
- `presentation/scan/soat_entry_flow.dart` — `abstract final class SoatEntryFlow` que muestra `SoatVehicleOptionsSheet` y navega a `soatManualCapture`
- `presentation/widgets/soat_add_document_sheet.dart` — `SoatAddDocumentSheet` (bottom sheet con opciones galería + PDF); SOAT-específica, pop devuelve `int` (1=galería, 2=PDF)
- `presentation/widgets/soat_vehicle_options_sheet.dart` — `SoatVehicleOptionsSheet` (usa `SoatUploadCubit`); devuelve `SoatOptionsResult` (sealed: `SoatOptionsUpload` | `SoatOptionsManual`)
- `presentation/cubit/soat_upload_cubit.dart` — maneja el picking de imagen para SOAT

### `lib/features/vehicles/`

**Domain:**
- `domain/models/vehicle_model.dart` — campos mapeables desde tarjeta de propiedad: `brand`, `model`, `year`, `licensePlate`, `vin`; también `color`, `engine` (fuera de scope v1)

**Presentation (activo — bajo `presentation/form/`):**
- `form/vehicle_form_page.dart` — página que crea `BlocProvider<VehicleFormCubit>` + `BlocProvider<FormImageCubit>`
- `form/vehicle_form_body.dart` — `VehicleFormBody` actual (ACTIVO); las líneas 35-36 tienen `VehicleScanBanner` comentado con `// const VehicleScanBanner()`
- `form/widgets/vehicle_form_basic_section.dart` — sección con brand, model, name
- `form/widgets/vehicle_form_id_section.dart` — sección con licensePlate, VIN, purchaseDate
- `form/widgets/vehicle_form_specs_section.dart` — sección specs (engine, horsepower, etc.)
- `form/widgets/vehicle_scan_banner.dart` — banner visual ya implementado con `onTap: () { // TODO: implement scan property card }` y strings l10n correctos; icono usa `AppColors.textOnDarkPrimary` (**no `Colors.white`**)

**Presentation (huérfano — bajo `presentation/widgets/`):**
- `widgets/vehicle_form.dart` — `VehicleForm` antigua (NO se usa en ningún import activo); es el set duplicado del form viejo
- `widgets/vehicle_form_cover_photo_section.dart`, `vehicle_form_documents_section.dart`, `vehicle_form_add_more_doc_slot.dart`, `vehicle_form_empty_cover_state.dart`, `vehicle_form_image_preview.dart`, `vehicle_form_outline_button.dart`, `vehicle_form_section_label.dart` — widgets HUÉRFANOS referenciados solo por `vehicle_form.dart` (también huérfano)
- `widgets/vehicle_form_scan_banner.dart` — banner HUÉRFANO paralelo a `form/widgets/vehicle_scan_banner.dart`; tiene bug: usa `Colors.white` sobre primario en lugar de `AppColors.textOnDarkPrimary`

**Cubit:**
- `presentation/cubit/vehicle_form_cubit.dart` — `@injectable VehicleFormCubit`; NO tiene `prefillFromScan()` — está **not started**
- `presentation/cubit/vehicle_form_state.dart` — `VehicleFormState` con `pendingManualSoat`, `pendingRtm`; no tiene campo de escaneo de tarjeta de propiedad

### `lib/features/vehicle_documents/`

Abstracción compartida para SOAT y RTM (domain models, base cubit `VehicleDocumentCubit<T>`, widgets genéricos de status/data/validity). No interviene en property card OCR.

### `lib/features/tecnomecanica/`

RTM: NO tiene document picker ni OCR. `TecnomecanicaEntryFlow.start()` navega directamente a `tecnomecanicaStatus`. No hay `SoatAddDocumentSheet` equivalente para RTM. La afirmación del PRD de que "SOAT y RTM migran" a `DocumentSourceSheet` requiere verificar: RTM actualmente no usa ningún sheet de opciones.

### `lib/shared/widgets/`

No existe `DocumentSourceSheet` ni nada de selección de fuente de documento. El helper `document_downloader.dart` está bajo `lib/shared/helpers/` y solo gestiona descarga, no captura.

---

## Dependencias

| Paquete | Versión | Relevancia para este feature |
|---|---|---|
| `google_mlkit_text_recognition` | `^0.15.0` | OCR on-device — ya en uso para SOAT |
| `image_picker` | `^1.2.1` | Galería/cámara — ya en uso |
| `file_picker` | `^11.0.2` | PDF picker — ya en uso para SOAT (NO se necesita para property card v1) |
| `injectable` + `get_it` | `^2.7.1+2` | DI — patrón a seguir |
| `freezed` | `^3.2.3` | Para estado de cubit si es complejo |
| `flutter_bloc` / `bloc` | — | Cubit pattern |
| `flutter_form_builder` | — | FormBuilder en `vehicle_form_body.dart` — `formKey.currentState?.fields[key]?.didChange()` es el mecanismo de prefill |
| `firebase_analytics` | `^12.0.0` | Telemetría — catálogo necesita 3 eventos nuevos |

**No se necesitan dependencias nuevas** para implementar este feature completo.

---

## Superficie rideglory-api

Este feature es **100% on-device**: no hay endpoints de backend involucrados en el OCR de tarjeta de propiedad. El scanner procesa la imagen localmente con ML Kit y solo popula el formulario en memoria. El guardado del vehículo ya usa los endpoints existentes:

| Microservicio | Endpoint | Uso |
|---|---|---|
| `vehicles-ms` | `POST /vehicles` | Crear vehículo con campos prefillados |
| `vehicles-ms` | `PATCH /vehicles/:id` | Editar vehículo con campos prefillados |

**No se requieren cambios en el backend** para ninguna de las 6 fases.

---

## Gap analysis

| Pieza | Estado | Detalle |
|---|---|---|
| `OcrService` + `MlKitOcrService` | **implemented** | Completo, reutilizable sin cambios |
| `OcrResult` / `OcrBlock` | **implemented** | Idéntico para property card |
| `SoatParser` (patrón de referencia) | **implemented** | Template para `PropertyCardParser` |
| `SoatExtraction` (patrón de referencia) | **implemented** | Template para `PropertyCardExtraction` |
| `ScanSoatUseCase` (patrón de referencia) | **implemented** | Template para `ScanPropertyCardUseCase` (sin rama PDF) |
| `PropertyCardExtraction` (domain model) | **not started** | Campos: brand, model, year, licensePlate, vin + OcrFieldConfidence por campo |
| `ParsePropertyCardTextUseCase` | **not started** | Wrapper `call(OcrResult) → PropertyCardExtraction` |
| `PropertyCardParser` | **not started** | Reglas RUNT colombianas; campos objetivos: marca, modelo, año, placa, VIN |
| `ScanPropertyCardUseCase` | **not started** | Sin rama PDF; telemetría con 3 nuevos eventos GA4 |
| `VehicleScanCubit` | **not started** | `Cubit<ResultState<PropertyCardExtraction>>`; `@injectable` (no `@singleton`) |
| `VehicleFormCubit.prefillFromScan()` | **not started** | `formKey.currentState?.fields[key]?.didChange(value)` para cada campo extraído con high/medium |
| `DocumentSourceSheet` (shared) | **not started** | Parametrizable; reemplaza `SoatAddDocumentSheet` para el caso cámara+galería |
| Reconectar `VehicleScanBanner` en `vehicle_form_body.dart` | **partial** | Banner UI existe (`form/widgets/vehicle_scan_banner.dart`), comentado; `onTap` pendiente |
| Strings l10n para property card scan | **partial** | `vehicle_form_scan_title` y `vehicle_form_scan_subtitle` existen; faltan: loader, toast éxito, toast error, instrucción cara frontal |
| Eventos GA4 para property card scan | **not started** | Necesita 3 entradas en `AnalyticsEvents`: `propertyScanAttempted`, `propertyScanSuccess`, `propertyScanFailed` |
| Tests unitarios `PropertyCardParser` | **not started** | ≥6 fixtures sintéticos (motos, carros, casos negativos) |
| Limpieza código muerto (`presentation/widgets/vehicle_form*.dart`) | **not started** | 8+ archivos huérfanos bajo `presentation/widgets/`; `VehicleForm` no se importa desde ningún punto activo |
| Migración SOAT a `DocumentSourceSheet` | **partial** | `SoatAddDocumentSheet` existe y es SOAT-específica; `SoatVehicleOptionsSheet` tiene lógica propia con `SoatUploadCubit` — la migración es más quirúrgica de lo que el PRD sugiere |
| Migración RTM a `DocumentSourceSheet` | **not applicable (v1)** | RTM no tiene sheet de fuente; `TecnomecanicaEntryFlow` navega directo sin picker de imagen |

---

## Patrones

### Patrón parser (replicar de SOAT)
`SoatParser` es stateless `@injectable`, recibe `OcrResult`, devuelve dominio puro. `PropertyCardParser` sigue exactamente el mismo contrato. Las 3 estrategias de extracción (label proximity, field-specific regex, generic fallback) son aplicables para marca/modelo/año/placa/VIN desde el layout RUNT.

### Patrón usecase de scan
`ScanSoatUseCase` orquesta `OcrService → ParseUseCase → analytics`. `ScanPropertyCardUseCase` omite la rama `SoatPdfRasterizer` (scope v1 sin PDF) y reemplaza los eventos GA4 específicos de SOAT por los nuevos de property card.

### Prefill de form con FormBuilder
El `VehicleFormCubit` ya posee `formKey`. El mecanismo correcto para prefill es `formKey.currentState?.fields[VehicleFormFields.brand]?.didChange(value)`. No se necesita reconstruir el form ni pasar `initialValue`; `didChange` actualiza el campo en caliente y dispara validación.

### Cubit de scan en el árbol (no singleton)
`VehicleScanCubit` va como `BlocProvider` local en `VehicleFormPage` (junto a `VehicleFormCubit` y `FormImageCubit`). El estado del scan no necesita persistir fuera de la sesión del form.

### DocumentSourceSheet vs SoatVehicleOptionsSheet
La "migración" del PRD aplica solo a la versión simple (`SoatAddDocumentSheet` con galería+PDF). `SoatVehicleOptionsSheet` es más compleja (tiene `SoatUploadCubit` y devuelve `SoatOptionsResult` sealed class) — migrarla requiere que `DocumentSourceSheet` soporte el mismo contrato de sealed result o que SOAT mantenga su sheet actual. La recomendación es que `DocumentSourceSheet` sea el sheet simple (cámara + galería, sin PDF), y SOAT siga usando su sheet propia que incluye la opción Manual. Esto simplifica la fase 2 y no rompe SOAT.

---

## Implicaciones para el plan

1. **Fase 1 (limpieza) es autónoma y bajo riesgo**: Los 8+ archivos huérfanos bajo `presentation/widgets/vehicle_form*.dart` no tienen importadores activos. Se pueden borrar con un `dart analyze` de verificación. Eliminar primero desbloquea las fases siguientes sin ruido de archivos muertos.

2. **Fase 2 (DocumentSourceSheet) debe re-scopearse**: La sheet nueva solo necesita servir al caso property card (cámara + galería). No tiene sentido forzar la migración de `SoatVehicleOptionsSheet` (que tiene lógica de `SoatUploadCubit` y opción Manual) — esa migración agrega riesgo sin beneficio en v1. La fase 2 puede crear `DocumentSourceSheet` y conectarla únicamente al property card scanner.

3. **PropertyCardParser es la pieza de mayor incertidumbre**: No existen fixtures reales de tarjetas de propiedad colombianas en el repo. Los tests deberán construirse con texto sintético que imite el layout RUNT. La fase 3 debe documentar los patrones RUNT asumidos (etiqueta "MARCA", "LINEA/MODELO", "MODELO/AÑO", "PLACA", "VIN/SERIE") en comentarios del parser para que sean auditables.

4. **El prefill NO requiere reconstruir el form**: `formKey.currentState?.fields[key]?.didChange()` funciona en caliente. El `VehicleFormCubit.prefillFromScan()` no necesita emitir un estado nuevo de `VehicleFormState`; puede ser un método que actualiza los campos directamente vía formKey. Esto simplifica el binding en la fase 5.

5. **VehicleFormScanBanner tiene un bug de color**: `presentation/widgets/vehicle_form_scan_banner.dart` (huérfano) usa `Colors.white` sobre el acento naranja — violación del estándar de texto oscuro sobre primario. El banner activo correcto es `form/widgets/vehicle_scan_banner.dart` que ya usa `AppColors.textOnDarkPrimary`. La fase 1 borra el huérfano y la fase 5 activa el correcto.

6. **Sin cambios de backend**: Las 6 fases son flutter-only. La coordinación con `rideglory-api` solo ocurre en el save del vehículo, que ya existe y no se modifica.
