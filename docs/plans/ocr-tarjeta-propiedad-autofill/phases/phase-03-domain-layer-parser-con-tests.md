# Fase 3 — Domain layer + parser con tests

**Timestamp:** 2026-06-19T20:09:30Z
**Slug:** `ocr-tarjeta-propiedad-autofill`
**Fase:** 3 de 6
**Nivel rg-exec recomendado:** normal

---

## Objetivo

Implementar el dominio y la lógica de parseo para la tarjeta de propiedad colombiana: el modelo `PropertyCardExtraction` con heurística de confianza, el wrapper sealed `PropertyCardScanResult`, el parser stateless `PropertyCardParser` (registrado vía `@injectable`), y el use case `ParsePropertyCardTextUseCase`. Exponer la constante pública `kMinHighConfidenceFields = 2` con comentario explícito de ajuste. Verificar la implementación con una suite de ≥ 6 fixtures sintéticos que ejerciten los patrones de layout RUNT.

---

## Alcance (entra / no entra)

### Entra

- `PropertyCardExtraction` — modelo de dominio inmutable con 5 campos (brand, model, year, licensePlate, vin), sus `OcrFieldConfidence` pares, helpers `shouldPrefill`, `extractedFieldsCount`, `highConfidenceCount`, `isFieldAutofilled`, `confidenceOf`, y `copyWith`. Reutiliza el enum `OcrFieldConfidence` ya definido en `soat_extraction.dart` (mismo archivo; importar desde SOAT).
- Constante `static const int _minHighFields = 2` en `PropertyCardExtraction.shouldPrefill`, comentada con `/// Returns true when at least [_minHighFields] fields have [OcrFieldConfidence.high] confidence.`
- Constante pública de test `const int kMinHighConfidenceFields = 2` declarada en el mismo archivo de `PropertyCardExtraction`, con comentario: `// Ajustar tras pruebas con tarjetas reales — layout RUNT puede requerir umbral menor`.
- Enum `PropertyCardField { brand, model, year, licensePlate, vin }` en el mismo archivo.
- `PropertyCardScanResult` — wrapper sealed de éxito (`extraction`) + `PropertyCardScanException` con `PropertyCardScanFailureReason` (mismos valores que `SoatScanFailureReason`: `noTextDetected`, `lowConfidence`, `permissionDenied`, `unknownError`) y extensión `analyticsValue`.
- `PropertyCardParser` — parser stateless `@injectable` que recibe `OcrResult` y devuelve `PropertyCardExtraction`. Etiquetas RUNT documentadas en comentarios. 3 estrategias por campo: label proximity, regex específico RUNT, regex genérico de fallback.
- `ParsePropertyCardTextUseCase` — wrapper `@injectable` `call(OcrResult) → PropertyCardExtraction` alrededor de `PropertyCardParser`.
- Suite de 6 fixtures en `test/features/vehicles/data/parser/property_card_parser_test.dart`.
- `dart analyze` sin warnings en archivos nuevos al finalizar la fase.

### No entra

- `ScanPropertyCardUseCase` (orquestación OCR + telemetría) — es la fase 4.
- `VehicleScanCubit` ni ningún widget de presentación — son la fase 5.
- Eventos GA4 — son la fase 4.
- Cambios al enum `OcrFieldConfidence` en `soat_extraction.dart` — se importa tal cual; no se modifica el archivo SOAT.
- Reglas de aseguradoras equivalentes a `soat_insurer_rules.dart` — no aplicables a tarjeta de propiedad.
- `build_runner` / code-gen — no se necesita; todos los modelos son `const` factories manuales (mismo patrón que `SoatExtraction`).

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Crear `PropertyCardExtraction`** en `lib/features/vehicles/domain/models/property_card_extraction.dart`.
   - Importar `OcrFieldConfidence` desde `lib/features/soat/domain/models/soat_extraction.dart`.
   - Declarar `enum PropertyCardField { brand, model, year, licensePlate, vin }`.
   - Clase `@immutable PropertyCardExtraction` con constructor `const`, constructor `const PropertyCardExtraction.empty()`, 5 campos nullable + 5 pares de confianza con valor default `OcrFieldConfidence.low`.
   - Getter interno `List<OcrFieldConfidence> get _confidences` con los 5 valores.
   - Getter `int get highConfidenceCount`.
   - Getter `int get extractedFieldsCount`.
   - Getter `bool get hasMediumConfidence`.
   - Constante privada `static const int _minHighFields = 2` con doc comment del contrato.
   - Getter `bool get shouldPrefill => highConfidenceCount >= _minHighFields`.
   - Constante pública de test `const int kMinHighConfidenceFields = 2` con comentario de ajuste (OBL-3).
   - Método `bool isFieldAutofilled(PropertyCardField field)`.
   - Método `OcrFieldConfidence confidenceOf(PropertyCardField field)`.
   - Método `PropertyCardExtraction copyWith({...})`.

2. **Crear `PropertyCardScanResult`** en `lib/features/vehicles/domain/models/property_card_scan_result.dart`.
   - Enum `PropertyCardScanFailureReason { noTextDetected, lowConfidence, permissionDenied, unknownError }`.
   - Extension `PropertyCardScanFailureReasonX` con getter `String get analyticsValue` (snake_case).
   - Clase `PropertyCardScanException implements Exception` con `final PropertyCardScanFailureReason reason`.
   - Clase `PropertyCardScanResult` con `const PropertyCardScanResult({required this.extraction})` y `final PropertyCardExtraction extraction`.

3. **Crear `PropertyCardParser`** en `lib/features/vehicles/data/parser/property_card_parser.dart`.
   - Anotar `@injectable`, constructor `const`.
   - Documentar en el encabezado del archivo las etiquetas RUNT asumidas:
     ```
     // Etiquetas RUNT conocidas (layout tarjeta de propiedad colombiana):
     // MARCA            → campo brand
     // LINEA / LINEA/MODELO → campo model (puede ir junto a MARCA en motos)
     // MODELO / MODELO/AÑO → campo year (puede contener "2019" o "2019 SPORT")
     // No. DE MATRÍCULA / PLACA → campo licensePlate (formato: ABC123 o AB123C)
     // VIN / SERIE / No. SERIE → campo vin (alfanumérico 17 chars estándar, puede variar)
     ```
   - Método público `PropertyCardExtraction parse(OcrResult ocr)` que retorna `PropertyCardExtraction.empty()` si `ocr.isEmpty`.
   - Normalizar texto completo con helper `_normalize(String input)` (lowercase + quitar tildes).
   - Implementar `_detectBrand`, `_detectModel`, `_detectYear`, `_detectLicensePlate`, `_detectVin`, cada uno retornando `_FieldResult<String>`.
   - Cada detector aplica 3 estrategias en orden:
     - **Estrategia 1 (high):** búsqueda por label proximity — bloque que contiene la etiqueta RUNT → extrae token del mismo bloque o bloque adyacente.
     - **Estrategia 2 (medium):** regex campo-específico sobre `ocr.fullText`.
     - **Estrategia 3 (medium/low):** regex genérico de fallback.
   - Helpers reutilizables: `_normalize`, `_closestBlockOnSameLine`, `_closestBlockBelow`, `_firstTokenAfterLabel`.
   - Regex específicos documentados con el patrón RUNT que los origina.
   - Clase privada `_FieldResult<T>` con `value` y `confidence`.

4. **Crear `ParsePropertyCardTextUseCase`** en `lib/features/vehicles/domain/usecases/parse_property_card_text_usecase.dart`.
   - Anotar `@injectable`, constructor `const`.
   - Campo `final PropertyCardParser _parser`.
   - Método `PropertyCardExtraction call(OcrResult ocr) => _parser.parse(ocr)`.

5. **Escribir suite de tests** en `test/features/vehicles/data/parser/property_card_parser_test.dart`.
   - Reutilizar el helper `OcrResult fixture(String text)` del `soat_parser_test.dart` (copiar el helper local al archivo — no importar desde el test de SOAT).
   - Implementar los 6 fixtures descritos abajo.
   - Verificar que cada fixture afirma el valor correcto, la confianza esperada y el valor de `shouldPrefill`.

6. **Ejecutar `dart analyze`** sobre los 4 archivos nuevos. Corregir cualquier warning antes de marcar la fase como completa.

7. **Ejecutar `flutter test test/features/vehicles/data/parser/property_card_parser_test.dart`**. Todos los tests deben pasar.

---

## Archivos a crear/modificar (rutas reales)

| Accion | Ruta | Que cambia |
|--------|------|------------|
| CREAR | `lib/features/vehicles/domain/models/property_card_extraction.dart` | Modelo de dominio `PropertyCardExtraction`, enum `PropertyCardField`, constante `kMinHighConfidenceFields` |
| CREAR | `lib/features/vehicles/domain/models/property_card_scan_result.dart` | Wrapper sealed `PropertyCardScanResult`, `PropertyCardScanException`, `PropertyCardScanFailureReason` |
| CREAR | `lib/features/vehicles/data/parser/property_card_parser.dart` | Parser stateless `@injectable` con estrategias por campo y etiquetas RUNT comentadas |
| CREAR | `lib/features/vehicles/domain/usecases/parse_property_card_text_usecase.dart` | Use case `@injectable` wrapper sobre `PropertyCardParser` |
| CREAR | `test/features/vehicles/data/parser/property_card_parser_test.dart` | Suite de ≥ 6 fixtures unitarios |

**No se modifica ningún archivo existente en esta fase.**

---

## Contratos / API rideglory-api

Ninguno. Esta fase es 100% on-device; no toca endpoints ni contratos de red.

---

## Cambios de datos / migraciones

Ninguno. No hay esquemas de base de datos ni `SharedPreferences` involucrados.

---

## Criterios de aceptacion

1. `lib/features/vehicles/domain/models/property_card_extraction.dart` existe y compila. Contiene `PropertyCardExtraction`, `PropertyCardField`, y la constante pública `kMinHighConfidenceFields = 2`.
2. `PropertyCardExtraction.shouldPrefill` usa `static const int _minHighFields = 2` (sin literal mágico), con doc comment que documenta el contrato (A4).
3. `kMinHighConfidenceFields` tiene el comentario de ajuste: `// Ajustar tras pruebas con tarjetas reales — layout RUNT puede requerir umbral menor` (OBL-3).
4. `PropertyCardParser` es `@injectable`, `const`-constructible y stateless. Todos los campos públicos/privados son `final` o `static final`.
5. Las etiquetas RUNT asumidas (`MARCA`, `LINEA`, `MODELO/AÑO`, `No. DE MATRÍCULA`, `VIN`) están documentadas en comentarios del parser.
6. `ParsePropertyCardTextUseCase` es `@injectable` y su único método público es `call(OcrResult) → PropertyCardExtraction`.
7. `flutter test test/features/vehicles/data/parser/property_card_parser_test.dart` pasa con los 6 fixtures (cero fallos).
8. `dart analyze` no emite warnings ni errores sobre los 4 archivos nuevos.
9. Ningún archivo del feature SOAT fue modificado (verificar con `git diff --name-only lib/features/soat/`).
10. No se requirió correr `build_runner` para compilar la fase.

---

## Pruebas

### Fixture 1 — Carro completo (caso feliz)

Texto sintético con los 5 campos presentes y sus etiquetas RUNT explícitas. Aserciones: `brand`, `model`, `year`, `licensePlate`, `vin` con confianza `high`; `shouldPrefill == true`; `extractedFieldsCount == 5`.

```
MINISTERIO DE TRANSPORTE
CERTIFICADO DE PROPIEDAD
MARCA: CHEVROLET
LINEA: SPARK GT
MODELO: 2019
No. DE MATRÍCULA: ABC123
VIN: 9BWZZZ377VT004251
```

### Fixture 2 — Moto RUNT (marca/modelo en una sola línea)

Layout donde RUNT imprime `MARCA/LINEA` concatenados. Aserciones: `brand` y `model` extraídos correctamente por el parser de fallback; al menos 2 campos con confianza `high` o `medium`; `shouldPrefill` depende de la implementación del parser (puede ser `true` o `false` según heurística — el test afirma el valor que el parser produce, documentando el comportamiento esperado).

```
MINISTERIO DE TRANSPORTE
MARCA LINEA: YAMAHA FZ
MODELO: 2021
PLACA: BCD987
SERIE: 9C6RG3348L0011111
```

### Fixture 3 — Tarjeta deteriorada sin VIN

VIN ausente; 4 campos restantes presentes con label. Aserciones: `vin == null`, `vinConfidence == OcrFieldConfidence.low`; `extractedFieldsCount == 4`; `highConfidenceCount >= 2`; `shouldPrefill == true`.

```
MARCA: RENAULT
LINEA: LOGAN
MODELO: 2017
No. DE MATRÍCULA: DEF456
```

### Fixture 4 — Imagen sin texto de tarjeta (OcrResult vacío)

`OcrResult` con `fullText == ''` y `blocks == []`. Aserciones: retorna `PropertyCardExtraction.empty()`; todos los campos `null`; `shouldPrefill == false`; `extractedFieldsCount == 0`.

### Fixture 5 — Campo MODELO/AÑO combinado en una sola celda

RUNT imprime `MODELO/AÑO: SPORT 2019`. El parser debe separar el año (valor numérico 4 dígitos) del texto del modelo. Aserciones: `year == '2019'`; `model` extrae `'SPORT'` o similar (o `null` si no hay celda LINEA separada); `yearConfidence` es al menos `medium`.

```
MARCA: KIA
LINEA: PICANTO
MODELO/AÑO: SPORT 2019
PLACA: GHI789
VIN: KNABE241795411234
```

### Fixture 6 — Placa con formato antiguo (3L+3D) vs. nuevo (3L+2D)

Dos sub-tests dentro del mismo grupo:
- Placa `ABC123` (formato antiguo 3 letras + 3 dígitos): `licensePlate == 'ABC123'`, `licensePlateConfidence` al menos `medium`.
- Placa `AB123C` (formato nuevo 3L+2D+1L, circulación Bogotá reciente): `licensePlate == 'AB123C'`, `licensePlateConfidence` al menos `medium`.

Ambos deben extraerse correctamente con el regex de placa colombiana del parser.

```
// Sub-test A
MARCA: MAZDA
PLACA: ABC123
MODELO: 2015

// Sub-test B
MARCA: TOYOTA
PLACA: AB123C
MODELO: 2023
```

### Tipo de prueba

**Unitaria pura.** Sin mocks, sin Flutter, sin DI. `PropertyCardParser` es `const` e instanciable directamente en el test (`const PropertyCardParser()`). El helper `fixture(String text)` construye `OcrResult` sintético con bounding boxes calculados por línea (patrón idéntico al `soat_parser_test.dart`).

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigacion |
|---|--------|-------------|---------|------------|
| R1 | Patrones RUNT asumidos en texto sintético no cubren la variedad real de tarjetas físicas (tipografía, deterioro, iluminación) | Alta | Medio | Documentar cada etiqueta RUNT asumida en comentarios del parser para que sean auditables. `kMinHighConfidenceFields` como constante nombrada con comentario de ajuste. Telemetría en fase 4 (`propertyScanFailed` con `failureReason`) permite diagnosticar en producción. |
| R2 | Importar `OcrFieldConfidence` desde `soat_extraction.dart` crea coupling cross-feature | Baja | Bajo | El enum pertenece al core del dominio OCR; moverlo a `lib/core/services/ocr/ocr_field_confidence.dart` es una mejora de hygiene válida (fuera de scope v1). Documentar como deuda técnica si el auditor lo señala. |
| R3 | Campo `year` extraído como `String` con ruido textual (e.g. `'SPORT 2019'`) no es parseable directamente por `int.tryParse()` en fase 5 | Media | Bajo | El parser debe extraer solo el año numérico (regex `\b\d{4}\b` sobre el texto del bloque). Afirmar en fixture 5 que `year == '2019'`, no `'SPORT 2019'`. |
| R4 | `build_runner` falla en entornos frescos por gotcha `objective_c` | Media (conocido) | Medio | No aplica directamente (esta fase no requiere `build_runner`). Si DI falla en fases posteriores, usar `--force-jit` según `project_build_runner_force_jit.md`. |

---

## Dependencias (fases prerequisito y por que)

**Depende de Fase 2 (Shared DocumentSourceSheet).**

Aunque `PropertyCardParser` y `ParsePropertyCardTextUseCase` no tienen dependencias de código en la fase 2, el plan de ejecución secuencial las establece para mantener un árbol de dependencias lineal y permitir que la fase 3 sea revisada con el contexto del sheet ya definido. En términos de compilación, la fase 3 compila de forma autónoma desde la fase 1 (que garantiza que el árbol de archivos activos está limpio).

No depende de fase 4, 5, ni 6.

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Por que normal y no lite:** la fase contiene lógica de parseo con heurística de confianza por campo (3 estrategias × 5 campos), modelos de dominio nuevos, y una suite de tests que cubre 6 escenarios con distintos layouts RUNT. El riesgo principal es que los patrones RUNT asumidos en texto sintético pueden no cubrir la variedad real de tarjetas físicas colombianas; los fixtures deben ser suficientemente adversariales para detectar regresiones. No hay contratos API ni migraciones, pero la complejidad interna del parser y la necesidad de iterar el umbral `kMinHighConfidenceFields` requieren 2 rondas de auditor Opus para asegurar calidad antes de que las fases 4 y 5 dependan de estos contratos.

**Por que no full:** no hay integración con servicios externos, no hay estado reactivo, no hay UI, y el scope está delimitado a 4 archivos Dart + 1 archivo de test. El riesgo de regresión cross-feature es bajo (solo se leen artefactos de SOAT, no se modifican).
