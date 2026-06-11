# PRD Normalizado — Eliminar campo `city` de eventos

**Slug:** `remove-city-field`
**Generado:** 2026-06-11T21:46:20Z
**Fuente:** `docs/plans/event-form-stepper/remove-city-field.md`
**Nivel:** normal

---

## 1 Objetivo

Eliminar el campo `city` de la entidad Event en todos los layers del sistema: base de datos (Prisma), contratos compartidos, microservicios backend, y el cliente Flutter (domain / data / presentation). `meetingPointName` actúa como proxy geográfico suficiente en el cubit y en el contexto de IA; `city` es redundante y su eliminación simplifica el modelo sin pérdida funcional.

---

## 2 Por qué

- No hay usuarios ni eventos reales en producción; la eliminación es segura y no requiere migración de datos existentes.
- El campo de filtro `city` en `GET /events` no está siendo usado por la UI actualmente.
- Mantener un campo sin uso introduce ruido en contratos, DTOs, formularios y contexto de IA (Gemini), aumentando la superficie de mantenimiento.
- El formulario de creación de eventos usa `meetingPointName` (punto de encuentro) como referencia geográfica; `city` es un duplicado de menor precisión.

---

## 3 Alcance

### Backend — `rideglory-api`

| # | Archivo | Acción |
|---|---------|--------|
| B1 | `events-ms/prisma/schema.prisma` | Eliminar campo `city` del modelo `Event`; ejecutar `npx prisma migrate dev --name remove_event_city`; regenerar cliente (`npx prisma generate`) |
| B2 | `rideglory-contracts/src/events/dto/create-event.dto.ts` | Eliminar campo `city` |
| B3 | `rideglory-contracts/src/events/dto/event-filter.dto.ts` | Eliminar campo `city` |
| B4 | `rideglory-contracts/src/ai/dto/ai-description-event-context.dto.ts` | Eliminar campo `city` |
| B5 | `events-ms/src/events/events.service.ts` | Eliminar referencias a `city` en create / update / filter |
| B6 | `api-gateway/src/ai/gemini.service.ts` | Eliminar `city` del contexto enviado a Gemini; usar `meetingPoint` si disponible |
| B7 | Contratos | Rebuild: `cd rideglory-contracts && npm run build`; reinstalar en microservicios afectados (`pnpm install`) |

### Flutter — `lib/`

| # | Archivo | Acción |
|---|---------|--------|
| F1 | `lib/features/events/domain/model/event_model.dart` | Eliminar campo `city` (constructor, copyWith, toString, ==, hashCode); regenerar freezed |
| F2 | `lib/features/events/data/dto/event_dto.dart` | Eliminar `city` del DTO |
| F3 | `lib/features/events/data/service/event_service.dart` | Eliminar `@Query('city') String? city` del método GET events |
| F4 | `lib/features/events/data/repository/event_repository_impl.dart` | Eliminar parámetro `city` |
| F5 | `lib/features/events/domain/repository/event_repository.dart` | Eliminar parámetro `city` |
| F6 | `lib/features/events/domain/use_cases/get_events_use_case.dart` | Eliminar parámetro `city` |
| F7 | `lib/features/events/domain/model/ai_description_request.dart` | Eliminar campo `city` |
| F8 | `lib/features/events/data/dto/ai_event_context_dto.dart` | Eliminar campo `city`; actualizar `fromRequest()` para no incluirlo |
| F9 | `lib/features/events/domain/use_cases/generate_event_description_use_case.dart` | Eliminar `city: request.city` |
| F10 | `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart` | Eliminar `AppCityAutocomplete` y toda referencia a `EventFormFields.city` |
| F11 | `lib/features/events/constants/event_form_fields.dart` (o donde viva) | Eliminar constante `city` |
| F12 | Generación de código | Correr `dart run build_runner build --delete-conflicting-outputs` y `dart analyze`; todo en verde |

---

## 4 Áreas afectadas

- **Base de datos:** esquema Prisma de `events-ms`; requiere migración local.
- **Contratos compartidos (`rideglory-contracts`):** DTOs de creación, filtro y contexto de IA.
- **Microservicios:** `events-ms` (servicio y controlador), `api-gateway` (integración Gemini).
- **Domain Flutter:** `EventModel`, `AiDescriptionRequest`, repositorio abstracto, use cases.
- **Data Flutter:** `EventDto`, `AiEventContextDto`, `EventService` (Retrofit), `EventRepositoryImpl`.
- **Presentation Flutter:** sección de formulario `EventFormBasicInfoSection`, constantes de formulario.
- **Tests Flutter:** tests de analytics que pasan `city: ''` deben actualizarse para no incluir el campo.
- **Sin impacto esperado:** routing, autenticación, tracking WebSocket, otros features (vehicles, maintenance, SOAT, RTM).

---

## 5 Criterios de aceptación

1. `grep -rn "\.city" lib/features/events/ --include="*.dart"` retorna vacío (excepto archivos `*.g.dart` y `*.freezed.dart`).
2. `grep -rn "city" rideglory-api/events-ms/prisma/schema.prisma` retorna vacío.
3. `grep -rn "city" rideglory-api/rideglory-contracts/src/events/` retorna vacío.
4. Migración Prisma `remove_event_city` aplicada localmente; `events-ms` compila (`tsc --noEmit` o `nest build`) y las pruebas del microservicio pasan.
5. `dart analyze lib/` — salida "No issues found" (sin warnings ni errors nuevos).
6. `flutter test` — todos los tests en verde; los tests que antes pasaban `city: ''` o `city: <valor>` han sido actualizados para no incluir el campo.
7. `AppCityAutocomplete` no aparece en ningún archivo bajo `lib/features/events/presentation/`.
8. La constante `EventFormFields.city` (o equivalente) no existe en el codebase Flutter.
9. El formulario de creación/edición de evento carga y navega sin errores en tiempo de ejecución (no hay referencias rotas a `city`).
10. `api-gateway/src/ai/gemini.service.ts` no contiene referencias a `city` en el payload enviado a Gemini.

---

## 6 Guardrails de regresión

- **No romper otros features:** el formulario de evento completo (básico, ubicación, fecha, vehículo) debe seguir funcionando end-to-end tras los cambios.
- **No eliminar `meetingPointName`:** este campo reemplaza funcionalmente a `city` y debe permanecer intacto.
- **Migración solo local:** no ejecutar migraciones en entornos staging/prod sin aprobación humana explícita (per workflow — deploy workflow rule).
- **No tocar archivos generados manualmente:** `*.g.dart` y `*.freezed.dart` son output de `build_runner`; solo regenerar, no editar a mano.
- **Contracts rebuild obligatorio:** cualquier cambio en `rideglory-contracts` requiere `npm run build` + `pnpm install` en cada microservicio afectado; si se omite, fallan con `MODULE_NOT_FOUND`.
- **No commitear:** el árbol de trabajo queda sucio para revisión humana; el usuario commitea tras aprobar.
- **Linting Flutter:** `dart analyze` debe quedar en verde antes de dar la fase por terminada.

---

## 7 Constraints heredados

- **Sin usuarios reales en producción:** refactors agresivos son seguros; los tests deben pasar de todas formas.
- **Arquitectura Clean:** Domain no importa Flutter ni hace I/O de red; Data no expone DTOs a Presentation; flujo inward domain ← data / presentation.
- **DTO Pattern B:** cualquier DTO residual debe seguir extendiendo su modelo de dominio; `toModel()` y `fromModel()` están prohibidos.
- **Payloads de escritura vía `.toJson()` del DTO:** nunca construir `Map<String, dynamic>` manual para bodies HTTP.
- **build_runner con `--force-jit`** si el entorno es worktree/CI fresco (ver memory `project_build_runner_force_jit.md`).
- **Local API hack** (`shouldUseLocalApi=true` en `api_base_url_resolver.dart`) no debe commitearse ni revertirse.
- **Actualizar docs de feature:** si `docs/features/events.md` existe y documenta el campo `city`, actualizarlo para reflejar su eliminación.
