# Documentación del Feature: SOAT

> Última actualización: 2026-05-31  
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
   - 6.1 [Flujo con documento (galería / PDF) — `SoatEntryFlow`](#61-flujo-con-documento-galería--pdf--soatentryflow)
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

1. **Captura del SOAT** asociado a un vehículo: número de póliza, aseguradora, fechas de inicio/expiración, opcionalmente documento del SOAT (imagen desde galería o PDF).
2. **Visualización del estado** (`valid` / `expiringSoon` / `expired`) calculado por días hasta vencimiento.
3. **Renovación**: editar SOAT existente, reemplazar documento.
4. **Eliminación** del SOAT de un vehículo (`DELETE`), **solo** desde la pantalla "Mi SOAT" (ver [§6.5](#65-eliminar-el-soat-de-un-vehículo)).

> **Documento solo desde galería o PDF.** La captura con **cámara fue retirada** (peor lectura OCR). El documento se sube desde **Galería** o **PDF** (PDF resaltado como opción primaria). La selección está centralizada en `SoatDocumentPicker` (`presentation/scan/soat_document_picker.dart`): galería a calidad 100 sin redimensionar (el texto pequeño del SOAT necesita resolución) y PDF vía `FilePicker`. Lo usan tanto `SoatUploadCubit` (bottom sheet de opciones) como el formulario (`SoatManualCapturePage`).

> **OCR opcional (autocompletar SOAT).** La app puede leer el documento del SOAT **on-device** (ML Kit, sin backend ni nube) para luego **ofrecer** el prellenado de los campos. El OCR corre dentro de la captura (`SoatManualCapturePage`) vía `ScanSoatUseCase`; no existe una pantalla de escaneo separada. El autocompletado es **opt-in**: tras detectar un SOAT válido se muestra un banner con el botón "Autocompletar campos" y el usuario decide. La entrada manual sigue disponible y es la fuente de verdad. Si el documento no se reconoce como SOAT, se muestra un **aviso inline (warning, no bloqueante)**, no un snackbar. Ver [§6.4 Sub-flujo OCR](#64-sub-flujo-ocr-autocompletar-soat).

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
│   └── soat_upload_cubit.dart     (selección de archivo galería/PDF; usado por soat_vehicle_options_sheet)
├── pages/
│   ├── soat_manual_capture_page.dart   (formulario unificado: captura/confirmación con OCR, registro manual y edición; sin Cubit dedicado)
│   ├── soat_manual_capture_params.dart (extra de la ruta)
│   └── soat_status_page.dart           (vista del SOAT existente; provee SoatCubit)
├── scan/
│   ├── soat_document_picker.dart       (selección centralizada del documento: galería calidad 100 + PDF)
│   └── soat_entry_flow.dart            (helper: muestra el sheet de opciones y navega a la captura manual)
└── widgets/
    ├── soat_status_view.dart
    ├── soat_data_view.dart              (vista "Mi SOAT": estado + datos + lista de acciones ver/eliminar + CTA renovar)
    ├── soat_action_tile.dart            (fila de acción discreta ícono+label+chevron para la card de acciones)
    ├── soat_empty_state.dart
    ├── soat_upload_option_card.dart     (card de subida: botones Galería + PDF, PDF resaltado)
    ├── soat_manual_option_card.dart
    ├── soat_vehicle_options_sheet.dart
    ├── soat_add_document_sheet.dart     (sheet "Agregar documento" en captura manual: Galería/PDF)
    ├── soat_document_section.dart       (card del documento adjunto rediseñado: preview + cambiar/eliminar/abrir)
    ├── soat_not_recognized_warning.dart (aviso inline no bloqueante cuando el OCR no reconoce un SOAT)
    ├── soat_validity_card.dart          (cálculo de vigencia en tiempo real)
    ├── soat_autofill_banner.dart        (banner opt-in de autocompletado OCR)
    └── soat_detail_row.dart
```

> **Eliminados** en el rediseño: `soat_scan_cubit.dart`, `soat_scan_page.dart`, `soat_scan_params.dart`, `soat_scan_launcher.dart`, `soat_scan_loader.dart`, `soat_scan_source_sheet.dart`, `soat_delete_button.dart`, `soat_section_header.dart` (`SoatSectionHeader`), `SoatUploadPage` y la ruta `soatScan`. El OCR ahora corre on-the-fly dentro de `SoatManualCapturePage` (no hay launcher ni pantalla de escaneo dedicada).

---

## 4. Cubits y estados

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `SoatCubit` | `cubit/soat_cubit.dart` | `@injectable` | `ResultState<SoatModel>` | Lectura/guardado/borrado del SOAT (status page) |
| `SoatUploadCubit` | `cubit/soat_upload_cubit.dart` | `@injectable` | `SoatUploadState` (sealed class) | Selección de archivo (galería/PDF); lo consume `SoatVehicleOptionsSheet` |

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

Métodos (la captura con **cámara fue retirada**):
- `pickFromGallery()` → `SoatDocumentPicker.pickImageFromGallery()` (imagen calidad 100, sin redimensionar).
- `pickFromFile()` → `SoatDocumentPicker.pickPdf()` (`FilePicker` con `allowedExtensions: ['pdf']`).

Cualquiera de los dos emite `SoatUploadImagePicked(XFile)` al éxito y `SoatUploadInitial` si el usuario cancela.

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

### 6.1 Flujo con documento (galería / PDF) — `SoatEntryFlow`

El punto de entrada único es el helper **`SoatEntryFlow.start(context, ...)`** (`scan/soat_entry_flow.dart`). Reemplazó a la antigua `SoatUploadPage`. Lo consumen todos los puntos que antes navegaban a `AppRoutes.vehicleSoat` (garage `vehicle_soat_card`/`vehicle_soat_section`, slot del form `vehicle_soat_form_slot`, sección de docs del form, renovación en `SoatDataView`/`SoatEmptyState`). Sirve tanto para **creación** como para **edición** de vehículo.

```
SoatEntryFlow.start(context, vehicle?, onSaved?, formCubit?)
  └─ showModalBottomSheet(SoatVehicleOptionsSheet)
        ├─ SoatUploadOptionCard (Galería / PDF) → SoatOptionsUpload(image)
        └─ SoatManualOptionCard                  → SoatOptionsManual()
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

Es la **única** pantalla de captura/confirmación, registro manual y edición. (`SoatConfirmationPage` y `SoatFormCubit` fueron eliminados.) No usa Cubit dedicado: estado local con `setState`, invoca los use cases vía `getIt`.

**Título del AppBar** (`_appBarTitle`), según el caso:
- `existingSoat != null` → "Editar" (`soat_edit_title`).
- documento/OCR ya adjunto al abrir (`_isConfirmationMode`) → "Confirmar" (`vehicle_soat_confirm_title`).
- en otro caso → "Registrar" (`vehicle_soat_form_title`).

```
SoatManualCapturePage(vehicle?, existingSoat?, initialLocalImagePath?, extraction?)
  ├─ SoatDocumentSection: preview + adjuntar/cambiar (galería/PDF) o eliminar local (_pickImage → SoatAddDocumentSheet)
  ├─ Si extraction.shouldPrefill && !autofillApplied → SoatAutofillBanner (opt-in)
  │     └─ "Autocompletar campos" → _applyAutofill() (patchValue + setState fechas)
  ├─ Si el OCR no reconoce el documento → SoatNotRecognizedWarning (inline, no bloqueante)
  ├─ Form fields: policyNumber, insurer (requerido), startDate, expiryDate
  ├─ SoatValidityCard (vigencia en vivo a partir de las fechas)
  └─ Guardado (_submit):
     ├─ Modo edición (vehicle.id != null):
     │   ├─ Sube imagen/PDF nueva (si hay) a soat/{vehicleId}/{timestamp}.{ext}
     │   ├─ getIt<SaveSoatUseCase>(vehicleId, soat)
     │   └─ context.pop(true) si éxito
     └─ Modo creación (vehicle == null o sin id):
         └─ context.pop(PendingManualSoat) — sin tocar backend; VehicleFormView lo guarda tras crear el vehículo
```

> El borrado del SOAT **ya no vive en esta pantalla** (se quitó `SoatDeleteButton`). Eliminar solo es posible desde "Mi SOAT" (`SoatDataView`) — ver [§6.5](#65-eliminar-el-soat-de-un-vehículo).

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

**Disparador.** El documento se elige en `SoatVehicleOptionsSheet` (vía `SoatEntryFlow`) o se cambia desde `SoatManualCapturePage` (sheet `SoatAddDocumentSheet`). El OCR corre **dentro de `SoatManualCapturePage`** (`_scanDocument`), no en un launcher ni pantalla previa (ambos eliminados).

**Recorrido (OCR dentro de la captura manual).**
1. `SoatManualCapturePage` recibe `initialLocalImagePath` (documento ya elegido) y, en `initState`, llama `_scanDocument(path, source, autoApply: true)`. Al cambiar el documento desde `_pickImage`, vuelve a escanear (sin autoApply; ofrece el banner opt-in).
2. `_scanDocument` invoca `getIt<ScanSoatUseCase>()` directamente:
   - Si la fuente es PDF, `SoatPdfRasterizer` rasteriza la página 1 a PNG (`pdfx`) antes del OCR.
   - `MlKitOcrService.recognizeText()` → `OcrResult` (texto + bloques con bounding box).
   - `ParseSoatTextUseCase` → `SoatParser.parse()` → `SoatExtraction` con confianza por campo.
3. Si el escaneo detecta SOAT y `shouldPrefill` (≥2 campos `high`), se ofrece el `SoatAutofillBanner` (opt-in) o se aplica directamente cuando `autoApply` es true.
4. Si el escaneo lanza `SoatScanException`, se marca `_documentNotRecognized = true` y se muestra `SoatNotRecognizedWarning` inline bajo el documento (sin SnackBar, no bloqueante). El flag se limpia al elegir/quitar documento o cuando un escaneo posterior sí detecta SOAT.

> El documento se elige solo desde **galería o PDF**; `SoatScanSource.camera` sigue existiendo en el enum pero ya no se usa (la captura con cámara se retiró). `SoatScanLauncher`, `SoatScanPage` y `SoatScanCubit` fueron eliminados: el flujo de captura escanea on-the-fly dentro de la página.

**Capas / archivos.**
- Core: `lib/core/services/ocr/` (`OcrService`, `MlKitOcrService`, `OcrResult`/`OcrBlock`); `lib/core/services/analytics/` (`AnalyticsService`, `FirebaseAnalyticsService`).
- Domain: `soat/domain/models/soat_extraction.dart`, `soat_scan_result.dart` (define `SoatScanSource`/`SoatScanException`); `soat/domain/usecases/parse_soat_text_usecase.dart`, `scan_soat_usecase.dart`.
- Data: `soat/data/parser/soat_parser.dart`, `soat_insurer_rules.dart`, `soat_pdf_rasterizer.dart`.
- Presentation: el OCR vive dentro de `pages/soat_manual_capture_page.dart` (`_scanDocument`); widgets `soat_not_recognized_warning`, `soat_autofill_banner`. (Eliminados: `soat_scan_cubit`, `soat_scan_page`, `soat_scan_params`, `soat_scan_launcher`, `soat_scan_loader`, `soat_scan_source_sheet`.)

**Reglas del parser** (`SoatParser`, Dart puro y testeable):
- **Aseguradora:** matching por substring normalizado (sin tildes) sobre las autorizadas (Fasecolda). Empate → mayor área de bloque, ponderada x2 en el cuarto superior del documento (logo).
- **Póliza:** cascada — label `póliza` → regex específica por aseguradora → regex genérica. Para el label en **layout de tabla**, ancla el valor en el bloque inmediatamente **debajo** del label en la misma columna (`_closestBlockBelow`), además del token en la misma línea. Descarta **celulares colombianos** (10 dígitos que inician en 3) y **fechas**, y entre candidatos prefiere el token con **más dígitos**.
- **Fechas:** regex multi-formato (`DD/MM/AAAA`, `DD-MM-AAAA`, `DD mmm AAAA`, ISO). Asociación a labels (`vigencia desde`/`hasta`/`vence`). **Validación dura: 360–370 días**; si falla, ambas fechas quedan `low` (con `datesFailedValidation`) y no se prellenan.
- **Umbral global:** `<2` campos `high` → no se prellena (no se ofrece el banner); el usuario completa a mano.

**Telemetría** (Firebase Analytics, anónima): `soat_scan_attempted`; `soat_scan_success` (`fields_extracted_count` int, `insurer_detected` **0/1** — 1 si se detectó aseguradora, 0 si no; **nunca** viaja el nombre de la aseguradora, `had_pdf` 0/1); `soat_scan_failed` (`failure_reason`: `no_text_detected` / `low_confidence` / `validation_failed` / `permission_denied` / `unknown_error`). Constantes en `AnalyticsEvents` / `AnalyticsParams` (`lib/core/services/analytics/`).

**Permisos:** `READ_MEDIA_IMAGES` en `AndroidManifest.xml`; `NSPhotoLibraryUsageDescription` en `Info.plist`. (La captura con cámara se retiró; el permiso `CAMERA` puede seguir declarado por otros features.)

> **Nota de build:** el paquete transitivo `objective_c` (de `google_mlkit_text_recognition`) declara native build hooks, lo que rompe la compilación AOT del script de build_runner en el SDK actual. Generar código con `dart run build_runner build --force-jit` (JIT) en lugar del AOT por defecto.

> **Nota de build (R8 / release APK):** `google_mlkit_text_recognition` referencia reconocedores de otros scripts (chino, devanagari, japonés, coreano) que la app **no** empaqueta (solo usa Latin). En el build release con minificación, R8 fallaba en `:app:minifyReleaseWithR8` por esas clases ausentes. Se resolvió con reglas `-dontwarn` en `android/app/proguard-rules.pro` (enlazado vía `proguardFiles(...)` en `buildTypes.release` de `android/app/build.gradle.kts`). Si en el futuro se agrega otro plugin de ML Kit con módulos de idioma opcionales (p. ej. barcode/face por script), añadir su `-dontwarn` correspondiente ahí.

### 6.5 Eliminar el SOAT de un vehículo

El borrado (`DELETE /vehicles/{vehicleId}/soat`) ahora es posible **únicamente desde la pantalla "Mi SOAT"** (`SoatDataView`, dentro de `SoatStatusPage`). Se quitó el borrado del detalle del vehículo (`vehicle_soat_card.dart`), del slot del form de edición (`vehicle_soat_form_slot.dart`) y del formulario de captura/edición (`SoatManualCapturePage`); esos puntos hoy solo inician `SoatEntryFlow` para agregar/renovar.

En `SoatDataView` las acciones se presentan como una **lista discreta** (no botones de color apilados), con `SoatActionTile` (ícono + etiqueta + chevron) dentro de una card:
- **Ver documento** (`soat_view_document`) — solo si `documentUrl != null`; abre el archivo remoto vía `DocumentDownloader.openRemote`.
- **Eliminar** (`soat_delete_button`, tinte `error`) — pide confirmación con `ConfirmationDialog` (`DialogActionType.danger`) y, al confirmar, `context.read<SoatCubit>().delete(vehicleId)`; en éxito → `VehicleCubit.clearSoatLocally(vehicleId)` + SnackBar `soat_deleted_success` + `context.pop()`.

Por separado, cuando el SOAT está **vencido**, la vista muestra un **único CTA principal** `AppButton` "Registrar nuevo SOAT" (`soat_renew_btn`) que lanza `SoatEntryFlow.start(...)` y recarga `SoatCubit` al guardar.

**Capa:** `DeleteSoatUseCase` → `SoatRepository.deleteSoat` → `SoatService.deleteSoat`. `SoatCubit.delete()` emite `empty` en éxito y retorna `true`.

> El widget reutilizable `SoatDeleteButton` fue **eliminado**; el borrado lo encapsula directamente `SoatDataView` mediante `SoatActionTile`.

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

> Las rutas `AppRoutes.vehicleSoat` (`/vehicles/soat`), `AppRoutes.soatUpload` (`/soat/upload`), `AppRoutes.soatScan` (`/soat/scan`) y las pantallas `SoatUploadPage` / `SoatScanPage` fueron **eliminadas**. Solo quedan `soatStatus` y `soatManualCapture`. Para agregar/renovar SOAT usa `SoatEntryFlow.start(context, ...)` (ver §6.1).

`soatManualCapture` es ahora la ruta única para captura/confirmación, registro manual y edición. El flujo de creación de vehículo con documento de SOAT adjunto navega aquí con `pushReplacementNamed` (antes usaba `SoatConfirmationPage` por `Navigator.push`, hoy eliminada).

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
| `vehicles` | `VehicleModel.soatStatus` + `soatExpiryDate` se actualizan vía `VehicleCubit.updateSoatLocally()` tras guardar y se limpian con `VehicleCubit.clearSoatLocally()` tras eliminar. `VehicleFormView` puede iniciar el flujo SOAT durante la creación del vehículo; `vehicle_soat_card.dart`, `vehicle_soat_section.dart` y `vehicle_soat_form_slot.dart` lanzan `SoatEntryFlow` para agregar/renovar (ya **no** borran: el borrado vive solo en "Mi SOAT") |
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
Estado local con `setState()`, invoca los use cases (`SaveSoatUseCase`, `ScanSoatUseCase`) vía `getIt`. Inconsistente con el resto del codebase, pero es la pantalla unificada (captura/confirmación, manual y edición) tras eliminar `SoatFormCubit` y `SoatConfirmationPage`. No borra (ver §6.5).

### Captura solo desde galería o PDF
La cámara fue retirada (`SoatUploadCubit.pickFromCamera` ya no existe; `SoatDocumentPicker` solo expone galería + PDF). El enum `SoatScanSource` conserva `camera` pero no se usa.

### Path de upload usa la extensión real
`SoatManualCapturePage._saveToBackend()` y `VehicleFormView._savePendingManualSoatAndPop()` construyen `soat/{vehicleId}/{ms}.{ext}` con la extensión real del archivo (`split('.').last`). Ya no se hardcodea `.jpg` (el viejo `SoatFormCubit` fue eliminado).

### Fallback de `expiryDate` con `DateTime.now()`
Si el backend devuelve `expiryDate: null` (no debería), `SoatDto.toModel()` usa `DateTime.now()`. La UI mostrará "vence hoy" engañosamente. Mejor lanzar excepción explícita.

### 404 = SOAT no existe
`SoatRepositoryImpl.getSoat()` mapea HTTP 404 a `Right(null)`. Esto es deliberado: significa "el vehículo aún no tiene SOAT registrado". Cualquier otro error sí va a `Left`.

### Borrado centralizado en "Mi SOAT"
El borrado del SOAT vive **solo** en `soat_data_view.dart` (`SoatActionTile` "Eliminar" → `SoatCubit.delete` → `clearSoatLocally`). Se quitó de `vehicle_soat_card.dart`, `vehicle_soat_form_slot.dart` y `SoatManualCapturePage`, y el widget `SoatDeleteButton` fue eliminado. Ver §6.5.

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
| Cubit de upload (galería/PDF) | `lib/features/soat/presentation/cubit/soat_upload_cubit.dart` |
| Selección centralizada del documento | `lib/features/soat/presentation/scan/soat_document_picker.dart` |
| Use case de borrado | `lib/features/soat/domain/usecases/delete_soat_usecase.dart` |
| Use case de escaneo OCR | `lib/features/soat/domain/usecases/scan_soat_usecase.dart` |
| Helper de entrada (sheet + navegación) | `lib/features/soat/presentation/scan/soat_entry_flow.dart` |
| Page de status | `lib/features/soat/presentation/pages/soat_status_page.dart` |
| Page unificada manual/edición/confirmación (sin cubit, con OCR inline) | `lib/features/soat/presentation/pages/soat_manual_capture_page.dart` |
| Banner opt-in de autocompletado | `lib/features/soat/presentation/widgets/soat_autofill_banner.dart` |
| Vista "Mi SOAT" (estado + acciones ver/eliminar + CTA renovar) | `lib/features/soat/presentation/widgets/soat_data_view.dart` |
| Fila de acción discreta | `lib/features/soat/presentation/widgets/soat_action_tile.dart` |
| Card de validez | `lib/features/soat/presentation/widgets/soat_validity_card.dart` |
| Sección de documento (rediseño) | `lib/features/soat/presentation/widgets/soat_document_section.dart` |
| Inicio del flujo SOAT desde vehicles | `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart`, `lib/features/vehicles/presentation/form/widgets/vehicle_soat_form_slot.dart` |
| Update/clear local del status | `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` (`updateSoatLocally`, `clearSoatLocally`) |
| Endpoint | `lib/core/http/api_routes.dart` (`vehicleSoat(id)`) |

---

## 13. Abstracción `vehicle_documents/` (Fase 1 — iteración tecnomecánica)

A partir de la Fase 1 de la iteración de tecnomecánica, la lógica compartida entre documentos legales de vehículo fue extraída a `lib/features/vehicle_documents/`. SOAT fue el primer documento en migrarse a este patrón.

### Qué comparte SOAT con otros documentos

| Elemento | Ruta | Uso |
|---|---|---|
| Mixin de expiración | `lib/features/vehicle_documents/domain/vehicle_document_expiry.dart` | `daysUntilExpiry`, `documentStatus` |
| Contrato del modelo | `lib/features/vehicle_documents/domain/vehicle_document_model.dart` | Interface que `SoatModel` implementa |
| Estado de documento | `lib/features/vehicle_documents/domain/vehicle_document_status.dart` | `valid`, `expiringSoon`, `expired`, `none` |
| Kind enum | `lib/features/vehicle_documents/domain/vehicle_document_kind.dart` | `soat`, `rtm` |
| Cubit base | `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart` | `VehicleDocumentCubit<T>` abstracto |
| Widgets genéricos | `lib/features/vehicle_documents/presentation/widgets/` | `DocumentStatusView`, `DocumentDataView`, `DocumentEmptyState`, `DocumentDetailRow`, `DocumentSectionHeader`, `DocumentValidityCard` |

### Renombrado `VehicleSoatFormData`

El modelo de datos del formulario de vehículo fue renombrado de `SoatData` a `VehicleSoatFormData` para evitar confusión con `SoatModel` del feature SOAT.

### Agregar un tercer documento

Para agregar un nuevo documento legal (ej. seguros adicionales):
1. Crear `lib/features/<doc>/domain/models/<doc>_model.dart` que implemente `VehicleDocumentModel` y use el mixin `VehicleDocumentExpiry`.
2. Crear cubit concreto que extienda `VehicleDocumentCubit<DocModel>`.
3. Reusar los widgets genéricos de `vehicle_documents/presentation/widgets/` pasando el copy como parámetros.
4. Añadir el `kind` correspondiente al enum `VehicleDocumentKind`.
5. No duplicar lógica de expiración ni widgets en el feature nuevo.
