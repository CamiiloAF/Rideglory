# Architect handoff — event-form-stepper Fase 1 (revisión Auditor)

**Date:** 2026-06-11T19:36:08Z
**Status:** done (bloqueante D1 escalado al humano)
**Slug:** event-form-stepper-fase1

---

## PREGUNTA BLOQUEANTE AL HUMANO — leer antes de continuar

**¿La portada IA entra en Fase 1?**

Toda la cadena de generación de portada (Flutter + backend) referenciada en PRD §3-4 NO EXISTE en el código actual:
- `EventCoverRepository`, `GetGenerateCoverUseCase`, `EventCoverRepositoryImpl` — ninguno existe en `lib/`
- `POST /ai/cover` endpoint — no existe en `api-gateway/src/ai/ai.controller.ts`
- `GeminiService.generateCover()` — no existe en `gemini.service.ts`

Solo existen `AiCoverRequestDto` / `AiCoverResponseDto` en `rideglory-contracts` (sin implementación).

El PRD asume MODIFY sobre archivos inexistentes — defecto del plan. Se necesita decisión explícita:

- **Opción A (recomendada):** sacar toda la portada de Fase 1. AC-2, AC-3, AC-4, AC-7 del PRD quedan sin objeto. La cadena cover se implementa en una Fase separada con archivos correctamente creados.
- **Opción B:** incluir cover en Fase 1 creando (no modificando) todos los archivos de la cadena, y definiendo un contrato real que reconcilie con los DTOs existentes en `rideglory-contracts` (no duplicar el concepto).

**Este handoff documenta ambas opciones. El change map principal usa Opción A.**

---

## Decisiones

### D1 — Portada IA fuera de Fase 1 (Opción A adoptada)

La cadena cover no existe en Flutter ni en backend. El plan la asumió como MODIFY de archivos preexistentes — ese supuesto es incorrecto. Dado que crear una feature completa (Flutter + backend + Gemini prompt engineering) es work no trivial y no declarado en el objetivo §1 del PRD ("establecer la base técnica del wizard"), la Opción A es la más segura.

**Si el humano confirma Opción B:** ver §Contratos más abajo para el shape mínimo viable. El campo `coverResult` en `EventFormState` y el método `generateCover()` en el cubit solo se añaden bajo Opción B. El constructor de `EventFormCubit` no cambia en Opción A.

### D2 — `city` en builders: `buildEventToSave()` requiere corrección

Línea 344 de `event_form_cubit.dart`: `city: formData[EventFormFields.city] as String` — cast no-nullable. Con el stepper, el campo `city` desaparece del formulario en Fase 2; el cast fallará con excepción de tipo. Fase 1 lo fija a `city: ''` directamente sin leer del form.

`buildDraftToSave()` línea 417 ya usa `?.trim() ?? ''` — ya es seguro; sin cambio adicional.

### D3 — `EventFormCubit` constructor en Opción A: 5 params, sin cambio

Constructor actual confirmado: `CreateEventUseCase, UpdateEventUseCase, UploadEventImageUseCase, GetCurrentUserIdUseCase, AnalyticsService` (5° param es `AnalyticsService`, no un use case). Test `event_form_cubit_analytics_test.dart` confirma los 5 params. Bajo Opción A no se añade ningún use case nuevo al constructor — el test existente sigue verde sin modificación.

### D4 — `EventFormDetailsSection` es código muerto eliminable sin riesgo

Confirmado con grep: 0 referencias externas en `lib/`. El directorio `sections/details/` contiene solo `difficulty_picker.dart` y `event_type_picker.dart`, importados únicamente desde `event_form_details_section.dart`. Eliminación es segura.

### D5 — `city` en `AiDescriptionEventContext` (description flow) no afectado

El campo `city` en `AiDescriptionEventContext` (flow de descripción IA existente) es requerido y no cambia en Fase 1. El stepper eliminará el campo del formulario en Fase 2-3; hasta entonces el formulario sigue teniendo el campo visible.

### D6 — Cardinalidad de `stepFields` vs `EventFormFields`

`EventFormFields` tiene 17 constantes: `name, description, city, dateRange, isMultiDay, meetingTime, difficulty, eventType, meetingPoint, destination, isMultiBrand, allowedBrands, price, maxParticipants, isFreeEvent, routeType, waypoints`. El PRD AC-9 dice total=16 (sin `city`). El Build agent debe determinar si `routeType` y `waypoints` son campos del form o de estado del cubit (son campos de estado — no van en `stepFields`). Ajustar cardinalidad antes de codificar.

---

## Change map (Opción A — sin portada IA)

| # | File | Action | Reason | Risk |
|---|------|--------|--------|------|
| 1 | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | modify | +`@Default(0) int currentStep` en `EventFormState`; `city: ''` fijo en `buildEventToSave()`; +`nextStep/prevStep/goToStep`, +`_step1Fields/_step2Fields/_step3Fields/stepFields`, +`validateStep/isCurrentStepValid` | med |
| 2 | `lib/features/events/presentation/form/cubit/event_form_cubit.freezed.dart` | modify (regenerado) | Codegen tras cambio de `EventFormState` | low |
| 3 | `lib/l10n/app_es.arb` | modify | +9 keys `event_step_*` | low |
| 4 | `lib/l10n/app_localizations.dart` | modify (regenerado) | `flutter gen-l10n` tras editar ARB | low |
| 5 | `lib/l10n/app_localizations_es.dart` | modify (regenerado) | `flutter gen-l10n` tras editar ARB | low |
| 6 | `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart` | delete | Código muerto, 0 referencias externas | low |
| 7 | `lib/features/events/presentation/form/widgets/sections/details/difficulty_picker.dart` | delete | Solo usado por archivo eliminado | low |
| 8 | `lib/features/events/presentation/form/widgets/sections/details/event_type_picker.dart` | delete | Solo usado por archivo eliminado | low |

**Archivos fuera del change map bajo Opción A (NO tocar):**
- `rideglory-api/api-gateway/src/events/dto/generate-cover.dto.ts` — no crear
- `rideglory-api/api-gateway/src/ai/ai.controller.ts` — no modificar
- `rideglory-api/api-gateway/src/ai/gemini.service.ts` — no modificar
- `lib/features/events/domain/repository/event_cover_repository.dart` — no crear
- `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart` — no crear
- `lib/features/events/data/repository/event_cover_repository_impl.dart` — no crear
- `lib/features/events/presentation/form/widgets/event_form_content.dart` — out of scope
- `lib/features/events/presentation/form/widgets/event_form_view.dart` — out of scope
- `rideglory-contracts` (submódulo) — no modificar

---

## Contratos rideglory-api

**Opción A:** ningún contrato nuevo. Sin cambios de backend en Fase 1.

**Opción B (solo si el humano lo confirma):** crear `POST /ai/cover` en `AiController`. El contrato debe reconciliar con los DTOs preexistentes en `rideglory-contracts`:
- `AiCoverRequestDto` ya definido como `{ prompt: string; draftId: UUID }` — shape diferente al que el PRD original asumía. Reconciliar explícitamente: ¿se usa el DTO existente o se crea uno local? No duplicar el concepto.
- `GeminiService.generateCover()` no debe retornar `response.text` como `imageUrl` — definir qué representa el campo (URL de imagen real, placeholder, o resultado de Imagen API de Google).

---

## Datos / migraciones

Ninguno. No se toca ninguna tabla Prisma, colección Firestore ni esquema de base de datos.

---

## Env

Ningún delta. No se añaden ni modifican variables de entorno.

---

## Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | Exec-run anterior no commitado — archivos `??` en `lib/features/events/` distintos a los conocidos | ALTA | Paso 0 bloqueante: `git status`. Detener si hay `??` no esperados |
| R2 | `buildEventToSave()` lanza excepción de tipo si `city` no está en el form en Fases futuras | ALTA | Fase 1 fija `city: ''` sin leer del form (línea 344) |
| R3 | Codegen freezed puede fallar con conflictos de `build_runner` | BAJA | `--delete-conflicting-outputs`; ante fallo: `dart run build_runner clean` primero |
| R4 | `stepFields` drift: cardinalidad real puede diferir del AC-9 si `routeType`/`waypoints`/`isFreeEvent` son de estado, no de form | MEDIA | Build agent debe verificar qué constantes de `EventFormFields` corresponden a form fields reales vs. campos de estado del cubit |
| R5 | Test `event_form_cubit_analytics_test.dart` — NO rompe en Opción A (constructor no cambia) | N/A bajo Opción A | — |

---

## Orden de implementación (Opción A)

1. Verificación pre-vuelo: `git status` — bloqueante si hay `??` no esperados en `lib/features/events/`
2. Eliminar `event_form_details_section.dart` y directorio `sections/details/`
3. Modificar `EventFormState` en `event_form_cubit.dart`: +`@Default(0) int currentStep`
4. Corregir `buildEventToSave()`: reemplazar `city: formData[EventFormFields.city] as String` por `city: ''`
5. Añadir métodos de navegación y mapping: `_step1Fields`, `_step2Fields`, `_step3Fields`, `stepFields`, `validateStep()`, `isCurrentStepValid()`, `nextStep()`, `prevStep()`, `goToStep()`
6. Ejecutar codegen: `dart run build_runner build --delete-conflicting-outputs`
7. Añadir 9 keys `event_step_*` en `app_es.arb` + ejecutar `flutter gen-l10n`
8. Verificar: `dart analyze` limpio + `flutter test` sin fallos nuevos

---

## Superficie de regresión

- `EventFormCubit` / `EventFormState` — campos existentes no se eliminan; solo se añade `currentStep` con default. Código existente que llame `state.saveResult`, `state.waypoints`, etc. sigue compilando.
- `event_form_cubit_analytics_test.dart` — constructor no cambia en Opción A; test sigue verde sin modificación. El 5° parámetro es `AnalyticsService` (confirmado en código y test).
- `buildEventToSave()` — `city: ''` no rompe ningún widget existente (ningún widget en Fase 1 depende del valor de city en el evento construido).
- `event_form_basic_info_section_test.dart` — no importa `EventFormDetailsSection`; sigue verde.
- No hay test para `EventFormDetailsSection` — su eliminación no rompe ningún test.

---

## Fuera de alcance

- Toda cadena de portada IA (Flutter + backend) — requiere confirmación del humano (Opción B)
- Widgets de paso (Step 1–4), stepper visual, barra de navegación — Fase 2
- Tests nuevos para navegación y mapping — Fase 3
- Eliminación del campo `city` del formulario visible (`EventFormBasicInfoSection`) — fuera del plan de Fase 1
- Cambios en `EventFormView` o `EventFormContent`
- `AiDescriptionEventContext.city` — permanece requerido y sin cambios
