# Plan: ocr-tarjeta-propiedad-autofill

> Estado: BORRADOR — revision humana pendiente. Generado: 2026-06-19T20:16:29Z

## Overview

Feature Flutter-only de 6 fases que permite al rider fotografiar su tarjeta de propiedad colombiana desde el formulario de vehículo y ver los campos (marca, modelo, año, placa, VIN) completados automáticamente via OCR on-device (ML Kit). Sin cambios de backend ni migraciones. El flujo reutiliza la infraestructura OCR del feature SOAT y extiende el formulario de vehículo existente con un cubit local, un parser dedicado y un banner activo.

Correcciones v2 aplicadas por el Auditor Opus: (1) El campo `year` está confirmado en `lib/features/vehicles/presentation/form/widgets/vehicle_form_basic_section.dart` como `AppTextField(name: VehicleFormFields.year)` cuyo valor es `String`; `vehicle_form_cubit.dart` lo parsea con `int.tryParse()`. `prefillFromScan()` debe llamar `didChange(extraction.year)` con el año como `String`, no como `DateTime` ni `int`. (2) R3 de la tabla de riesgos reemplazado: el riesgo ya no es el tipo de `year` (confirmado), sino borrar accidentalmente un archivo activo de `form/widgets/` confundiéndolo con su homónimo huérfano en `presentation/widgets/`. (3) NOTA-1 añadida a la fase 1 listando los pares de homónimos peligrosos para que el implementador solo borre los de `presentation/widgets/`.

## Fases

- Fase 1 [LITE]: [Fase 1 — Limpieza de código muerto](phases/phase-01-limpieza-de-codigo-muerto.md)
- Fase 2 [LITE]: [Fase 2 — Shared DocumentSourceSheet](phases/phase-02-shared-documentsourcesheet.md)
- Fase 3 [NORMAL]: [Fase 3 — Domain layer + parser con tests](phases/phase-03-domain-layer-parser-con-tests.md)
- Fase 4 [LITE]: [Fase 4 — Use case de escaneo + telemetría (v2 corregida por Auditor Opus)](phases/phase-04-use-case-de-escaneo-telemetria.md)
- Fase 5 [NORMAL]: [Fase 5 — Presentación: banner activo + prefill del formulario](phases/phase-05-presentacion-banner-activo-prefill-del-formulari.md)
- Fase 6 [LITE]: [Fase 6 — QA, strings es-CO y documentación](phases/phase-06-qa-strings-es-co-y-documentacion.md)

## Supuestos

1. No hay fixtures reales de tarjetas de propiedad en el repo. Los tests usarán texto sintético que imita el layout RUNT.
2. RTM (Tecnomecánica) no migra en v1. `TecnomecanicaEntryFlow` no usa `DocumentSourceSheet`.
3. `SoatAddDocumentSheet` y `SoatVehicleOptionsSheet` no se tocan.
4. `VehicleScanCubit` es cubit local al formulario (no persiste fuera de la sesión).
5. El prefill sobreescribe datos manuales existentes en modo edición (v1 sin dialog de confirmación).
6. Permisos de cámara y galería ya están declarados por el feature SOAT.
7. Sin cambios de backend. Endpoints existentes no modificados.
8. Sin dependencias nuevas en `pubspec.yaml`.

## Riesgos

| # | Riesgo | Probabilidad | Impacto | Mitigación en el plan |
|---|--------|-------------|---------|----------------------|
| R1 | Falsos negativos del parser en tarjetas físicas reales (tipografía RUNT, deterioro, iluminación) | Alta | Medio | `kMinHighConfidenceFields` como constante nombrada con comentario de ajuste; telemetría `propertyScanFailed` con `failureReason` para diagnosticar en producción. |
| R2 | `formKey.currentState` nulo en el momento del prefill (carrera de condición) | Media | Alto (falla silenciosa) | Prefill disparado desde `BlocListener` en `VehicleFormBody`, nunca desde el cubit ni desde dentro del banner. `BlocProvider<VehicleScanCubit>` montado antes del `FormBuilder` en el árbol de `VehicleFormPage`. |
| R3 | Borrar accidentalmente un archivo activo de `form/widgets/` confundiéndolo con su homónimo huérfano en `presentation/widgets/` | Baja | Medio | NOTA-1 lista los pares de homónimos y exige verificar la ruta completa antes de cada `git rm`. Gate de fase 1: `dart analyze` + `flutter test` pasan antes de avanzar. |
| R4 | Scope creep en `DocumentSourceSheet` (PDF / opción Manual) | Baja | Bajo | Spec de fase 2 restringe explícitamente a `{ camera, gallery }`. Cualquier extensión es v2. |
| R5 | Regresión en SOAT durante la limpieza de la fase 1 | Baja | Medio | Verificar con `grep` + `dart analyze` que cero archivos activos importan los huérfanos antes de borrar. `flutter test test/features/soat/` al final de la fase. |
| R6 | `build_runner` falla en entornos frescos (gotcha `objective_c`) | Media (conocido) | Medio | Usar `--force-jit`; copiar `.env` y configs Firebase antes de correr (ver `project_build_runner_force_jit.md`). |
| R7 | Dos banners con nombres similares confunden al implementador de fase 5 | Baja-Media | Bajo | Gate de fase 1 verifica que `vehicle_form_scan_banner.dart` (huérfano, bajo `presentation/widgets/`) ya no existe antes de avanzar a fase 5. El banner activo correcto es `form/widgets/vehicle_scan_banner.dart`. |

## Deuda técnica registrada (fuera de scope)

- `SoatAddDocumentSheet` importado desde `tecnomecanica_manual_capture_page.dart` (cross-feature coupling). No se toca; registrado para v2.
- Migración de `SoatAddDocumentSheet` y `SoatVehicleOptionsSheet` a `DocumentSourceSheet` en una futura iteración de SOAT.

## Como ejecutar una fase

> Cada fase se implementa con rg-exec en el NIVEL recomendado (ver el [LITE/NORMAL/FULL] del titulo y la seccion "Ejecucion recomendada" de cada fase):

```
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/ocr-tarjeta-propiedad-autofill/phases/phase-01-limpieza-de-codigo-muerto.md', mode: '<lite|normal|full>' } })
```

> lite = mecanico/bajo riesgo; normal = feature acotada; full = complejo/riesgoso (contratos, migraciones, seguridad).
