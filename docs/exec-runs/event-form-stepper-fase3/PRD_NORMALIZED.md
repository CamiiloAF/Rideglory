# PRD Normalizado — Event Form Stepper: Fase 3 Cobertura y Cierre

**Slug:** `event-form-stepper-fase3`
**Generado:** 2026-06-12T04:05:07Z
**Fuente:** `docs/plans/event-form-stepper/phases/phase-03-cobertura-y-cierre.md`
**Nivel rg-exec:** lite

---

## 1 Objetivo

Cerrar el wizard de creación de eventos con suite de tests verde y análisis limpio: actualizar dos archivos de test existentes que fallan por los cambios de `city` introducidos en Fases 1–2, agregar 8 tests unitarios de cubit y 3 smoke tests de widget para `EventFormStep1`, y verificar que `dart analyze` y `flutter test` pasen sin errores.

---

## 2 Por qué

Las Fases 1 y 2 modificaron `EventFormCubit` (métodos de navegación de paso, `buildEventToSave()` con `city: ''`) y crearon `EventFormStep1` / `EventStepNavBar`, dejando tests existentes desactualizados y sin cobertura de los nuevos métodos. Sin esta fase, el repositorio quedaría con tests rotos y código sin verificación automatizada, lo que degrada la confianza en futuros cambios.

---

## 3 Alcance

### Entra

- Actualizar `event_form_cubit_analytics_test.dart`: fixture `_mockEvent` cambia `city: 'Medellín'` → `city: ''` (línea 39).
- Actualizar `event_form_basic_info_section_test.dart`: comentario de header (línea 6), nombre del test AC18 (línea 147) y assertion `ctx.city` (línea 220) para reflejar que `city` viene de `state.meetingPointName ?? ''`.
- Crear `test/features/events/presentation/form/cubit/event_form_cubit_stepper_test.dart` con 8 tests unitarios (TC-step-01 a TC-step-08) cubriendo `nextStep`, `prevStep`, `goToStep`, `isCurrentStepValid`, `buildEventToSave` y estado inicial.
- Crear `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart` con 3 smoke tests de widget (TC-wdg-01 a TC-wdg-03).
- Verificar `dart analyze lib/` limpio (excluidos `*.g.dart` y `*.freezed.dart`).
- Verificar que no quedan referencias a `EventFormFields.city` en `lib/features/events/presentation/`.

### No entra

- Widget tests para `EventFormStep2`, `EventFormStep3`, `EventFormStep4Review`.
- Tests de integración end-to-end del wizard.
- Profiling de memoria (`IndexedStack` + Mapbox) — deuda técnica de Fase 2.
- Tests del backend (`generate-cover.dto.ts`) — cubierto en Fase 1.
- Cambios bajo `lib/` salvo referencia residual a `EventFormFields.city` detectada en Paso 6.

---

## 4 Áreas afectadas

| Capa | Archivos |
|------|----------|
| Tests (cubit) | `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` (mod), `event_form_cubit_stepper_test.dart` (nuevo) |
| Tests (widget) | `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` (mod), `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart` (nuevo) |
| `lib/` (condicional) | Cualquier referencia residual a `EventFormFields.city` en `lib/features/events/presentation/` detectada por `grep` |

No hay cambios en backend (`rideglory-api`), contratos de API, migraciones ni diseño Pencil.

---

## 5 Criterios de aceptación

1. `flutter test` pasa sin fallos (0 failing tests).
2. `dart analyze lib/` retorna cero errores y cero warnings en archivos no generados (excluidos `*.g.dart` y `*.freezed.dart`).
3. `grep -r "EventFormFields.city" lib/features/events/presentation/` no retorna ningún resultado.
4. La fixture `_mockEvent` en `event_form_cubit_analytics_test.dart` usa `city: ''`.
5. El test AC18 en `event_form_basic_info_section_test.dart` verifica `ctx.city == ''` (o `== state.meetingPointName` si el scaffold provee un cubit con valor conocido) — nunca verifica que `city` provenga de `EventFormFields.city`.
6. Los 8 tests de cubit en `event_form_cubit_stepper_test.dart` pasan:
   - TC-step-01: `nextStep()` incrementa `currentStep` de 0 a 1.
   - TC-step-02: `nextStep()` en paso 3 no supera `currentStep == 3`.
   - TC-step-03: `prevStep()` decrementa `currentStep` de 1 a 0.
   - TC-step-04: `prevStep()` en paso 0 no baja de 0.
   - TC-step-05: `goToStep(2)` asigna `currentStep == 2`.
   - TC-step-06: `isCurrentStepValid()` con `formKey` sin campos montados retorna `true`.
   - TC-step-07: `buildEventToSave()` produce `city == ''`.
   - TC-step-08: Estado inicial tiene `currentStep == 0`.
7. Los 3 smoke tests de `event_form_step1_test.dart` pasan:
   - TC-wdg-01: `EventFormStep1` renderiza sin overflow ni excepciones con nombre vacío.
   - TC-wdg-02: Botón 'Continuar' de `EventStepNavBar` deshabilitado con nombre vacío.
   - TC-wdg-03: Botón 'Continuar' habilitado tras escribir un nombre en el campo.

---

## 6 Guardrails de regresión

- No romper ningún test existente fuera de los 2 archivos modificados en esta fase.
- No modificar código bajo `lib/` excepto eliminación de referencias residuales a `EventFormFields.city` detectadas por `grep` en Paso 6.
- Si `buildEventToSave()` requiere `formKey` montado (TC-step-07 falla en test unitario), mover el test al smoke test de widget — no suprimir ni ignorar el comportamiento.
- Los mocks de `PlaceService` y `AiDescriptionChatCubit` deben desregistrarse en `tearDown` para evitar contaminación entre tests (patrón de `event_form_basic_info_section_test.dart` líneas 106–126).
- No resolver residuos de Fases 1–2 fuera del alcance de esta fase sin reportar al humano primero.

---

## 7 Constraints heredados

- **Arquitectura Clean Architecture / BLoC:** Tests de cubit instancian `EventFormCubit` directamente con mocks; tests de widget usan `BlocProvider.value` — no acceder a GetIt desde widgets de test.
- **`dart analyze` limpio:** El repositorio no acepta warnings ni errores en `lib/` (excluidos archivos generados). Condición de cierre de fase.
- **Sin commits automáticos:** El árbol de trabajo queda sucio; el humano revisa y commitea.
- **Localización:** El scaffold de widget test debe incluir `localizationsDelegates` completos para evitar errores de `context.l10n`.
- **Flavor dev/prod:** Los tests corren contra código sin flavor específico; no se requiere `--dart-define-from-file`.
- **Depende de Fases 1 y 2 completas:** `nextStep`, `prevStep`, `goToStep`, `isCurrentStepValid`, `buildEventToSave` con `city: ''`, `EventFormStep1` y `EventStepNavBar` deben existir antes de ejecutar esta fase.
