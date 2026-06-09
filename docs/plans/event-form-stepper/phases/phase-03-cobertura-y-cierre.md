# Fase 3 — Cobertura y cierre

**Slug:** `event-form-stepper`
**Fecha:** 2026-06-09T02:13:57Z
**Nivel rg-exec:** lite
**Depende de:** Fase 2

---

## Objetivo

El flujo completo del wizard pasa `dart analyze` limpio y los tests cubren los cambios introducidos
en el cubit por las Fases 1–2, más un smoke test de widget para `EventFormStep1`. Sin nuevos
contratos de backend, sin migraciones, sin lógica nueva de negocio.

---

## Alcance

### Entra

- Actualizar los dos archivos de test existentes que fallan por los cambios de `city`:
  - `event_form_cubit_analytics_test.dart`: fixture `_mockEvent` usa `city: 'Medellín'` → `city: ''`.
  - `event_form_basic_info_section_test.dart`: actualizar header de archivo, mock setup, nombre del
    test AC18 y assertion `ctx.city` para reflejar que city ya no proviene de `EventFormFields.city`
    sino de `state.meetingPointName ?? ''`.
- Crear nuevos tests de cubit cubriendo los métodos añadidos en Fases 1–2 en `EventFormCubit`:
  - `nextStep()` / `prevStep()` / `goToStep()` / `isCurrentStepValid()` / `buildEventToSave()`.
- Crear un smoke test de widget para `EventFormStep1`.
- Verificar que `dart analyze` corre limpio en `lib/` (excluidos `.g.dart` y `.freezed.dart`).
- Verificar que no quedan referencias a `EventFormFields.city` en `lib/features/events/presentation/`.

### No entra

- Widget tests para `EventFormStep2`, `EventFormStep3`, `EventFormStep4Review`.
- Tests de integración end-to-end del wizard completo.
- Profiling de memoria (`IndexedStack` + Mapbox) — tech debt documentado en Fase 2.
- Tests del backend (`generate-cover.dto.ts`) — cubierto en Fase 1 mediante inspección del payload.

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 1 — Verificar base limpia

Correr `dart analyze lib/` y `flutter test`. Si hay fallos previos a cualquier cambio de esta fase,
documentarlos y resolverlos antes de continuar (pueden ser residuos de Fase 2 sin cerrar).

### Paso 2 — Actualizar `event_form_cubit_analytics_test.dart`

Archivo: `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart`

- Línea 39: `city: 'Medellín'` → `city: ''`.

Solo ese cambio. La fixture `_mockEvent` pasa `city` al constructor de `EventModel`; tras la Fase 1
`buildEventToSave()` produce `city: ''`, así que la fixture debe alinear su valor para que los mocks
de `mockCreate(_mockEvent)` y `mockUpdate(_mockEvent)` sigan coincidiendo.

### Paso 3 — Actualizar `event_form_basic_info_section_test.dart`

Archivo: `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart`

Cambios puntuales:

| Línea actual | Cambio |
|---|---|
| 6 (header comentario) `city == EventFormFields.city value` | Reemplazar por `city == state.meetingPointName ?? ''` |
| 85 (mock setup) `city: any(named: 'city')` | No cambia — el parámetro sigue existiendo en `sendMessage`; sin modificación. |
| 147 (nombre del test) `'AC18: _buildEventContext maps title/eventType/city from form fields correctly'` | Renombrar a `'AC18: _buildEventContext maps title/eventType from form fields; city uses meetingPointName proxy'` |
| 220 (assertion) `expect(ctx.city, isA<String>())` | Cambiar a `expect(ctx.city, '', reason: 'city es string vacío cuando meetingPointName no está seteado')` |

**Nota:** El test AC18 en línea 147 también ejercita `ctx.city`. Dado que en el smoke el widget se
renderiza sin un `EventFormCubit` real con `meetingPointName` seteado, el valor esperado es `''`.
Si el scaffold del test provee un `EventFormCubit` mock/stub con `meetingPointName = 'Medellín'`,
actualizar el expect a `'Medellín'` (decidir según el helper `_buildHost` del test). Ajustar el
helper si es necesario para proveer un cubit stub con `meetingPointName` conocido.

### Paso 4 — Crear tests de cubit en archivo nuevo

Archivo a crear: `test/features/events/presentation/form/cubit/event_form_cubit_stepper_test.dart`

Tests a implementar (todos unitarios, sin Flutter widget tree):

| ID | Descripcion | Assertion |
|---|---|---|
| TC-step-01 | `nextStep()` incrementa `currentStep` de 0 a 1 | `state.currentStep == 1` |
| TC-step-02 | `nextStep()` en paso 3 no supera 3 | tras 5 llamadas, `state.currentStep == 3` |
| TC-step-03 | `prevStep()` decrementa `currentStep` de 1 a 0 | `state.currentStep == 0` |
| TC-step-04 | `prevStep()` en paso 0 no baja de 0 | `state.currentStep == 0` |
| TC-step-05 | `goToStep(2)` asigna `currentStep == 2` | `state.currentStep == 2` |
| TC-step-06 | `isCurrentStepValid()` con Step 0 y `formKey` sin campos retorna `true` (no hay campo `name` registrado → null-safe → válido) | `isCurrentStepValid() == true` |
| TC-step-07 | `buildEventToSave()` produce un `EventModel` con `city == ''` | `event.city == ''` |
| TC-step-08 | Estado inicial tiene `currentStep == 0` | `cubit.state.currentStep == 0` |

**Observación para TC-step-06 y TC-step-07:** `EventFormCubit` requiere `formKey.currentState`
montado en un árbol Flutter para que `fields[name]` no sea null. En tests unitarios puros,
`formKey.currentState` es null → `fields[name]` retorna null → `field?.validate()` retorna null
(safe) → el bucle no falla → `validateStep()` retorna `true`. Documentar este comportamiento con un
comentario en el test. Para TC-step-07, llamar `buildEventToSave()` con valores de formulario vacíos
(sin montar FormBuilder): el método usa `formData[field] ?? defaultValue`; confirmar que retorna
`city: ''` sin excepción. Si `buildEventToSave()` requiere `formKey` montado, mover TC-step-07 al
smoke test de widget (Paso 5).

### Paso 5 — Crear smoke test de widget para `EventFormStep1`

Archivo a crear: `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart`

Tests a implementar (widget tests con `tester`):

| ID | Descripcion | Assertion |
|---|---|---|
| TC-wdg-01 | `EventFormStep1` renderiza sin overflow ni excepciones con nombre vacío | `find.byType(EventFormStep1)` findsOneWidget, sin `FlutterError` |
| TC-wdg-02 | Botón 'Continuar' de `EventStepNavBar` deshabilitado con nombre vacío | `tester.widget<AppButton>(find.text('Continuar')).onPressed == null` o equivalente |
| TC-wdg-03 | Botón 'Continuar' habilitado tras escribir un nombre | Ingresar texto en el campo `name`, pump, botón habilitado |

**Scaffold mínimo del test:**

```dart
Widget _buildStep1Host() {
  final cubit = EventFormCubit(
    MockCreateEventUseCase(),
    MockUpdateEventUseCase(),
    MockUploadEventImageUseCase(),
    MockGetCurrentUserIdUseCase(),
    MockGetGenerateCoverUseCase(),
    MockAnalyticsService(),
  );
  cubit.initialize();
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: [...],
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(
        body: FormBuilder(
          key: cubit.formKey,
          child: EventFormStep1(),
        ),
      ),
    ),
  );
}
```

Registrar en GetIt los mocks de `PlaceService` y `AiDescriptionChatCubit` en `setUp` (reusar el
patrón de `event_form_basic_info_section_test.dart`).

### Paso 6 — Verificación `dart analyze` y referencias de `city`

```bash
# Sin errores en lib/ (excepto archivos generados)
dart analyze lib/

# No deben aparecer hits en presentación
grep -r "EventFormFields.city" lib/features/events/presentation/
```

Si `grep` retorna hits, localizar el archivo y eliminar la referencia (reportar si el cambio no era
obvio).

### Paso 7 — Correr suite completa

```bash
flutter test
```

Todos los tests deben pasar. Si alguno falla por cambios residuales de Fases 1–2 no relacionados
con esta fase, documentar el fallo y resolverlo en este mismo paso antes de cerrar la fase.

---

## Archivos a crear/modificar

| Ruta | Operacion | Que cambia |
|---|---|---|
| `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` | Modificar | Línea 39: `city: 'Medellín'` → `city: ''` en fixture `_mockEvent` |
| `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` | Modificar | Header comentario (línea 6), nombre del test AC18 (línea 147), assertion `ctx.city` (línea 220) actualizados para reflejar que city viene de `meetingPointName ?? ''` |
| `test/features/events/presentation/form/cubit/event_form_cubit_stepper_test.dart` | Crear (nuevo) | 8 tests unitarios cubriendo `nextStep`, `prevStep`, `goToStep`, `isCurrentStepValid`, `buildEventToSave`, estado inicial |
| `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart` | Crear (nuevo) | Smoke test: 3 casos (render sin overflow, botón Continuar deshabilitado/habilitado según nombre) |

**No se modifica ningún archivo bajo `lib/`** salvo que `dart analyze` o `grep` revelen una
referencia residual a `EventFormFields.city` en la capa de presentación (Paso 6 lo detectaría).

---

## Contratos / API rideglory-api

Ninguno. Esta fase no toca `rideglory-api`. El contrato `GenerateCoverDto.city` ya fue actualizado
en Fase 1.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptacion

1. `flutter test` pasa sin fallos (0 failing tests).
2. `dart analyze lib/` retorna cero errores y cero warnings en archivos no generados
   (excluidos `*.g.dart` y `*.freezed.dart`).
3. `grep -r "EventFormFields.city" lib/features/events/presentation/` no retorna ningún resultado.
4. La fixture `_mockEvent` en `event_form_cubit_analytics_test.dart` usa `city: ''`.
5. El test AC18 en `event_form_basic_info_section_test.dart` verifica `ctx.city == ''`
   (o `== state.meetingPointName` si el scaffold provee un cubit con valor conocido) — nunca
   verifica que `city` provenga de `EventFormFields.city`.
6. Los 8 tests de cubit en `event_form_cubit_stepper_test.dart` pasan:
   - `nextStep()` no supera `currentStep == 3`.
   - `prevStep()` no baja de `currentStep == 0`.
   - `buildEventToSave()` produce `city == ''`.
   - Estado inicial tiene `currentStep == 0`.
7. Los 3 smoke tests de `event_form_step1_test.dart` pasan:
   - Renderiza sin overflow.
   - Botón 'Continuar' deshabilitado con nombre vacío.
   - Botón 'Continuar' habilitado con nombre lleno.

---

## Pruebas

### Unitarias (sin Flutter widget tree)

Archivo: `test/features/events/presentation/form/cubit/event_form_cubit_stepper_test.dart`

- `TC-step-01` a `TC-step-08` (ver tabla en Paso 4).
- Instanciar `EventFormCubit` directamente con mocks (mismo patrón que
  `event_form_cubit_analytics_test.dart`).
- No requiere `tester.pumpWidget`.

### Widget tests

Archivo: `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart`

- `TC-wdg-01` a `TC-wdg-03` (ver tabla en Paso 5).
- Scaffold mínimo con `BlocProvider`, `FormBuilder` y delegates de localización.
- GetIt registra `PlaceService` mock y `AiDescriptionChatCubit` mock (igual que
  `event_form_basic_info_section_test.dart`).

### Tests existentes actualizados

- `event_form_cubit_analytics_test.dart` — cambio de fixture (1 línea).
- `event_form_basic_info_section_test.dart` — actualización de 3 puntos (comentario, nombre de
  test, assertion).

### No incluidos en esta fase

- Tests de `EventFormStep2`, `EventFormStep3`, `EventFormStep4Review` — complejidad media, fuera del
  alcance definido en `05-sintesis.md` sección Plan-7.
- Tests de integración del wizard completo.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigacion |
|---|---|---|---|
| R1 | **`buildEventToSave()` requiere `formKey` montado** — Si el método lanza `NullPointerException` o retorna valores inesperados sin `FormBuilder` en el árbol, TC-step-07 falla en test unitario. | BAJA | Mover TC-step-07 al smoke test de widget (Paso 5) donde el `FormBuilder` sí está montado. Documentar la decisión en el test con un comentario. |
| R2 | **`AiDescriptionChatCubit` en GetIt no limpiado entre tests** — Si `setUp`/`tearDown` no desregistra el cubit mock correctamente, los tests de `event_form_step1_test.dart` pueden recibir un mock de una ejecución anterior. | BAJA | Reutilizar el patrón exacto de `setUp`/`tearDown` de `event_form_basic_info_section_test.dart` (líneas 106–126). |
| R3 | **Mapbox SDK intenta inicializarse en widget test** — `EventFormStep3` (en `IndexedStack`) podría intentar inicializar Mapbox al montarse aunque no sea el paso activo. Si `EventFormStep1` lo incluye indirectamente, el test falla. | BAJA | `EventFormStep1` no incluye `EventFormStep3`; el `IndexedStack` vive en `EventFormView`. El smoke test solo monta `EventFormStep1` directamente. Si la estrategia cambia, verificar que Mapbox tiene stub en el entorno de test. |
| R4 | **Residuos de Fases 1–2 no cerradas** — Si Fase 2 dejó archivos de widgets sin generar o referencias rotas, `dart analyze` falla antes de cualquier cambio de Fase 3. | MEDIA | Paso 1 detecta esto explícitamente. Resolver residuos antes de continuar. Si el fallo es fuera del alcance de Fase 3, reportar al humano. |

---

## Dependencias

### Fase 2 (prerequisito directo)

Fase 3 requiere que:

1. `EventFormCubit` ya tenga los métodos `nextStep()`, `prevStep()`, `goToStep()`,
   `isCurrentStepValid()`, `validateStep()` y el campo `currentStep` en `EventFormState`
   — añadidos en Fase 1.
2. `buildEventToSave()` y `buildDraftToSave()` ya produzcan `city: ''` — cambiados en Fase 1.
3. `EventFormStep1` exista como widget en
   `lib/features/events/presentation/form/widgets/steps/event_form_step1.dart` — creado en Fase 2.
4. `EventStepNavBar` exista en
   `lib/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart` — creado en Fase 2.
5. `EventFormBasicInfoSection._buildEventContext()` ya lea `state.meetingPointName ?? ''` en lugar
   de `formValues[EventFormFields.city]` — cambiado en Fase 2.
6. `AppCityAutocomplete` ya eliminado de `EventFormBasicInfoSection` — hecho en Fase 2.

Sin Fase 2 completa, los smoke tests de `EventFormStep1` no pueden compilar y las assertions de
`city` en `event_form_basic_info_section_test.dart` no tienen base correcta.

---

## Ejecucion recomendada

**Nivel rg-exec: lite**

**Por que ese nivel:** Cambio mecánico de bajo riesgo: actualizar assertions en tests existentes
(2 archivos, 4 líneas en total) y agregar tests de cubit y 1 smoke test de widget. Sin contratos
`rideglory-api`, sin migraciones, sin lógica nueva de negocio. Toda la actividad está en `test/`,
completamente reversible. Una sola área de código afectada. Encaja exactamente en la definición
`lite` de la rúbrica: "cambio mecánico, sin backend, sin lógica nueva, una área, reversible".
