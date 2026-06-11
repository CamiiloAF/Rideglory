# Fase 1 — Fundación técnica

**Slug:** `event-form-stepper`
**Fecha:** 2026-06-09T02:14:35Z
**Nivel rg-exec:** normal

---

## Objetivo

Establecer la base técnica que habilita el wizard de pasos sin romper ninguna operación existente: `city` deja de ser requerido en toda la cadena Flutter + backend, `EventFormState` adquiere `currentStep`, `EventFormCubit` centraliza el mapeo step→fields y la lógica de navegación/validación, los strings del stepper quedan definidos en ARB, y el código muerto de `EventFormDetailsSection` es eliminado.

Al terminar esta fase, `dart analyze` pasa limpio y todos los tests existentes siguen en verde. Las Fases 2 y 3 pueden arrancar sobre esta base sin conflictos.

---

## Alcance

### Entra

- Verificación pre-vuelo de `git status` (prerrequisito bloqueante).
- Backend `rideglory-api`: hacer `city` opcional en `GenerateCoverDto`.
- Cadena Flutter `city` → `String?` en tres archivos de domain/data (`EventCoverRepository`, `GetGenerateCoverUseCase`, `EventCoverRepositoryImpl`); el impl omite la clave `city` del body map cuando es null o vacío.
- `EventFormState`: añadir campo `@Default(0) int currentStep` + regenerar código freezed.
- `EventFormCubit`: fijar `city: ''` en `buildEventToSave()` / `buildDraftToSave()`; cambiar firma de `generateCover()` a `String? city`; añadir `nextStep()` / `prevStep()` / `goToStep(int)`; añadir `_step1Fields` / `_step2Fields` / `_step3Fields` / `stepFields` / `validateStep(int)` / `isCurrentStepValid()`.
- 9 nuevas ARB keys del stepper en `app_es.arb` + archivos de localización regenerados.
- Eliminación de `event_form_details_section.dart` y del directorio `sections/details/`.

### No entra

- Ningún widget de paso (Step 1–4), indicador visual ni barra de navegación — eso es Fase 2.
- Cambios en `EventFormView`, `EventFormContent`, ni en ningún otro widget del formulario.
- Tests nuevos — eso es Fase 3.
- Cualquier otra ruta, endpoint o DTO de `rideglory-api` distinto de `generate-cover.dto.ts`.

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 0 — Verificación pre-vuelo (bloqueante)

Ejecutar `git status` en el repo Flutter. Si hay archivos `??` en `lib/features/events/` que no sean los ya conocidos del exec-run `app-ai-description-assistant` (cubit, widgets ai_chat, DTOs de IA, etc.), **detener y reportar al humano** antes de continuar. El exec-run debe estar commitado antes de iniciar esta fase.

### Paso 1 — Backend: `GenerateCoverDto.city` opcional

Archivo: `rideglory-api/api-gateway/src/events/dto/generate-cover.dto.ts`

Cambiar el campo `city`:

```typescript
// Antes
@IsString()
@IsNotEmpty()
city: string;

// Después
@IsOptional()
@IsString()
city?: string;
```

Añadir `IsOptional` al import de `class-validator`. Verificar que el servicio backend que consume este DTO ya maneja `city` como opcional (el prompt a Gemini no debe fallar si `city` es `undefined`).

### Paso 2 — Flutter domain: `EventCoverRepository` interface

Archivo: `lib/features/events/domain/repository/event_cover_repository.dart`

Cambiar el parámetro `city` de `required String` a `String?`:

```dart
abstract class EventCoverRepository {
  Future<Either<DomainException, String>> generateCover({
    required String title,
    required String eventType,
    String? city,               // era: required String city
  });
}
```

### Paso 3 — Flutter domain: `GetGenerateCoverUseCase`

Archivo: `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart`

Cambiar `required String city` a `String? city` en la firma del método `call()` y en el forward al repositorio:

```dart
Future<Either<DomainException, String>> call({
  required String title,
  required String eventType,
  String? city,               // era: required String city
}) =>
    _eventCoverRepository.generateCover(
      title: title,
      eventType: eventType,
      city: city,
    );
```

### Paso 4 — Flutter data: `EventCoverRepositoryImpl`

Archivo: `lib/features/events/data/repository/event_cover_repository_impl.dart`

Cambiar la firma de `generateCover()` y construir el body map de forma condicional:

```dart
@override
Future<Either<DomainException, String>> generateCover({
  required String title,
  required String eventType,
  String? city,               // era: required String city
}) async {
  final result = await executeService(
    function: () async {
      final body = <String, dynamic>{
        'title': title,
        'eventType': eventType,
      };
      // Incluir city solo si tiene valor — omitir la clave del payload cuando city es null o vacío
      if (city != null && city.isNotEmpty) {
        body['city'] = city;
      }
      final dto = await _eventCoverService.generateCover(body);
      return dto.imageUrl;
    },
  );

  return result.fold(
    (error) => Left(
      DomainException(
        message: error.message.isNotEmpty
            ? error.message
            : 'No pudimos generar la portada. Sube tu propia imagen.',
      ),
    ),
    Right.new,
  );
}
```

### Paso 5 — `EventFormState`: añadir `currentStep`

Archivo: `lib/features/events/presentation/form/cubit/event_form_cubit.dart`

En la clase freezed `EventFormState`, añadir el campo:

```dart
@Default(0) int currentStep,
```

Ubicarlo junto con los demás campos de estado de navegación (después de `waypoints` / `waypointLocations` y antes del cierre del factory).

### Paso 6 — Codegen freezed

```bash
dart run build_runner build --delete-conflicting-outputs
```

Verificar que `event_form_cubit.freezed.dart` regenera correctamente con el nuevo campo `currentStep`.

### Paso 7 — `EventFormCubit`: `city: ''` en builders

Archivo: `lib/features/events/presentation/form/cubit/event_form_cubit.dart`

En `buildEventToSave()` (línea ~374): cambiar `city: formData[EventFormFields.city] as String` por `city: ''`.

En `buildDraftToSave()` (línea ~447): el valor ya usa `?.trim() ?? ''` — mantener el resultado equivalente a `city: ''` (eliminar la lectura del form field y fijar directamente `city: ''`).

### Paso 8 — `EventFormCubit`: firma de `generateCover()`

Archivo: `lib/features/events/presentation/form/cubit/event_form_cubit.dart`

Cambiar la firma del método (línea ~249):

```dart
Future<void> generateCover({
  required String title,
  required String eventType,
  String? city,               // era: required String city
}) async {
  // ... pasar city al use case tal cual (nullable, sin forzar '')
  final result = await _getGenerateCoverUseCase(
    title: title,
    eventType: eventType,
    city: city,
  );
  // ...
}
```

### Paso 9 — `EventFormCubit`: navegación y validación por paso

Archivo: `lib/features/events/presentation/form/cubit/event_form_cubit.dart`

Añadir las constantes y métodos de navegación/validación:

```dart
// Mapeo campo → paso. Debe estar sincronizado con EventFormFields.
// Ruta canónica: lib/features/events/constants/event_form_fields.dart
static const _step1Fields = [
  EventFormFields.name,
  EventFormFields.description,
  EventFormFields.dateRange,
  EventFormFields.isMultiDay,
  EventFormFields.meetingTime,
];

static const _step2Fields = [
  EventFormFields.difficulty,
  EventFormFields.eventType,
  EventFormFields.price,
  EventFormFields.isFreeEvent,
  EventFormFields.maxParticipants,
  EventFormFields.isMultiBrand,
  EventFormFields.allowedBrands,
];

static const _step3Fields = [
  EventFormFields.meetingPoint,
  EventFormFields.destination,
  EventFormFields.routeType,
  EventFormFields.waypoints,
];

static const stepFields = <int, List<String>>{
  0: _step1Fields,
  1: _step2Fields,
  2: _step3Fields,
};

void nextStep() {
  final next = state.currentStep + 1;
  if (next <= 3) emit(state.copyWith(currentStep: next));
}

void prevStep() {
  final prev = state.currentStep - 1;
  if (prev >= 0) emit(state.copyWith(currentStep: prev));
}

void goToStep(int step) {
  assert(step >= 0 && step <= 3, 'step must be between 0 and 3');
  emit(state.copyWith(currentStep: step));
}

bool validateStep(int step) {
  final fields = stepFields[step];
  if (fields == null) return true;
  return fields.every(
    (name) => formKey.currentState?.fields[name]?.validate() ?? true,
  );
}

bool isCurrentStepValid() => validateStep(state.currentStep);
```

**Nota:** `isMultiDay` no tiene validator, por lo que `validate()` retorna `true` siempre. `dateRange` tiene un validator que solo activa cuando `isMultiDay == true` — el implementador confirma en `EventFormDateTimeSection` que el validator de `dateRange` no falla cuando `isMultiDay == false` antes de cerrar el AC.

### Paso 10 — ARB: 9 nuevas keys del stepper

Archivo: `lib/l10n/app_es.arb`

Añadir antes del cierre `}` del archivo (en la sección `event_`):

```json
"event_step_basicInfo": "Básico",
"event_step_details": "Detalles",
"event_step_route": "Ruta",
"event_step_reviewAndPublish": "Revisar",
"event_step_continue": "Continuar",
"event_step_back": "Atrás",
"event_step_of": "de",
"event_step_saveDraft": "Guardar borrador",
"event_step_progressLabel": "Paso {current} de {total}",
"@event_step_progressLabel": {
  "placeholders": {
    "current": { "type": "int" },
    "total": { "type": "int" }
  }
}
```

**No crear** la key `event_form_publish_action` — ya existe en línea 592. El botón Publicar del Step 4 la reutilizará.

Regenerar los archivos de localización:

```bash
flutter gen-l10n
```

Verificar que `app_localizations.dart` y `app_localizations_es.dart` contienen los nuevos getters.

### Paso 11 — Eliminar código muerto

Verificar primero que `EventFormDetailsSection` no tiene importadores fuera del propio archivo:

```bash
grep -r "EventFormDetailsSection\|event_form_details_section" lib/ --include="*.dart" -l
```

Si solo aparece el propio archivo, eliminar:

- `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart`
- `lib/features/events/presentation/form/widgets/sections/details/difficulty_picker.dart`
- `lib/features/events/presentation/form/widgets/sections/details/event_type_picker.dart`
- Directorio `lib/features/events/presentation/form/widgets/sections/details/` (vacío tras eliminar los archivos)

### Paso 12 — Verificación final

```bash
dart analyze
flutter test
```

Ambos deben pasar sin errores nuevos.

---

## Archivos a crear/modificar

### Backend (`rideglory-api`)

| Ruta | Acción | Qué cambia |
|------|--------|------------|
| `api-gateway/src/events/dto/generate-cover.dto.ts` | Modificar | `city: string` con `@IsNotEmpty()` → `city?: string` con `@IsOptional()` |

### Flutter (`Rideglory`)

| Ruta | Acción | Qué cambia |
|------|--------|------------|
| `lib/features/events/domain/repository/event_cover_repository.dart` | Modificar | `required String city` → `String? city` en la firma abstracta |
| `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart` | Modificar | `required String city` → `String? city` en `call()` y en el forward |
| `lib/features/events/data/repository/event_cover_repository_impl.dart` | Modificar | `required String city` → `String? city`; body map construido condicionalmente (omite `city` si null o vacío) |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | Modificar | +`currentStep` en `EventFormState`; `city: ''` en builders; `generateCover()` con `String? city`; +navegación (nextStep/prevStep/goToStep); +`_step1Fields`/`_step2Fields`/`_step3Fields`/`stepFields`; +`validateStep()`/`isCurrentStepValid()` |
| `lib/features/events/presentation/form/cubit/event_form_cubit.freezed.dart` | Generado | Regenerado por `build_runner` con el nuevo campo `currentStep` |
| `lib/l10n/app_es.arb` | Modificar | +9 keys del stepper (`event_step_*`) |
| `lib/l10n/app_localizations.dart` | Generado | Regenerado por `flutter gen-l10n` |
| `lib/l10n/app_localizations_es.dart` | Generado | Regenerado por `flutter gen-l10n` |

### Archivos a eliminar

| Ruta | Motivo |
|------|--------|
| `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart` | Código muerto — cero importaciones en `lib/` |
| `lib/features/events/presentation/form/widgets/sections/details/difficulty_picker.dart` | Código muerto — solo importado por el archivo eliminado |
| `lib/features/events/presentation/form/widgets/sections/details/event_type_picker.dart` | Código muerto — solo importado por el archivo eliminado |

---

## Contratos / API rideglory-api

**Endpoint afectado:** `POST /events/generate-cover`

**DTO:** `api-gateway/src/events/dto/generate-cover.dto.ts`

**Cambio de contrato:**

| Campo | Antes | Después |
|-------|-------|---------|
| `city` | `string` (requerido — `@IsNotEmpty()`) | `string` (opcional — `@IsOptional()`) |

**Compatibilidad:** el cambio es retro-compatible. Clientes que sigan enviando `city` funcionan igual. Clientes nuevos pueden omitirlo. No requiere versionado de API ni migración.

**Verificación en backend:** confirmar que el servicio que llama a Gemini ya maneja `city` como campo de contexto opcional en el prompt (si `city` es `undefined`, el prompt no debe incluir la línea de ciudad).

---

## Cambios de datos / migraciones

Ninguno. Los cambios son únicamente en código Flutter y en la validación del DTO del API gateway. No se toca ninguna tabla, colección Firestore ni esquema Prisma.

---

## Criterios de aceptación

1. **`dart analyze` limpio:** cero errores ni warnings nuevos en `lib/` (excluidos `*.g.dart` y `*.freezed.dart`).

2. **City opcional en backend:** `generate-cover.dto.ts` tiene `@IsOptional()` sobre `city?: string`. Una petición sin el campo `city` retorna `2xx` (no `400`).

3. **Cadena Flutter — omisión condicional:** `EventCoverRepositoryImpl.generateCover()` con `city: null` o `city: ''` construye un body map que **no contiene la clave `'city'`**. Con `city: 'Medellín'` el map sí contiene `'city': 'Medellín'`. Verificable inspeccionando el map antes de la llamada a `_eventCoverService.generateCover`.

4. **Firma nullable propagada:** `EventCoverRepository.generateCover()` y `GetGenerateCoverUseCase.call()` declaran `String? city` (sin `required`). El compilador acepta llamarlos sin pasar `city`.

5. **`currentStep` en estado:** `EventFormState().currentStep == 0` (valor por defecto). `emit(state.copyWith(currentStep: 2)).currentStep == 2`.

6. **`city: ''` en builders:** `buildEventToSave()` y `buildDraftToSave()` producen un `EventModel` (o `CreateEventDto` / `UpdateEventDto`) con `city == ''` sin lanzar excepción.

7. **`generateCover()` con city nullable:** llamar `cubit.generateCover(title: 'T', eventType: 'E')` (sin `city`) no falla en compilación ni en tiempo de ejecución (delega `city: null` al use case).

8. **`validateStep(0)` comportamiento:** retorna `false` cuando el campo `EventFormFields.name` tiene valor vacío; retorna `true` cuando tiene un valor no vacío. Verificable con un `FormBuilder` + `GlobalKey<FormBuilderState>` en test.

9. **`_step1Fields` = 5 entries, `_step2Fields` = 7 entries, `_step3Fields` = 4 entries.** Total = 16. Los 16 campos son todas las constantes de `EventFormFields` excepto `city`.

10. **`stepFields` map:** `EventFormCubit.stepFields[0]` es idéntico a `_step1Fields`, `stepFields[1]` a `_step2Fields`, `stepFields[2]` a `_step3Fields`.

11. **Navegación de paso:** `nextStep()` desde `currentStep == 3` no emite estado nuevo (límite superior). `prevStep()` desde `currentStep == 0` no emite (límite inferior).

12. **9 ARB keys nuevas:** existen en `app_es.arb` y en `app_localizations_es.dart` regenerado. La key `event_form_publish_action` no está duplicada.

13. **Código muerto eliminado:** `event_form_details_section.dart` y el directorio `sections/details/` no existen en el working tree.

14. **Tests existentes en verde:** `flutter test` pasa sin fallos tras todos los cambios.

---

## Pruebas

Esta fase no requiere tests nuevos (eso es Fase 3). Sin embargo, el implementador debe verificar que los tests existentes siguen pasando.

**Tests existentes que tocan código modificado:**

| Archivo de test | Qué verificar |
|----------------|---------------|
| `test/features/events/presentation/form/cubit/` (cualquier test de `EventFormCubit`) | Pasan sin error tras añadir `currentStep` y cambiar `generateCover()`. Si hay llamadas a `generateCover(city: ...)` con `required`, adaptar la invocación. |
| `test/features/events/presentation/form/widgets/` | No deben referenciar `EventFormDetailsSection` ni sus imports. |

**Codegen necesario (no es test, pero es verificación):**

```bash
dart run build_runner build --delete-conflicting-outputs
# Verificar que event_form_cubit.freezed.dart regenera sin conflictos
flutter gen-l10n
# Verificar que app_localizations_es.dart contiene los nuevos métodos
dart analyze
flutter test
```

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | **Exec-run no commitado:** si los archivos `??` de `app-ai-description-assistant` aún están sin commitear, el cubit tiene `generateCover()` referenciando `city` como `required` en una versión distinta. Trabajar sobre esa versión produce conflictos. | ALTA | Paso 0 obliga a verificar `git status`. Si hay archivos `??` no conocidos en `lib/features/events/`, **detener** y reportar al humano antes de continuar. |
| R2 | **`dateRange` validator con `isMultiDay == false`:** si el validator de `dateRange` en `EventFormDateTimeSection` no tiene guarda correcta, `validateStep(0)` puede retornar `false` incluso cuando el usuario no activó el modo multi-día. | MEDIA | El implementador inspecciona el validator de `dateRange` en `EventFormDateTimeSection` antes de declarar cumplido el AC 8. Si el validator falla con `isMultiDay == false`, corregirlo en este mismo paso (es un bug preexistente). |
| R3 | **Step-field mapping drift:** `_stepFields` se desincroniza con `EventFormFields` en refactors futuros. No detectado por el compilador. | MEDIA | Comentario explícito en `_stepFields` vinculando cada entry a `EventFormFields.<constante>`. Test unitario de `validateStep()` en Fase 3 actúa como safety net. |
| R4 | **`IsOptional` no importado en DTO:** el decorador `@IsOptional()` no está en el import de `class-validator`. | BAJA | El implementador añade `IsOptional` al import existente de `class-validator` en el mismo commit. |
| R5 | **Código muerto con importadores ocultos:** si `EventFormDetailsSection` tiene algún importador generado o en test que `grep` no detectó. | BAJA | Ejecutar `grep -r "EventFormDetailsSection\|event_form_details_section" lib/ test/ --include="*.dart" -l` antes de eliminar. Si aparece algún importador inesperado, eliminar el import primero. |
| R6 | **Conflicto de codegen:** `build_runner` puede fallar si hay un `part` directive sin archivo generado previo. | BAJA | Usar `--delete-conflicting-outputs` como especificado. Si falla, ejecutar `dart run build_runner clean` primero. |

---

## Dependencias

**Fases prerrequisito:** ninguna (esta es la Fase 1 — no depende de ninguna otra fase del plan).

**Prerrequisito externo bloqueante:** el exec-run `app-ai-description-assistant` debe estar commitado en la rama antes de iniciar. Ese exec-run modifica `EventFormBasicInfoSection` y `EventFormCubit` (convierte a `StatefulWidget`, añade AI chat); trabajar sobre versiones no commitadas generaría conflictos imposibles de resolver automáticamente.

**Fases que dependen de esta:** Fase 2 (wizard completo) y Fase 3 (cobertura) dependen de que `currentStep`, `validateStep()`, `stepFields`, y las ARB keys existan — todo entregado aquí.

---

## Ejecución recomendada

**Nivel:** `normal`

**Justificación:**

- **Toca `rideglory-api` (TypeScript, cross-repo):** la rúbrica excluye `lite` ante cualquier cambio de contrato de API, aunque sea un cambio mínimo. `generate-cover.dto.ts` es un contrato HTTP — requiere verificación de que el servicio de IA detrás del endpoint maneja `city` como opcional correctamente.
- **Cadena domain/data con lógica condicional:** los tres archivos de la cadena `EventCoverRepository` / `GetGenerateCoverUseCase` / `EventCoverRepositoryImpl` introducen lógica de omisión condicional del campo (`city != null && city.isNotEmpty`). Es mecánico pero requiere que el auditor verifique la correcta propagación nullable y la ausencia de la clave en el body map.
- **Codegen freezed obligatorio:** cambiar `EventFormState` requiere regenerar `event_form_cubit.freezed.dart`. El auditor debe confirmar que el archivo generado no tiene regresiones.
- **Sin migración de datos ni seguridad/PII:** no escala a `full`.
