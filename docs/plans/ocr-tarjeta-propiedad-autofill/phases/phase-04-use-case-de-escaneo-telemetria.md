# Fase 4 — Use case de escaneo + telemetría

**Plan:** `ocr-tarjeta-propiedad-autofill`
**Timestamp:** 2026-06-19T20:13:10Z
**Depende de:** Fase 3 (Domain layer + parser con tests)
**Nivel de ejecución recomendado:** lite

---

## Objetivo

Implementar `ScanPropertyCardUseCase` como orquestador del flujo OCR de tarjeta de propiedad: llama a `OcrService` para reconocer texto, delega el parseo al `ParsePropertyCardTextUseCase` (ya existente desde Fase 3), y emite tres eventos GA4 para medir el funnel de escaneo en producción. Es una simplificación directa de `ScanSoatUseCase` sin la rama PDF.

---

## Alcance (entra / no entra)

### Entra

- `ScanPropertyCardUseCase` (@injectable, domain/usecases) — orquesta OCR → parse → telemetría; consume `ParsePropertyCardTextUseCase` provisto por Fase 3.
- Tres constantes nuevas en `AnalyticsEvents`: `propertyScanAttempted`, `propertyScanSuccess`, `propertyScanFailed`.
- `dart analyze` pasa limpio (cero warnings en archivos nuevos y en los tocados).

### No entra

- `ParsePropertyCardTextUseCase` — creado y probado en Fase 3; esta fase solo lo consume vía constructor de `ScanPropertyCardUseCase`.
- Rama PDF (`SoatPdfRasterizer`): no aplica para tarjeta de propiedad en v1.
- `PropertyCardExtraction`, `PropertyCardScanResult`, `PropertyCardParser` — ya implementados en Fase 3.
- `VehicleScanCubit` — se crea en Fase 5.
- Ningún parámetro nuevo en `AnalyticsParams`: `fieldsExtractedCount` y `failureReason` ya existen.
- Ningún cambio en `AnalyticsService` ni en su implementación.
- Ningún cambio de UI, rutas, DI manual (solo anotación `@injectable`), ni ARB strings.
- Ningún cambio de backend.

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 1 — Añadir eventos GA4 en `AnalyticsEvents`

Abrir `lib/core/services/analytics/analytics_events.dart` y añadir una nueva sección `// Tarjeta de propiedad` (inmediatamente después de la sección `// SOAT`). Añadir tres constantes:

```dart
// ---------------------------------------------------------------------------
// Tarjeta de propiedad
// ---------------------------------------------------------------------------

/// El rider inicia un escaneo de tarjeta de propiedad.
/// Max 40 chars: 'property_scan_attempted'.length == 23. ✓
static const String propertyScanAttempted = 'property_scan_attempted';

/// El escaneo terminó con éxito y se prefillaron los campos del vehículo.
/// Param: [AnalyticsParams.fieldsExtractedCount].
/// Max 40 chars: 'property_scan_success'.length == 21. ✓
static const String propertyScanSuccess = 'property_scan_success';

/// El escaneo falló (baja confianza, sin texto, error).
/// Param: [AnalyticsParams.failureReason].
/// Max 40 chars: 'property_scan_failed'.length == 20. ✓
static const String propertyScanFailed = 'property_scan_failed';
```

Verificar con `.length` que ningún nombre supera 40 caracteres (todos están por debajo de 24).

### Paso 2 — Crear `ScanPropertyCardUseCase`

Crear `lib/features/vehicles/domain/usecases/scan_property_card_usecase.dart`.

`ParsePropertyCardTextUseCase` es un colaborador inyectado que ya existe desde la Fase 3
(`lib/features/vehicles/domain/usecases/parse_property_card_text_usecase.dart`). Solo se importa.

Estructura basada en `ScanSoatUseCase` eliminando la rama PDF y usando los eventos nuevos:

```dart
import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../../core/services/analytics/analytics_events.dart';
import '../../../../core/services/analytics/analytics_params.dart';
import '../../../../core/services/analytics/analytics_service.dart';
import '../../../../core/services/ocr/ocr_service.dart';
import '../models/property_card_scan_result.dart';
import 'parse_property_card_text_usecase.dart';

/// Orchestrates the full property card scan: OCR → parse → telemetry.
///
/// [ParsePropertyCardTextUseCase] is injected (created in Phase 3) and wraps
/// [PropertyCardParser]. This use case does not re-implement parsing logic.
///
/// Throws [PropertyCardScanException] with a machine-readable reason when
/// the image cannot be turned into a prefillable extraction. Telemetry events
/// are anonymous (no text, no images leave the device).
@injectable
class ScanPropertyCardUseCase {
  const ScanPropertyCardUseCase(
    this._ocrService,
    this._parsePropertyCardText,
    this._analytics,
  );

  final OcrService _ocrService;
  final ParsePropertyCardTextUseCase _parsePropertyCardText;
  final AnalyticsService _analytics;

  Future<PropertyCardScanResult> call({required File file}) async {
    await _analytics.logEvent(AnalyticsEvents.propertyScanAttempted);

    final ocr = await _ocrService.recognizeText(file);
    if (ocr.isEmpty) {
      await _logFailure(PropertyCardScanFailureReason.noTextDetected);
      throw const PropertyCardScanException(
        PropertyCardScanFailureReason.noTextDetected,
      );
    }

    final extraction = _parsePropertyCardText(ocr);

    if (!extraction.shouldPrefill) {
      final reason = extraction.extractedFieldsCount > 0
          ? PropertyCardScanFailureReason.lowConfidence
          : PropertyCardScanFailureReason.noTextDetected;
      await _logFailure(reason);
      throw PropertyCardScanException(reason);
    }

    await _analytics.logEvent(AnalyticsEvents.propertyScanSuccess, {
      AnalyticsParams.fieldsExtractedCount: extraction.extractedFieldsCount,
    });

    return PropertyCardScanResult(extraction: extraction);
  }

  Future<void> _logFailure(PropertyCardScanFailureReason reason) {
    return _analytics.logEvent(AnalyticsEvents.propertyScanFailed, {
      AnalyticsParams.failureReason: reason.analyticsValue,
    });
  }
}
```

**Nota crítica de telemetría:** `propertyScanAttempted` se emite al inicio del método `call()`, **antes** del OCR. Esto permite contar intentos fallidos por errores de plataforma (cámara/galería que lanza antes de llegar al OCR) que de otro modo serían silenciosos.

### Paso 3 — Verificar registro DI automático

`ScanPropertyCardUseCase` lleva `@injectable`. `ParsePropertyCardTextUseCase` ya tiene `@injectable` desde la Fase 3. No es necesario tocar `injection.config.dart` manualmente; `build_runner` lo regenera. Verificar que la Fase 5 corra `dart run build_runner build --delete-conflicting-outputs --force-jit` para que ambos queden registrados antes de que `VehicleScanCubit` los inyecte.

Esta fase NO requiere correr `build_runner` por sí misma porque los archivos no contienen anotaciones `@freezed` ni Retrofit. Sin embargo, si el implementador quiere confirmar la ausencia de errores de compilación, puede correr `dart analyze` directamente sin regenerar.

### Paso 4 — `dart analyze` final

Correr `dart analyze` desde la raíz del proyecto. El único resultado aceptable es:

```
No issues found!
```

o warnings pre-existentes no relacionados con los archivos nuevos o tocados. Resolver cualquier warning antes de dar la fase por terminada.

---

## Archivos a crear/modificar (rutas reales)

| Acción | Ruta | Qué cambia |
|--------|------|------------|
| Modificar | `lib/core/services/analytics/analytics_events.dart` | Añadir sección `// Tarjeta de propiedad` con 3 constantes (`propertyScanAttempted`, `propertyScanSuccess`, `propertyScanFailed`). |
| Crear | `lib/features/vehicles/domain/usecases/scan_property_card_usecase.dart` | Orquestador `@injectable` que llama `OcrService → ParsePropertyCardTextUseCase → analytics`; lanza `PropertyCardScanException` si `!extraction.shouldPrefill`. |

**Total: 1 archivo modificado, 1 archivo creado.** Sin cambios en código generado, sin cambios en ARB, sin cambios de backend.

---

## Contratos / API rideglory-api

**Ninguno.** Esta fase es completamente on-device. La telemetría GA4 se envía a Firebase Analytics mediante el cliente ya configurado en la app; no hay llamadas a `rideglory-api`.

---

## Cambios de datos / migraciones

**Ninguno.** No hay cambio de esquema en ninguna base de datos. Los tres eventos GA4 nuevos son solo constantes de string en el cliente; Firebase Analytics los registra automáticamente cuando se llama a `_analytics.logEvent(...)`.

---

## Criterios de aceptación (numerados, observables, testeables)

1. `dart analyze` reporta cero issues en los dos archivos de la fase (incluyendo `analytics_events.dart` y `scan_property_card_usecase.dart`).
2. Las constantes `AnalyticsEvents.propertyScanAttempted`, `AnalyticsEvents.propertyScanSuccess`, `AnalyticsEvents.propertyScanFailed` existen y sus `.length` son ≤ 40 (verificable en test o REPL).
3. `ScanPropertyCardUseCase` compila sin importar `SoatPdfRasterizer` ni ningún símbolo de la feature SOAT.
4. `ScanPropertyCardUseCase.call()` emite `propertyScanAttempted` como primera acción, antes de llamar a `_ocrService.recognizeText()`.
5. Al recibir `ocr.isEmpty == true`, el use case emite `propertyScanFailed` con `failureReason: 'no_text_detected'` y lanza `PropertyCardScanException(PropertyCardScanFailureReason.noTextDetected)`.
6. Al recibir `extraction.shouldPrefill == false` con `extractedFieldsCount > 0`, el use case emite `propertyScanFailed` con `failureReason: 'low_confidence'` y lanza `PropertyCardScanException(PropertyCardScanFailureReason.lowConfidence)`.
7. Al recibir `extraction.shouldPrefill == true`, el use case emite `propertyScanSuccess` con `{AnalyticsParams.fieldsExtractedCount: extraction.extractedFieldsCount}` y retorna `PropertyCardScanResult(extraction: extraction)`.
8. `ScanPropertyCardUseCase` inyecta `ParsePropertyCardTextUseCase` (creado en Fase 3) vía constructor y lo invoca con `call(ocr)` — sin re-implementar lógica de parseo ni duplicar la clase.
9. `ScanPropertyCardUseCase` tiene la anotación `@injectable` (verificable por inspección del archivo); `ParsePropertyCardTextUseCase` ya tiene `@injectable` desde la Fase 3 y no necesita modificarse.
10. Los archivos nuevos no importan ningún símbolo de la capa de presentación ni de Flutter (solo `dart:io`, `package:injectable`, paquetes core del proyecto y símbolos del dominio de vehicles).

---

## Pruebas (unitarias/widget/integración)

### Unitarias — `ScanPropertyCardUseCase`

Crear `test/features/vehicles/domain/usecases/scan_property_card_usecase_test.dart` con mocks de `OcrService`, `ParsePropertyCardTextUseCase` y `AnalyticsService`. `ParsePropertyCardTextUseCase` es un colaborador inyectado preexistente (Fase 3): se mockea aquí para aislar el comportamiento del use case de escaneo sin re-testar la lógica de parseo (que ya tiene cobertura propia en `property_card_parser_test.dart`). Casos a cubrir:

| # | Caso | Verificación |
|---|------|--------------|
| U1 | OCR devuelve `OcrResult` vacío | Emite `propertyScanFailed` con `failure_reason: no_text_detected`; lanza `PropertyCardScanException(noTextDetected)`. |
| U2 | OCR devuelve texto pero `shouldPrefill == false` con `extractedFieldsCount > 0` | Emite `propertyScanFailed` con `failure_reason: low_confidence`; lanza `PropertyCardScanException(lowConfidence)`. |
| U3 | OCR devuelve texto pero `shouldPrefill == false` con `extractedFieldsCount == 0` | Emite `propertyScanFailed` con `failure_reason: no_text_detected`; lanza `PropertyCardScanException(noTextDetected)`. |
| U4 | Scan exitoso: mock de `ParsePropertyCardTextUseCase` retorna extracción con `shouldPrefill == true` | Emite `propertyScanAttempted` (primero), luego `propertyScanSuccess` con `fieldsExtractedCount` correcto; retorna `PropertyCardScanResult`. |
| U5 | Orden de eventos en caso exitoso | Verificar que `propertyScanAttempted` se emite antes de `recognizeText()`; `propertyScanSuccess` se emite antes del `return`. |

Usar `mocktail` (ya en `dev_dependencies` por el resto del proyecto) para los mocks.

### Unitarias — `ParsePropertyCardTextUseCase`

No se prueba aquí: fue creado y validado con ≥6 fixtures en `test/features/vehicles/data/parser/property_card_parser_test.dart` (Fase 3). El test U4 de esta fase verifica que `ScanPropertyCardUseCase` lo invoca correctamente como colaborador inyectado, que es el único contrato relevante para esta fase.

### No se requieren pruebas de widget ni de integración

Esta fase no introduce UI. Las pruebas listadas son suficientes para dar confianza al auditor.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R1 | Importar accidentalmente un símbolo de SOAT (p.ej. `SoatScanFailureReason`) en lugar del equivalente de vehicles | Baja | Bajo | El linter detecta imports no usados; `dart analyze` falla si hay ambigüedad de tipos. Revisar los `import` manualmente antes de cerrar la fase. |
| R2 | `AnalyticsEvents` no recibe la sección nueva y la Fase 5 falla en compilación por referencia a constante inexistente | Baja | Alto | Este archivo se toca en el Paso 1, que es el primer paso; el Paso 4 (`dart analyze`) lo detectaría si se omitiera. |
| R3 | `build_runner` no regenera `injection.config.dart` en esta fase y el DI queda desactualizado para la Fase 5 | Media (conocido) | Medio | Documentado explícitamente en el Paso 3: la Fase 5 es responsable de correr `build_runner`. Esta fase solo requiere `dart analyze`, no `build_runner`. |
| R4 | `_analytics.logEvent` lanza una excepción en el path de éxito o de fallo y burbujea al caller sin ser capturada | Baja | Bajo | Mismo comportamiento que `ScanSoatUseCase` (el patrón de referencia no captura errores de analytics); si el servicio de analytics falla, es un error de configuración de Firebase, no del use case. No se captura deliberadamente para no enmascarar errores de setup en desarrollo. |

---

## Dependencias

### Prerequisito: Fase 3 — Domain layer + parser con tests

`ScanPropertyCardUseCase` importa:
- `PropertyCardScanResult` y `PropertyCardScanException` de `domain/models/property_card_scan_result.dart` (Fase 3).
- `ParsePropertyCardTextUseCase` de `domain/usecases/parse_property_card_text_usecase.dart` (Fase 3) — clase ya creada y registrada como `@injectable`; esta fase solo la consume vía constructor.
- `PropertyCardExtraction` a través de `ParsePropertyCardTextUseCase` (Fase 3).

Sin la Fase 3 completada, esta fase no compila.

### No hay otras dependencias de fase

La Fase 1 (limpieza) y la Fase 2 (DocumentSourceSheet) no son prerequisito de esta fase; sus artefactos no son importados aquí.

---

## Ejecución recomendada (nivel rg-exec: lite)

**Por qué lite:**

- **Use case plano sin freezed:** `ScanPropertyCardUseCase` es una clase Dart ordinaria; no usa `@freezed`, no requiere `build_runner` en esta fase, no genera código adicional.
- **Sin HTTP propio:** el use case solo llama a `OcrService` (ya inyectado) y a `AnalyticsService` (ya inyectado). No hay clientes Retrofit ni WebSocket que configurar.
- **Sin cambios de backend ni de contratos:** el único "contrato" nuevo son tres constantes de string en `AnalyticsEvents`; no hay schema de API, no hay migración, no hay coordinación cross-repo.
- **Replica directa de `ScanSoatUseCase`** con una simplificación (elimina rama PDF); el implementador tiene un template funcional probado en producción.
- **Los params GA4 ya existen:** `AnalyticsParams.fieldsExtractedCount` y `AnalyticsParams.failureReason` están presentes en el catálogo; no hay discusión de diseño pendiente.
- **`ParsePropertyCardTextUseCase` ya existe (Fase 3):** esta fase no crea colaboradores ni modelos nuevos; solo orquesta los ya existentes.
- **Riesgo bajo y completamente reversible:** dos archivos (1 modificado, 1 creado); un `git revert` o `git rm` deja el árbol exactamente como estaba antes de la fase.
- **Criterios de aceptación mecánicos:** la verificación final es `dart analyze` + los tests unitarios del use case (5 casos). No hay UX que revisar, no hay pantallas que validar.

El nivel `normal` quedaría justificado solo si hubiera lógica de ramificación compleja (como la rama PDF de SOAT) o si los contratos del dominio fueran inciertos. En este caso, el dominio viene sellado de la Fase 3 y el flujo es lineal.
