# 05 — Sintesis PO: storage-hygiene

**Timestamp:** 2026-06-19T20:16:52Z
**Slug:** `storage-hygiene`
**Estado:** PLAN FINAL

---

## Overview

El plan **storage-hygiene** introduce un ciclo de vida completo de limpieza de archivos en Firebase Storage para Rideglory: cuando un usuario reemplaza o elimina una imagen de vehiculo, portada de evento, o documento SOAT/RTM, el archivo anterior se borra automaticamente de Storage. El plan elimina la acumulacion silenciosa de archivos huerfanos sin cambios de UI, sin modificar contratos del backend (rideglory-api), y sin migraciones de datos.

La estructura es: una utilidad central robusta e idempotente (Fase 1), seguida de integracion por feature (Fases 2–5) en orden de impacto decreciente, con una fase de QA y documentacion que cierra el ciclo (Fase 6). Todos los archivos helpers de test se crean en Fase 1 para que las fases siguientes los importen directamente.

El barrido retroactivo de huerfanos preexistentes queda explicitamente fuera de alcance y registrado como deuda tecnica conocida.

---

## Cambios aplicados

Los siguientes ajustes del Architect (A1–A6) y del Plan Reviewer (AJ-1–AJ-6) fueron integrados en el plan final:

| Ajuste | Tipo | Fase afectada | Descripcion |
|--------|------|---------------|-------------|
| A1 | Arquitectura | 1 | `deleteByUrl` cubre cuatro casos explicitos (null/vacia, externa, 404, error red/permisos). Un test por caso. |
| A2 | Arquitectura | 2 | `permanentlyDeleteVehicle` cambia firma de `String vehicleId` a `VehicleModel vehicle`. Borrado de Storage en el cubit post-delete exitoso. |
| A3 | Arquitectura | 2 | Borrado de imagen anterior en `updateVehicle` ocurre en `VehicleFormCubit._saveExistingVehicle` (presentacion, post-update exitoso), no en repositorio ni use case. |
| A4 | Arquitectura | 4, 5 | Para SOAT y RTM el borrado ocurre en el repositorio (no en el cubit). El cubit extrae `oldDocumentUrl` del estado y lo pasa como parametro opcional. |
| A5 | Arquitectura | 1 | `test/helpers/storage_mocks.dart` se crea en Fase 1. Fases 2–5 lo importan directamente. Fase 6 solo verifica completitud. |
| A6 | Arquitectura | 2 | `VehicleRepositoryImpl._vehicleRequest` se anota con `// TODO(debt)` pero NO se corrige en este plan. |
| AJ-1 | Plan (critico) | 2 | Criterio de aceptacion explicito: cambiar firma de `permanentlyDeleteVehicle`. Sin este cambio el borrado en eliminaciones permanentes requiere un GET extra de red. |
| AJ-2 | Plan (critico) | 4, 5 | Criterio de aceptacion obligatorio: capturar `oldDocumentUrl` del estado ANTES de `emit(loading)`. Patron documentado en cada fase. |
| AJ-3 | Plan (critico) | 2, 3, 4, 5 | Cada fase que integra `deleteByUrl` incluye un test `verifyInOrder([backendServiceCall, deleteByUrlCall])`. No diferir a Fase 6. |
| AJ-4 | Plan (recomendado) | 2, 3 | Sub-tareas A (migracion upload) y B (deleteByUrl en update/delete) separadas explicitamente. A es diferible; B requiere que el repositorio inyecte `ImageStorageService`. |
| AJ-5 | Plan (recomendado) | 1 | Verificar comportamiento de `AppEnv.firebaseStorageBucket` en tests. Documentar solucion (override o constructor injection) en criterio de aceptacion. |
| AJ-6 | Plan (menor) | 4, 5 | Documentar como comportamiento conocido y aceptado: si el cubit esta en `Empty`/`Initial` al disparar delete, `oldDocumentUrl` es null y el archivo no se borra. No compensar con GET. |

---

## Lista final de fases

| # | Titulo | Depende de | Nivel | Razon del nivel |
|---|--------|------------|-------|-----------------|
| 1 | Storage Delete Utility | — | **lite** | Cambio mecanico en un servicio existente (`ImageStorageService`). Un solo archivo de produccion + helpers de test. Sin contratos de API, sin UI, sin migraciones. Bajo blast radius. Reversible. |
| 2 | Vehicle Image Cleanup | 1 | **normal** | Toca dos cubits (`VehicleFormCubit`, `VehicleActionCubit`), un repositorio, y cambia la firma de un metodo publico de cubit. Logica post-exito con ramificacion (reemplazo vs. eliminacion vs. archivo). Requiere `verifyInOrder` en tests. Riesgo medio de regresion si el orden de operaciones falla. |
| 3 | Event Cover Cleanup | 1 | **normal** | Similar a Fase 2: toca `EventRepositoryImpl` y el cubit de detalle/form de evento. Tiene el edge case de portadas generadas por IA (URLs Unsplash) que `deleteByUrl` debe rechazar silenciosamente. Riesgo acotado pero multi-area. |
| 4 | SOAT Document Cleanup | 1 | **normal** | Cambia firmas de interfaz de dominio (`SoatRepository`, `SaveSoatUseCase`, `DeleteSoatUseCase`). Inyecta nuevo servicio en el repositorio. Patron de captura de URL antes de `emit(loading)` critico. Blast radius: dominio + datos + presentacion. |
| 5 | RTM Document Cleanup | 1 | **normal** | Identico en estructura a Fase 4 (espejo). Misma justificacion de nivel. Se puede ejecutar en paralelo con Fase 4 si se evitan conflictos de merge, pero para simplicidad se serializa. |
| 6 | QA & Docs | 2, 3, 4, 5 | **lite** | Sin cambios de produccion. Solo verificar completitud de `test/helpers/`, correr `flutter test` + `dart analyze`, y actualizar cuatro docs de features. Sin riesgo de regresion. |

---

## Supuestos y riesgos

### Supuestos

- `AppEnv.firebaseStorageBucket` es accesible en la capa de datos y su valor es consistente en todos los entornos. Si falla en tests, la Fase 1 documenta el override a usar.
- `ImageStorageService` ya es `@injectable` y todas las clases que lo necesiten pueden recibirlo por DI sin code-gen adicional.
- El backend (rideglory-api) no gestiona Firebase Storage en ningun endpoint: las URLs se persisten como strings en la BD y el ciclo de vida del archivo en Storage es 100% responsabilidad del cliente Flutter. Sin cambios de contrato.
- Las Fases 4 y 5 pueden ejecutarse en cualquier orden posterior a la Fase 1; no tienen dependencia entre si.
- Archivar un vehiculo (`isArchived=true`) es semanticamente distinto a eliminarlo: la imagen se preserva. La distincion ya esta modelada en dominio y no cambia.
- El upload de imagenes/documentos sigue ocurriendo en la capa donde ya ocurre (cubit para vehiculos/eventos, cubit de upload para SOAT/RTM); este plan no mueve esa logica.

### Riesgos

| # | Riesgo | Severidad | Mitigacion |
|---|--------|-----------|------------|
| R1 | **Borrado prematuro:** `deleteByUrl` antes de confirmar persistencia backend → archivo borrado con modelo inconsistente | Alta | Orden estricto: write al API primero, borrado de Storage solo en bloque de exito del `fold`. Verificado con `verifyInOrder` en cada fase 2–5. |
| R2 | **URL anterior no disponible en cubit (SOAT/RTM):** si el usuario llega a save/delete sin haber cargado el modelo, `oldDocumentUrl` es null y el archivo queda huerfano | Media | Documentado como comportamiento conocido (AJ-6). El cubit debe tener `state is Data` antes de exponer acciones de save/delete en UI. Degradacion controlada sin GET compensatorio. |
| R3 | **`VehicleFormCubit` emite `data` antes de `deleteByUrl`:** si el cubit espera a `deleteByUrl` para emitir `data`, la UI queda bloqueada durante el borrado de Storage | Media | Criterio de aceptacion de Fase 2: emitir `ResultState.data` con el nuevo modelo ANTES de llamar `deleteByUrl`. El borrado es fire-and-forget desde la perspectiva de la UI. |
| R4 | **Portadas de Unsplash (eventos):** si `deleteByUrl` se llama sobre una URL externa, debe rechazarla silenciosamente sin error | Baja | La validacion de bucket en Fase 1 cubre este caso — URL externa = skip silencioso. |
| R5 | **Huerfanos preexistentes (upload anonimo de evento pre-id):** imagenes en `events/{timestamp}/cover.jpg` de eventos abandonados | Baja | Explicito fuera de alcance. Registrado como deuda tecnica. |
| R6 | **build_runner en entornos frescos:** puede fallar por build hooks de `objective_c` | Baja | Usar `--force-jit` o copiar `pubspec.lock` de main (documentado en MEMORY.md). Fase 6 valida el build limpio. |
| R7 | **Mocks mocktail fragiles ante cambios del SDK de Firebase Storage** | Baja | Centralizados en `test/helpers/storage_mocks.dart` desde Fase 1. Un solo archivo a actualizar si el SDK cambia. |
