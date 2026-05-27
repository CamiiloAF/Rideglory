# Iter-8 — Scope propuesto (pre-`/solo-plan`)

**Estado:** Borrador para revisión humana. **No aprobado**, **no ejecutado**.
**PRD fuente:** [`docs/prds/prd-tecnomecanica-feature.md`](./prds/prd-tecnomecanica-feature.md)
**Iteración:** 8
**Tipo:** Feature nuevo (tecnomecánica) + refactor de abstracción compartida con SOAT
**Estimado:** ~4–5 días de desarrollo + 1 día QA

---

## Tema único

**Tecnomecánica con paridad funcional al SOAT, vía abstracción compartida `VehicleDocument`.** Una sola iteración que entrega el feature nuevo Y deja el codebase mejor preparado para futuros documentos de vehículo.

---

## Stories propuestas

### Bloque A — Refactor preparatorio (va primero, sin tocar RTM)

| ID | Story | Acceptance |
|---|---|---|
| 8.1 | Como arquitectura, extraigo de `lib/features/soat/` un módulo compartido `lib/features/vehicle_documents/` con interfaz `VehicleDocumentModel`, enum `VehicleDocumentKind`, lógica de status (4 estados), cubit genérico y widgets reutilizables. | Los tests existentes del SOAT siguen pasando sin modificación. `SoatModel implements VehicleDocumentModel`. Widgets de validity card, status badge, detail row, section header y empty state viven en `vehicle_documents/widgets/` y son consumidos por SOAT. Cero regresión funcional. |
| 8.2 | Como backend, refactorizo `notification-scheduler.service.ts` extrayendo un método genérico `sendDocumentExpiryReminders(kind, daysAhead, notificationType)` que cubre tanto SOAT como cualquier documento futuro. | Los 3 crons de SOAT existentes ahora delegan al método genérico; los tests existentes pasan sin cambios; el comportamiento de notificaciones SOAT no cambia. |

### Bloque B — Tecnomecánica (depende de A)

| ID | Story | Acceptance |
|---|---|---|
| 8.3 | Como rider, puedo subir el documento de mi tecnomecánica (foto/PDF) para un vehículo y guardar los datos (número de certificado, fecha inicio, fecha vencimiento, CDA emisor). | Documento guardado en backend; badge RTM del vehículo refleja el estado correcto. |
| 8.4 | Como rider, puedo ingresar manualmente los datos de mi tecnomecánica cuando no quiero subir el documento. | Formulario valida fecha de vencimiento obligatoria; al guardar, el estado RTM refleja la lógica de vigencia correcta. |
| 8.5 | Como rider, veo en el detalle de mi vehículo un badge de estado RTM (Sin RTM / Vigente / Por vencer / Vencida) **junto al badge de SOAT existente**, y al tocarlo voy al flujo correspondiente. | Los dos badges coexisten visualmente; los 4 estados de RTM se calculan correctamente; tap navega al flujo de RTM. |
| 8.6 | Como rider, recibo notificación push 30 días antes, 7 días antes y el día del vencimiento de mi tecnomecánica, con el nombre de la moto afectada. | Las tres notificaciones llegan en las fechas correctas con el copy correcto; aparecen en el centro de notificaciones; el tap navega al detalle del vehículo. |
| 8.7 | Como rider con moto nueva (<2 años desde `purchaseDate`), veo una nota informativa que indica que la RTM puede no ser obligatoria todavía, pero puedo registrarla si quiero. | Si `purchaseDate` existe y la moto tiene <2 años, una banner suave en `TecnomecanicaUploadPage` muestra el mensaje. No bloquea el flujo. |

---

## Archivos esperados

### Backend (`rideglory-api`)

**Nuevos:**
- `vehicles-ms/prisma/migrations/<timestamp>_add_tecnomecanica/migration.sql`
- `vehicles-ms/src/vehicles/tecnomecanica.service.ts`
- `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts`
- `vehicles-ms/src/vehicles/dto/create-tecnomecanica.dto.ts`
- `api-gateway/src/vehicles/dto/create-tecnomecanica.dto.ts`

**Modificados:**
- `vehicles-ms/prisma/schema.prisma` (modelo `Tecnomecanica`)
- `vehicles-ms/src/vehicles/vehicles.controller.ts` (handlers MS RPC)
- `vehicles-ms/src/vehicles/vehicles.module.ts` (registrar service)
- `api-gateway/src/vehicles/vehicles.controller.ts` (rutas REST)
- `api-gateway/src/scheduler/notification-scheduler.service.ts` (refactor + crons RTM)
- `api-gateway/src/notifications/notifications.service.ts` (3 nuevos `NotificationType`)
- `api-gateway/src/notifications/notifications.service.spec.ts`

### Flutter

**Nuevos — módulo compartido:**
- `lib/features/vehicle_documents/domain/models/vehicle_document_model.dart`
- `lib/features/vehicle_documents/domain/models/vehicle_document_status.dart`
- `lib/features/vehicle_documents/domain/models/vehicle_document_kind.dart`
- `lib/features/vehicle_documents/domain/mixins/vehicle_document_expiry_logic.dart`
- `lib/features/vehicle_documents/domain/repository/vehicle_document_repository.dart` (interfaz)
- `lib/features/vehicle_documents/domain/usecases/get_vehicle_document_usecase.dart`
- `lib/features/vehicle_documents/domain/usecases/save_vehicle_document_usecase.dart`
- `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart`
- `lib/features/vehicle_documents/presentation/widgets/document_validity_card.dart`
- `lib/features/vehicle_documents/presentation/widgets/document_status_badge.dart`
- `lib/features/vehicle_documents/presentation/widgets/document_detail_row.dart`
- `lib/features/vehicle_documents/presentation/widgets/document_section_header.dart`
- `lib/features/vehicle_documents/presentation/widgets/document_empty_state.dart`

**Nuevos — feature tecnomecánica:**
- `lib/features/tecnomecanica/domain/models/tecnomecanica_model.dart`
- `lib/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart`
- `lib/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart`
- `lib/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart`
- `lib/features/tecnomecanica/data/dto/tecnomecanica_dto.dart`
- `lib/features/tecnomecanica/data/service/tecnomecanica_service.dart`
- `lib/features/tecnomecanica/data/repository/tecnomecanica_repository_impl.dart`
- `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart`
- `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_form_cubit.dart`
- `lib/features/tecnomecanica/presentation/pages/tecnomecanica_upload_page.dart`
- `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart`
- `lib/features/tecnomecanica/presentation/pages/tecnomecanica_confirmation_page.dart`
- `lib/features/tecnomecanica/presentation/pages/tecnomecanica_status_page.dart`
- `lib/features/tecnomecanica/presentation/widgets/` (solo widgets específicos del feature si los hay; el resto vive en `vehicle_documents/`)

**Tests nuevos:**
- `test/features/vehicle_documents/domain/vehicle_document_expiry_logic_test.dart` (4 estados)
- `test/features/vehicle_documents/presentation/vehicle_document_cubit_test.dart` (genérico)
- `test/features/tecnomecanica/data/tecnomecanica_repository_impl_test.dart`
- `test/features/tecnomecanica/presentation/tecnomecanica_form_cubit_test.dart`

**Modificados:**
- `lib/features/soat/domain/models/soat_model.dart` → `implements VehicleDocumentModel`; mover lógica de `status` y `daysUntilExpiry` al mixin compartido
- `lib/features/soat/data/repository/soat_repository_impl.dart` → si la interfaz `VehicleDocumentRepository` lo permite, declarar `implements`
- `lib/features/soat/presentation/widgets/*` → eliminar widgets duplicados, importar desde `vehicle_documents/`
- `lib/features/vehicles/presentation/` → detalle de vehículo agrega badge de RTM junto al de SOAT
- `lib/shared/router/app_router.dart` → rutas RTM
- `lib/l10n/app_es.arb` → strings nuevos `tecnomecanica_*` y posiblemente `document_status_*` compartidos
- `lib/core/di/` → registrar `TecnomecanicaService`, `TecnomecanicaRepository`, cubits
- `pubspec.yaml` → posiblemente sin cambios (todo lo necesario ya está)

### Docs
- `docs/features/tecnomecanica.md` (nuevo)
- `docs/features/soat.md` (actualizar tras refactor)
- `CLAUDE.md` (entry nuevo en tabla de features + mención del módulo `vehicle_documents/`)

### Sin cambios
- Diseño Pencil — los componentes ya existen (badge, validity card, status page). Si se quieren frames específicos de RTM se evalúa en `/solo-design`, pero el copy es lo único que cambia visualmente.
- `notifications-ms` — el sistema genérico ya soporta tipos adicionales.

---

## Pre-flight

- [ ] `git merge main --no-edit` (regla del proyecto)
- [ ] iter-7 (OCR SOAT) mergeado y estable, o explícitamente postergado en backlog
- [ ] Diseño Pencil revisado: ¿necesitamos un badge visual distinto para SOAT vs RTM (mismo estilo, distinto label) o icons distintos?
- [ ] Backend: `vehicles-ms` corre limpio localmente con migraciones actuales

---

## Definition of Done

- [ ] Todas las stories 8.1–8.7 cumplen acceptance
- [ ] **Regresión SOAT cero**: tests existentes pasan sin cambios; smoke test manual del flujo SOAT completo en dispositivo real
- [ ] `dart analyze` sin warnings nuevos; `flutter test` al 100%
- [ ] Backend: `npm run test` (todos los MS) al 100%
- [ ] Migración Prisma aplicada **local primero**, validada por humano antes de remoto (regla del proyecto)
- [ ] Smoke test manual: registrar RTM en moto real, ver badge cambiar, disparar cron manualmente para ver notificación
- [ ] `app_es.arb` actualizado y `flutter gen-l10n` ejecutado
- [ ] `docs/features/tecnomecanica.md` creado; `docs/features/soat.md` y `CLAUDE.md` actualizados
- [ ] PR description documenta explícitamente el refactor de SOAT y las pruebas hechas para confirmar no-regresión

---

## Riesgos (resumen del PRD §6)

- **Refactor SOAT rompe producción** → tests existentes + smoke manual.
- **Sobre-abstracción** → solo lo que tiene ≥2 usos hoy.
- **Scheduler rompe SOAT** → método genérico mantiene firma exacta del helper actual.
- **Migración Prisma** → local antes que remoto.

---

## Orden de ejecución recomendado dentro de la iteración

1. **Stories 8.1 + 8.2** (refactor preparatorio, frontend + backend). PR independiente si pesa ≥40 archivos.
2. **Story 8.3** (backend tecnomecánica: schema + service + endpoints).
3. **Story 8.4** (Flutter manual capture sobre la abstracción ya existente).
4. **Story 8.5** (badge RTM en detalle vehículo).
5. **Story 8.6** (recordatorios push + integración notification center).
6. **Story 8.7** (nota informativa vehículo nuevo).

---

## Próximos pasos

1. **Revisar este scope** y el PRD con la persona de producto (tú).
2. Si OK → correr `/solo-plan` apuntando al PRD para obtener el plan formal PO + Architect.
3. Tras `/solo-plan`, correr `/solo-approve` para activar iter-8 en `workflow/state.json`.
4. Solo entonces, `/iter 8` ejecuta la iteración completa.
