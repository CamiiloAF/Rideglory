# Documentación del Feature: SOAT

> Última actualización: 2026-05-28  
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
   - 6.1 [Flujo con documento (foto / PDF)](#61-flujo-con-documento-foto--pdf)
   - 6.2 [Flujo manual (sin documento)](#62-flujo-manual-sin-documento)
   - 6.3 [Flujo durante creación de vehículo](#63-flujo-durante-creación-de-vehículo)
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

> **OCR opcional (autocompletar SOAT).** Desde iter OCR, la app puede leer la foto/PDF del SOAT **on-device** (ML Kit, sin backend ni nube) y **prellenar** los cuatro campos. El usuario siempre confirma antes de guardar; la entrada manual sigue disponible y es la fuente de verdad. Ver [§6.4 Sub-flujo OCR](#64-sub-flujo-ocr-autocompletar-soat).

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
    └── save_soat_usecase.dart
```

**`SoatRepository`** (interface):
```dart
Future<Either<DomainException, SoatModel?>> getSoat(String vehicleId);

Future<Either<DomainException, SoatModel>> saveSoat({
  required String vehicleId,
  required SoatModel soat,
});
```

> `getSoat` retorna `SoatModel?` — `null` significa "no hay SOAT registrado para este vehículo" (404 desde el backend mapeado a `Right(null)`).

**Use cases (todos `@injectable`)**:
- `GetSoatUseCase.call(String vehicleId)`
- `SaveSoatUseCase.call({vehicleId, soat})`

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
```

**`SoatRepositoryImpl`** maneja 404 como `Right(null)`:
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
│   ├── soat_cubit.dart            (estado SOAT cargado)
│   ├── soat_upload_cubit.dart     (selección de archivo)
│   └── soat_form_cubit.dart       (formulario con validación + upload)
├── pages/
│   ├── soat_upload_page.dart           (selecciona: foto, galería, PDF, o manual)
│   ├── soat_manual_capture_page.dart   (formulario manual; sin Cubit dedicado)
│   ├── soat_manual_capture_params.dart (extra de la ruta)
│   ├── soat_confirmation_page.dart     (post-foto: campos + validez + guardar)
│   └── soat_status_page.dart           (vista del SOAT existente)
└── widgets/
    ├── soat_status_view.dart
    ├── soat_data_view.dart
    ├── soat_empty_state.dart
    ├── soat_upload_option_card.dart
    ├── soat_manual_option_card.dart
    ├── soat_vehicle_info_card.dart
    ├── soat_vehicle_options_sheet.dart
    ├── soat_document_section.dart       (preview + reemplazo)
    ├── soat_validity_card.dart          (cálculo de vigencia en tiempo real)
    ├── soat_detail_row.dart
    ├── soat_section_header.dart
    └── soat_upload_question_header.dart
```

---

## 4. Cubits y estados

| Cubit | Archivo | DI | Estado | Notas |
|---|---|---|---|---|
| `SoatCubit` | `cubit/soat_cubit.dart` | `@injectable` | `ResultState<SoatModel>` | Lectura del SOAT (status page) |
| `SoatUploadCubit` | `cubit/soat_upload_cubit.dart` | `@injectable` | `SoatUploadState` (sealed class) | Selección de archivo (cámara, galería, PDF) |
| `SoatFormCubit` | `cubit/soat_form_cubit.dart` | `@injectable` | `SoatFormState` (freezed) | Formulario completo con upload + persistencia |

### `SoatCubit`

`ResultState<SoatModel>` — `initial`, `loading`, `data(SoatModel)`, `empty` (sin SOAT registrado), `error`.

Métodos:
- `load(vehicleId)` — `getSoat()`; si retorna null → `empty`, si retorna data → `data`.
- `save({vehicleId, soat}) → bool` — `saveSoat()`; retorna `true/false` para que la UI sepa si debe popear.

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

### `SoatFormCubit`

**`SoatFormState`** (freezed union):
```
initial()
datesUpdated({startDate?, expiryDate?})    — para re-render de SoatValidityCard
soatLoaded(SoatModel)                      — preloaded en edit
loading()
success(SoatModel)
error(DomainException)
```

**Inyecciones:**
- `VehicleRepository` (no `SoatRepository`) — usa `upsertSoat`/`getSoat` del feature vehicles.
- `ImageStorageService` — para subir imagen a Firebase.

**Estado interno:**
```
formKey: GlobalKey<FormBuilderState>
_startDate: DateTime?
_expiryDate: DateTime?
_existingDocumentUrl: String?
```

Métodos:
- `onDatesChanged({startDate?, expiryDate?})` — actualiza fechas + emite `datesUpdated` (para que `SoatValidityCard` reaccione).
- `loadExistingSoat(vehicleId)` — pre-carga via `VehicleRepository.getSoat()`.
- `submit(vehicleId, {documentImage?})`:
  1. `formKey.currentState.saveAndValidate()`.
  2. Valida `_startDate < _expiryDate`.
  3. Si hay `documentImage`, sube a `soat/{vehicleId}/{timestamp}.jpg` via `ImageStorageService.uploadImage()`.
  4. Construye `SoatModel` y llama `VehicleRepository.upsertSoat()`.
  5. Emite `success(saved)` o `error(...)`.

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

### 6.1 Flujo con documento (foto / PDF)

```
SoatUploadPage(vehicle)
  ├─ Provee SoatUploadCubit
  ├─ Botones: Cámara | Galería | PDF | Captura manual
  └─ Tap cámara → SoatUploadCubit.pickFromCamera()
                  └─ emit(SoatUploadImagePicked(XFile))

BlocListener detecta SoatUploadImagePicked:
  └─ Navigator.push(MaterialPageRoute(SoatConfirmationPage(vehicle, documentImage)))

SoatConfirmationPage(vehicle, documentImage)
  ├─ Provee SoatFormCubit
  ├─ Si vehicle.soatStatus != null → cubit.loadExistingSoat(vehicle.id!)
  ├─ Renderiza:
  │   ├─ Preview del documento (imagen o icono PDF)
  │   ├─ Form fields: policyNumber, insurer, startDate, expiryDate
  │   ├─ SoatValidityCard (calcula vigencia en vivo a partir de fechas del cubit)
  │   └─ CTA "Guardar"
  └─ "Guardar" → SoatFormCubit.submit(vehicleId, documentImage)
                  └─ Upload imagen → Firebase Storage path: soat/{vehicleId}/{timestamp}.jpg
                  └─ upsertSoat(vehicleId, soat con documentUrl)
                  └─ emit(success(saved))

Listener post-éxito:
  ├─ VehicleCubit.updateSoatLocally(vehicleId, expiryDate)
  ├─ Si !isFromVehicleCreation → router.pop() (vuelve atrás)
  └─ SnackBar "SOAT guardado"
```

### 6.2 Flujo manual (sin documento)

```
SoatUploadPage(vehicle)
  └─ Tap "Captura manual" → context.pushNamed(soatManualCapture, extra: SoatManualCaptureParams(vehicle))

SoatManualCapturePage(vehicle, existingSoat?, initialLocalImagePath?)
  ├─ NO usa Cubit — estado local con setState
  ├─ Form fields + opcional adjuntar foto/PDF via _pickDocumentBottomSheet()
  └─ Guardado:
     ├─ Modo edición (vehicle.id != null + existingSoat):
     │   ├─ Sube imagen (si hay) a soat/{vehicleId}/{timestamp}.{ext}
     │   ├─ Llama getIt<SaveSoatUseCase>(vehicleId: ..., soat: ...)
     │   └─ pop(true) si éxito
     │
     └─ Modo creación (vehicle == null o sin id):
         └─ pop(PendingManualSoat) — sin tocar backend; deja que VehicleFormPage termine de crear el vehículo + guardar SOAT
```

### 6.3 Flujo durante creación de vehículo

`VehicleFormPage` ofrece dos rutas para capturar SOAT antes de tener `vehicleId`:

1. **Adjuntar imagen + datos** durante el form de vehículo (via `VehicleFormCubit.pickSoatDocument()`):
   - Al guardar el vehículo (`POST /vehicles/my`), `VehicleFormView` hace `pushReplacement` a `SoatConfirmationPage(vehicle: saved, documentImage: ..., isFromVehicleCreation: true)`.
   - Mantiene `VehicleFormPage` fuera del back stack.

2. **Captura manual antes de tener ID** (`PendingManualSoat`):
   - Usuario llena los campos pre-creación → `VehicleFormCubit.storePendingManualSoat(data)`.
   - Al guardar el vehículo, `VehicleFormView._savePendingManualSoatAndPop()` sube imagen (si hay) + llama `VehicleRepository.upsertSoat(vehicleId, soat)` + pop.

Más detalles en [vehicles.md §13](./vehicles.md#13-patrones-y-trampas-conocidas).

### 6.4 Sub-flujo OCR (autocompletar SOAT)

Autocompletado **on-device** del SOAT desde foto/galería/PDF. Privacidad total: ni la imagen ni el texto reconocido salen del dispositivo (ML Kit local; no hay backend ni Cloud Vision).

**Disparadores.** Botón **"Escanear SOAT"** (`SoatScanButton`) en `SoatUploadPage` y en `SoatManualCapturePage`.

**Recorrido.**
1. `SoatScanLauncher.launch(context)` abre `SoatScanSourceSheet` (cámara / galería / PDF) y selecciona el archivo con `image_picker` o `file_picker`.
2. Navega a `SoatScanPage` (ruta `AppRoutes.soatScan`, extra `SoatScanParams`), que muestra `SoatScanLoader` ("Leyendo documento…").
3. `SoatScanCubit.scan()` ejecuta `ScanSoatUseCase`:
   - Si la fuente es PDF, `SoatPdfRasterizer` rasteriza la página 1 a PNG (`pdfx`) antes del OCR.
   - `MlKitOcrService.recognizeText()` → `OcrResult` (texto + bloques con bounding box).
   - `ParseSoatTextUseCase` → `SoatParser.parse()` → `SoatExtraction` con confianza por campo.
4. `SoatScanPage` hace `pop` con el `SoatExtraction` (éxito) o `pop(null)` + toast (fallo silencioso al manual).
5. La página origen abre `SoatManualCapturePage` con `extraction` + `initialLocalImagePath`. Si `SoatExtraction.shouldPrefill` (≥2 campos `high`), los campos se prellenan; cada campo OCR muestra `SoatAutofillBadge` (verde=high, naranja=medium) y se ve `SoatOcrBanner`.

**Capas / archivos.**
- Core: `lib/core/services/ocr/` (`OcrService`, `MlKitOcrService`, `OcrResult`/`OcrBlock`); `lib/core/services/analytics/` (`AnalyticsService`, `FirebaseAnalyticsService`).
- Domain: `soat/domain/models/soat_extraction.dart`, `soat_scan_result.dart`; `soat/domain/usecases/parse_soat_text_usecase.dart`, `scan_soat_usecase.dart`.
- Data: `soat/data/parser/soat_parser.dart`, `soat_insurer_rules.dart`, `soat_pdf_rasterizer.dart`.
- Presentation: `soat/presentation/cubit/soat_scan_cubit.dart`; `pages/soat_scan_page.dart`, `soat_scan_params.dart`; `scan/soat_scan_launcher.dart`; widgets `soat_scan_button`, `soat_scan_source_sheet`, `soat_scan_loader`, `soat_ocr_banner`, `soat_autofill_badge`.

**Reglas del parser** (`SoatParser`, Dart puro y testeable):
- **Aseguradora:** matching por substring normalizado (sin tildes) sobre las 10 autorizadas (Fasecolda 2026). Empate → mayor área de bloque en el cuarto superior (logo). 
- **Póliza:** cascada — label `póliza` → regex específica por aseguradora (top-5) → regex genérica.
- **Fechas:** regex multi-formato (`DD/MM/AAAA`, `DD-MM-AAAA`, `DD mmm AAAA`, ISO). Asociación a labels (`vigencia desde`/`hasta`/`vence`). **Validación dura: 360–370 días**; si falla, ambas fechas quedan `low` y no se prellenan.
- **Umbral global:** `<2` campos `high` → no se prellena nada + toast (caída silenciosa al manual).

**Telemetría** (Firebase Analytics, anónima): `soat_scan_attempted`; `soat_scan_success` (`fields_extracted_count`, `insurer_detected`, `had_pdf`); `soat_scan_failed` (`failure_reason`: `no_text_detected` / `low_confidence` / `validation_failed` / `permission_denied` / `unknown_error`).

**Permisos:** `CAMERA` + `READ_MEDIA_IMAGES` en `AndroidManifest.xml`; `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` en `Info.plist`.

> **Nota de build:** el paquete transitivo `objective_c` (de `google_mlkit_text_recognition`) declara native build hooks, lo que rompe la compilación AOT del script de build_runner en el SDK actual. Generar código con `dart run build_runner build --force-jit` (JIT) en lugar del AOT por defecto.

---

## 7. Subida del documento

Path en Firebase Storage:
```
soat/{vehicleId}/{timestampMs}.{ext}
```

- `SoatFormCubit.submit()` usa `.jpg` (hardcoded) cuando viene de `SoatConfirmationPage`.
- `SoatManualCapturePage` usa la extensión real (`.jpg`, `.png`, `.pdf`) según el archivo seleccionado.

> Pequeña inconsistencia: el flujo de confirmación asume jpg aun cuando el documento sea PDF. Si el usuario sube un PDF por `pickFromFile()`, se almacena con extensión `.jpg` por accidente. Considerar unificar.

**Si la subida falla**, el comportamiento varía:
- `SoatFormCubit.submit()` → emite `SoatFormState.error(...)`.
- `SoatManualCapturePage` (modo creación) y `VehicleFormView._savePendingManualSoatAndPop()` → **continúan** guardando el SOAT sin documentUrl y muestran warning.

---

## 8. Rutas de navegación

| Ruta | Constante | Builder | Extras |
|---|---|---|---|
| `/vehicles/soat` | `AppRoutes.vehicleSoat` | `SoatUploadPage(vehicle: extra as VehicleModel)` | `VehicleModel` |
| `/soat/upload` | `AppRoutes.soatUpload` | `SoatUploadPage(vehicle: extra as VehicleModel)` | `VehicleModel` |
| `/soat/status` | `AppRoutes.soatStatus` | `SoatStatusPage(vehicle: extra as VehicleModel)` | `VehicleModel` |
| `/soat/manual-capture` | `AppRoutes.soatManualCapture` | `SoatManualCapturePage(vehicle, existingSoat: null, initialLocalImagePath: params.initialLocalImagePath)` | `SoatManualCaptureParams` |

> `vehicleSoat` y `soatUpload` apuntan a la misma `SoatUploadPage`. Verifica cuál usar antes de duplicar navegaciones.

`SoatConfirmationPage` **no tiene ruta declarada**. Se accede vía `Navigator.push(MaterialPageRoute(...))` directamente desde `SoatUploadPage` y `VehicleFormView` (`pushReplacement`).

**`SoatManualCaptureParams`** (`soat_manual_capture_params.dart`):
```
vehicle: VehicleModel?
initialLocalImagePath: String?
```

---

## 9. API endpoints

| Operación | Método | Endpoint | Body / Response |
|---|---|---|---|
| Obtener SOAT | `GET` | `/vehicles/{vehicleId}/soat` | → `SoatDto` (o 404 si no existe) |
| Crear / actualizar | `POST` | `/vehicles/{vehicleId}/soat` | Body: `SoatRequestJson` → `SoatDto` |

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
| `vehicles` | `VehicleModel.soatStatus` + `soatExpiryDate` se actualizan vía `VehicleCubit.updateSoatLocally()` tras éxito. `SoatFormCubit` inyecta `VehicleRepository` (no `SoatRepository`). `VehicleFormView` puede iniciar el flujo SOAT durante la creación del vehículo |
| `home` | `HomeGarageSoatBadge` lee `VehicleModel.soatStatus` para mostrar pill de color |
| `notifications` | Tipos `SOAT_30D`, `SOAT_7D`, `SOAT_DAY_OF` (notificaciones programadas server-side a partir de `expiryDate`) |

---

## 11. Patrones y trampas conocidas

### Dos `SoatModel`/`SoatStatus`
Existe uno en `lib/features/soat/domain/models/soat_model.dart` (este feature) y otro en `lib/features/vehicles/domain/models/soat_model.dart`. Son tipos distintos aunque tengan campos similares. Cuando se importa, verificar cuál:
- Si se trabaja con `VehicleRepository.upsertSoat/getSoat` → tipo de feature `vehicles`.
- Si se trabaja con `SoatRepository` → tipo de feature `soat`.

### Sin OCR
La app no extrae datos del documento. El usuario digita todos los campos manualmente. Si se quiere OCR, hay que integrar (google_ml_kit, ml_text_recognition u otro) en `SoatConfirmationPage`.

### `SoatFormCubit` usa `VehicleRepository`, no `SoatRepository`
Es la única forma de aprovechar el método unificado `upsertSoat` del feature vehicles. Si se decide consolidar todo en `SoatRepository`, este cubit debe cambiar.

### `SoatManualCapturePage` no usa Cubit
Estado local con `setState()`. Inconsistente con el resto del codebase. Si se refactoriza, mover a `SoatFormCubit` con un modo "manual" extra.

### Path de upload hardcodea `.jpg`
`SoatFormCubit.submit()` siempre construye `soat/{vehicleId}/{ms}.jpg` aunque el archivo sea PDF. `SoatManualCapturePage` usa la extensión real. Considerar usar `XFile.mimeType` o `path.extension` consistentemente.

### Fallback de `expiryDate` con `DateTime.now()`
Si el backend devuelve `expiryDate: null` (no debería), `SoatDto.toModel()` usa `DateTime.now()`. La UI mostrará "vence hoy" engañosamente. Mejor lanzar excepción explícita.

### 404 = SOAT no existe
`SoatRepositoryImpl.getSoat()` mapea HTTP 404 a `Right(null)`. Esto es deliberado: significa "el vehículo aún no tiene SOAT registrado". Cualquier otro error sí va a `Left`.

### Navegación mixta GoRouter + Navigator
`SoatConfirmationPage` se abre con `Navigator.push` (no GoRouter), porque el código original venía de un push directo desde `SoatUploadPage`. Para `pop`, según `isFromVehicleCreation`:
- Si `true` (vehículo recién creado): `Navigator.of(context).pop()` (cierra solo confirmation).
- Si `false`: hace pop adicional vía `router.pop()` para volver más atrás.

Si refactorizas a GoRouter puro, revisar este flujo.

### `SoatStatus.noSoat` no proviene de `SoatModel.status`
El getter solo retorna `valid` / `expiringSoon` / `expired`. `noSoat` se asigna externamente cuando no hay SOAT registrado (`VehicleModel.soatStatus == null`).

### `SoatUploadCubit.pickFromFile` solo PDFs
`allowedExtensions: ['pdf']`. Si se quiere permitir otras extensiones (Excel, Word), modificar este array.

### Auto-pop ambiguo en `SoatConfirmationPage`
El listener post-success ejecuta `Navigator.pop()` y opcionalmente otro `router.pop()` para vehicleCreation flow. Si se cambia el origen del push, revisar para evitar pops dobles.

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
| Cubit principal (carga) | `lib/features/soat/presentation/cubit/soat_cubit.dart` |
| Cubit de upload | `lib/features/soat/presentation/cubit/soat_upload_cubit.dart` |
| Cubit del form (post-foto) | `lib/features/soat/presentation/cubit/soat_form_cubit.dart` |
| Page de upload | `lib/features/soat/presentation/pages/soat_upload_page.dart` |
| Page de status | `lib/features/soat/presentation/pages/soat_status_page.dart` |
| Page manual (sin cubit) | `lib/features/soat/presentation/pages/soat_manual_capture_page.dart` |
| Page de confirmación | `lib/features/soat/presentation/pages/soat_confirmation_page.dart` |
| Card de validez | `lib/features/soat/presentation/widgets/soat_validity_card.dart` |
| Sección de documento | `lib/features/soat/presentation/widgets/soat_document_section.dart` |
| Update local del status | `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` (`updateSoatLocally`) |
| Endpoint | `lib/core/http/api_routes.dart` (`vehicleSoat(id)`) |
