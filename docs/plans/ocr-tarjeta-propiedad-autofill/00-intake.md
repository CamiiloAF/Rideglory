# Intake — OCR Tarjeta de Propiedad Autofill

**Timestamp:** 2026-06-19T19:47:04Z
**Slug:** `ocr-tarjeta-propiedad-autofill`

---

## Fuente

`docs/prds/prd-ocr-tarjeta-propiedad-autofill.md`

---

## Objetivo

Activar el scanner de tarjeta de propiedad colombiana en el formulario de vehículo: el rider toma foto (o elige de galería) y el formulario se prellena automáticamente con los campos extraídos via OCR on-device (ML Kit), reutilizando toda la infraestructura ya construida para el feature SOAT.

---

## Alcance percibido

### Piezas a crear
- **`PropertyCardExtraction`** — modelo puro en domain con campos nullable + confianza por campo.
- **`ParsePropertyCardTextUseCase`** — función pura `OcrResult → PropertyCardExtraction`.
- **`ScanPropertyCardUseCase`** — orquesta `OcrService → parse → telemetría` (clon del patrón SOAT, sin rama PDF).
- **`PropertyCardParser`** — Dart puro, reglas + regex sobre etiquetas RUNT; stateless y testeable con fixtures.
- **`VehicleScanCubit`** — `Cubit<ResultState<PropertyCardExtraction>>`; registrado en DI.
- Método **`VehicleFormCubit.prefillFromScan(PropertyCardExtraction)`** — reemplaza todos los campos extraídos con confianza `high`/`medium`.
- Tests unitarios del parser (≥6 fixtures: motos, carros, casos negativos).

### Piezas a modificar/migrar
- **`SoatAddDocumentSheet`** → mover/refactorizar a `lib/shared/widgets/document_source_sheet.dart` como `DocumentSourceSheet` parametrizable (`showCamera`, `showGallery`, `showPdf`, `instruction`). SOAT y RTM migran sin cambio de comportamiento.
- **`VehicleScanBanner`** — descomentar en `vehicle_form_body.dart` (líneas 35–36 + import); conectar `onTap` al cubit → `DocumentSourceSheet`.
- **`app_es.arb`** — reutilizar/añadir strings: loader, toasts, instrucción de cara frontal.

### Limpieza de código muerto
- Eliminar set duplicado del form viejo en `presentation/widgets/vehicle_form*.dart` (8 archivos huérfanos del refactor iter-6).

### Fuera de alcance (v1)
- Sin PDF (no se usa `SoatPdfRasterizer`).
- Sin OCR en backend ni subida de imagen.
- Sin Nº motor/chasis en el modelo.
- Sin overlay guía de cámara.

### Fases propuestas (del PRD §8)
1. Limpieza previa — borrar set duplicado; `dart analyze` limpio.
2. Shared sheet — `DocumentSourceSheet`; migrar SOAT y RTM.
3. Domain + parser — `PropertyCardExtraction`, `ParsePropertyCardTextUseCase`, `PropertyCardParser` + tests con fixtures.
4. Use case + scan — `ScanPropertyCardUseCase` + telemetría.
5. Presentation — `VehicleScanCubit`, restaurar banner, wiring `DocumentSourceSheet` → cubit → `VehicleFormCubit.prefillFromScan`.
6. QA + docs — strings es-CO, permisos, `flutter test`/`dart analyze`, doc del feature.

---

## Preguntas abiertas

1. **Fixtures reales del parser:** ¿Existen ya fixtures (imágenes o text dumps) de tarjetas de propiedad moto/carro para los tests? Si no, los tests unitarios del parser deberán fabricarse con texto sintético que imite el layout RUNT — ¿es aceptable como punto de partida?
2. **Migración SOAT/RTM:** Al mover `SoatAddDocumentSheet` a shared, ¿hay riesgo de que la fase 2 rompa el feature SOAT en la sesión actual? Confirmar que la suite de tests cubre el sheet de SOAT antes de moverlo.
3. **Permisos cámara/galería:** El PRD los da por confirmados; verificar en `AndroidManifest.xml` e `Info.plist` antes de la fase 5, no al final del QA.
4. **`VehicleScanCubit` en el árbol BLoC:** Según la regla "Evitar Cubits singleton", este cubit debería ir como `BlocProvider` en el árbol de la pantalla de formulario de vehículo (no `@singleton`). ¿Se confirma que no es necesario persistir el estado de scan más allá de la sesión del formulario?
5. **Política de reemplazo en edición:** El PRD dice que escanear siempre reemplaza todos los campos (`high`/`medium`). En modo edición, si el usuario tenía datos manuales, ¿se le muestra una confirmación antes de sobreescribir, o simplemente el snackbar posterior es suficiente?
