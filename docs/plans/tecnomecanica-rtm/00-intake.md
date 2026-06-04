# Intake — Tecnomecánica (RTM)

**Slug:** `tecnomecanica-rtm`
**Creado:** 2026-06-04T13:00:21Z
**Sesión:** Planeación (no se modifica código de la app)

## Fuente

`docs/prds/prd-tecnomecanica-feature.md` (PRD completo, leído íntegro).

Tipo declarado en el PRD: **Feature nuevo + refactor de abstracción compartida con SOAT**.
Prioridad media-alta, estimado 1 iteración (~4–5 días). Depende de que el feature SOAT (iter-2) esté terminado y estable. Explícitamente **no** incluye OCR para RTM.

## Objetivo

Shippear la **tecnomecánica (RTM)** con paridad funcional total respecto al SOAT (registrar, ver, actualizar, badge de estado, recordatorios push 30d/7d/0d, centro de notificaciones) y, en el mismo trabajo, **extraer una abstracción compartida `VehicleDocument`** en Flutter y en la interfaz HTTP del backend para que SOAT y RTM —y cualquier documento futuro— reutilicen modelo de estado, widgets, cubit, scheduler y rutas sin duplicación.

## Alcance percibido

### Frontend (Flutter — este repo)
- Nuevo módulo `lib/features/vehicle_documents/` (genérico): `VehicleDocumentModel` (abstract), enums `VehicleDocumentStatus` y `VehicleDocumentKind`, repositorio/usecases genéricos, cubit genérico parametrizado por `kind`, y widgets reutilizables (validity card, status badge, detail row, section header, empty state).
- Refactor de `lib/features/soat/` para consumir el genérico: `SoatModel implements VehicleDocumentModel`, widgets compartidos, **regresión cero** (todos los tests SOAT existentes pasan sin cambiar su acceptance). Va **primero**, antes de RTM.
- Nuevo `lib/features/tecnomecanica/` (espejo fino de SOAT): páginas Upload, ManualCapture, Confirmation, Status, todas sobre widgets genéricos. Campos propios: `certificateNumber`, `cdaName` (texto libre), `cdaCode?`.
- Detalle del vehículo: **dos badges** (SOAT + RTM), cada uno con 4 estados (sin / vigente / por vencer / vencido), tap-ables hacia su flujo.
- Lógica de `status` y `daysUntilExpiry` compartida vía mixin/helper `VehicleDocumentExpiryLogic`.
- `app_es.arb`: strings `tecnomecanica_*` y, donde aplique, strings genéricos `document_*`. Copy en español.
- Nota informativa (no bloqueante) de exención por antigüedad cuando la moto tenga <2 años desde `purchaseDate`.
- DoD de calidad: sin nuevos warnings de `dart analyze`; `flutter test` al 100%.

### Backend (rideglory-api — repo separado, /Users/cami/Developer/Personal/rideglory-api)
- `vehicles-ms`: nueva tabla Prisma `Tecnomecanica` (espejo de `Soat`, **tablas separadas**, no tabla genérica con `type`); `TecnomecanicaService`, controller MS y DTOs con tests; RPC para que api-gateway consulte vencimientos.
- `api-gateway`: rutas REST `POST/GET /api/vehicles/:vehicleId/tecnomecanica` con Firebase Auth guard; `create-tecnomecanica.dto.ts`; refactor de `notification-scheduler.service.ts` a helper genérico `sendDocumentExpiryReminders(kind, days, notificationType)` + 3 crons RTM (30d/7d/0d) en `America/Bogota`; 3 nuevos `NotificationType` (`TECNOMECANICA_30D/7D/DAY_OF`).
- `notifications-ms`: sin cambios de modelo (el patrón ya soporta tipos adicionales).
- Migración Prisma: correr **local primero**, validación humana, luego remoto (regla del proyecto).

### HTTP/Retrofit (este repo)
- Dos servicios Retrofit separados (`SoatService`, `TecnomecanicaService`) con el mismo contrato semántico (GET por vehicleId, POST con payload). Sin cliente HTTP unificado.

### Tests
- Unit: lógica de status (4 estados) a nivel de `VehicleDocumentModel` con casos SOAT y RTM; cubit genérico con test parametrizado por kind; widgets compartidos probados una sola vez.
- Backend: crons RTM con fixtures de fechas (30d/7d/0d/otros); `tecnomecanica.service.spec.ts`; `notifications.service.spec.ts` actualizado.

### Docs
- Nuevo `docs/features/tecnomecanica.md`; actualizar `docs/features/soat.md` por el refactor; agregar `tecnomecanica` y la abstracción `vehicle_documents/` a `CLAUDE.md`; documentar endpoint nuevo en `rideglory-api/docs/features/` si existe.

### Fuera de alcance (confirmado por el PRD)
OCR auto-fill RTM; inspección histórica; integración con APIs de CDAs; reglas de exención automatizadas/enforzadas; generalización a un tercer tipo de documento.

## Preguntas abiertas

1. **Estado actual del SOAT vs. PRD.** ¿La estructura real de `lib/features/soat/` (data/domain/presentation) coincide con lo que el PRD asume? Hay que mapear sus modelos, repositorios, cubits, páginas y widgets concretos antes de definir qué es genérico y qué queda como capa fina. (Pendiente de auditoría en fase de Architect.)
2. **Forma del `SoatModel` actual.** ¿Ya sigue Pattern B (DTO extiende Model)? ¿Cómo se reconcilia `SoatModel implements VehicleDocumentModel` con el patrón DTO-extends-Model del proyecto sin romper la serialización?
3. **`purchaseDate` en el vehículo.** ¿`VehicleModel` ya expone una fecha de compra/antigüedad utilizable para la nota de exención <2 años? Si no existe, ¿se omite la nota o se añade el campo (¿implica backend)?
4. **Estrategia de copy genérico vs. específico.** ¿Se unifican strings de estado en `document_status_*` (reemplazando los de SOAT) o se mantienen claves SOAT y se añaden RTM en paralelo? Decisión afecta regresión y el ARB.
5. **Deep links / navegación desde notificación.** El PRD dice "depende de iter-1 deep links si está en flight". ¿Cuál es el estado real del deep-linking hoy? Define si el tap de notificación RTM navega directo al detalle o cae en un fallback.
6. **Tamaño de PR / split.** El PRD permite separar la PR del refactor SOAT de la PR de RTM si ≥40 archivos. ¿El plan debe estructurar fases que produzcan dos cortes commit-ables independientes?
7. **Badge en detalle del vehículo.** ¿Dónde vive hoy el badge SOAT en el detalle del vehículo (feature `vehicles/` vs `soat/`) y cómo se inyecta el segundo badge RTM sin acoplar `vehicles/` a ambos features concretos?
8. **Contrato RPC de vencimientos.** ¿El scheduler actual de SOAT consulta vencimientos vía RPC ya existente que se pueda parametrizar, o requiere endpoint MS nuevo para RTM?
