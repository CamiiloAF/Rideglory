# Fase 6 — QA, analytics y cierre

**Slug:** ai-event-generation  
**Fecha:** 2026-06-05T21:49:43Z  
**Nivel rg-exec recomendado:** normal

---

## Objetivo

El feature de asistentes IA para eventos es apto para producción: observabilidad completa con 5 eventos de telemetría emitidos exclusivamente desde cubits, todas las strings localizadas en `app_es.arb`, specs NestJS para los dos endpoints IA, cobertura de `flutter test` al 100% en código nuevo, documentación del feature actualizada, y backend desplegado en EC2 siguiendo el workflow local-first.

---

## Alcance (entra / no entra)

### Entra
- 5 constantes en `AnalyticsEvents` + params de soporte en `AnalyticsParams`
- Llamadas `analyticsService.logEvent(...)` desde los cubits `AiDescriptionChatCubit` y `AiCoverChatCubit`
- Gate bloqueante: verificación de diff que confirma que **ningún** `logEvent('ai_*')` aparece en archivos de widget o en `build()`
- 4 keys de error tipado + strings de UI IA en `lib/l10n/app_es.arb`
- Regeneración de `app_localizations_es.dart` tras editar el ARB
- Specs NestJS: `ai-description.spec.ts` y `ai-cover.spec.ts` en `rideglory-api/api-gateway/src/ai/`
- Eliminación del archivo de test `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` (importa `EventCoverRepository`/`GetGenerateCoverUseCase` retirados en Fase 5; dejarlo causa rotura de imports en `flutter test`)
- Tests Flutter nuevos: cubit tests, `MarkdownToDeltaConverter` tests, use case tests, widget tests del bottom sheet de chat de descripción y de portada
- `dart analyze` limpio en todo el proyecto Flutter
- `flutter test` con 100% de cobertura en archivos nuevos creados en Fases 4 y 5
- Actualización de `docs/features/events.md` con el nuevo flujo de asistentes IA
- Deploy backend en EC2: sin migración Prisma (AJ-2; cuota en Firestore); verificar que la TTL policy de Firestore esté activa en la colección `ai_usage_quotas`

### No entra
- Código de aplicación Flutter nuevo (todo implementado en Fases 4 y 5)
- Código backend nuevo (todo implementado en Fases 1-3)
- Retiro de código legacy (completado en Fase 5)
- Migración Prisma (eliminada por AJ-2; cuota vive en Firestore)
- Tests end-to-end / patrol (fuera del alcance de esta fase)
- Cambios al esquema Firestore (ya definido en Fase 3)

---

## Qué se debe hacer (pasos concretos y ordenados)

### 1. Agregar constantes de analytics

**1.1 — Agregar 5 eventos en `AnalyticsEvents`:**

Agregar en `lib/core/services/analytics/analytics_events.dart` bajo una sección `// AI — generación (ai-event-generation)`:

| Constante | Valor string | Emisión |
|-----------|-------------|---------|
| `aiDescriptionGenerated` | `'ai_description_generated'` | Cubit recibe respuesta exitosa de `GenerateEventDescriptionUseCase` |
| `aiImageGenerated` | `'ai_image_generated'` | Cubit recibe respuesta exitosa de `GenerateEventCoverUseCase` |
| `aiQuotaExceeded` | `'ai_quota_exceeded'` | Cubit recibe error tipado de quota (user o project) |
| `aiGenerationFailed` | `'ai_generation_failed'` | Cubit recibe cualquier error distinto de quota (safety_blocked, network_error) |
| `aiCoverUsed` | `'ai_cover_used'` | Cubit ejecuta `Navigator.of(context).pop(selectedImageUrl)` para confirmar portada |

Verificar length ≤ 40 para cada nombre. Todos cumplen: `'ai_description_generated'.length == 24`, `'ai_image_generated'.length == 18`, `'ai_quota_exceeded'.length == 17`, `'ai_generation_failed'.length == 20`, `'ai_cover_used'.length == 13`.

**1.2 — Agregar params de soporte en `AnalyticsParams`:**

Agregar bajo sección `// AI — generación (ai-event-generation)`:

| Constante | Valor | Tipo | Uso |
|-----------|-------|------|-----|
| `aiGenerationType` | `'ai_generation_type'` | `String` | `'description'` o `'cover'` — distingue el tipo de generación en `aiGenerationFailed` y `aiQuotaExceeded` |
| `aiErrorCode` | `'ai_error_code'` | `String` | Código canónico: `quota_exceeded_user`, `quota_exceeded_project`, `safety_blocked`, `network_error` |
| `aiTurnIndex` | `'ai_turn_index'` | `int` | Índice del turno en el historial (0-based) al momento de generar |

Agregar también los valores canónicos de `ai_generation_type`:
- `aiGenerationTypeDescription = 'description'`
- `aiGenerationTypeCover = 'cover'`

### 2. Instrumentar cubits (gate bloqueante)

Abrir `lib/features/events/presentation/form/ai_description/cubit/ai_description_chat_cubit.dart` y `lib/features/events/presentation/form/ai_cover/cubit/ai_cover_chat_cubit.dart` (rutas esperadas según el plan; verificar las rutas reales contra el código entregado en Fases 4-5 antes de editar).

**Regla crítica (A7 / gate bloqueante):** todos los `analyticsService.logEvent('ai_*', ...)` se invocan **dentro de métodos del cubit**, nunca desde `build()`, `initState()`, callbacks `onTap`, ni desde archivos `*_widget.dart` / `*_page.dart`.

**Resolución de `error.code` antes de instrumentar:**

`DomainException` actualmente solo tiene el campo `message` (`lib/core/exceptions/domain_exception.dart`). Antes de usar `error.code` en los cubits, verificar si Fases 4-5 agregaron un campo o getter `code` a `DomainException`. Hay dos escenarios posibles:

- **Si Fases 4-5 agregaron `final String? code` a `DomainException`** (junto con factory constructors `quotaExceededUser`, `quotaExceededProject`, etc.): usar `error.code ?? 'unknown'` directamente.
- **Si DomainException sigue teniendo solo `message` (sin campo `code`)**: derivar el código en el cubit via mapeo del tipo o del mensaje, usando una función privada en el cubit:
  ```dart
  String _toAnalyticsErrorCode(DomainException error) {
    // Mapeo basado en el tipo de excepción o en el mensaje
    // si Fases 4-5 usaron subclases o factory constructors distinguibles por tipo:
    if (error is QuotaExceededUserException) return 'quota_exceeded_user';
    if (error is QuotaExceededProjectException) return 'quota_exceeded_project';
    if (error is SafetyBlockedException) return 'safety_blocked';
    if (error is NetworkErrorException) return 'network_error';
    return 'unknown';
  }
  ```
  Si Fases 4-5 usaron una clase única con factory constructors pero sin `code`, el implementador debe agregar el campo `code` a `DomainException` en esta fase antes de instrumentar (cambio retrocompatible: `final String? code`; valor default `null`).

**En `AiDescriptionChatCubit`:**
- Método `generateDescription(...)`: tras `emit(state.copyWith(generationResult: ResultState.data(...)))`, invocar:
  ```dart
  _analyticsService.logEvent(AnalyticsEvents.aiDescriptionGenerated, {
    AnalyticsParams.aiTurnIndex: state.history.length,
  });
  ```
- Tras emitir error de quota (quotaExceededUser o quotaExceededProject):
  ```dart
  _analyticsService.logEvent(AnalyticsEvents.aiQuotaExceeded, {
    AnalyticsParams.aiGenerationType: AnalyticsParams.aiGenerationTypeDescription,
    AnalyticsParams.aiErrorCode: _toAnalyticsErrorCode(error),
  });
  ```
- Tras cualquier otro error (`safetyBlocked`, `networkError`):
  ```dart
  _analyticsService.logEvent(AnalyticsEvents.aiGenerationFailed, {
    AnalyticsParams.aiGenerationType: AnalyticsParams.aiGenerationTypeDescription,
    AnalyticsParams.aiErrorCode: _toAnalyticsErrorCode(error),
  });
  ```

**En `AiCoverChatCubit`:**
- Método `generateCover(...)`: tras `emit(state.copyWith(currentGeneration: ResultState.data(...)))`:
  ```dart
  _analyticsService.logEvent(AnalyticsEvents.aiImageGenerated, {
    AnalyticsParams.aiTurnIndex: state.history.length,
  });
  ```
- Mismo patrón de quota y error genérico que `AiDescriptionChatCubit`, con `aiGenerationTypeCover`.
- Método `confirmCover(String imageUrl)` (el que llama `Navigator.of(context).pop(imageUrl)`):
  ```dart
  _analyticsService.logEvent(AnalyticsEvents.aiCoverUsed);
  ```

**Inyección de `AnalyticsService`:** ambos cubits reciben `AnalyticsService` por constructor. Marcados `@injectable`; el DI lo resuelve automáticamente. No usar `getIt<AnalyticsService>()` directamente en el cubit.

### 3. Gate bloqueante — revisión de diff

Antes de dar por completada la instrumentación, ejecutar:

```bash
grep -rn "logEvent.*ai_" lib/ --include="*.dart"
```

Verificar que **todas** las líneas resultantes pertenecen a archivos `*_cubit.dart`. Si aparece alguna línea en un archivo `*_widget.dart`, `*_page.dart`, `*_view.dart` o `*_screen.dart`, el implementador debe moverla al cubit correspondiente antes de continuar.

### 4. Agregar strings en `app_es.arb`

Abrir `lib/l10n/app_es.arb` y agregar las siguientes claves bajo la sección de IA (crear sección si no existe):

**Strings de error tipado (obligatorias — ya referenciadas en Fases 4-5):**
```json
"ai_error_quota_exceeded_user": "Has alcanzado tu límite diario de generaciones. Vuelve mañana.",
"ai_error_quota_exceeded_project": "El servicio de IA está temporalmente saturado. Inténtalo más tarde.",
"ai_error_safety_blocked": "Tu solicitud fue bloqueada por el filtro de contenido. Intenta reformular.",
"ai_error_network": "Error de conexión. Verifica tu internet e intenta de nuevo."
```

**Strings de UI del asistente de descripción** (verificar contra implementación real de Fases 4-5; agregar las que falten):
```json
"ai_description_chat_title": "Asistente de descripción",
"ai_description_welcome": "Hola, cuéntame sobre tu rodada y te ayudo a escribir una descripción.",
"ai_description_hint": "Escribe un mensaje...",
"ai_description_insert_button": "Insertar en descripción",
"ai_description_confirm_replace_title": "¿Reemplazar descripción?",
"ai_description_confirm_replace_body": "Tienes contenido en el editor. ¿Lo reemplazas con la sugerencia de la IA?",
"ai_quota_remaining": "{count} generaciones restantes hoy",
"@ai_quota_remaining": { "placeholders": { "count": { "type": "int" } } }
```

**Strings de UI del asistente de portada** (verificar contra implementación real):
```json
"ai_cover_chat_title": "Asistente de portada",
"ai_cover_welcome": "Describe la portada que quieres y la genero para ti.",
"ai_cover_hint": "Describe la portada...",
"ai_cover_use_button": "Usar esta imagen",
"ai_cover_use_fullscreen_button": "Usar esta portada",
"ai_cover_generating": "Generando imagen...",
"ai_cover_fullscreen_title": "Previsualización"
```

Después de editar el ARB, ejecutar:
```bash
dart run build_runner build --delete-conflicting-outputs
```
o:
```bash
flutter gen-l10n
```

Verificar que `lib/l10n/app_localizations_es.dart` se regeneró correctamente y que `dart analyze` pasa limpio.

### 5. Escribir specs NestJS

Las rutas raíz son siempre relativas al repo backend: `rideglory-api/api-gateway/src/ai/`.

**5.1 — `rideglory-api/api-gateway/src/ai/ai-description.spec.ts`**

Estructura de suites obligatorias:

- `AiController — POST /ai/description`
  - `happy path` → devuelve 200 con `{ markdown: string, remainingGenerations: number }`
  - `quota exceeded user` → `AiQuotaService.checkAndIncrement` lanza `TooManyRequestsException`; controller propaga 429 con `{ error: 'quota_exceeded_user' }`
  - `quota exceeded project` → `GeminiService.generateDescription` lanza 429 de Gemini; controller devuelve 429 con `{ error: 'quota_exceeded_project' }`
  - `safety blocked` → `GeminiService` lanza excepción de safety filter; controller devuelve 422 con `{ error: 'safety_blocked' }`
  - `network error` → `GeminiService` lanza `ServiceUnavailableException`; controller devuelve 503 con `{ error: 'network_error' }`
- `AiDescriptionRequestDto — validation`
  - Lanza `BadRequestException` cuando `eventContext.title` está ausente
  - Lanza `BadRequestException` cuando `history` supera 10 turnos
  - Acepta body válido sin errores
- `GeminiService.generateDescription — unit`
  - Invoca `@google/genai` con el prompt correcto
  - Propaga error de red como `ServiceUnavailableException`

Patrón de mocking: idéntico a los specs existentes en api-gateway (mock de servicios como objetos planos con `jest.fn()`; `jest.clearAllMocks()` en `beforeEach`).

**5.2 — `rideglory-api/api-gateway/src/ai/ai-cover.spec.ts`**

Estructura de suites obligatorias:

- `AiController — POST /ai/cover`
  - `happy path` → devuelve 200 con `{ imageUrl: string, draftId: string, remainingGenerations: number }`; la URL sigue el patrón `pending/{userId}/{draftId}.jpg`
  - `quota exceeded user` → propaga 429 con `{ error: 'quota_exceeded_user' }`
  - `quota exceeded project` → propaga 429 con `{ error: 'quota_exceeded_project' }`
  - `safety blocked` → propaga 422 con `{ error: 'safety_blocked' }`
  - `network error` → propaga 503 con `{ error: 'network_error' }`
  - `storage upload fails` → `Firebase Storage bucket.file().save()` lanza error; controller propaga 503
- `AiCoverRequestDto — validation`
  - Lanza `BadRequestException` cuando `prompt` está ausente
  - Lanza `BadRequestException` cuando `draftId` no es UUID válido (si se agrega validación `@IsUUID()`)
  - Acepta body válido sin errores
- `StorageCleanupService — unit`
  - `runWeeklyCleanup()` llama a `bucket.getFiles()` con el prefijo `pending/`
  - Solo borra archivos con más de 7 días (`timeCreated < ahora - 7 días`)
  - No borra archivos recientes

### 6. Eliminar test de legacy retirado

Verificar que `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` **fue eliminado en Fase 5**. Si sigue presente, eliminarlo ahora:

```bash
rm test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart
```

Este archivo importa `EventCoverRepository` y `GetGenerateCoverUseCase`, ambos retirados en Fase 5. Su presencia rompe `flutter test` con imports rotos. Este paso es **bloqueante** antes de ejecutar el paso 8 (flutter test).

### 7. Escribir tests Flutter

**Estructura de directorios de test (correcta para este proyecto — underscore en `use_cases`):**

```
test/features/events/
  domain/
    use_cases/
      generate_event_description_use_case_test.dart   ← use case tests
      generate_event_cover_use_case_test.dart         ← use case tests (verifica UUID v4)
  presentation/
    utils/
      markdown_to_delta_converter_test.dart           ← tests unitarios del converter
    cubit/
      ai_description_chat_cubit_test.dart             ← cubit tests (unit)
      ai_cover_chat_cubit_test.dart                   ← cubit tests (unit)
    widgets/
      ai_description_chat_sheet_test.dart             ← widget tests del bottom sheet
      ai_cover_chat_sheet_test.dart                   ← widget tests del bottom sheet
```

**7.1 — `MarkdownToDeltaConverter` tests (unitarios):**

Ruta: `test/features/events/presentation/utils/markdown_to_delta_converter_test.dart`

El converter vive en `lib/features/events/presentation/utils/` (AJ-4: `Delta` es tipo flutter_quill, no puede ir en domain ni data). El test sigue la misma estructura de carpetas bajo `test/`.

Cubrir exactamente el subconjunto especificado en A4:
- Párrafo simple → Delta con `insert: 'texto\n'`
- `## Heading` → Delta con `insert: 'Heading\n', attributes: { header: 2 }`
- `**bold**` → Delta con `insert: 'bold', attributes: { bold: true }`
- `*italic*` → Delta con `insert: 'italic', attributes: { italic: true }`
- `- item` (lista sin ordenar) → Delta con `insert: 'item\n', attributes: { list: 'bullet' }`
- Elemento no soportado (p.ej. tabla, código) → se inserta como texto plano sin lanzar excepción
- Combinaciones: `**bold** y *italic* en el mismo párrafo`
- Input vacío → Delta vacío o Delta con `\n`

**7.2 — `AiDescriptionChatCubit` tests (unitarios):**

Ruta: `test/features/events/presentation/cubit/ai_description_chat_cubit_test.dart`

Usar `bloc_test` (`test`, `bloc_test`, `mocktail`). Mockear `GenerateEventDescriptionUseCase` y `AnalyticsService`.

Escenarios:
- Estado inicial: `history: []`, `generationResult: Initial`, `remainingQuota: 0`
- `generateDescription(...)` happy path → emite `Loading` luego `Data`; `AnalyticsEvents.aiDescriptionGenerated` se invocó una vez
- `generateDescription(...)` con error de quota (user) → emite `Error`; `AnalyticsEvents.aiQuotaExceeded` se invocó con `aiGenerationTypeDescription`
- `generateDescription(...)` con `safetyBlocked` → emite `Error`; `AnalyticsEvents.aiGenerationFailed` se invocó con `aiGenerationTypeDescription`
- `generateDescription(...)` con `networkError` → emite `Error`; `AnalyticsEvents.aiGenerationFailed` se invocó
- `history` se acumula correctamente turno a turno (2 llamadas consecutivas)
- `remainingQuota` se actualiza desde el response

**7.3 — `AiCoverChatCubit` tests (unitarios):**

Ruta: `test/features/events/presentation/cubit/ai_cover_chat_cubit_test.dart`

Simetría con `AiDescriptionChatCubit`. Agregar:
- `confirmCover(url)` → `AnalyticsEvents.aiCoverUsed` invocado una vez
- `generatedUrls` acumula URLs tras cada generación exitosa

**7.4 — Use case tests:**

Rutas:
- `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart`
- `test/features/events/domain/use_cases/generate_event_cover_use_case_test.dart`

Convención del repo: directorio `use_cases` (con guion bajo), no `usecases`.

- `GenerateEventDescriptionUseCase`: mockear `AiDescriptionRepository`; verificar que el use case devuelve `Right(markdown)` o `Left(DomainException)` según el repositorio
- `GenerateEventCoverUseCase`: mockear `AiCoverRepository`; verificar que el `draftId` generado es un UUID v4 válido (regex `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`); verificar `Right(imageUrl)` o `Left(DomainException)`

**7.5 — Widget tests del bottom sheet:**

Rutas:
- `test/features/events/presentation/widgets/ai_description_chat_sheet_test.dart`
- `test/features/events/presentation/widgets/ai_cover_chat_sheet_test.dart`

Usar `flutter_test` + `mocktail`. Proveer `BlocProvider<AiDescriptionChatCubit>` / `BlocProvider<AiCoverChatCubit>` con cubit mock o real.

Escenarios de descripción:
- Estado `Initial`: se muestra mensaje de bienvenida; campo de texto habilitado; botón "Insertar" no visible o deshabilitado
- Estado `Loading`: campo bloqueado; burbuja de tres puntos visible
- Estado `Data`: burbuja con texto visible; botón "Insertar en descripción" visible y habilitado
- Estado `Error` con quota exceeded user: banner de error con key `ai_error_quota_exceeded_user` visible; campo deshabilitado
- Estado `Error` con safety blocked: banner con key `ai_error_safety_blocked` visible; campo habilitado

Escenarios de portada:
- Estado `Initial`: placeholder 16:9 visible; campo habilitado
- Estado `Loading`: shimmer 16:9 visible; campo bloqueado
- Estado `Data`: imagen cargada; botón "Usar esta imagen" visible
- Tap "Usar esta imagen" → se llama `confirmCover` en el cubit (verificable con mock)

### 8. Verificar `dart analyze`

Ejecutar:
```bash
dart analyze
```

Resultado esperado: 0 errores, 0 warnings. Si hay infos o lints pendientes de Fases 4-5, resolverlos en esta fase. Los archivos `*.g.dart` y `*.freezed.dart` están excluidos por `analysis_options.yaml`.

### 9. Ejecutar `flutter test`

```bash
flutter test
```

Resultado esperado: todos los tests pasan. Prerequisito: el paso 6 (eliminación del test legacy) debe haberse completado antes; de lo contrario, `flutter test` falla con imports rotos. Si algún test de fase anterior falla por efectos del código nuevo (p.ej. un test de `EventFormCubit` que asume que no hay `externalController` en `AppRichTextEditor`), corregirlo antes de continuar.

### 10. Actualizar `docs/features/events.md`

Agregar o actualizar las siguientes secciones en `docs/features/events.md`:

**En sección "Visión general" / responsabilidades:** reemplazar la línea:
> Generación de portadas con IA (`POST /events/generate-cover`).

por:
> Asistente IA para descripción (`POST /ai/description`) y portada (`POST /ai/cover`) via Gemini. El flujo Unsplash/Claude fue retirado en la Fase 5 del plan ai-event-generation.

**Agregar nueva sección "Asistentes IA"** con:
- Descripción del flujo de descripción: `AiDescriptionChatCubit` (scoped al bottom sheet), `GenerateEventDescriptionUseCase`, `MarkdownToDeltaConverter` (en `presentation/utils/`), inyección en `AppRichTextEditor` via `externalController`
- Descripción del flujo de portada: `AiCoverChatCubit` (scoped al bottom sheet), `GenerateEventCoverUseCase`, `draftId` generado en use case, `Navigator.pop(url)` como mecanismo de retorno al `EventFormCubit`
- Tabla de 4 errores tipados y su mapeo a `DomainException`
- Referencia al sistema de cuotas Firestore: `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}`

**Actualizar sección "API endpoints":** agregar `POST /ai/description` y `POST /ai/cover`; marcar `POST /events/generate-cover` como `ELIMINADO en Fase 5`.

### 11. Deploy backend EC2

Seguir el workflow documentado en `docs/DEPLOY.md`:

1. Verificar en local que la TTL policy de Firestore está activa en la colección `ai_usage_quotas` apuntando al campo `expireAt`. Si no está configurada, crearla en Firebase Console antes del deploy.
2. Verificar variables de entorno en EC2: `GEMINI_API_KEY`, `FIREBASE_STORAGE_BUCKET`, `GEMINI_IMAGE_MODEL`. Las variables removidas en Fase 5 (`UNSPLASH_ACCESS_KEY`, `ANTHROPIC_API_KEY`) ya no deben estar presentes.
3. No hay migración Prisma en esta fase (AJ-2; cuota en Firestore).
4. Esperar confirmación humana de validación local antes de hacer deploy a producción (workflow local-first de `docs/DEPLOY.md`).
5. Tras el deploy, ejecutar smoke test manual: llamar `POST /ai/description` con un token válido y verificar `200` con `markdown` en el response.

---

## Archivos a crear/modificar (rutas reales)

| Acción | Ruta | Qué cambia |
|--------|------|-----------|
| Modificar | `lib/core/services/analytics/analytics_events.dart` | Agregar 5 constantes `ai_*` bajo sección AI |
| Modificar | `lib/core/services/analytics/analytics_params.dart` | Agregar `aiGenerationType`, `aiErrorCode`, `aiTurnIndex` y sus valores canónicos |
| Modificar (si aplica) | `lib/core/exceptions/domain_exception.dart` | Agregar `final String? code` si Fases 4-5 no lo agregaron (necesario para analytics) |
| Modificar | `lib/features/events/presentation/form/ai_description/cubit/ai_description_chat_cubit.dart` | Inyectar `AnalyticsService`; agregar `logEvent` en métodos de generación y error (verificar ruta real contra código de Fase 4) |
| Modificar | `lib/features/events/presentation/form/ai_cover/cubit/ai_cover_chat_cubit.dart` | Inyectar `AnalyticsService`; agregar `logEvent` en métodos de generación, error y confirmación (verificar ruta real contra código de Fase 5) |
| Modificar | `lib/l10n/app_es.arb` | Agregar ~12 keys IA incluyendo los 4 de error tipado |
| Modificar | `lib/l10n/app_localizations_es.dart` | Regenerado automáticamente tras editar ARB |
| Eliminar | `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` | Importa `EventCoverRepository`/`GetGenerateCoverUseCase` retirados en Fase 5; causa rotura de imports |
| Crear | `rideglory-api/api-gateway/src/ai/ai-description.spec.ts` | Specs NestJS para `POST /ai/description` |
| Crear | `rideglory-api/api-gateway/src/ai/ai-cover.spec.ts` | Specs NestJS para `POST /ai/cover` |
| Crear | `test/features/events/presentation/utils/markdown_to_delta_converter_test.dart` | Tests unitarios del converter Markdown→Delta (coherente con AJ-4: converter vive en `presentation/utils/`) |
| Crear | `test/features/events/presentation/cubit/ai_description_chat_cubit_test.dart` | Tests unitarios del cubit de descripción |
| Crear | `test/features/events/presentation/cubit/ai_cover_chat_cubit_test.dart` | Tests unitarios del cubit de portada |
| Crear | `test/features/events/presentation/widgets/ai_description_chat_sheet_test.dart` | Widget tests del bottom sheet de descripción |
| Crear | `test/features/events/presentation/widgets/ai_cover_chat_sheet_test.dart` | Widget tests del bottom sheet de portada |
| Crear | `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart` | Tests del use case de descripción (directorio `use_cases` con guion bajo) |
| Crear | `test/features/events/domain/use_cases/generate_event_cover_use_case_test.dart` | Tests del use case de portada (verifica UUID v4) |
| Modificar | `docs/features/events.md` | Actualizar flujo de portada/descripción IA; marcar endpoint legacy como eliminado |

> **Nota sobre rutas de cubits:** las rutas exactas de `ai_description_chat_cubit.dart` y `ai_cover_chat_cubit.dart` deben verificarse contra el código entregado en Fases 4 y 5. La estructura `presentation/form/ai_description/cubit/` es la esperada por el plan; si el implementador usó una ruta distinta, seguir la real.

---

## Contratos / API rideglory-api

Ninguno nuevo. Los contratos de `POST /ai/description` y `POST /ai/cover` están definidos en Fases 1-2 y publicados en `rideglory-contracts/src/ai/`. Esta fase solo escribe specs que los verifican.

---

## Cambios de datos / migraciones

Ninguno. La TTL policy de Firestore sobre `ai_usage_quotas` se configura en Firebase Console (operación de infraestructura, no migración de código); si no estaba activa tras Fase 3, se activa en el paso 11 de esta fase antes del deploy.

---

## Criterios de aceptación (numerados, observables, testeables)

1. `grep -rn "logEvent.*ai_" lib/ --include="*.dart"` devuelve únicamente líneas en archivos `*_cubit.dart`. Ninguna línea en `*_widget.dart`, `*_page.dart`, `*_screen.dart` ni `*_view.dart`.

2. Los 5 eventos `ai_description_generated`, `ai_image_generated`, `ai_quota_exceeded`, `ai_generation_failed`, `ai_cover_used` existen como constantes en `AnalyticsEvents` y cada uno se invoca en el cubit correspondiente en el path correcto (éxito, error, confirmación).

3. `lib/l10n/app_es.arb` contiene los 4 keys de error (`ai_error_quota_exceeded_user`, `ai_error_quota_exceeded_project`, `ai_error_safety_blocked`, `ai_error_network`) y al menos los 7 keys de UI IA adicionales. `app_localizations_es.dart` se generó correctamente.

4. `dart analyze` devuelve 0 errores y 0 warnings en el proyecto Flutter.

5. `flutter test` pasa al 100%: todos los tests existentes siguen verdes, `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` fue eliminado (ya no hay imports rotos de código legacy), y todos los tests nuevos de esta fase pasan.

6. `test/features/events/presentation/utils/markdown_to_delta_converter_test.dart` (ruta coherente con AJ-4: converter en `presentation/utils/`) cubre los 6 escenarios base (párrafo, h2, bold, italic, lista, elemento no soportado) y pasa sin errores.

7. Los cubit tests verifican explícitamente que `analyticsService.logEvent` fue invocado con los parámetros correctos en cada escenario (happy path, quota exceeded, error).

8. `rideglory-api/api-gateway/src/ai/ai-description.spec.ts` y `rideglory-api/api-gateway/src/ai/ai-cover.spec.ts` existen y corren sin errores (`pnpm test` o `jest` en api-gateway).

9. `docs/features/events.md` menciona `POST /ai/description` y `POST /ai/cover` en la sección de API endpoints; `POST /events/generate-cover` está marcado como eliminado; existe sección "Asistentes IA" con los flujos descritos.

10. El backend está desplegado en EC2 y el smoke test `POST /ai/description` devuelve 200 con campo `markdown` presente.

11. La TTL policy de Firestore está activa en la colección `ai_usage_quotas` apuntando al campo `expireAt`.

---

## Pruebas (unitarias / widget / integración)

### Unitarias Flutter

| Archivo de test | Qué verifica |
|-----------------|-------------|
| `test/features/events/presentation/utils/markdown_to_delta_converter_test.dart` | 8+ escenarios: párrafo, h2, bold, italic, lista, no-soportado, combinaciones, input vacío |
| `test/features/events/presentation/cubit/ai_description_chat_cubit_test.dart` | Estado inicial, happy path con analytics, 4 errores tipados con analytics, acumulación de history, actualización de remainingQuota |
| `test/features/events/presentation/cubit/ai_cover_chat_cubit_test.dart` | Simétrico al anterior; más: `confirmCover` dispara `aiCoverUsed`; `generatedUrls` acumula |
| `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart` | Delega al repo; mapea Right/Left |
| `test/features/events/domain/use_cases/generate_event_cover_use_case_test.dart` | Genera UUID v4 válido; delega al repo; mapea Right/Left |

### Widget Flutter

| Archivo de test | Qué verifica |
|-----------------|-------------|
| `test/features/events/presentation/widgets/ai_description_chat_sheet_test.dart` | Render en 5 estados: Initial, Loading, Data, Error quota, Error safety |
| `test/features/events/presentation/widgets/ai_cover_chat_sheet_test.dart` | Render en 5 estados: Initial, Loading, Data, Error quota, Error network; tap "Usar esta imagen" llama cubit |

### Unitarias NestJS (specs)

| Archivo de spec | Qué verifica |
|-----------------|-------------|
| `rideglory-api/api-gateway/src/ai/ai-description.spec.ts` | 5 suites: happy path, 4 error codes, validación DTO, unit de GeminiService |
| `rideglory-api/api-gateway/src/ai/ai-cover.spec.ts` | 5 suites: happy path, 4 error codes + storage failure, validación DTO, unit de StorageCleanupService |

### Integración / E2E

No aplica en esta fase.

---

## Riesgos y mitigaciones

| ID | Riesgo | Prob | Impacto | Mitigación |
|----|--------|------|---------|-----------|
| F6-R1 | Rutas reales de cubits difieren de las esperadas en el plan | Media | Bajo | Paso 2 instruye verificar rutas contra código entregado antes de editar; los test imports revelarán discrepancias al primer `flutter test` |
| F6-R2 | `DomainException` sin campo `code` hace que `error.code` no compile | Alta | Medio | Paso 2 cubre este caso explícitamente: verificar si Fases 4-5 agregaron `code`; si no, agregar `final String? code` a `DomainException` antes de instrumentar; alternativa: derivar el código via match de tipo en `_toAnalyticsErrorCode()` |
| F6-R3 | `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` no fue eliminado en Fase 5 | Media | Alto | Paso 6 es bloqueante y explícito: verificar existencia y eliminar antes de ejecutar `flutter test` |
| F6-R4 | `AnalyticsService` no inyectable en cubits scoped (no van en `injection.config.dart` si son `@injectable` sin módulo registrado) | Baja | Medio | Los cubits scoped de chat son `@injectable`; `AnalyticsService` también; el DI los resuelve; si surge error, inyectar via parámetro de constructor en el `BlocProvider` local |
| F6-R5 | Widget tests del bottom sheet son frágiles si el widget usa claves hardcodeadas o depende de `MediaQuery` / `SafeArea` | Media | Bajo | Usar `find.byType(AppButton)` + `find.text(...)` con l10n; envolver en `MaterialApp` con `AppLocalizations` en el test setup |
| F6-R6 | TTL policy de Firestore no activa en producción tras Fase 3 | Media | Bajo | Paso 11 verifica explícitamente antes del deploy; solución: crear la policy en Firebase Console (5 minutos) |
| F6-R7 | `pnpm test` en api-gateway falla por dependencias no instaladas en módulo `ai/` | Baja | Bajo | Verificar que `@google/genai` y `firebase-admin` están en `package.json` de api-gateway; `pnpm install` si falta |
| F6-R8 | Smoke test EC2 falla por propagación de Remote Config (límites `ai_*_daily_limit`) | Baja | Bajo | Forzar valores default en `AiQuotaService` si Remote Config no se propagó; `fetchAndActivate()` al init del servicio |

---

## Dependencias (fases prerequisito y por qué)

| Fase prerequisito | Por qué es necesaria |
|-------------------|---------------------|
| **Fase 4** — App: Asistente de descripción | `AiDescriptionChatCubit`, `MarkdownToDeltaConverter` (en `presentation/utils/`), `GenerateEventDescriptionUseCase` y el bottom sheet de chat deben existir para instrumentarlos y testearlos en Fase 6 |
| **Fase 5** — App: Asistente de portada + retiro legacy | `AiCoverChatCubit`, `GenerateEventCoverUseCase` y el bottom sheet de portada deben existir; además, el código legacy (`GetGenerateCoverUseCase`, `EventCoverRepository`) ya fue retirado, por lo que `get_generate_cover_use_case_test.dart` debe haber sido eliminado (o se elimina aquí en el paso 6); `docs/features/events.md` puede documentar el estado final sin confusión |

Las Fases 1-3 (backend) son prerequisito transitivo via Fases 4-5.

---

## Ejecución recomendada (nivel rg-exec: normal)

**Por qué nivel normal y no full:**

- **Sin migración de datos ni retiro de código legacy:** ambos completados en Fases 3 y 5 respectivamente. No hay blast radius de retiro; los cambios son aditivos (analytics, strings, tests, docs, specs backend), con la única excepción de eliminar un archivo de test de legacy, que es trivial.
- **Gate bloqueante de analytics (A7):** añade rigor al proceso — el implementador debe pasar el grep de verificación antes de continuar — pero no añade complejidad técnica. Es una verificación de diff, no una operación de refactor.
- **Riesgo medio por cobertura de tests + deploy:** el volumen de tests es significativo (7 archivos de test nuevos, ~40-50 test cases), y el deploy EC2 tiene pasos de verificación manual. El nivel normal (pipeline completo con implementador + auditor iterativo) cubre bien este riesgo: el auditor puede solicitar escenarios de test adicionales o correcciones de analytics antes de aprobar.
- **Specs NestJS:** son nuevos archivos en api-gateway sin modificar código productivo; riesgo bajo y bien acotado.
- **Full no se justifica:** no hay modificación de widgets compartidos con blast radius amplio (eso fue Fase 4), ni retiro atómico de código legacy (Fase 5), ni integración con API en preview inestable (Fase 2). El nivel normal con su ciclo implementador → auditor es suficiente para garantizar calidad sin sobredimensionar el esfuerzo.
