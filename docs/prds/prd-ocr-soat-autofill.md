# PRD — Autocompletar SOAT desde foto/PDF con ML Kit on-device

**Tipo:** Feature (mejora UX sobre el flujo SOAT existente de iter-2)
**Prioridad:** Media (acelera onboarding del SOAT, no es bloqueante)
**Estimado:** 1 iteración corta (~3 días de trabajo)
**Fecha de creación:** 2026-05-27
**Reemplaza:** entrada "OCR auto-fill del SOAT — alta complejidad (ML Kit / Cloud Vision); entrada manual es suficiente para MVP · Candidate: post-iter-1" del backlog.

---

## 1. Problema

Hoy el rider que quiere registrar su SOAT debe escribir manualmente cuatro campos críticos: número de póliza, fecha de inicio, fecha de vencimiento y aseguradora. El SOAT colombiano es un documento con formato relativamente estable entre las **10 aseguradoras autorizadas** por la Superfinanciera (verificado vía Fasecolda, mayo 2026): SURA, Seguros Bolívar, AXA Colpatria, Seguros del Estado, La Previsora, Liberty Seguros, Mapfre, Seguros Mundial, La Equidad y Aseguradora Solidaria. Los campos relevantes son fácilmente identificables por sus etiquetas en todos los formatos.

La PRD original descartó OCR como "alta complejidad" asumiendo ML Kit o Cloud Vision como única ruta. Esa lectura es incorrecta: `google_mlkit_text_recognition` es **gratis, on-device, sin cuota, sin backend, sin API key**, y la complejidad real está en el parser de texto, no en el OCR.

---

## 2. Objetivo

Permitir al rider tomar una foto (o seleccionar de galería / PDF) del documento del SOAT y que el formulario de captura manual se **prellene** con los cuatro campos extraídos automáticamente. El usuario siempre confirma antes de guardar.

**No-objetivos:**
- No se reemplaza la entrada manual; conviven.
- No se hace OCR en backend ni en la nube — todo es local.
- No se entrena un modelo propio (descartado por bajo ROI; ver §6).
- No se sube la imagen al servidor solo para OCR (la subida a Storage que ya hace el feature se mantiene como hoy, sin cambios).

---

## 3. Solución técnica

### 3.1 Stack

| Pieza | Tecnología | Costo | Notas |
|---|---|---|---|
| OCR | `google_mlkit_text_recognition` | Gratis | On-device, agrega ~20MB al APK por modelos nativos |
| Captura | `image_picker` (ya en uso) | Gratis | Cámara + galería |
| Rasterizado PDF | `pdfx` o `printing` | Gratis | Para SOAT digital — render a imagen antes de OCR |
| Recorte opcional | `image_cropper` | Gratis | Mejora acierto cuando la foto trae bordes |
| Parser | Dart puro | — | Reglas + regex sobre el texto reconocido |

### 3.2 Flujo de usuario

1. En `SoatUploadPage` o en `SoatManualCapturePage`, además del botón actual de subir documento, aparece un botón **"Escanear SOAT"**.
2. Usuario elige foto / galería / PDF.
3. Pantalla intermedia muestra spinner "Leyendo documento…".
4. ML Kit corre on-device; el parser de SOAT mapea texto → 4 campos.
5. El usuario aterriza en `SoatManualCapturePage` con los campos prellenados y un banner sutil: "Datos extraídos del documento — revisa antes de guardar".
6. Cada campo prellenado se marca visualmente (ej: ícono de varita mágica al lado) para que el usuario sepa qué vino del OCR.
7. Si el OCR falla o extrae <2 campos con confianza alta, **no se prellena nada** y se cae silenciosamente al flujo manual con un toast: "No pudimos leer el documento, ingresa los datos manualmente".

### 3.3 Arquitectura (Clean Architecture)

**Capa core** (`lib/core/services/ocr/`)
- `OcrService` (interfaz domain-style): `Future<OcrResult> recognizeText(File image)`.
- `MlKitOcrService` (implementación): envuelve `TextRecognizer`; registrado en GetIt como `@Injectable(as: OcrService)`.
- `OcrResult`: clase pura Dart con `fullText: String` + `blocks: List<OcrBlock>` (cada bloque con texto y bounding box).

**Capa domain del feature SOAT** (`lib/features/soat/domain/`)
- `SoatExtraction`: modelo con `policyNumber: String?`, `startDate: DateTime?`, `expiryDate: DateTime?`, `insurer: String?`, y un `confidence: SoatExtractionConfidence` (`high` / `medium` / `low` por campo, o agregado).
- `ParseSoatTextUseCase`: función pura que recibe `OcrResult` y devuelve `SoatExtraction`. Pura Dart, fácil de testear con fixtures.
- `ScanSoatUseCase`: orquesta `OcrService.recognizeText()` + `ParseSoatTextUseCase`.

**Capa data del feature SOAT** (`lib/features/soat/data/`)
- `SoatParser`: implementación del parser con las reglas concretas por aseguradora (clases internas o lookup table).
- (Opcional) `SoatPdfRasterizer`: convierte PDF a imagen usando `pdfx` antes de pasar al OCR.

**Capa presentation** (`lib/features/soat/presentation/`)
- `SoatScanCubit extends Cubit<ResultState<SoatExtraction>>`: gestiona el flujo escanear → procesar → entregar.
- `SoatScanPage`: pantalla intermedia con loader, manejo de errores, redirección a `SoatManualCapturePage` con el resultado.
- `SoatManualCapturePage`: recibe un `SoatExtraction?` opcional como parámetro y prellenа el formulario; los campos marcados muestran el indicador "auto-rellenado".

### 3.4 El parser — el núcleo de valor

**Aseguradora.** Lista cerrada de las **10 aseguradoras autorizadas** por la Superfinanciera (Fasecolda, 2026):
SURA, Seguros Bolívar, AXA Colpatria, Seguros del Estado, La Previsora, Liberty Seguros, Mapfre, Seguros Mundial, La Equidad, Aseguradora Solidaria. Matching:
- Substring case-insensitive sobre `fullText` con normalización de tildes y variantes comunes (p.ej. "SURA" / "Suramericana", "Solidaria" / "Aseguradora Solidaria").
- En empate, gana la que aparece en el bloque con mayor área (`boundingBox.height * width`) en el cuarto superior del documento (suele ser el logo).
- Si no hay match, `insurer = null` con confidence `low`.

**Número de póliza.** Estrategia en cascada:
1. Buscar líneas con labels: `póliza`, `poliza`, `n° póliza`, `no. póliza`, `número de póliza`. Capturar el alfanumérico (8–15 chars) más cercano.
2. Si se identificó aseguradora, aplicar regex específica de esa compañía cuando se conozca el formato (ver §3.5 abajo); las que no tengan regex específica caen al patrón genérico.
3. Si ambas estrategias fallan, `policyNumber = null`.

**Fechas (inicio + vencimiento).** Estrategia:
1. Regex multi-formato sobre `fullText`: `DD/MM/YYYY`, `DD-MM-YYYY`, `DD MMM YYYY` (con meses en español: `ene`, `feb`, …, `dic`), `YYYY-MM-DD`.
2. Buscar labels de contexto (`vigencia desde`, `desde`, `hasta`, `vence`, `vencimiento`) y asociar cada fecha al label más cercano por bounding box.
3. Si no hay labels claros: si encuentro exactamente dos fechas, la menor es inicio y la mayor es vencimiento.
4. **Validación dura:** la diferencia entre `expiryDate` y `startDate` debe ser de 360–370 días (SOAT siempre dura 1 año). Si falla, ambos campos quedan con confidence `low` y NO se prellenan.

### 3.5 Estados y umbrales

- **High confidence** (campo prellenado, marca verde): el campo se extrajo con label de contexto explícito + validación pasada.
- **Medium confidence** (campo prellenado, marca naranja, banner de "revisar con cuidado"): el campo se extrajo por regex pero sin label de contexto cercano.
- **Low confidence** (campo NO prellenado): el OCR no logró extraer el campo con seguridad.

**Regla global:** si menos de 2 campos tienen confidence `high`, **no se prellena nada** y se va al flujo manual. Mejor experiencia que mostrar datos malos.

---

## 4. Criterios de aceptación

- [ ] `OcrService` y `MlKitOcrService` registrados en DI; `SoatScanCubit` registrado.
- [ ] Botón "Escanear SOAT" presente en `SoatUploadPage` y `SoatManualCapturePage`.
- [ ] Flujo escanear → procesar → prellenar funcional con foto desde cámara, galería y **PDF (vía rasterizado con `pdfx`)** — los tres orígenes son requisitos de v1.
- [ ] Parser detecta correctamente las **10 aseguradoras autorizadas en Colombia** (SURA, Seguros Bolívar, AXA Colpatria, Seguros del Estado, La Previsora, Liberty Seguros, Mapfre, Seguros Mundial, La Equidad, Aseguradora Solidaria) con matching por nombre + variantes comunes. Regex específica de número de póliza implementada para al menos las 5 con mayor cuota de mercado conocida (SURA, Bolívar, Estado, AXA Colpatria, Mundial); las 5 restantes usan regex genérica.
- [ ] Si <2 campos `high confidence`, no se prellena nada y se muestra toast informativo.
- [ ] Campos prellenados muestran indicador visual de origen OCR.
- [ ] Tests unitarios del parser con al menos 8 fixtures de texto reconocido (mínimo 1 por aseguradora soportada + casos negativos).
- [ ] `dart analyze` sin nuevos warnings; `flutter test` al 100%.
- [ ] `app_es.arb` con strings nuevos (botón, banner, toasts, loader).
- [ ] Permisos cámara + galería + lectura de archivos verificados en `AndroidManifest.xml` e `Info.plist` (ya existen para subida SOAT — confirmar).
- [ ] Tamaño del APK monitoreado (se acepta hasta +25MB por modelos ML Kit).
- [ ] Documento `docs/features/soat.md` actualizado con el sub-flujo OCR (o creado si no existe).

---

## 5. Telemetría y aprendizaje continuo

Sin enviar imágenes ni texto a backend (privacidad), registrar **eventos anónimos** en Firebase Analytics:

- `soat_scan_attempted`
- `soat_scan_success` con propiedades: `fields_extracted_count`, `insurer_detected` (nullable string), `had_pdf` (bool)
- `soat_scan_failed` con propiedad: `failure_reason` (`no_text_detected`, `low_confidence`, `validation_failed`, `permission_denied`, `unknown_error`)

Esto permite, en futuras iteraciones, identificar qué aseguradoras o tipos de documento están dando problemas y mejorar el parser sin acceso a los documentos reales.

---

## 6. Decisiones explícitamente descartadas

| Opción | Razón del descarte |
|---|---|
| Cloud Vision / Document AI | Costo recurrente por documento; backend extra; latencia de red |
| Tesseract en backend | Calidad inferior a ML Kit on-device para fotos de celular; añade infra |
| PaddleOCR en microservicio Python | Mejor calidad que Tesseract pero requiere GPU/CPU dedicada; no justificado para MVP cuando ML Kit basta |
| Entrenar modelo de visión propio | ROI pésimo: miles de muestras anotadas, GPU, MLOps; ML Kit ya resuelve la etapa de OCR |
| LLM multimodal (Claude/GPT-4o vision) | Costo por documento (~$0.01–0.03) y dependencia de servicio externo; reconsiderable si ML Kit demuestra calidad insuficiente tras 4–6 semanas en producción |
| Subir imagen al servidor para OCR | Privacidad + costo de banda; ML Kit es on-device |

---

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| Calidad de foto del usuario (luz, ángulo, sombras) | Instrucciones UI claras + recorte opcional + caída silenciosa a manual si confidence bajo |
| Variaciones de layout entre aseguradoras | Parser por reglas con override por aseguradora detectada; nuevas aseguradoras se agregan como tests fixtures + reglas |
| SOAT en PDF digital con texto vectorial | Rasterizar a imagen primero (texto extraíble directamente del PDF queda como mejora futura) |
| Crecimiento del APK (~20MB) | Aceptado; documentar en release notes |
| Cambios futuros de formato de SOAT (regulación) | Feature flag remoto para desactivar el botón "Escanear" sin redeploy si el parser deja de funcionar masivamente |

---

## 8. Fuera de alcance (futuras iteraciones)

- OCR de otros documentos (tecnomecánica, licencia de conducir, tarjeta de propiedad).
- Extracción de texto directo de PDFs digitales (sin OCR) cuando el PDF trae capa de texto.
- Modelo ML específico entrenado con SOATs reales para reemplazar las reglas (solo si la telemetría justifica el esfuerzo).
- Modo "captura asistida" con overlay guía sobre la cámara para enmarcar el documento.
