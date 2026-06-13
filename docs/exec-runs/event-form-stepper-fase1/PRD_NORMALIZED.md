# PRD Normalizado — Fase 1: Fundación técnica (event-form-stepper)

**Slug:** `event-form-stepper-fase1`
**Generado:** 2026-06-11T19:20:10Z
**Fuente:** `docs/plans/event-form-stepper/phases/phase-01-fundacion-tecnica.md`
**Nivel rg-exec:** normal

---

## 1 Objetivo

Establecer la base técnica que habilita el wizard de pasos del formulario de eventos sin romper ninguna operación existente: `city` deja de ser requerido en toda la cadena Flutter + backend; `EventFormState` adquiere el campo `currentStep`; `EventFormCubit` centraliza el mapeo step→fields y la lógica de navegación/validación; los strings del stepper quedan definidos en ARB; y el código muerto de `EventFormDetailsSection` es eliminado.

Al terminar esta fase, `dart analyze` pasa limpio y todos los tests existentes siguen en verde. Las Fases 2 y 3 pueden arrancar sobre esta base sin conflictos.

---

## 2 Por qué

El formulario de creación de eventos pasará a ser un wizard multi-paso (stepper). Para habilitar esa refactorización sin regresar la funcionalidad existente es necesario:

- Desacoplar `city` (campo que desaparece del flujo de usuario) de la validación obligatoria en backend y en la cadena domain/data/presentation.
- Centralizar el estado de paso activo (`currentStep`) en el cubit, de modo que las Fases 2 y 3 tengan un contrato estable sobre el que construir los widgets y los tests.
- Pre-poblar el sistema de localización con los strings del stepper para que los widgets de Fase 2 no bloqueen por strings faltantes.
- Eliminar el código muerto (`EventFormDetailsSection` y su directorio `sections/details/`) antes de que la Fase 2 lo duplique o confunda.

---

## 3 Alcance

### Entra

- **Backend (`rideglory-api`):** hacer `city` opcional en `GenerateCoverDto` (`generate-cover.dto.ts`).
- **Flutter — cadena `city` nullable:** `EventCoverRepository`, `GetGenerateCoverUseCase`, `EventCoverRepositoryImpl` — `city` pasa de `required String` a `String?`; el impl omite la clave `city` del body map cuando es `null` o vacío.
- **`EventFormState`:** añadir campo `@Default(0) int currentStep` + regenerar código freezed.
- **`EventFormCubit`:** fijar `city: ''` en `buildEventToSave()` / `buildDraftToSave()`; cambiar firma de `generateCover()` a `String? city`; añadir `nextStep()` / `prevStep()` / `goToStep(int)`; añadir `_step1Fields` / `_step2Fields` / `_step3Fields` / `stepFields` / `validateStep(int)` / `isCurrentStepValid()`.
- **ARB:** 9 nuevas keys del stepper (`event_step_*`) en `app_es.arb` + regeneración de archivos de localización.
- **Eliminación de código muerto:** `event_form_details_section.dart` y el directorio `sections/details/`.
- **Verificación pre-vuelo:** `git status` antes de cualquier cambio; bloqueante si hay archivos `??` desconocidos en `lib/features/events/`.

### No entra

- Ningún widget de paso (Step 1–4), indicador visual ni barra de navegación (Fase 2).
- Cambios en `EventFormView`, `EventFormContent` ni en ningún otro widget del formulario.
- Tests nuevos (Fase 3).
- Cualquier otro endpoint o DTO de `rideglory-api` distinto de `generate-cover.dto.ts`.

---

## 4 Áreas afectadas

| Área | Archivos / rutas |
|------|-----------------|
| **Backend** | `rideglory-api/api-gateway/src/events/dto/generate-cover.dto.ts` |
| **Domain** | `lib/features/events/domain/repository/event_cover_repository.dart`, `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart` |
| **Data** | `lib/features/events/data/repository/event_cover_repository_impl.dart` |
| **Presentation / Cubit** | `lib/features/events/presentation/form/cubit/event_form_cubit.dart`, `event_form_cubit.freezed.dart` (generado) |
| **Localización** | `lib/l10n/app_es.arb`, `lib/l10n/app_localizations.dart` (gen), `lib/l10n/app_localizations_es.dart` (gen) |
| **Archivos eliminados** | `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart`, `lib/features/events/presentation/form/widgets/sections/details/difficulty_picker.dart`, `lib/features/events/presentation/form/widgets/sections/details/event_type_picker.dart` |

---

## 5 Criterios de aceptación

1. **`dart analyze` limpio:** cero errores ni warnings nuevos en `lib/` (excluidos `*.g.dart` y `*.freezed.dart`).

2. **City opcional en backend:** `generate-cover.dto.ts` tiene `@IsOptional()` sobre `city?: string`. Una petición sin el campo `city` retorna `2xx` (no `400`).

3. **Cadena Flutter — omisión condicional:** `EventCoverRepositoryImpl.generateCover()` con `city: null` o `city: ''` construye un body map que **no contiene la clave `'city'`**. Con `city: 'Medellín'` el map sí contiene `'city': 'Medellín'`. Verificable inspeccionando el map antes de la llamada a `_eventCoverService.generateCover`.

4. **Firma nullable propagada:** `EventCoverRepository.generateCover()` y `GetGenerateCoverUseCase.call()` declaran `String? city` (sin `required`). El compilador acepta llamarlos sin pasar `city`.

5. **`currentStep` en estado:** `EventFormState().currentStep == 0` (valor por defecto). `emit(state.copyWith(currentStep: 2)).currentStep == 2`.

6. **`city: ''` en builders:** `buildEventToSave()` y `buildDraftToSave()` producen un `EventModel` (o `CreateEventDto` / `UpdateEventDto`) con `city == ''` sin lanzar excepción.

7. **`generateCover()` con city nullable:** llamar `cubit.generateCover(title: 'T', eventType: 'E')` (sin `city`) no falla en compilación ni en tiempo de ejecución (delega `city: null` al use case).

8. **`validateStep(0)` comportamiento:** retorna `false` cuando el campo `EventFormFields.name` tiene valor vacío; retorna `true` cuando tiene un valor no vacío. Verificable con un `FormBuilder` + `GlobalKey<FormBuilderState>` en test.

9. **Cardinalidad de `_stepXFields`:** `_step1Fields` contiene exactamente 5 entries, `_step2Fields` exactamente 7 entries, `_step3Fields` exactamente 4 entries. Total = 16. Los 16 campos son todas las constantes de `EventFormFields` excepto `city`.

10. **`stepFields` map:** `EventFormCubit.stepFields[0]` es idéntico a `_step1Fields`, `stepFields[1]` a `_step2Fields`, `stepFields[2]` a `_step3Fields`.

11. **Límites de navegación de paso:** `nextStep()` desde `currentStep == 3` no emite estado nuevo (límite superior). `prevStep()` desde `currentStep == 0` no emite (límite inferior).

12. **9 ARB keys nuevas:** existen en `app_es.arb` y en `app_localizations_es.dart` regenerado. La key `event_form_publish_action` no está duplicada.

13. **Código muerto eliminado:** `event_form_details_section.dart` y el directorio `sections/details/` no existen en el working tree.

14. **Tests existentes en verde:** `flutter test` pasa sin fallos tras todos los cambios.

---

## 6 Guardrails de regresión

- El endpoint `POST /events/generate-cover` sigue funcionando cuando `city` es enviado (compatibilidad hacia atrás).
- El formulario de creación/edición de eventos sigue funcionando en su estado actual (ningún widget es modificado en esta fase).
- No se introducen nuevas referencias a `EventFormDetailsSection` ni sus sub-widgets en ningún archivo.
- El validator de `dateRange` en `EventFormDateTimeSection` no falla cuando `isMultiDay == false` (si lo hace es un bug preexistente que debe corregirse en esta misma fase).
- `dart analyze` y `flutter test` pasan sin fallos nuevos antes de cerrar la fase.
- Ningún archivo de localización existente pierde keys; solo se añaden las 9 nuevas `event_step_*`.
- `event_form_publish_action` no es duplicada en el ARB.

---

## 7 Constraints heredados

- **Verificación pre-vuelo bloqueante:** si `git status` muestra archivos `??` desconocidos en `lib/features/events/` (distintos de los ya conocidos del exec-run `app-ai-description-assistant`), **detener y reportar al humano** antes de continuar. El exec-run `app-ai-description-assistant` debe estar commitado.
- **Codegen obligatorio:** tras modificar `EventFormState`, ejecutar `dart run build_runner build --delete-conflicting-outputs`. Ante fallos, ejecutar `dart run build_runner clean` primero.
- **Sin commits:** este exec-run deja el working tree sucio a propósito; el humano commitea al revisar.
- **Sin migración de datos:** no se toca ninguna tabla, colección Firestore ni esquema Prisma.
- **Cambio de API retro-compatible:** el campo `city` pasa a opcional — clientes que sigan enviándolo siguen funcionando.
- **Nivel rg-exec normal:** requerido por la combinación de cambio de contrato cross-repo (TypeScript + Dart), lógica condicional en la capa data, y codegen freezed obligatorio.
- **`IsOptional` debe añadirse al import de `class-validator`** en el DTO del backend.
- **Confirmar comportamiento Gemini con `city` undefined:** el servicio que construye el prompt no debe fallar si `city` llega como `undefined`.
