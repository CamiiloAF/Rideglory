# Documentación del Feature: SOAT

> Última actualización: 2026-05-29  
> Alcance: `lib/features/soat/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Data](#32-data)
   - 3.3 [Presentation](#33-presentation)
4. [Cubits y estados](#4-cubits-y-estados)
5. [Cálculo de SoatStatus](#5-cálculo-de-soatstatus)
6. [Flujos de captura](#6-flujos-de-captura)
   - 6.1 [Flujo con documento (foto / PDF) — escaneo OCR desde el card](#61-flujo-con-documento-foto--pdf--escaneo-ocr-desde-el-card)
   - 6.2 [Pantalla de formulario unificada](#62-pantalla-de-formulario-unificada-soatmanualcapturepage)
   - 6.3 [Flujo durante creación de vehículo](#63-flujo-durante-creación-de-vehículo)
   - 6.4 [Sub-flujo OCR](#64-sub-flujo-ocr-autocompletar-soat)
   - 6.5 [Eliminar el SOAT de un vehículo](#65-eliminar-el-soat-de-un-vehículo)
7. [Subida del documento](#7-subida-del-documento)
8. [Rutas de navegación](#8-rutas-de-navegación)
9. [API endpoints](#9-api-endpoints)
10. [Conexiones con otros features](#10-conexiones-con-otros-features)
11. [Patrones y trampas conocidas](#11-patrones-y-trampas-conocidas)
12. [Archivos clave de referencia rápida](#12-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El **SOAT** (Seguro Obligatorio de Accidentes de Tránsito) es la póliza obligatoria para motos en Colombia. Este feature gestiona:

1. **Captura del SOAT** asociado a un vehículo: número de póliza, aseguradora, fechas de inicio/expiración, opcionalmente foto o PDF del documento.
2. **Visualización del estado** (`valid` / `expiringSoon` / `expired`) calculado por días hasta vencimiento.
3. **Renovación**: editar SOAT existente, reemplazar documento.
4. **Eliminación** del SOAT de un vehículo (`DELETE`), disponible desde varias pantallas.

> **OCR opcional (autocompletar SOAT).** La app puede leer la foto/PDF del SOAT **on-device** (ML Kit, sin backend ni nube) para luego **ofrecer** el prellenado de los campos. El escaneo se dispara directamente desde el card de subida (botones Cámara / Galería / PDF); ya no existe un botón "Escanear SOAT" separado. El autocompletado es **opt-in**: tras detectar un SOAT válido se muestra un banner con el botón "Autocompletar campos" y el usuario decide. La entrada manual sigue disponible y es la fuente de verdad. Ver [§6.4 Sub-flujo OCR](#64-sub-flujo-ocr-autocompletar-soat).

El feature **convive con `vehicles`** porque la API expone el SOAT bajo `/vehicles/{id}/soat`. Hay duplicación intencional:
- `vehicles/data/dto/soat_dto.dart` + `VehicleRepository.upsertSoat()` (vista del feature vehicles).
- `soat/` con sus propios `SoatRepository`, DTO y service.

Ambas implementaciones apuntan al mismo backend.

---

## 2. Modelo de dominio

### `SoatModel`
> `lib/features/soat/domain/models/soat_model.dart`

```
SoatModel
  id: String                     (requerido)
  vehicleId: String              (requerido)
  policyNumber: String?
  startDate: DateTime?
  expiryDate: DateTime           (requerido)
  insurer: String?
  documentUrl: String?           — URL Firebase Storage
  createdAt: DateTime?
  updatedAt: DateTime?

Getters:
  status: SoatStatus             — valid | expiringSoon | expired
  daysUntilExpiry: int           — negativo si ya venció
```

> Existe **otro `SoatModel`** en `lib/features/vehicles/domain/models/soat_model.dart` (re-export desde feature `vehicles`). Usado por `VehicleRepository.upsertSoat()/getSoat()`. Aunque tengan la misma forma, son **clases distintas** y no son intercambiables sin mapeo manual. Cuando se trabaje con SOAT, verificar cuál import se usa.

### `SoatStatus` (enum)
```
noSoat       — sin SOAT registrado
valid        — vigente (> 30 días para vencer)
expiringSoon — 0–30 días para vencer
expired      — vencido (días < 0)
```

`SoatStatus.noSoat` no se calcula desde el modelo — se asigna desde el feature `vehicles` cuando `VehicleModel.soatStatus == null` o cuando el endpoint devuelve null.

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/soat/domain/
├── models/
│   └── soat_model.dart       (SoatStatus + SoatModel + getters de vigencia)
├── repository/
│   └── soat_repository.dart  (interface)
└── usecases/
    ├── get_soat_usecase.dart
    ├── save_soat_usecase.dart
    ├── delete_soat_usecase.dart
    ├── parse_soat_text_usecase.dart   (OCR — ver §6.4)
    └── scan_soat_usecase.dart         (OCR — ver §6.4)
```

**`SoatRepository`** (interface):
```dart
Future<Either<DomainException, SoatModel?>> getSoat(String vehicleId);

Future<Either<DomainException, SoatModel>> saveSoat({
  required String vehicleId,
  required SoatModel soat,
});

Future<Either<DomainException, Unit>> deleteSoat(String vehicleId);
```

> `getSoat` retorna `SoatModel?` — `null` significa "no hay SOAT registrado para este vehículo" (404 desde el backend mapeado a `Right(null)`).

**Use cases (todos `@injectable`)**:
- `GetSoatUseCase.call(String vehicleId)`
- `SaveSoatUseCase.call({vehicleId, soat})`
- `DeleteSoatUseCase.call(String vehicleId)` — delega en `SoatRepository.deleteSoat`

---

### 3.2 Data
```
lib/features/soat/data/
├── dto/
│   └── soat_dto.dart
├── repository/
│   └── soat_repository_impl.dart   (@Injectable(as: SoatRepository))
└── service/
    └── soat_service.dart            (@singleton @RestApi)
```

**`SoatDto`** (`@JsonSerializable(converters: apiJsonDateTimeConverters)`):

Mismos campos que `SoatModel`, todos opcionales en la deserialización. Extensión `SoatModelToRequest.toRequestJson()` serializa para POST:

```dart
{
  'expiryDate': ISO8601 UTC,           // requerido
  'policyNumber': string?,             // opcional
  'startDate': ISO8601 UTC?,
  'insurer': string,
  'documentUrl': string?,              // opcional
}
```

> **Trampa:** `SoatDto.toModel()` asigna `DateTime.now()` si `expiryDate` viene `null` del backend. Es un fallback defensivo, pero significa que el modelo nunca tendrá `expiryDate` faltante. Verifica antes que el endpoint siempre devuelva la fecha.

**`SoatService` (Retrofit)**:
```dart
@GET('/vehicles/{vehicleId}/soat')
Future<SoatDto> getSoat(@Path('vehicleId') String vehicleId);

@POST('/vehicles/{vehicleId}/soat')
Future<SoatDto> saveSoat(
  @Path('vehicleId') String vehicleId,
  @Body() Map<String, dynamic> request,
);

@DELETE('/vehicles/{vehicleId}/soat')
Future<void> deleteSoat(@Path('vehicleId') String vehicleId);
```

**`SoatRepositoryImpl`** maneja 404 como `Right(null)` (solo en `getSoat`); `saveSoat` y `deleteSoat` van por `executeService()` (este último retorna `Right(unit)`):
```dart
on DioException catch (e) {
  if (e.response?.statusCode == 404) return const Right(null);
  return const Left(DomainException(message: 'No se pudo cargar el SOAT...'));
}
```

---

### 3.3 Presentation
```
lib/features/soat/presentation/
├── cubit/
│   ├── soat_cubit.dart            (estado SOAT cargado: load/save/delete)
│   ├── soat_upload_cubit.dart     (selección de archivo; usado por soat_vehicle_options_sheet)
│   └── soat_scan_cubit.dart       (OCR — ver §6.4)
├── pages/
│   ├── soat_manual_capture_page.dart   (formulario unificado: escaneo/confirmación, registro manual y edición; sin Cubit dedicado)
│   ├── soat_manual_capture_params.dart (extra de la ruta)
│   ├── soat_scan_page.dart             (OCR — ver §6.4)
│   ├── soat_scan_params.dart           (OCR — ver §6.4)
│   └── soat_status_page.dart           (vista del SOAT existente)
├── scan/
│   ├── soat_entry_flow.dart            (helper: muestra el sheet de opciones y navega a la captura manual)
│   └── soat_scan_launcher.dart         (OCR — ver §6.4)
└── widgets/
    ├── soat_status_view.dart
    ├── soat_data_view.dart              (vista "Mi SOAT": estado + datos + ver/renovar/eliminar)
    ├── soat_empty_state.dart
    ├── soat_upload_option_card.dart     (botones Cámara/Galería/PDF que disparan OCR)
    ├── soat_manual_option_card.dart
    ├── soat_vehicle_options_sheet.dart
    ├── soat_add_document_sheet.dart     (sheet "Agregar documento" en captura manual: Cámara/Galería/PDF)
    ├── soat_document_section.dart       (preview + reemplazo)
    ├── soat_not_recognized_warning.dart (aviso inline no bloqueante cuando el OCR no reconoce un SOAT)
    ├── soat_validity_card.dart          (cálculo de vigencia en tiempo real)
    ├── soat_autofill_banner.dart        (banner opt-in de autocompletado OCR)
    ├── soat_delete_button.dart          (botón destructivo reutilizable con confirmación)
    ├── soat_detail_row.dart
    ├── soat_section_header.dart
    ├── soat_scan_loader.dart            (OCR — ver §6.4)
    └── soat_scan_source_sheet.dart      (OCR — ver §6.4)
```

---

## 4. Cubits y estados

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `SoatCubit` | `cubit/soat_cubit.dart` | `@injectable` | `ResultState<SoatModel>` | Lectura/guardado/borrado del SOAT (status page) |
| `SoatUploadCubit` | `cubit/soat_upload_cubit.dart` | `@injectable` | `SoatUploadState` (sealed class) | Selección de archivo; lo consume `SoatVehicleOptionsSheet` |
| `SoatScanCubit` | `cubit/soat_scan_cubit.dart` | `@injectable` | `ResultState<SoatExtraction>` | OCR — ver §6.4 |

> `SoatFormCubit` fue **eliminado**. `SoatManualCapturePage` (formulario unificado) maneja su propio estado con `setState` e invoca los use cases directamente vía `getIt`.

### `SoatCubit`

`ResultState<SoatModel>` — `initial`, `loading`, `data(SoatModel)`, `empty` (sin SOAT registrado), `error`.

Métodos:
- `load(vehicleId)` — `getSoat()`; si retorna null → `empty`, si retorna data → `data`.
- `save({vehicleId, soat}) → bool` — `saveSoat()`; retorna `true/false` para que la UI sepa si debe popear.
- `delete(vehicleId) → bool` — `deleteSoat()`; en éxito emite `empty` y retorna `true`.

### `SoatUploadCubit`

```dart
sealed class SoatUploadState {}
final class SoatUploadInitial      extends SoatUploadState {}
final class SoatUploadPicking      extends SoatUploadState {}
final class SoatUploadImagePicked  extends SoatUploadState { final XFile image; }
final class SoatUploadError        extends SoatUploadState { final String message; }
```

Métodos:
- `pickFromCamera()`, `pickFromGallery()` → `ImageStorageService.pickImage*()`.
- `pickFromFile()` → `FilePicker` con `allowedExtensions: ['pdf']`.

Cualquiera de los tres emite `SoatUploadImagePicked(XFile)` al éxito y `SoatUploadInitial` si el usuario cancela.

> El único consumidor de este cubit es `SoatVehicleOptionsSheet`.

---

## 5. Cálculo de SoatStatus

`SoatModel.status` (getter en `domain/models/soat_model.dart`):

```dart
SoatStatus get status {
  final days = daysUntilExpiry;
  if (days < 0)     return SoatStatus.expired;
  if (days <= 30)   return SoatStatus.expiringSoon;
  return SoatStatus.valid;
}

int get daysUntilExpiry {
  final now = DateTime.now();
  final today  = DateTime(now.year, now.month, now.day);     // medianoche
  final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
  return expiry.difference(today).inDays;
}
```

Umbral fijo: **30 días**. `noSoat` no se calcula aquí — se asigna externamente cuando no hay registro.

> `VehicleCubit._soatStatusFrom(DateTime expiryDate)` replica este cálculo (también 30 días) para actualizar localmente `VehicleModel.soatStatus` cuando se guarda un SOAT desde el form del vehículo.

---

## 6. Flujos de captura

### 6.1 Flujo con documento (foto / PDF) — `SoatEntryFlow` + escaneo OCR

El punto de entrada único es el helper **`SoatEntryFlow.start(context, ...)`** (`scan/soat_entry_flow.dart`). Reemplazó a la antigua `SoatUploadPage`. Lo consumen todos los puntos que antes navegaban a `AppRoutes.vehicleSoat` (garage, form de vehículo, renovación en `SoatDataView`/`SoatEmptyState`, etc.).

```
SoatEntryFlow.start(context, vehicle?, onSaved?, formCubit?)
  └─ showModalBottomSheet(SoatVehicleOptionsSheet)
        ├─ SoatUploadOptionCard (Cámara/Galería/PDF) → SoatOptionsUpload(image)
        └─ SoatManualOptionCard                       → SoatOptionsManual()
  └─ Según resultado, navega a soatManualCapture:
        ├─ Vehículo existente (vehicle.id != null):
        │     SoatManualCaptureParams(vehicle, initialLocalImagePath: image?.path)
        │     → modo edición/guardar backend; al volver con true → onSaved()
        └─ Vehículo nuevo (vehicle == null/sin id):
              SoatManualCaptureParams(initialLocalImagePath: image?.path)
              → espera PendingManualSoat → formCubit.storePendingManualSoat(data)

SoatManualCapturePage (ver §6.2)
  ├─ Si llegó con initialLocalImagePath → escanea OCR en initState (autoApply)
  ├─ Si el OCR detecta SOAT → autocompleta; si falla → aviso inline no bloqueante
  │     (SoatNotRecognizedWarning bajo el documento; sin SnackBar)
  └─ Guarda en backend (modo edición) o retorna PendingManualSoat (modo creación)
```

> El sheet **solo elige** el documento (o la opción manual); el OCR corre dentro de `SoatManualCapturePage`. Si el OCR no reconoce el SOAT, el documento queda adjunto y se muestra un aviso inline; el usuario puede guardar igualmente o completar los datos a mano.

### 6.2 Pantalla de formulario unificada (`SoatManualCapturePage`)

Es la **única** pantalla de escaneo/confirmación, registro manual y edición. (`SoatConfirmationPage` y `SoatFormCubit` fueron eliminados.) No usa Cubit dedicado: estado local con `setState`, invoca los use cases vía `getIt`.

```
SoatManualCapturePage(vehicle?, existingSoat?, initialLocalImagePath?, extraction?)
  ├─ SoatDocumentSection: preview + adjuntar/cambiar foto/PDF (_pickImage → bottom sheet)
  ├─ Si extraction.shouldPrefill && !autofillApplied → SoatAutofillBanner
  │     └─ "Autocompletar campos" → _applyAutofill() (patchValue + setState fechas)
  ├─ Form fields: policyNumber, insurer (requerido), startDate, expiryDate
  ├─ SoatValidityCard (vigencia en vivo a partir de las fechas)
  └─ Guardado (_submit):
     ├─ Modo edición (vehicle.id != null):
     │   ├─ Sube imagen/PDF nueva (si hay) a soat/{vehicleId}/{timestamp}.{ext}
     │   ├─ getIt<SaveSoatUseCase>(vehicleId, soat)
     │   └─ context.pop(true) si éxito
     │   └─ Además: SoatDeleteButton al fondo (solo si existingSoat != null) — ver §6.5
     └─ Modo creación (vehicle == null o sin id):
         └─ context.pop(PendingManualSoat) — sin tocar backend; VehicleFormView lo guarda tras crear el vehículo
```

> El autocompletado es **opt-in**: aunque el OCR supere el umbral, los campos NO se prellenan solos. El usuario pulsa "Autocompletar campos" en el banner. Ya **no** existen los badges por campo (`SoatAutofillBadge`).

### 6.3 Flujo durante creación de vehículo

`VehicleFormPage` ofrece dos rutas para capturar SOAT antes de tener `vehicleId`, ambas hacia `SoatManualCapturePage` (ruta `AppRoutes.soatManualCapture`):

1. **Adjuntar imagen + datos** durante el form de vehículo (via `VehicleFormCubit.pickSoatDocument()`):
   - Al guardar el vehículo (`POST /vehicles/my`), `VehicleFormView` hace `pushReplacementNamed(soatManualCapture, SoatManualCaptureParams(vehicle: saved, initialLocalImagePath: soatPath))`.
   - Mantiene `VehicleFormPage` fuera del back stack.

2. **Captura manual antes de tener ID** (`PendingManualSoat`):
   - `VehicleFormDocsSection` abre `soatManualCapture` y recibe un `PendingManualSoat` → `VehicleFormCubit.storePendingManualSoat(data)`.
   - Al guardar el vehículo, `VehicleFormView._savePendingManualSoatAndPop()` sube imagen (si hay) + llama `VehicleRepository.upsertSoat(vehicleId, soat)` + pop.

Más detalles en [vehicles.md §13](./vehicles.md#13-patrones-y-trampas-conocidas).

### 6.4 Sub-flujo OCR (autocompletar SOAT)

Lectura **on-device** del SOAT desde foto/galería/PDF. Privacidad total: ni la imagen ni el texto reconocido salen del dispositivo (ML Kit local; no hay backend ni Cloud Vision).

**Disparador.** El documento se elige en `SoatVehicleOptionsSheet` (vía `SoatEntryFlow`) o se cambia desde `SoatManualCapturePage` (sheet `SoatAddDocumentSheet`). El OCR corre **dentro de `SoatManualCapturePage`** (`_scanDocument`), no en un launcher previo. `SoatScanLauncher` / `SoatScanPage` siguen existiendo como mecanismo de escaneo on-device reutilizable.

**Recorrido (OCR dentro de la captura manual).**
1. `SoatManualCapturePage` recibe `initialLocalImagePath` (documento ya elegido) y, en `initState`, llama `_scanDocument(path, source, autoApply: true)`. Al cambiar el documento desde `_pickImage`, vuelve a escanear (sin autoApply; ofrece el banner opt-in).
2. `_scanDocument` invoca `getIt<ScanSoatUseCase>()` directamente:
   - Si la fuente es PDF, `SoatPdfRasterizer` rasteriza la página 1 a PNG (`pdfx`) antes del OCR.
   - `MlKitOcrService.recognizeText()` → `OcrResult` (texto + bloques con bounding box).
   - `ParseSoatTextUseCase` → `SoatParser.parse()` → `SoatExtraction` con confianza por campo.
3. Si el escaneo detecta SOAT y `shouldPrefill` (≥2 campos `high`), se ofrece el `SoatAutofillBanner` (opt-in) o se aplica directamente cuando `autoApply` es true.
4. Si el escaneo lanza `SoatScanException`, se marca `_documentNotRecognized = true` y se muestra `SoatNotRecognizedWarning` inline bajo el documento (sin SnackBar, no bloqueante). El flag se limpia al elegir/quitar documento o cuando un escaneo posterior sí detecta SOAT.

> `SoatScanLauncher.launch` (que sí navega a `SoatScanPage` y devuelve `SoatScanOutcome`) sigue disponible para flujos que prefieran la pantalla de escaneo dedicada, pero el flujo principal de captura escanea on-the-fly dentro de la página.

**Capas / archivos.**
- Core: `lib/core/services/ocr/` (`OcrService`, `MlKitOcrService`, `OcrResult`/`OcrBlock`); `lib/core/services/analytics/` (`AnalyticsService`, `FirebaseAnalyticsService`).
- Domain: `soat/domain/models/soat_extraction.dart`, `soat_scan_result.dart`; `soat/domain/usecases/parse_soat_text_usecase.dart`, `scan_soat_usecase.dart`.
- Data: `soat/data/parser/soat_parser.dart`, `soat_insurer_rules.dart`, `soat_pdf_rasterizer.dart`.
- Presentation: `soat/presentation/cubit/soat_scan_cubit.dart`; `pages/soat_scan_page.dart`, `soat_scan_params.dart`; `scan/soat_scan_launcher.dart` (define `SoatScanOutcome`); widgets `soat_scan_source_sheet` (fallback, no usado por el flujo actual), `soat_scan_loader`, `soat_autofill_banner`. (Eliminados: `soat_scan_button`, `soat_ocr_banner`, `soat_autofill_badge`.)

**Reglas del parser** (`SoatParser`, Dart puro y testeable):
- **Aseguradora:** matching por substring normalizado (sin tildes) sobre las 10 autorizadas (Fasecolda 2026). Empate → mayor área de bloque en el cuarto superior (logo). 
- **Póliza:** cascada — label `póliza` → regex específica por aseguradora (top-5) → regex genérica.
- **Fechas:** regex multi-formato (`DD/MM/AAAA`, `DD-MM-AAAA`, `DD mmm AAAA`, ISO). Asociación a labels (`vigencia desde`/`hasta`/`vence`). **Validación dura: 360–370 días**; si falla, ambas fechas quedan `low` y no se prellenan.
- **Umbral global:** `<2` campos `high` → no se prellena nada + toast (caída silenciosa al manual).

**Telemetría** (Firebase Analytics, anónima): `soat_scan_attempted`; `soat_scan_success` (`fields_extracted_count`, `insurer_detected`, `had_pdf`); `soat_scan_failed` (`failure_reason`: `no_text_detected` / `low_confidence` / `validation_failed` / `permission_denied` / `unknown_error`).

**Permisos:** `CAMERA` + `READ_MEDIA_IMAGES` en `AndroidManifest.xml`; `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` en `Info.plist`.

> **Nota de build:** el paquete transitivo `objective_c` (de `google_mlkit_text_recognition`) declara native build hooks, lo que rompe la compilación AOT del script de build_runner en el SDK actual. Generar código con `dart run build_runner build --force-jit` (JIT) en lugar del AOT por defecto.

### 6.5 Eliminar el SOAT de un vehículo

El SOAT se puede eliminar (`DELETE /vehicles/{vehicleId}/soat`) desde **4 lugares**. Todos piden confirmación destructiva con `ConfirmationDialog` (`DialogActionType.danger`) y, tras éxito, refrescan el estado local con `VehicleCubit.clearSoatLocally(vehicleId)` y muestran el SnackBar `soat_deleted_success`.

| Origen | Archivo | Cómo borra | Estado tras éxito |
|---|---|---|---|
| Detalle del vehículo (card SOAT) | `vehicles/.../garage/widgets/vehicle_soat_card.dart` | `getIt<DeleteSoatUseCase>()` (ícono papelera inline) | `clearSoatLocally` + `setState(_soat=null)` |
| Pantalla "Mi SOAT" | `soat/.../widgets/soat_data_view.dart` (en `SoatStatusPage`) | `SoatDeleteButton` → `context.read<SoatCubit>().delete()` | `clearSoatLocally` + `context.pop()` |
| Editar SOAT | `SoatManualCapturePage` (modo edición, `existingSoat != null`) | `SoatDeleteButton` → `getIt<DeleteSoatUseCase>()` | `clearSoatLocally` + `context.pop(true)` |
| Editar vehículo (slot SOAT) | `vehicles/.../form/widgets/vehicle_soat_form_slot.dart` | `getIt<DeleteSoatUseCase>()` (ícono papelera inline) | `clearSoatLocally` + `setState(_soat=null)` |

**Capa:** `DeleteSoatUseCase` → `SoatRepository.deleteSoat` → `SoatService.deleteSoat`.

**Widget reutilizable:** `SoatDeleteButton` (`soat/.../widgets/soat_delete_button.dart`) — botón `AppButtonVariant.danger` outlined que encapsula la confirmación; recibe `onDelete: Future<bool> Function()` (el borrado real) y `onDeleted: VoidCallback`. Lo usan `soat_data_view.dart` y `SoatManualCapturePage`. `vehicle_soat_card.dart` y `vehicle_soat_form_slot.dart` implementan su propio ícono de papelera inline (mismo `ConfirmationDialog`), no `SoatDeleteButton`.

---

## 7. Subida del documento

Path en Firebase Storage:
```
soat/{vehicleId}/{timestampMs}.{ext}
```

- `SoatManualCapturePage` (modo edición) usa la extensión real del archivo (`.jpg`, `.png`, `.pdf`), tomada de `_localImagePath.split('.').last`.
- `VehicleFormView._savePendingManualSoatAndPop()` (modo creación) sube el documento pendiente con su extensión.

**Si la subida falla**, el comportamiento varía:
- `SoatManualCapturePage` (modo edición) → muestra error en pantalla (`_error`) y **no** guarda.
- `SoatManualCapturePage` (modo creación) retorna `PendingManualSoat` sin subir nada; la subida la hace `VehicleFormView` después.
- `VehicleFormView._savePendingManualSoatAndPop()` → **continúa** guardando el SOAT sin documentUrl y muestra warning.

---

## 8. Rutas de navegación

| Ruta | Constante | Builder | Extras |
|---|---|---|---|
| `/soat/status` | `AppRoutes.soatStatus` | `SoatStatusPage(vehicle: extra as VehicleModel)` | `VehicleModel` |
| `/soat/manual-capture` | `AppRoutes.soatManualCapture` | `SoatManualCapturePage(vehicle, existingSoat: params.soat, initialLocalImagePath, extraction)` | `SoatManualCaptureParams` |
| `/soat/scan` | `AppRoutes.soatScan` | `SoatScanPage(params: extra as SoatScanParams)` | `SoatScanParams` |

> Las rutas `AppRoutes.vehicleSoat` (`/vehicles/soat`) y `AppRoutes.soatUpload` (`/soat/upload`) y la pantalla `SoatUploadPage` fueron **eliminadas**. Para agregar/renovar SOAT usa `SoatEntryFlow.start(context, ...)` (ver §6.1).

`soatManualCapture` es ahora la ruta única para escaneo/confirmación, registro manual y edición. El flujo de creación de vehículo con imagen de SOAT adjunta navega aquí con `pushReplacementNamed` (antes usaba `SoatConfirmationPage` por `Navigator.push`, hoy eliminada).

**`SoatManualCaptureParams`** (`soat_manual_capture_params.dart`):
```
vehicle: VehicleModel?
soat: SoatModel?                 — precarga en modo edición
initialLocalImagePath: String?
extraction: SoatExtraction?      — resultado OCR para ofrecer el autocompletado
```

---

## 9. API endpoints

| Operación | Método | Endpoint | Body / Response |
|---|---|---|---|
| Obtener SOAT | `GET` | `/vehicles/{vehicleId}/soat` | → `SoatDto` (o 404 si no existe) |
| Crear / actualizar | `POST` | `/vehicles/{vehicleId}/soat` | Body: `SoatRequestJson` → `SoatDto` |
| Eliminar SOAT | `DELETE` | `/vehicles/{vehicleId}/soat` | sin body → `void` (repo lo mapea a `Right(unit)`) |

`SoatRequestJson` (forma exacta):
```json
{
  "expiryDate": "2026-12-31T00:00:00.000Z",
  "policyNumber": "ABC123456789",
  "startDate": "2026-01-01T00:00:00.000Z",
  "insurer": "Seguros XX",
  "documentUrl": "https://firebasestorage.../o/soat..."
}
```

> Definido en `ApiRoutes.vehicleSoat(vehicleId) = '/vehicles/{vehicleId}/soat'`.

---

## 10. Conexiones con otros features

| Feature | Conexión |
|---|---|
| `vehicles` | `VehicleModel.soatStatus` + `soatExpiryDate` se actualizan vía `VehicleCubit.updateSoatLocally()` tras guardar y se limpian con `VehicleCubit.clearSoatLocally()` tras eliminar. `VehicleFormView` puede iniciar el flujo SOAT (`soatManualCapture`) durante la creación del vehículo; `vehicle_soat_card.dart` y `vehicle_soat_form_slot.dart` permiten eliminar el SOAT |
| `home` | `HomeGarageSoatBadge` lee `VehicleModel.soatStatus` para mostrar pill de color |
| `notifications` | Tipos `SOAT_30D`, `SOAT_7D`, `SOAT_DAY_OF` (notificaciones programadas server-side a partir de `expiryDate`) |

---

## 11. Patrones y trampas conocidas

### Dos `SoatModel`/`SoatStatus`
Existe uno en `lib/features/soat/domain/models/soat_model.dart` (este feature) y otro en `lib/features/vehicles/domain/models/soat_model.dart`. Son tipos distintos aunque tengan campos similares. Cuando se importa, verificar cuál:
- Si se trabaja con `VehicleRepository.upsertSoat/getSoat` → tipo de feature `vehicles`.
- Si se trabaja con `SoatRepository` → tipo de feature `soat`.

### Autocompletado OCR es opt-in
El OCR (ML Kit on-device) ofrece prellenar los campos, pero **nunca** lo hace solo: aunque `SoatExtraction.shouldPrefill` sea `true`, solo se muestra el `SoatAutofillBanner` y el usuario debe pulsar "Autocompletar campos". No hay badges por campo. Ver §6.4.

### `SoatManualCapturePage` no usa Cubit
Estado local con `setState()`, invoca los use cases (`SaveSoatUseCase`, `DeleteSoatUseCase`) vía `getIt`. Inconsistente con el resto del codebase, pero es la pantalla unificada (escaneo/confirmación, manual y edición) tras eliminar `SoatFormCubit` y `SoatConfirmationPage`.

### Path de upload usa la extensión real
`SoatManualCapturePage._saveToBackend()` y `VehicleFormView._savePendingManualSoatAndPop()` construyen `soat/{vehicleId}/{ms}.{ext}` con la extensión real del archivo (`split('.').last`). Ya no se hardcodea `.jpg` (el viejo `SoatFormCubit` fue eliminado).

### Fallback de `expiryDate` con `DateTime.now()`
Si el backend devuelve `expiryDate: null` (no debería), `SoatDto.toModel()` usa `DateTime.now()`. La UI mostrará "vence hoy" engañosamente. Mejor lanzar excepción explícita.

### 404 = SOAT no existe
`SoatRepositoryImpl.getSoat()` mapea HTTP 404 a `Right(null)`. Esto es deliberado: significa "el vehículo aún no tiene SOAT registrado". Cualquier otro error sí va a `Left`.

### Borrado replicado en 4 pantallas
`vehicle_soat_card.dart` y `vehicle_soat_form_slot.dart` duplican la lógica de confirmación + `DeleteSoatUseCase` con un ícono de papelera inline, mientras `soat_data_view.dart` y `SoatManualCapturePage` reutilizan `SoatDeleteButton`. Si se cambia el copy/comportamiento de borrado, recordar los 4 sitios (ver §6.5). Todos llaman `clearSoatLocally` tras éxito.

### `SoatStatus.noSoat` no proviene de `SoatModel.status`
El getter solo retorna `valid` / `expiringSoon` / `expired`. `noSoat` se asigna externamente cuando no hay SOAT registrado (`VehicleModel.soatStatus == null`).

### `SoatUploadCubit.pickFromFile` solo PDFs
`allowedExtensions: ['pdf']`. Si se quiere permitir otras extensiones (Excel, Word), modificar este array. Nota: el único consumidor de este cubit es `SoatVehicleOptionsSheet`.

---

## 12. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo SOAT + getters de vigencia | `lib/features/soat/domain/models/soat_model.dart` |
| Modelo SOAT alternativo (vehicles) | `lib/features/vehicles/domain/models/soat_model.dart` |
| Repository interface | `lib/features/soat/domain/repository/soat_repository.dart` |
| Use cases | `lib/features/soat/domain/usecases/` |
| DTO + toRequestJson | `lib/features/soat/data/dto/soat_dto.dart` |
| Service Retrofit | `lib/features/soat/data/service/soat_service.dart` |
| Repository impl (404 handling) | `lib/features/soat/data/repository/soat_repository_impl.dart` |
| Cubit principal (carga/guardado/borrado) | `lib/features/soat/presentation/cubit/soat_cubit.dart` |
| Cubit de upload | `lib/features/soat/presentation/cubit/soat_upload_cubit.dart` |
| Cubit de escaneo OCR | `lib/features/soat/presentation/cubit/soat_scan_cubit.dart` |
| Use case de borrado | `lib/features/soat/domain/usecases/delete_soat_usecase.dart` |
| Helper de entrada (sheet + navegación) | `lib/features/soat/presentation/scan/soat_entry_flow.dart` |
| Page de status | `lib/features/soat/presentation/pages/soat_status_page.dart` |
| Page unificada manual/edición/confirmación (sin cubit) | `lib/features/soat/presentation/pages/soat_manual_capture_page.dart` |
| Launcher de escaneo (define SoatScanOutcome) | `lib/features/soat/presentation/scan/soat_scan_launcher.dart` |
| Banner opt-in de autocompletado | `lib/features/soat/presentation/widgets/soat_autofill_banner.dart` |
| Botón de borrado reutilizable | `lib/features/soat/presentation/widgets/soat_delete_button.dart` |
| Vista "Mi SOAT" (ver/renovar/eliminar) | `lib/features/soat/presentation/widgets/soat_data_view.dart` |
| Card de validez | `lib/features/soat/presentation/widgets/soat_validity_card.dart` |
| Sección de documento | `lib/features/soat/presentation/widgets/soat_document_section.dart` |
| Borrado desde detalle/edición de vehículo | `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart`, `lib/features/vehicles/presentation/form/widgets/vehicle_soat_form_slot.dart` |
| Update/clear local del status | `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` (`updateSoatLocally`, `clearSoatLocally`) |
| Endpoint | `lib/core/http/api_routes.dart` (`vehicleSoat(id)`) |
