# Plan: storage-hygiene

> Estado: BORRADOR — revision humana pendiente. Generado: 2026-06-19T20:33:57Z

## Overview

El plan storage-hygiene introduce un ciclo de vida completo de limpieza de archivos en Firebase Storage: cuando un usuario reemplaza o elimina una imagen de vehiculo, portada de evento, o documento SOAT/RTM, el archivo anterior se borra automaticamente. La estructura es una utilidad central robusta e idempotente (Fase 1), seguida de integracion por feature (Fases 2–5) en orden de impacto decreciente, cerrada por QA y documentacion (Fase 6). No hay cambios de UI, contratos de rideglory-api, ni migraciones de datos. Los helpers de test se crean en Fase 1 para que las fases siguientes los importen directamente. El barrido retroactivo de huerfanos preexistentes queda explicitamente fuera de alcance como deuda tecnica conocida. Todos los ajustes del Architect (A1–A6) y del Plan Reviewer (AJ-1–AJ-6) estan integrados: cuatro casos explicitos en deleteByUrl, cambio de firma de permanentlyDeleteVehicle a recibir VehicleModel, patron de captura de oldDocumentUrl antes de emit(loading), verifyInOrder en cada fase 2–5, y documentacion de comportamiento aceptado ante estado Empty/Initial.

## Fases

| # | Archivo | Nivel | Depende de |
|---|---------|-------|------------|
| 1 | [Fase 1 — Storage Delete Utility](phases/phase-01-storage-delete-utility.md) | **LITE** | — |
| 2 | [Fase 2 — Vehicle Image Cleanup](phases/phase-02-vehicle-image-cleanup.md) | **NORMAL** | Fase 1 |
| 3 | [Fase 3 — Event Cover Cleanup](phases/phase-03-event-cover-cleanup.md) | **NORMAL** | Fase 1 |
| 4 | [Fase 4 — SOAT Document Cleanup](phases/phase-04-soat-document-cleanup.md) | **NORMAL** | Fase 1 |
| 5 | [Fase 5 — RTM Document Cleanup](phases/phase-05-rtm-document-cleanup.md) | **NORMAL** | Fase 1 |
| 6 | [Fase 6 — QA & Docs](phases/phase-06-qa-docs.md) | **LITE** | Fases 2–5 |

## Supuestos

- `AppEnv.firebaseStorageBucket` es accesible en la capa de datos y su valor es consistente en todos los entornos. Si falla en tests, la Fase 1 documenta el override a usar.
- `ImageStorageService` ya es `@injectable` y todas las clases que lo necesiten pueden recibirlo por DI sin code-gen adicional.
- El backend (rideglory-api) no gestiona Firebase Storage en ningun endpoint: las URLs se persisten como strings en la BD y el ciclo de vida del archivo en Storage es 100% responsabilidad del cliente Flutter. Sin cambios de contrato.
- Las Fases 4 y 5 pueden ejecutarse en cualquier orden posterior a la Fase 1; no tienen dependencia entre si.
- Archivar un vehiculo (`isArchived=true`) es semanticamente distinto a eliminarlo: la imagen se preserva. La distincion ya esta modelada en dominio y no cambia.
- El upload de imagenes/documentos sigue ocurriendo en la capa donde ya ocurre (cubit para vehiculos/eventos, cubit de upload para SOAT/RTM); este plan no mueve esa logica.

## Riesgos

| # | Riesgo | Severidad | Mitigacion |
|---|--------|-----------|------------|
| R1 | **Borrado prematuro:** `deleteByUrl` antes de confirmar persistencia backend → archivo borrado con modelo inconsistente | Alta | Orden estricto: write al API primero, borrado de Storage solo en bloque de exito del `fold`. Verificado con `verifyInOrder` en cada fase 2–5. |
| R2 | **URL anterior no disponible en cubit (SOAT/RTM):** si el usuario llega a save/delete sin haber cargado el modelo, `oldDocumentUrl` es null y el archivo queda huerfano | Media | Documentado como comportamiento conocido (AJ-6). El cubit debe tener `state is Data` antes de exponer acciones de save/delete en UI. Degradacion controlada sin GET compensatorio. |
| R3 | **`VehicleFormCubit` emite `data` antes de `deleteByUrl`:** si el cubit espera a `deleteByUrl` para emitir `data`, la UI queda bloqueada durante el borrado de Storage | Media | Criterio de aceptacion de Fase 2: emitir `ResultState.data` con el nuevo modelo ANTES de llamar `deleteByUrl`. El borrado es fire-and-forget desde la perspectiva de la UI. |
| R4 | **Portadas de Unsplash (eventos):** si `deleteByUrl` se llama sobre una URL externa, debe rechazarla silenciosamente sin error | Baja | La validacion de bucket en Fase 1 cubre este caso — URL externa = skip silencioso. |
| R5 | **Huerfanos preexistentes (upload anonimo de evento pre-id):** imagenes en `events/{timestamp}/cover.jpg` de eventos abandonados | Baja | Explicito fuera de alcance. Registrado como deuda tecnica. |
| R6 | **build_runner en entornos frescos:** puede fallar por build hooks de `objective_c` | Baja | Usar `--force-jit` o copiar `pubspec.lock` de main (documentado en MEMORY.md). Fase 6 valida el build limpio. |
| R7 | **Mocks mocktail fragiles ante cambios del SDK de Firebase Storage** | Baja | Centralizados en `test/helpers/storage_mocks.dart` desde Fase 1. Un solo archivo a actualizar si el SDK cambia. |

## Como ejecutar una fase

> Cada fase se implementa con `rg-exec` en el nivel recomendado (ver el `[LITE/NORMAL/FULL]` de la tabla de fases y la seccion "Ejecucion recomendada" de cada archivo de fase):

```
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/storage-hygiene/phases/phase-01-storage-delete-utility.md', mode: 'lite' } })
```

- `lite` — mecanico / bajo riesgo (Fases 1 y 6)
- `normal` — feature acotada con ramificacion y tests de orden (Fases 2–5)
- `full` — complejo / riesgoso (contratos, migraciones, seguridad) — no aplica en este plan
