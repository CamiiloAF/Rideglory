# 03 — Architect Review: OCR Tarjeta de Propiedad Autofill

**Timestamp:** 2026-06-19T19:54:05Z
**Slug:** `ocr-tarjeta-propiedad-autofill`
**Verdict:** `ok_con_ajustes`

---

## Validación por fase

### Fase 1 — Limpieza de código muerto

**Complejidad:** baja

**Validación:** Correcta. El cluster huérfano está perfectamente delimitado:

- Raíz del cluster: `lib/features/vehicles/presentation/widgets/vehicle_form.dart`
- Dependientes exclusivos de esa raíz (solo se importan entre sí):
  `vehicle_form_cover_photo_section.dart`, `vehicle_form_documents_section.dart`,
  `vehicle_form_add_more_doc_slot.dart`, `vehicle_form_empty_cover_state.dart`,
  `vehicle_form_image_preview.dart`, `vehicle_form_outline_button.dart`,
  `vehicle_form_section_label.dart`, `vehicle_form_scan_banner.dart`
- `vehicle_selector.dart` bajo `presentation/widgets/` también está huérfano
  (el `VehicleSelector` que usa la app vive en `shared/widgets/`, no aquí). Se puede
  incluir en la limpieza sin riesgo.

**Procedimiento de verificación obligatorio (para el implementador):** antes de borrar
cada archivo, confirmar con `dart analyze` que cero archivos activos lo referencian.
Borrar todos de una sola pasada y re-ejecutar `dart analyze` + `flutter test` al
finalizar. Si algún import escapa al análisis estático, los tests lo capturan.

**Sin cambios de API, DI, ni code-gen.** Esta fase es autónoma y prerequisito correcto
para las demás.

---

### Fase 2 — Shared document source sheet

**Complejidad:** baja

**Validación:** Aceptable con ajuste de scope (ver sección Ajustes). El widget
`DocumentSourceSheet` es un bottom sheet simple (cámara + galería, sin PDF, sin opción
Manual) que sirve únicamente al property card scanner. Su contrato de retorno debe
ser un `sealed class DocumentSourceOption` con variantes `camera` y `gallery` — no
un entero (`int` como usa `SoatAddDocumentSheet`) para evitar repetir esa deuda de
legibilidad.

**Placement:** `lib/shared/widgets/modals/document_source_sheet.dart`. Justificación:
ya existen `AppDialog` y `ConfirmationDialog` en ese directorio y el sheet es verdaderamente
genérico (sin lógica de cubit ni de dominio).

**Advertencia sobre `SoatAddDocumentSheet`:** el scan de SOAT ya es usado también desde
`tecnomecanica_manual_capture_page.dart` (cross-feature import). Esto no se toca en
esta fase — se documenta como deuda técnica futura.

**Sin cambios de DI ni code-gen.** Widget stateless puro.

---

### Fase 3 — Domain layer + parser con tests

**Complejidad:** media

**Validación:** Correcta. El patrón replicado de SOAT es sólido:

| Pieza nueva | Patrón de referencia |
|---|---|
| `PropertyCardExtraction` | `SoatExtraction` (mismo `OcrFieldConfidence` enum, reutilizable) |
| `PropertyCardScanResult` | `SoatScanResult` (wrapper + excepción sealed) |
| `PropertyCardParser` | `SoatParser` (stateless `@injectable`, mismo contrato `parse(OcrResult)`) |
| `ParsePropertyCardTextUseCase` | `ParseSoatTextUseCase` (wrapper 1:1) |

**Ruta de archivos definitiva:**

```
lib/features/vehicles/domain/models/property_card_extraction.dart
lib/features/vehicles/domain/models/property_card_scan_result.dart
lib/features/vehicles/data/parser/property_card_parser.dart
lib/features/vehicles/domain/usecases/parse_property_card_text_usecase.dart
```

Rationale: la tarjeta de propiedad es un documento de vehículo; pertenece al feature
`vehicles`, no a uno nuevo. `PropertyCardParser` vive en `data/` (lógica de transformación
de texto externo), los modelos y el use case en `domain/`.

**Tests:** ubicar en `test/features/vehicles/data/parser/property_card_parser_test.dart`.
Mínimo 6 fixtures sintéticos:
1. Tarjeta de carro con los 5 campos presentes (caso feliz).
2. Moto con marca/modelo concatenados en una sola línea (RUNT moto).
3. Tarjeta deteriorada con VIN ausente (≥2 campos `high`, `shouldPrefill = true`).
4. Imagen sin texto de tarjeta (0 campos, `shouldPrefill = false`).
5. Layout con campo MODELO/AÑO en una sola celda (parser debe separar año).
6. Placa con formato antiguo de 3 letras + 3 dígitos vs. nuevo 3+2.

**`shouldPrefill` para property card:** la heurística de SOAT (`≥2 high`) se adopta
directamente. Si los datos reales muestran que el umbral es incorrecto, se ajusta el
parser sin tocar la fase de presentación.

**Sin cambios de API ni de backend.**

---

### Fase 4 — Use case de escaneo + telemetría

**Complejidad:** baja-media

**Validación:** Correcta. `ScanPropertyCardUseCase` es una simplificación de
`ScanSoatUseCase` (elimina la rama `SoatPdfRasterizer`). Contrato:

```dart
@injectable
class ScanPropertyCardUseCase {
  const ScanPropertyCardUseCase(
    this._ocrService,
    this._parsePropertyCardText,
    this._analytics,
  );

  Future<PropertyCardScanResult> call({required File file}) async { ... }
}
```

**Tres eventos GA4 nuevos en `AnalyticsEvents`:**
- `propertyScanAttempted` — al inicio del call, antes del OCR
- `propertyScanSuccess` — con param `fieldsExtractedCount` (int)
- `propertyScanFailed` — con param `failureReason` (string)

`AnalyticsParams.fieldsExtractedCount` y `failureReason` **ya existen** — no hay
que añadir params nuevos.

**Registro DI:** `ScanPropertyCardUseCase` y `ParsePropertyCardTextUseCase` son
`@injectable` (no singleton); se resuelven automáticamente si los archivos tienen la
anotación. No se añaden al `MultiBlocProvider` raíz.

**Sin code-gen adicional** (no hay freezed en estos use cases — son clases planas).

---

### Fase 5 — Presentación: banner activo + prefill del formulario

**Complejidad:** media

**Validación:** Correcta con una advertencia crítica sobre el timing del prefill.

**`VehicleScanCubit`:**

```dart
// lib/features/vehicles/presentation/cubit/vehicle_scan_cubit.dart
@injectable
class VehicleScanCubit extends Cubit<ResultState<PropertyCardExtraction>> {
  VehicleScanCubit(this._scanPropertyCard) : super(const ResultState.initial());

  final ScanPropertyCardUseCase _scanPropertyCard;

  Future<void> scan(File file) async {
    emit(const ResultState.loading());
    try {
      final result = await _scanPropertyCard(file: file);
      emit(ResultState.data(data: result.extraction));
    } on PropertyCardScanException catch (e) {
      emit(ResultState.error(error: DomainException(message: e.reason.analyticsValue)));
    }
  }
}
```

**Registro en `VehicleFormPage`:** añadir `BlocProvider<VehicleScanCubit>` al
`MultiBlocProvider` existente (junto a `VehicleFormCubit` y `FormImageCubit`).

**Timing del prefill — gotcha crítico:** `VehicleFormCubit.prefillFromScan()` llama
a `formKey.currentState?.fields[key]?.didChange(value)`. Si el cubit emite el
resultado antes de que `FormBuilder` haya montado sus campos (carrera de condición
en el primer frame), `fields[key]` es `null` y el prefill falla silenciosamente.

**Solución validada:** el prefill NO debe dispararse directamente desde el cubit.
En `VehicleFormBody` (o en un listener dentro de `VehicleFormView`), añadir un
`BlocListener<VehicleScanCubit, ResultState<PropertyCardExtraction>>` que, al
recibir el estado `data`, llama a
`context.read<VehicleFormCubit>().prefillFromScan(extraction)`. Esto garantiza que
el form está montado antes de que se ejecute `didChange`.

**`prefillFromScan` en `VehicleFormCubit`:** método que itera los campos de
`PropertyCardExtraction` con confianza `high` o `medium` y los aplica vía
`formKey.currentState?.fields[VehicleFormFields.X]?.didChange(value)`. No emite
un nuevo estado de `VehicleFormState` — solo actualiza el `FormBuilder` en caliente.

**Desconectar el banner comentado:** en `vehicle_form_body.dart` líneas 35-36,
descomentar `VehicleScanBanner()` y conectar su `onTap` para disparar el
`DocumentSourceSheet` → imagen → `VehicleScanCubit.scan()`.

---

### Fase 6 — QA, strings es-CO y documentación

**Complejidad:** baja

**Validación:** Correcta. Checklist arquitectónico obligatorio:

1. `dart analyze` sin warnings en código nuevo.
2. `flutter test test/features/vehicles/data/parser/property_card_parser_test.dart`
   pasa con ≥6 fixtures.
3. Cero strings hardcodeados en el flow de scan: verificar con
   `grep -rn '"[A-Z]' lib/features/vehicles/presentation/form/` — todos deben ser
   `context.l10n.*`.
4. Permisos cámara/galería: `NSCameraUsageDescription` en `Info.plist` y
   `CAMERA` + `READ_MEDIA_IMAGES` en `AndroidManifest.xml`. Confirmar que ya existen
   (feature SOAT los declara); si no, añadir.
5. Test de no-regresión SOAT: `flutter test test/features/soat/` debe pasar sin
   modificaciones.

**Documentación mínima:** actualizar `docs/features/vehicles.md` (si existe) para
reflejar el flow de scan de tarjeta de propiedad.

---

## Contratos

### Backend (rideglory-api)

**Ningún cambio requerido.** Las 6 fases son Flutter-only. El guardado del vehículo
usa los endpoints existentes sin modificación:

| Microservicio | Endpoint | Estado |
|---|---|---|
| `vehicles-ms` | `POST /vehicles` | Sin cambios — recibe los mismos campos |
| `vehicles-ms` | `PATCH /vehicles/:id` | Sin cambios — recibe los mismos campos |

### Code-gen

| Fase | Code-gen requerido | Detalle |
|---|---|---|
| 1 | No | Solo borrado de archivos |
| 2 | No | Widget stateless puro |
| 3 | No | Modelos de dominio inmutables con `const` factory manual (misma forma que `SoatExtraction`); `PropertyCardParser` es stateless plano |
| 4 | No | Use cases sin freezed |
| 5 | Sí — `dart run build_runner build` | `VehicleFormState` solo si se añade un campo nuevo; `VehicleScanCubit` sin freezed pero **verificar** que `injection.config.dart` se regenera para registrar `VehicleScanCubit` y `ScanPropertyCardUseCase` |
| 6 | Sí — `flutter gen-l10n` | Al añadir keys a `app_es.arb` |

### WebSocket

No interviene. Este feature es 100% on-device; no hay comunicación en tiempo real.

### Migraciones de datos

Ninguna. No hay cambio de esquema en rideglory-api ni en ninguna base de datos.

---

## Riesgos

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R1 | Parser produce falsos negativos en tarjetas reales (variaciones tipográficas RUNT, deterioro, brillo) | Alta | Medio | Documentar etiquetas RUNT asumidas en comentarios del parser; umbral `shouldPrefill` configurable como constante; analítica `propertyScanFailed` con `failureReason` permite medir el porcentaje en producción |
| R2 | Carrera de condición en prefill: `formKey.currentState` nulo | Media | Alto (falla silenciosa) | Dispatch del prefill desde `BlocListener` en el widget, nunca directamente desde el use case o cubit; documentado en Fase 5 |
| R3 | `SoatAddDocumentSheet` importado desde `tecnomecanica_manual_capture_page.dart` — cross-feature coupling no detectado inicialmente | Baja (ya detectado) | Bajo | No se toca en este plan; se registra como deuda técnica en el archivo de documentación final |
| R4 | `VehicleFormState` no tiene campo para el resultado del scan — si se requiere persistir el estado de scan más allá de la sesión del cubit | Baja | Bajo | `VehicleScanCubit` es local al form; el estado del scan no necesita persistir en `VehicleFormState`; si v2 lo requiere, añadir campo en ese momento |
| R5 | build_runner falla en entornos frescos por gotcha de `objective_c` | Media (conocido) | Medio | Usar `--force-jit` según `project_build_runner_force_jit.md`; copiar `.env` y configs Firebase antes de correr |

---

## Ajustes

### Ajuste A1 — Scope de Fase 2 (documentado explícitamente)

La fase 2 crea `DocumentSourceSheet` **solo** para el property card scanner. No migra
`SoatAddDocumentSheet` ni `SoatVehicleOptionsSheet`. El scope restringido ya estaba
implícito en el supuesto 3 del PO pero debe quedar explícito en el plan de fase para
que el implementador no intente la migración de SOAT como "mejora voluntaria".

**Placement concreto:** `lib/shared/widgets/modals/document_source_sheet.dart`.

**Retorno tipado:** `sealed class DocumentSourceOption { const factory DocumentSourceOption.camera() = _Camera; const factory DocumentSourceOption.gallery() = _Gallery; }` — no un `int`.

### Ajuste A2 — `VehicleScanCubit` conectado en `VehicleFormPage`, no como singleton

La Fase 5 debe especificar explícitamente que `VehicleScanCubit` se añade a
`VehicleFormPage.MultiBlocProvider` como tercer provider local. El implementador debe
asegurarse de NO añadirlo al `MultiBlocProvider` raíz en `main.dart`.

### Ajuste A3 — Ampliar limpieza Fase 1 con `vehicle_selector.dart` huérfano

El archivo `lib/features/vehicles/presentation/widgets/vehicle_selector.dart` contiene
`VehicleSelector` que no está importado desde ningún punto activo del árbol. La clase
`VehicleSelector` que sí usa la app vive en `lib/shared/widgets/`. Incluir este archivo
en la limpieza de la fase 1 para consistencia.

### Ajuste A4 — `PropertyCardExtraction.shouldPrefill` con umbral explícito

`shouldPrefill` debe documentar su umbral en un comentario inline:
`/// Returns true when at least [_minHighFields] fields have [OcrFieldConfidence.high] confidence.`
Y el umbral debe ser una constante nombrada (`static const int _minHighFields = 2`),
no un literal mágico. Esto facilita ajustarlo con datos reales sin búsqueda de regex.

### Ajuste A5 — Método `prefillFromScan` no emite estado

Confirmar en el plan de Fase 5 que `VehicleFormCubit.prefillFromScan()` es un
método síncrono que NO emite un nuevo `VehicleFormState`. Solo llama a
`formKey.currentState?.fields[key]?.didChange()` para cada campo. Si el implementador
lo hace `emit(state.copyWith(...))`, introduce una reconstrucción de formulario
innecesaria que puede resetear el estado de validación de campos no prefillados.
