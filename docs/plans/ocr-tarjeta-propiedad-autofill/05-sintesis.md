# 05 — Síntesis Final: OCR Tarjeta de Propiedad Autofill

**Timestamp:** 2026-06-19T20:03:55Z
**Slug:** `ocr-tarjeta-propiedad-autofill`
**Veredicto:** Plan consolidado listo para ejecución (v2 — corrección de auditor Opus)

---

## Overview

Feature Flutter-only de 6 fases que permite al rider fotografiar su tarjeta de propiedad colombiana desde el formulario de vehículo y ver los campos (marca, modelo, año, placa, VIN) completados automáticamente via OCR on-device (ML Kit). Sin cambios de backend ni migraciones. El flujo reutiliza la infraestructura OCR del feature SOAT y extiende el formulario de vehículo existente con un cubit local, un parser dedicado y un banner activo.

---

## Cambios aplicados

Los siguientes ajustes de Architect (A1–A5) y Plan Reviewer (obligatorios y recomendados) se incorporan en las especificaciones de fase. La corrección v2 del Auditor Opus actualiza REC-5 con el tipo confirmado del campo `year` y añade una nota de precaución sobre homónimos en la fase 1.

| ID | Origen | Fase afectada | Descripción |
|----|--------|---------------|-------------|
| A1 | Arch | 2 | Scope explícito: `DocumentSourceSheet` solo para property card scanner; no migra SOAT. Placement: `lib/shared/widgets/modals/document_source_sheet.dart`. |
| A2 | Arch | 5 | `VehicleScanCubit` como `BlocProvider` local en `VehicleFormPage` (tercer provider junto a `VehicleFormCubit` y `FormImageCubit`; nunca añadirlo al `MultiBlocProvider` raíz en `main.dart`). |
| A3 | Arch | 1 | Ampliar limpieza con `vehicle_selector.dart` (`lib/features/vehicles/presentation/widgets/vehicle_selector.dart`), también huérfano. |
| A4 | Arch | 3 | `PropertyCardExtraction.shouldPrefill` usa `static const int _minHighFields = 2` con comentario inline; no literal mágico. |
| A5 | Arch | 5 | `VehicleFormCubit.prefillFromScan()` es método síncrono que NO emite `VehicleFormState`; solo llama `didChange()` en los campos del `FormBuilder`. |
| OBL-1 | Plan Reviewer | 2 | Contrato de retorno del sheet: `enum DocumentSourceOption { camera, gallery }` (no `int`). Documentar en spec de fase 2. |
| OBL-2 | Plan Reviewer | 5 | `VehicleScanBanner` se convierte en `BlocBuilder<VehicleScanCubit, ResultState<PropertyCardExtraction>>`; el archivo existente se edita, no se reemplaza. Prefill desde `BlocListener` en `VehicleFormBody`. |
| OBL-3 | Plan Reviewer | 3 | Umbral `shouldPrefill` como constante nombrada `kMinHighConfidenceFields = 2` con comentario que indica necesidad de ajuste con tarjetas reales. |
| REC-4 | Plan Reviewer | 5 | Criterio de aceptación: tras `ResultState.error`, el banner vuelve a idle con `GestureDetector` activo (reintento disponible, sin quedar bloqueado). |
| REC-5 | Auditor Opus (v2) | 5 | **Tipo del campo `year` confirmado:** el campo vive en `lib/features/vehicles/presentation/form/widgets/vehicle_form_basic_section.dart` como `AppTextField(name: VehicleFormFields.year, keyboardType: TextInputType.number)`. Su valor en el `FormBuilder` es `String`; el cubit lo parsea con `int.tryParse()` al guardar (`vehicle_form_cubit.dart` línea 183). `prefillFromScan()` debe llamar `didChange(extraction.year)` pasando el año como `String` (e.g. `'2019'`), no como `DateTime` ni `int`. No hay `AppDatePicker` involucrado. |
| REC-6 | Plan Reviewer | 5/6 | String de instrucción 'cara frontal' como subtítulo dentro del `DocumentSourceSheet` (antes de elegir fuente). Posición exacta: debajo del título del sheet, antes de las opciones cámara/galería. Clave ARB en fase 6. |
| NOTA-1 | Auditor Opus (v2) | 1 | **Homónimos activos vs. huérfanos:** en `presentation/form/widgets/` existen archivos con nombres similares a los huérfanos: `vehicle_form_add_more_doc_slot.dart`, `vehicle_form_section_label.dart` (→ `vehicle_form_section_header.dart`), `vehicle_form_cover_empty_state.dart` (vs. `vehicle_form_empty_cover_state.dart`), `vehicle_form_cover_image_preview.dart` (vs. `vehicle_form_image_preview.dart`), `vehicle_form_cover_outline_button.dart` (vs. `vehicle_form_outline_button.dart`). El implementador debe borrar **solo** los archivos bajo `presentation/widgets/` (los huérfanos listados) y **no** los de `presentation/form/widgets/` (activos). Verificar la ruta completa antes de cada `git rm`. |

---

## Lista final de fases

| # | Título | Objetivo | dependsOn | Nivel | Por qué ese nivel |
|---|--------|----------|-----------|-------|-------------------|
| 1 | Limpieza de código muerto | Eliminar 10 archivos huérfanos: el cluster `vehicle_form` bajo `presentation/widgets/` (`vehicle_form.dart`, `vehicle_form_cover_photo_section.dart`, `vehicle_form_documents_section.dart`, `vehicle_form_add_more_doc_slot.dart`, `vehicle_form_empty_cover_state.dart`, `vehicle_form_image_preview.dart`, `vehicle_form_outline_button.dart`, `vehicle_form_section_label.dart`, `vehicle_form_scan_banner.dart`) más `vehicle_selector.dart` (A3). `dart analyze` + `flutter test` pasan limpios. Ver NOTA-1 sobre homónimos. | — | **lite** | Solo borrado de archivos. Sin lógica nueva, sin contratos, sin DI, reversible (git revert). Blast radius mínimo; `dart analyze` + `flutter test` verifican ausencia de regresión. |
| 2 | Shared DocumentSourceSheet | Crear `lib/shared/widgets/modals/document_source_sheet.dart`: `StatelessWidget` con retorno `enum DocumentSourceOption { camera, gallery }`. Subtítulo de instrucción 'cara frontal' incluido (posición: debajo del título, antes de las opciones). Sin lógica de cubit ni de dominio. No migra SOAT (A1, OBL-1, REC-6). | 1 | **lite** | Widget stateless puro. Una sola área (shared/widgets/modals). Sin code-gen, sin migraciones, sin contratos API. Alcance explícitamente restringido. |
| 3 | Domain layer + parser con tests | `PropertyCardExtraction` (domain/models), `PropertyCardScanResult` (domain/models), `PropertyCardParser` (@injectable, data/parser), `ParsePropertyCardTextUseCase` (domain/usecases). Constante `kMinHighConfidenceFields = 2` con comentario de ajuste (A4, OBL-3). ≥6 fixtures en `test/features/vehicles/data/parser/`. Etiquetas RUNT documentadas en comentarios del parser. | 2 | **normal** | Lógica de parseo con heurística de confianza, modelos de dominio nuevos y suite de tests. Riesgo medio: los patrones RUNT asumidos pueden no cubrir toda la variedad real. No hay contratos API ni migraciones, pero requiere validación rigurosa con fixtures y el umbral puede requerir iteración. |
| 4 | Use case de escaneo + telemetría | `ScanPropertyCardUseCase` (@injectable): `OcrService` → `ParsePropertyCardTextUseCase` → 3 eventos GA4 (`propertyScanAttempted`, `propertyScanSuccess` con `fieldsExtractedCount`, `propertyScanFailed` con `failureReason`). Replica `ScanSoatUseCase` sin la rama PDF. | 3 | **lite** | Use case plano sin freezed, sin HTTP propio, sin cambios de backend. Los eventos GA4 usan params ya existentes en `AnalyticsParams`. Riesgo bajo y reversible. |
| 5 | Presentación: banner activo + prefill | `VehicleScanCubit` (`@injectable`, `BlocProvider` local en `VehicleFormPage` como tercer provider — A2). Editar `vehicle_scan_banner.dart` para convertirlo en `BlocBuilder<VehicleScanCubit, ResultState<PropertyCardExtraction>>` (3 estados: idle / loading / error-reintento — OBL-2, REC-4). `BlocListener` en `VehicleFormBody` dispara `prefillFromScan()`. `VehicleFormCubit.prefillFromScan()` síncrono vía `didChange()` sin emitir estado (A5): campo `year` se pasa como `String` (confirmado — REC-5). Descomentar `VehicleScanBanner()` en `VehicleFormBody`. | 4 | **normal** | UI con estados múltiples, gotcha crítico de timing (`formKey` nulo), restricción de no emitir estado en prefill, y varios invariantes de arquitectura que el auditor debe verificar (BlocBuilder sin métodos `_buildXxx`, listener vs. banner, provider local vs. singleton). Riesgo medio-alto en UX si el banner o el listener se conectan incorrectamente. |
| 6 | QA, strings es-CO y documentación | Todos los textos en `app_es.arb`: título banner, subtítulo banner, instrucción cara frontal (en sheet), snackbars éxito/error-bajo-confianza/error-técnico. Verificar permisos `NSCameraUsageDescription`, `CAMERA` y `READ_MEDIA_IMAGES`. `flutter test` + `dart analyze` pasan. No regresión SOAT (`flutter test test/features/soat/`). Actualizar `docs/features/vehicles.md` si existe. | 5 | **lite** | Fase de verificación y l10n. Sin lógica nueva. Cambios mecánicos: añadir claves ARB, confirmar permisos, correr suites existentes. Reversible. |

---

## Supuestos y riesgos

### Supuestos vigentes (del PO, sin cambios)

1. No hay fixtures reales de tarjetas de propiedad en el repo. Los tests usarán texto sintético que imita el layout RUNT.
2. RTM (Tecnomecánica) no migra en v1. `TecnomecanicaEntryFlow` no usa `DocumentSourceSheet`.
3. `SoatAddDocumentSheet` y `SoatVehicleOptionsSheet` no se tocan.
4. `VehicleScanCubit` es cubit local al formulario (no persiste fuera de la sesión).
5. El prefill sobreescribe datos manuales existentes en modo edición (v1 sin dialog de confirmación).
6. Permisos de cámara y galería ya están declarados por el feature SOAT.
7. Sin cambios de backend. Endpoints existentes no modificados.
8. Sin dependencias nuevas en `pubspec.yaml`.

### Riesgos consolidados

| # | Riesgo | Probabilidad | Impacto | Mitigación en el plan |
|---|--------|-------------|---------|----------------------|
| R1 | Falsos negativos del parser en tarjetas físicas reales (tipografía RUNT, deterioro, iluminación) | Alta | Medio | `kMinHighConfidenceFields` como constante nombrada con comentario de ajuste; telemetría `propertyScanFailed` con `failureReason` para diagnosticar en producción. |
| R2 | `formKey.currentState` nulo en el momento del prefill (carrera de condición) | Media | Alto (falla silenciosa) | Prefill disparado desde `BlocListener` en `VehicleFormBody`, nunca desde el cubit ni desde dentro del banner. `BlocProvider<VehicleScanCubit>` montado antes del `FormBuilder` en el árbol de `VehicleFormPage`. |
| R3 | Borrar accidentalmente un archivo activo de `form/widgets/` confundiéndolo con su homónimo huérfano en `presentation/widgets/` | Baja | Medio | NOTA-1 lista los pares de homónimos y exige verificar la ruta completa antes de cada `git rm`. Gate de fase 1: `dart analyze` + `flutter test` pasan antes de avanzar. |
| R4 | Scope creep en `DocumentSourceSheet` (PDF / opción Manual) | Baja | Bajo | Spec de fase 2 restringe explícitamente a `{ camera, gallery }`. Cualquier extensión es v2. |
| R5 | Regresión en SOAT durante la limpieza de la fase 1 | Baja | Medio | Verificar con `grep` + `dart analyze` que cero archivos activos importan los huérfanos antes de borrar. `flutter test test/features/soat/` al final de la fase. |
| R6 | `build_runner` falla en entornos frescos (gotcha `objective_c`) | Media (conocido) | Medio | Usar `--force-jit`; copiar `.env` y configs Firebase antes de correr (ver `project_build_runner_force_jit.md`). |
| R7 | Dos banners con nombres similares confunden al implementador de fase 5 | Baja-Media | Bajo | Gate de fase 1 verifica que `vehicle_form_scan_banner.dart` (huérfano, bajo `presentation/widgets/`) ya no existe antes de avanzar a fase 5. El banner activo correcto es `form/widgets/vehicle_scan_banner.dart`. |

### Deuda técnica registrada (fuera de scope)

- `SoatAddDocumentSheet` importado desde `tecnomecanica_manual_capture_page.dart` (cross-feature coupling). No se toca; registrado para v2.
- Migración de `SoatAddDocumentSheet` y `SoatVehicleOptionsSheet` a `DocumentSourceSheet` en una futura iteración de SOAT.
