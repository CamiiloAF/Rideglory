# 05 — Síntesis final del plan

**Slug:** ai-event-generation
**Fecha:** 2026-06-05T21:37:41Z
**PO:** Consolidación post-revisión (Architect + Plan Reviewer + Auditor Opus — segunda ronda)

---

## Overview

Feature de generación IA para eventos de Rideglory: un organizador puede conversar con un asistente IA para generar y refinar la descripción de su evento e inyectarla al editor de texto enriquecido con un toque, y generar portadas 16:9 en un chat visual con previsualización full-screen. El feature usa Gemini Developer API (free tier), almacena imágenes temporales en Firebase Storage, controla cuotas diarias en Firestore, y retira completamente el flujo legacy Unsplash/Claude al finalizar la **Fase 5** (código backend, cliente Flutter y variables de entorno, en un único deploy coordinado).

El plan se divide en 6 fases ordenadas por dependencia: 3 de backend (1→2→3) seguidas de 2 de Flutter (4→5) y un cierre transversal (6). Las Fases 4 y 5 requieren que las Fases 1-3 estén desplegadas.

---

## Cambios aplicados

### Ajustes de Arquitectura (Architect Review)

| ID | Resumen | Impacto en el plan |
|----|---------|-------------------|
| AJ-1 | Paths de API renombrados a `/ai/*` (no `/events/ai/*`) | Fases 1-2: `AiController` expone `/ai/description` y `/ai/cover`; sin contaminación del `EventsController` |
| AJ-2 | Cuota en Firestore via firebase-admin (no Prisma/events-ms) | Fase 3: elimina migración Prisma, TCP round-trips y acoplamiento con events-ms; estructura `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}` con campo `expireAt: Timestamp` como objetivo de TTL policy |
| AJ-3 | `GEMINI_IMAGE_MODEL` como env var | Fase 2: el model ID de imagen no se hardcodea; permite cambiar sin redesplegar código |
| AJ-4 | `MarkdownToDeltaConverter` en `presentation/utils/` (no en `data/`) | Fase 4: `Delta` es tipo flutter_quill; no permitido en domain ni data; vive en `lib/features/events/presentation/utils/` |
| AJ-5 | `StorageCleanupService` dentro del `AiModule` (no módulo propio) | Fase 2: cron semanal `@Injectable()` siguiendo patrón `notification-scheduler.service.ts` |
| AJ-6 | Retiro del endpoint legacy fijado en Fase 5, no en Fase 3 | Fase 3 no toca el endpoint legacy; el retiro backend es atómico con el deploy de Fase 5 |

**Nota sobre AJ-4 vs gate del Plan Reviewer:** El Plan Reviewer especifica `presentation/utils/` porque `Delta` (flutter_quill) no puede importarse en domain. El espíritu de AJ-4 ("no en data") es correcto; la ubicación final es `presentation/utils/`. Se adopta la restricción del Plan Reviewer por precisión arquitectónica.

### Ajustes del Plan Reviewer

| ID | Resumen | Impacto en el plan |
|----|---------|-------------------|
| A1 | `remainingGenerations: int` en `AiDescriptionResponseDto` (Fase 1) y `AiCoverResponseDto` (Fase 2) | Evita parchear contratos retroactivamente en Fases 4-5; backend es fuente de verdad del conteo |
| A2 | Criterio de aceptación Fase 5: botón "Subir imagen" sobrevive; selector [Generar con IA] \| [Subir imagen] en paralelo | Fase 5: `CoverPreviewWidget` mantiene el flujo manual como alternativa |
| A3 | Fase 4 especifica explícitamente la creación de `AiChatTurn` en `lib/features/events/domain/model/ai_chat_turn.dart` como clase pura Dart sin imports Flutter | Fase 4: modelo de dominio claro para el historial del chat |
| A4 | Criterio Markdown→Delta acotado: soporta párrafo, h2, bold, italic, lista sin ordenar; el resto se inserta como texto plano sin error visible | Fase 4: evita scope creep; cualquier otro elemento tiene fallback seguro |
| A5 | Mecanismo cubit→cubit documentado: `Navigator.of(context).pop(selectedImageUrl)` como `String?`; caller llama `eventFormCubit.setCoverUrl(url)` | Fase 5: implementador no puede optar por estado global |
| A6 | "Usar esta imagen" presente en burbuja del chat (acción secundaria) Y como CTA primario en el visor full-screen | Fase 5: ambos puntos de confirmación funcionales |
| A7 | Gate de analytics en Fase 6: todos los `logEvent('ai_*')` se invocan desde métodos de cubit, sin llamadas en `build()` o callbacks de widget | Fase 6: criterio de aceptación bloqueante |
| A8 | Comentario inline en DTOs de IA documentando excepción Pattern B (DTOs compuestos con campos de control) | Fases 1-2: Tech Lead no marcará como violación |

### Correcciones del Auditor Opus — primera ronda

| ID | Resumen | Impacto en el plan |
|----|---------|-------------------|
| C1 | Enumeración explícita del código backend huérfano en Fase 5 | `ClaudeService`, `UnsplashService`, handler `generate-cover` en `events.controller.ts`, `generate-cover.spec.ts`, `@anthropic-ai/sdk` (y `axios` si no se usa en otro lado) de `api-gateway/package.json` — todos en Fase 5 |
| C2 | TTL Firestore corregido: campo `expireAt: Timestamp` (= `createdAt + 2 días`) como objetivo de la TTL policy | Fase 3: Firestore TTL policy no acepta un ajuste de "N días"; necesita un campo timestamp específico como objetivo |
| C3 | Nombre de modelo de dominio Flutter unificado a `AiChatTurn` / `ai_chat_turn.dart` | Plan Reviewer usó `ChatTurn`; se adopta nomenclatura del Architect por coherencia con rideglory-contracts |
| C4 | Retiro legacy completo en Fase 5; Fase 6 sin pasos de retiro | `UNSPLASH_ACCESS_KEY` y cualquier key de Anthropic se eliminan en Fase 5, no en Fase 6 |

### Correcciones del Auditor Opus — segunda ronda

| ID | Resumen | Impacto en el plan |
|----|---------|-------------------|
| D1 | `AppRichTextEditor` requiere modificación explícita para inyección de Delta | Fase 4 no puede asumir `controller.replaceContent(delta)` (no existe). El widget compartido debe modificarse; se adopta la opción (a): agregar param `QuillController? externalController`; implementar como artefacto de Fase 4 |
| D2 | Criterio de aceptación observable para inyección en editor | Fase 4: "el contenido del editor visible refleja el Delta insertado y `onChanged` propaga el nuevo JSON al `EventFormCubit`" |
| D3 | `draftId` (UUID en cliente) especificado en Fase 5 | Generar en `GenerateEventCoverUseCase` usando el paquete `uuid` (`Uuid().v4()`); no ad hoc en el cubit; incluir `uuid` en `pubspec.yaml` si no está presente |
| D4 | Mapeo explícito de los 4 códigos de error backend a estados Flutter con mensaje l10n y comportamiento de UI | Fases 4-5: tabla de mapeo en el detalle de cada fase (ver sección correspondiente) |

---

## Lista final de fases

| # | Título | Nivel | Por qué ese nivel |
|---|--------|-------|-------------------|
| 1 | Backend — Base de texto IA | normal | Nuevo módulo NestJS con contratos en rideglory-contracts e integración Gemini. Sin migración ni auth changes. Blast radius: api-gateway solamente. |
| 2 | Backend — Portada IA con Storage | full | Modelo Gemini en preview (inestable), precondición crítica de storageBucket en firebase-admin, escritura a Storage en producción, env vars nuevas en EC2, cron de limpieza. Falla silenciosa si bucket no está listo. |
| 3 | Backend — Sistema de cuotas | normal | Nueva colección Firestore + lógica de cuota + 4 errores tipados. Sin migración Prisma (AJ-2). Remote Config Admin SDK. Blast radius acotado: api-gateway + Firestore. |
| 4 | App — Asistente de descripción | full | Cross-cutting multi-capa, modificación de widget compartido (`AppRichTextEditor`) con blast radius en toda la app, cubit @freezed complejo, MarkdownToDeltaConverter, UI de chat. Toca el formulario central de eventos. |
| 5 | App — Asistente de portada + retiro legacy | full | Retiro atómico de código legacy (Flutter + backend simultáneamente), mecanismo cubit→cubit, UI chat + visor full-screen. Regresión rompe el flujo de portada para todos los organizadores. |
| 6 | QA, analytics y cierre | normal | Analytics (5 eventos), strings ARB, specs backend, widget tests, docs, deploy EC2. Sin migración ni retiro legacy (todo en Fase 5). Gate bloqueante de analytics. |

---

## Detalle de fases

### Fase 1 — Backend: Base de texto IA
**Objetivo:** El backend expone `POST /ai/description` (Gemini texto); el endpoint legacy permanece intacto.

**Resumen:**
- Instalar `@google/genai` en api-gateway
- Crear `AiModule` en `api-gateway/src/ai/` con `AiController` (rutas `/ai/*`) y `GeminiService.generateDescription()`
- Prompt con contexto rider colombiano; recibe `eventContext` + `history[]` (max 10 turnos), devuelve Markdown
- Publicar en `rideglory-contracts/src/ai/`: `AiDescriptionRequestDto`, `AiDescriptionResponseDto` (con `remainingGenerations: int`), `AiChatTurnDto` (campos: `role: AiChatRole (user|model)`, `content: string`), `AiErrorResponseDto` con enum `AiErrorCode`
- Agregar `GEMINI_API_KEY` a `.env.example` y variables EC2
- No eliminar `ClaudeService`, `@anthropic-ai/sdk` ni endpoint legacy en esta fase
- Comentario inline en `AiDescriptionResponseDto`:
  ```typescript
  // Excepción Pattern B: DTO compuesto con campo de control (remainingGenerations)
  // que no pertenece al modelo domain AiChatTurn. No extiende modelo domain.
  ```

**Dependencias:** ninguna

---

### Fase 2 — Backend: Portada IA con Storage
**Objetivo:** El backend produce imagen 16:9 via Gemini, la sube a Firebase Storage y devuelve URL pública; incluye cron de barrido de huérfanos.

**Resumen:**
- Agregar `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` al `initializeApp()` de firebase-admin en `FirebaseAuthService`; agregar `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` a `.env.example` y EC2
- **Gate día 1:** verificar escritura a bucket con una prueba manual o de integración antes de escribir lógica de generación de imagen
- Agregar `GeminiService.generateCover()` usando `responseModalities: ['IMAGE']`; el model ID se lee de `process.env.GEMINI_IMAGE_MODEL` (no hardcodear; el modelo correcto a validar es `gemini-2.0-flash-preview-image-generation` o su sucesor en el momento de la fase)
- Crear `POST /ai/cover` → imagen → Storage → URL pública en `pending/{userId}/{draftId}.jpg`
- `StorageCleanupService` como `@Injectable()` dentro de `AiModule` con `@Cron(CronExpression.EVERY_WEEK)` que borra archivos `pending/` con más de 7 días; patrón idéntico a `notification-scheduler.service.ts`
- Publicar `AiCoverRequestDto` (campos: `prompt: string`, `draftId: string`) y `AiCoverResponseDto` (campos: `imageUrl: string`, `draftId: string`, `remainingGenerations: int`) en rideglory-contracts
- Comentario inline en `AiCoverResponseDto`:
  ```typescript
  // Excepción Pattern B: DTO compuesto con campos de control (remainingGenerations, draftId)
  // que no pertenecen al modelo domain. No extiende modelo domain.
  ```
- El endpoint legacy `/events/generate-cover` sigue activo

**Dependencias:** Fase 1

---

### Fase 3 — Backend: Sistema de cuotas
**Objetivo:** Cada usuario tiene límite diario de generaciones (texto e imagen) configurable desde Firebase Remote Config; superarlo devuelve errores tipados.

**Resumen:**
- Crear `AiQuotaService` en `AiModule` que lee/escribe Firestore directamente via firebase-admin (sin TCP): colección `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}` con campos:
  - `descriptionCount: number` (default 0)
  - `coverCount: number` (default 0)
  - `createdAt: Timestamp`
  - `expireAt: Timestamp` (= `createdAt + 2 días`) — campo designado como objetivo de la TTL policy de Firestore; la policy se configura apuntando a este campo; Firestore elimina el documento cuando `expireAt` expira
- Configurar TTL policy en la colección `ai_usage_quotas` apuntando al campo `expireAt`
- Leer límites `ai_description_daily_limit` / `ai_cover_daily_limit` desde Remote Config Admin SDK
- Integrar `AiQuotaService.checkAndIncrement()` en `AiController` como guard antes de cada generación
- Implementar 4 errores tipados con status HTTP correspondiente:

| Código | HTTP | Condición |
|--------|------|-----------|
| `quota_exceeded_user` | 429 | El usuario superó su límite diario personal (`ai_*_daily_limit` de Remote Config) |
| `quota_exceeded_project` | 429 | La cuota del proyecto Gemini API está agotada (error 429 de Gemini) |
| `safety_blocked` | 422 | Gemini rechazó la solicitud por filtro de seguridad |
| `network_error` | 503 | Error de red al llamar a Gemini API (timeout, ECONNREFUSED, etc.) |

- **No** eliminar `ClaudeService`, `UnsplashService` ni `/events/generate-cover`
- Agregar nota en handoff de Fase 3: "El botón 'Generar portada con IA' del flujo antiguo quedará inoperativo para testers entre Fases 3 y 5; no afecta usuarios reales (sin usuarios en producción)"

**Dependencias:** Fases 1, 2

---

### Fase 4 — App: Asistente de descripción
**Objetivo:** Un organizador puede conversar con un asistente IA para generar y refinar la descripción, e inyectarla al editor de texto enriquecido con un toque.

**Resumen:**

**Modificación del widget compartido `AppRichTextEditor` (artefacto explícito):**

El widget `AppRichTextEditor` (`lib/shared/widgets/form/app_rich_text_editor.dart`) actualmente crea su `QuillController` internamente; no existe método `replaceContent()` ni forma de inyectar contenido desde fuera. Para soportar la inyección de Delta, el widget debe modificarse con la **opción (a): agregar param `QuillController? externalController`**:

```dart
// Cambio en AppRichTextEditor:
final QuillController? externalController;

// initState: usar externalController si se provee; sino crear uno interno
_controller = widget.externalController ?? QuillController(
  document: ...,
  selection: const TextSelection.collapsed(offset: 0),
);
```

La inyección del Delta se realiza así desde el cubit al confirmar "Insertar":
```dart
externalController.document = Document.fromDelta(convertedDelta);
```

El implementador de Fase 4 debe modificar `AppRichTextEditor`, agregar el parámetro como nullable (retrocompatible — todos los call sites existentes no lo pasan y siguen funcionando), y documentar el contrato en el docstring del widget.

*Domain (`lib/features/events/domain/`):*
- Crear **`AiChatTurn`** en `lib/features/events/domain/model/ai_chat_turn.dart` — clase pura Dart sin imports Flutter: campos `role: AiChatRole (user|model)`, `content: String`. Nombre canónico para todo el proyecto; simetría con `AiChatTurnDto` en rideglory-contracts.
- Crear `AiDescriptionRequest` en `domain/model/ai_description_request.dart` (payload para use case: `eventContext` + `history: List<AiChatTurn>`)
- Crear interfaz `AiDescriptionRepository` en `domain/repository/`
- Crear `GenerateEventDescriptionUseCase` → `Either<DomainException, String>` (devuelve Markdown)

*Data (`lib/features/events/data/`):*
- Implementar `AiDescriptionRepositoryImpl` con Retrofit service hacia `POST /ai/description`
- `AiDescriptionRequestDto` / `AiDescriptionResponseDto`: Pattern B no aplica — DTOs compuestos con `remainingGenerations`; documentar excepción con comentario inline (ver Fase 1)

*Presentation (`lib/features/events/presentation/`):*
- Crear `MarkdownToDeltaConverter` en `lib/features/events/presentation/utils/markdown_to_delta_converter.dart` — clase utilitaria pura; soporta: párrafo, h2 (→ header level 2 en Delta), bold, italic, lista sin ordenar; cualquier otro elemento → texto plano sin error visible; tests unitarios obligatorios
- Crear `AiDescriptionChatCubit` (`@injectable`, scoped al bottom sheet) con estado `@freezed`: `List<AiChatTurn> history`, `ResultState<String> generationResult`, `int remainingQuota`
- UI de chat como `DraggableScrollableSheet` (`initialChildSize: 0.65`, `minChildSize: 0.45`, `maxChildSize: 0.95`); `ListView` invertida; campo ≥ 48dp; botón "Insertar en descripción" `AppButton` primary ancho completo
- Estados obligatorios: idle (bienvenida), loading (burbuja tres puntos, campo bloqueado), data (burbuja con texto), error tipado (banner inline + "Reintentar"), quota=0 (campo deshabilitado)
- Confirmación via `ConfirmationDialog` al insertar si el editor tiene contenido previo; inserción directa si está vacío
- Cuota visible debajo del campo: "X generaciones restantes hoy"; primer turno lee de Remote Config, siguientes del campo `remainingGenerations` del response
- Conectar `AppRichTextEditor.onAiSuggest` → abrir bottom sheet con `BlocProvider<AiDescriptionChatCubit>` local; pasar `externalController` al widget para que la inyección sea posible

**Mapeo de errores backend → estado Flutter (Fases 4 y 5):**

| Código backend | DomainException | Mensaje l10n (key) | Comportamiento UI |
|---------------|-----------------|-------------------|-------------------|
| `quota_exceeded_user` | `DomainException.quotaExceededUser` | `ai_error_quota_exceeded_user` ("Has alcanzado tu límite diario de generaciones") | Banner inline; campo de entrada deshabilitado hasta el día siguiente; botón "Insertar" sigue activo si hay contenido previo |
| `quota_exceeded_project` | `DomainException.quotaExceededProject` | `ai_error_quota_exceeded_project` ("El servicio de IA está temporalmente saturado. Inténtalo más tarde") | Banner inline con botón "Reintentar"; campo de entrada habilitado |
| `safety_blocked` | `DomainException.safetyBlocked` | `ai_error_safety_blocked` ("Tu solicitud fue bloqueada por el filtro de contenido. Intenta reformular.") | Banner inline con botón "Reintentar"; campo habilitado |
| `network_error` | `DomainException.networkError` | `ai_error_network` ("Error de conexión. Verifica tu internet e intenta de nuevo.") | Banner inline con botón "Reintentar"; campo habilitado |

El `AiDescriptionRepository` / `AiCoverRepository` deben mapear los HTTP status codes y el campo `error` del body al `DomainException` correspondiente en `executeService()`. Los 4 keys l10n se agregan en `app_es.arb` en Fase 6.

**Criterios de aceptación de Fase 4:**
1. La conversión Markdown→Delta soporta: párrafo, h2, bold, italic, listas sin ordenar. Cualquier otro elemento se inserta como texto plano sin error visible.
2. Al tocar "Insertar en descripción", el contenido del editor visible refleja el Delta insertado, y `onChanged` propaga el nuevo JSON al `EventFormCubit` — verificable con un test de widget que inspecciona el `onChanged` callback.
3. `AppRichTextEditor` con `externalController` nulo sigue funcionando idéntico a hoy en todos los call sites existentes (retrocompatibilidad).
4. Los 4 errores tipados muestran el mensaje y comportamiento correcto según la tabla de mapeo.

**Dependencias:** Fase 3

---

### Fase 5 — App: Asistente de portada + retiro completo del flujo legacy
**Objetivo:** Un organizador puede generar portadas IA en un chat visual, previsualizar en pantalla completa y confirmar; el flujo Unsplash/Claude desaparece totalmente (Flutter + backend + secrets) en esta única fase.

**Resumen:**

**Generación del `draftId` (UUID en cliente):**

`AiCoverRequestDto` requiere un campo `draftId: string` (UUID) para nombrar el archivo en Storage (`pending/{userId}/{draftId}.jpg`). Este UUID se genera **en `GenerateEventCoverUseCase`** usando el paquete `uuid` (`const Uuid().v4()`). El implementador debe verificar si `uuid` ya está en `pubspec.yaml`; si no, agregarlo. El cubit no genera el UUID ad hoc; lo recibe del use case dentro del resultado del dominio o se pasa como parámetro al use case.

*Domain + Data (simétrico a Fase 4):*
- `AiCoverRequest` en `domain/model/ai_cover_request.dart` (campos: `prompt: String`, `draftId: String`)
- Interfaz `AiCoverRepository` + `AiCoverRepositoryImpl`
- `GenerateEventCoverUseCase` → `Either<DomainException, String>` (URL); genera `draftId = const Uuid().v4()` antes de construir `AiCoverRequest`

*Presentation:*
- `AiCoverChatCubit` (`@injectable`, scoped) con estado `@freezed`: `List<AiChatTurn> history`, `List<String> generatedUrls`, `ResultState<String> currentGeneration`, `int remainingQuota`
- Documentar en el cubit con comentario:
  ```dart
  // Comunicación con EventFormCubit: al confirmar imagen, llamar
  // Navigator.of(context).pop(selectedImageUrl) como String?.
  // El caller recibe la URL y llama eventFormCubit.setCoverUrl(url).
  // No usar estado global compartido entre cubits.
  ```
- UI de chat bottom sheet (idéntico tamaño a Fase 4); burbujas de imagen 16:9 (ancho sheet − 32dp); shimmer animado durante generación (~10-15 s) con indicador de progreso indeterminado bajo el shimmer; `CachedNetworkImage` al cargar
- Estados: idle (placeholder 16:9 + ícono cámara), loading (shimmer 16:9 + progreso indeterminado), data (imagen + botón "Usar esta imagen" secondary + ícono expand), error tipado (banner inline según tabla de mapeo de Fase 4), quota=0 (campo deshabilitado; botones "Usar" en burbujas anteriores siguen activos)
- Visor full-screen (`AiCoverFullScreenPage`): CTA `AppButton` "Usar esta portada" ancho completo + zona segura inferior; botón X top-right en SafeArea
- **"Usar esta imagen" disponible tanto en la burbuja del chat (acción secundaria) como CTA primario en el visor full-screen**
- **El botón "Subir imagen" permanece disponible.** Selector de flujo en `CoverPreviewWidget`: [Generar con IA] | [Subir imagen] en paralelo

*Retiro legacy Flutter (atómico con deploy backend):*
- Eliminar: `GetGenerateCoverUseCase`, `EventCoverService`, `EventCoverRepositoryImpl`, `CoverGenerationDto`
- Eliminar ruta `ApiRoutes.generateEventCover` de `api_routes.dart`

*Retiro legacy backend (atómico con deploy Flutter):*
- Eliminar de api-gateway: `ClaudeService` y todos sus usos
- Eliminar de api-gateway: `UnsplashService` y todos sus usos
- Eliminar de `events.controller.ts`: el handler `generate-cover` y su ruta `POST /events/generate-cover`
- Eliminar o convertir en spec negativo: `generate-cover.spec.ts`
- Eliminar de `api-gateway/package.json`: `@anthropic-ai/sdk`; verificar si `axios` se usa en otro lugar — si no, eliminarlo también
- Eliminar de EC2 y `.env.example`: `UNSPLASH_ACCESS_KEY`, cualquier key de Anthropic (`ANTHROPIC_API_KEY` u equivalente)

**Criterios de aceptación de Fase 5:**
1. El botón "Subir imagen" permanece funcional en `CoverPreviewWidget` tras el refactor.
2. El botón "Usar esta imagen" está presente en la burbuja del chat (acción secundaria) Y como CTA primario en el visor full-screen.
3. `Navigator.of(context).pop(selectedImageUrl)` es el único mecanismo de retorno de URL al caller; no existe estado global compartido entre `AiCoverChatCubit` y `EventFormCubit`.
4. Los 4 errores tipados muestran el mensaje y comportamiento correcto según la tabla de mapeo de Fase 4.
5. `dart analyze` limpio; `flutter test` pasa; el endpoint `POST /events/generate-cover` ya no existe en api-gateway.

**Dependencias:** Fases 3, 4

---

### Fase 6 — QA, analytics y cierre
**Objetivo:** El feature es apto para producción con observabilidad completa, cobertura de tests, strings localizadas y backend desplegado.

**Resumen:**
- Implementar 5 eventos de telemetría **desde métodos de cubit** (nunca desde `build()` ni callbacks de widget): `ai_description_generated`, `ai_image_generated`, `ai_quota_exceeded`, `ai_generation_failed`, `ai_cover_used`
- **Gate bloqueante:** revisión de diff confirma que todos los `logEvent('ai_*')` se invocan desde métodos de cubit; ninguna llamada en capa presentation widget
- Agregar todas las strings de IA al `app_es.arb`, incluyendo los 4 keys de error (`ai_error_quota_exceeded_user`, `ai_error_quota_exceeded_project`, `ai_error_safety_blocked`, `ai_error_network`); `dart analyze` limpio
- Escribir specs NestJS para `POST /ai/description` y `POST /ai/cover`
- Alcanzar `flutter test` al 100% en código nuevo (cubit tests, `MarkdownToDeltaConverter` tests, use case tests, widget tests del bottom sheet de chat)
- Actualizar `docs/features/events.md` con el nuevo flujo de asistentes IA
- Deploy backend en EC2 siguiendo workflow documentado (migraciones local-first; con AJ-2 no hay migración Prisma, solo verificar TTL policy de Firestore activa)
- No hay pasos de retiro legacy en esta fase (todos completados en Fase 5)

**Dependencias:** Fases 4, 5

---

## Supuestos y riesgos

### Supuestos

1. **Gemini free tier operativo:** Gemini texto y el modelo de imagen (`GEMINI_IMAGE_MODEL`) están disponibles en free tier; si el modelo de imagen cambia de nombre antes de Fase 2, actualizar la env var es suficiente.
2. **firebase-admin acepta `storageBucket`:** La instancia singleton se reinicializa en cada deploy; agregar el parámetro es suficiente sin cambios de IAM adicionales.
3. **Permisos de escritura al bucket:** Las credenciales firebase-admin ya configuradas tienen permisos de escritura; se verifican en día 1 de Fase 2.
4. **rideglory-contracts operativo:** El paquete `file:../rideglory-contracts` acepta DTOs nuevos bajo `src/ai/` sin setup adicional.
5. **Historial recortado en cliente:** El cliente envía máximo 10 turnos en `history[]` para no exceder la ventana de contexto.
6. **Sin usuarios reales en producción:** No hay usuarios activos que dependan del flujo Unsplash/Claude; el retiro es seguro.
7. **flutter_quill ^11.0.0:** No existe paquete maduro para Markdown→Delta; la implementación manual es viable con el subconjunto acotado (párrafo, h2, bold, italic, lista).
8. **`axios` en api-gateway:** El implementador de Fase 5 debe verificar si `axios` está en uso en otros módulos antes de eliminar la dependencia.
9. **`uuid` package:** Puede estar ya presente en `pubspec.yaml`; si no, agregarlo es el único cambio de dependencia Flutter de Fase 5.
10. **`AppRichTextEditor` retrocompatible:** El param `externalController` es nullable; todos los call sites existentes siguen funcionando sin cambios.

### Riesgos

| ID | Riesgo | Prob | Impacto | Fase | Mitigación |
|----|--------|------|---------|------|-----------|
| R1 | Modelo Gemini imagen inestable (preview; puede cambiar nombre) | Alta | Alto | 2 | `GEMINI_IMAGE_MODEL` como env var; validar en día 1 de Fase 2 |
| R2 | `storageBucket` no configurado en firebase-admin → falla silenciosa | Media | Alto | 2 | Gate explícito en Fase 2: verificar escritura a Storage antes de implementar lógica de generación |
| R3 | `MarkdownToDeltaConverter` — edge cases no cubiertos | Media | Medio | 4 | Subconjunto acotado (A4); fallback texto plano sin error; tests unitarios obligatorios |
| R4 | Latencia imagen Gemini (~10-15 s) → UX percibida de app colgada | Alta | Medio | 5 | Shimmer 16:9 + indicador de progreso indeterminado obligatorio (especificado en UX) |
| R5 | Ventana inoperativa de portada para testers (Fases 3-4) | Media | Bajo | 3-4 | Nota en handoff de Fase 3; sin usuarios reales; solo afecta QA interno |
| R6 | Propagación Remote Config (delay hasta 12h) | Baja | Bajo | 3-5 | `fetchAndActivate()` al montar cada chat cubit |
| R7 | Fase 4 subdimensionada (equivale a 2 features medianas) | Media | Medio | 4 | Si el sprint es ajustado: dividir en 4a (domain+data+cubit+AppRichTextEditor mod) y 4b (UI+integración); el plan lo permite |
| R8 | `generate-cover.spec.ts` huérfano falla en CI si no se suprime | Media | Bajo | 5 | El implementador debe suprimir o refactorizar el spec al retirar el handler |
| R9 | `Document.fromDelta()` inestable en flutter_quill 11.x | Baja | Medio | 4 | Probar en día 1 de Fase 4; alternativa: `QuillController.fromDocument(Document.fromJson(deltaJson))` |
