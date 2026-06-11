# PRD Normalizado — App: Asistente de portada IA + retiro legacy completo

**Slug:** app-ai-cover-assistant
**Generado:** 2026-06-09T02:17:44Z
**Fuente:** docs/plans/ai-event-generation/phases/phase-05-app-asistente-de-portada-retiro-completo-del-flu.md
**Nivel rg-exec:** full

---

## 1 Objetivo

Un organizador puede generar portadas IA en un chat visual (bottom sheet con burbujas-imagen 16:9), previsualizar en pantalla completa y confirmar la que le guste. El flujo legacy Unsplash/Claude desaparece totalmente — código Flutter, código backend y variables de entorno — como un deploy atómico coordinado en ambos repositorios.

---

## 2 Por qué

El flujo actual de generación de portadas usa Claude + Unsplash en el api-gateway (`POST /events/generate-cover`), que quedó obsoleto con la migración a Gemini. Mantenerlo crea deuda técnica activa (dependencias `@anthropic-ai/sdk`, `axios`, credenciales EC2 innecesarias) y divergencia de UX. La nueva arquitectura (Gemini, `POST /ai/cover`, cuotas diarias) ya está implementada en las Fases 1-3 del backend; esta fase completa el ciclo en el cliente Flutter y retira el código legacy de ambos repos.

---

## 3 Alcance

### Entra

**Flutter — dominio y data nuevos:**
- Modelos de dominio puros (`AiCoverRequest`, `AiCoverResult`); interfaz `AiCoverRepository`
- `GenerateEventCoverUseCase` — genera `draftId` con `Uuid().v4()` internamente (no en cubit)
- DTOs `AiCoverRequestDto` / `AiCoverResponseDto` con excepción Pattern B documentada
- Retrofit service `AiCoverService` hacia `POST /ai/cover`
- `AiCoverRepositoryImpl` con mapeo de 4 errores tipados vía `try/catch` sobre `DioException`

**Flutter — presentación nueva:**
- `AiCoverChatCubit` (`@injectable`, scoped al bottom sheet; NO `@singleton`)
- `AiCoverChatSheet` con `DraggableScrollableSheet`
- Widgets atómicos: `AiCoverImageBubble`, `AiCoverShimmerBubble`, `AiCoverChatInput`, `AiCoverQuotaIndicator`, `AiCoverErrorBanner`
- `AiCoverFullScreenPage` con CTA primario `AppButton` + `SafeArea` y botón X
- Integración en `event_form_content.dart`: selector [Generar con IA] | [Subir imagen]; pop del sheet aplica URL via `FormImageCubit.setRemoteImageUrl(url)` (sin tocar `EventFormCubit`)

**Flutter — retiro legacy (atómico):**
- Eliminar `GetGenerateCoverUseCase`, `EventCoverRepository`, `EventCoverRepositoryImpl`, `EventCoverService`, `CoverGenerationDto`, `CoverPreviewWidget`
- Limpiar `EventFormCubit`: campo `coverGenerationResult`, métodos `generateCover()`/`resetCoverGeneration()`, inyección `GetGenerateCoverUseCase`
- Limpiar `event_form_view.dart` y `event_form_content.dart` de toda referencia al flujo legacy
- Eliminar `ApiRoutes.generateEventCover`
- Strings l10n del nuevo flujo en `app_es.arb`
- Agregar paquete `uuid: ^4.5.1` a `pubspec.yaml`

**Backend (api-gateway) — retiro legacy (atómico):**
- Eliminar `ClaudeService`, `UnsplashService` y todos sus usos
- Eliminar handler `@Post('generate-cover')` de `events.controller.ts`
- Gestionar `generate-cover.spec.ts` (spec negativo 404 o eliminar) antes de verificar `axios`
- Eliminar `@anthropic-ai/sdk`; eliminar `axios` si grep confirma cero usos restantes
- Eliminar `UNSPLASH_ACCESS_KEY` y `ANTHROPIC_API_KEY` de `.env.example`

### No entra

- `AppRichTextEditor`, `AiDescriptionChatCubit`, `MarkdownToDeltaConverter` (Fase 4)
- Analytics `ai_*` (Fase 6)
- Specs NestJS de `POST /ai/cover` (Fase 6)
- Cambios en `events-ms`, Firestore ni Remote Config (Fases 1-3)

---

## 4 Áreas afectadas

| Repo | Área | Archivos clave |
|------|------|---------------|
| Flutter | Domain — events | `lib/features/events/domain/model/`, `domain/repository/`, `domain/use_cases/` |
| Flutter | Data — events | `lib/features/events/data/dto/`, `data/service/`, `data/repository/` |
| Flutter | Presentation — events/form | `lib/features/events/presentation/form/` (cubit, widgets, screens) |
| Flutter | Core | `lib/core/exceptions/domain_exception.dart`, `lib/core/http/api_routes.dart`, `lib/l10n/app_es.arb`, `pubspec.yaml` |
| Flutter | DI | `lib/core/di/injection.config.dart` (regenerado) |
| rideglory-api | api-gateway/src/events | `events.controller.ts`, `generate-cover.spec.ts`, `dto/generate-cover.dto.ts` |
| rideglory-api | api-gateway/src/common | `claude.service.ts`, `unsplash.service.ts` |
| rideglory-api | api-gateway | `package.json`, `package-lock.json`, `.env.example` |

---

## 5 Criterios de aceptación

1. **Botón "Subir imagen" operativo tras refactor.** El flujo de subida manual de imagen funciona exactamente igual que antes de la Fase 5: tap en "Subir imagen" → se abre el picker de galería → `FormImageCubit.pickImageFromGallery()` se invoca. Verificable en widget test que simula el tap y confirma la llamada al método.

2. **Botón "Usar esta imagen" en dos puntos de confirmación.** La burbuja del chat (`AiCoverImageBubble`) muestra el botón secondary "Usar esta imagen" visible. Al abrir el visor full-screen (`AiCoverFullScreenPage`), el CTA primario "Usar esta portada" es un `AppButton` ancho completo con `SafeArea` inferior. Ambos cierran el flujo retornando la URL como `String?`.

3. **`FormImageCubit.setRemoteImageUrl(url)` como único canal de aplicación de portada.** Tras el pop del sheet con una URL, el caller (`event_form_content.dart`) llama `context.read<FormImageCubit>().setRemoteImageUrl(url)`. No existe `EventFormCubit.setCoverUrl()` ni ningún otro mecanismo alternativo. No existe `context.read<EventFormCubit>()` dentro de `AiCoverChatCubit` ni en los widgets del sheet. Verificable por widget test de `event_form_content.dart`: (a) tap "Subir imagen" → `FormImageCubit.pickImageFromGallery()` invocado, sheet de IA no se abre; (b) pop del sheet con URL → `FormImageCubit.setRemoteImageUrl(url)` invocado, `EventFormCubit` no invocado para portada.

4. **Cuatro errores tipados con mensaje y comportamiento correcto.** Los comportamientos se verifican en cubit tests usando mocks que lanzan cada subclase:
   - `AiQuotaExceededUserException`: banner rojo; campo de texto deshabilitado; botones "Usar" en burbujas previas siguen activos.
   - `AiQuotaExceededProjectException`: banner con "Reintentar"; campo habilitado.
   - `AiSafetyBlockedException`: banner con "Reintentar"; campo habilitado.
   - `AiNetworkException`: banner con "Reintentar"; campo habilitado.

5. **Shimmer durante generación.** Al llamar a `generateCover`, la UI muestra `AiCoverShimmerBubble` 16:9 con `LinearProgressIndicator` indeterminado inmediatamente; el campo de entrada queda deshabilitado. Verificable en widget test con cubit mockeado en estado `loading`.

6. **`draftId` generado exclusivamente en el use case.** No existe ninguna llamada a `Uuid().v4()` en `AiCoverChatCubit` ni en ningún widget. Verificable por inspección (grep `Uuid()` en la codebase Flutter: debe aparecer solo en `generate_event_cover_use_case.dart`) y por test unitario del use case que verifica que el `draftId` tiene formato UUID v4.

7. **`event_form_cubit.dart` limpio de referencias legacy.** El archivo no contiene: campo `coverGenerationResult`, métodos `generateCover()`/`resetCoverGeneration()`, inyección `GetGenerateCoverUseCase`, ni su import. `dart analyze` limpio. Verificable por inspección directa y compilación sin errores.

8. **`event_form_view.dart` y `event_form_content.dart` limpios.** `event_form_view.dart` no tiene `coverGenerationResult` en `listenWhen` ni en el listener. `event_form_content.dart` no tiene `BlocBuilder<EventFormCubit>` para el `coverGenerationResult`, no tiene `_triggerGenerate()` ni referencia a `CoverPreviewWidget`. Verificable por `dart analyze` sin imports huérfanos.

9. **Strings l10n completas con keys unívocas.** Los textos del flujo de portada IA están en `app_es.arb` con `context.l10n.<key>` en todos los widgets. Ningún string de UI hardcodeado en Dart. Claves mínimas requeridas:
   - `ai_cover_placeholder_hint` ("Describe la portada que quieres generar")
   - `ai_cover_use_this_image` ("Usar esta imagen")
   - `ai_cover_use_this_cover` ("Usar esta portada")
   - `ai_cover_generate_button` ("Generar con IA")
   - `ai_cover_upload_button` ("Subir imagen")
   - `ai_cover_remaining_quota` ("{count} generaciones restantes hoy" — parametrizado)
   - Los 4 keys de error reutilizados si ya existen: `ai_error_quota_exceeded_user`, `ai_error_quota_exceeded_project`, `ai_error_safety_blocked`, `ai_error_network`

10. **Endpoint `POST /events/generate-cover` eliminado.** Una llamada HTTP a ese endpoint devuelve 404. Verificable con `curl` o en el spec negativo de `generate-cover.spec.ts`.

11. **Retiro de servicios backend completo y sin imports huérfanos.** `ClaudeService` y `UnsplashService` no existen en `api-gateway/src/`. Ningún módulo NestJS los importa ni importa `@anthropic-ai/sdk`. Verificable con:
    ```bash
    grep -r "ClaudeService\|UnsplashService\|anthropic-ai/sdk\|anthropic" api-gateway/src/ --include="*.ts"
    # Resultado esperado: cero líneas
    ```

12. **`dart analyze` limpio y `flutter test` verde.** Sin nuevos warnings ni errores de lint tras el retiro de código legacy y la adición del nuevo flujo. Ningún import apunta a archivos eliminados.

---

## 6 Guardrails de regresión

- El flujo de **subida manual de imagen** (picker de galería) debe seguir funcionando sin cambios tras el refactor de `event_form_content.dart`.
- `EventFormCubit` no debe adquirir ningún nuevo método relacionado con portada (`setCoverUrl()` u otro); la URL fluye exclusivamente por `FormImageCubit`.
- `AiCoverChatCubit` debe ser `@injectable` (transient), NO `@singleton`; no debe aparecer en el `MultiBlocProvider` de `main.dart`.
- `Uuid().v4()` debe aparecer únicamente en `generate_event_cover_use_case.dart` — ningún widget ni cubit lo llama directamente.
- `context.mounted` debe verificarse en `event_form_content.dart` tras el `await showModalBottomSheet` antes de llamar `context.read<FormImageCubit>()`.
- El spec `generate-cover.spec.ts` debe gestionarse **antes** de correr el grep de `axios`; si no, el grep dará falsos positivos.
- Variables de entorno EC2 (`UNSPLASH_ACCESS_KEY`, `ANTHROPIC_API_KEY`) se eliminan de EC2 **después** de confirmar la estabilidad del deploy de Fase 5 — no antes.
- `dart analyze` debe pasar en cero errores/warnings después de cada paso de retiro.
- Los tests de integración existentes en `integration_test/events_patrol_test.dart` deben pasar sin regresión.

---

## 7 Constraints heredados

- **Clean Architecture:** dominio no importa Flutter ni hace I/O; data no importa widgets ni `BuildContext`; presentación no llama HTTP directamente ni expone DTOs.
- **Pattern B DTOs:** toda excepción al patrón (DTOs compuestos, request-only) debe documentarse con comentario inline obligatorio.
- **Un widget por archivo:** regla de cero tolerancia; cada clase que extiende `StatelessWidget`/`StatefulWidget` en su propio archivo `.dart`.
- **Sin métodos que retornan widgets:** `Widget _buildX()` está prohibido; cada pieza de UI es su propia clase widget.
- **`AppButton` y componentes shared:** siempre verificar `lib/shared/widgets/` antes de crear componentes nuevos; nunca usar `ElevatedButton`/`TextButton` directamente si existe equivalente shared.
- **Texto oscuro sobre primario:** sobre el acento naranja (`#f98c1f`), texto/iconos/knob van oscuros (`darkBgPrimary`), nunca blanco.
- **Strings localizadas:** todo texto visible por el usuario va en `app_es.arb` con `context.l10n.<key>`; cero hardcoding.
- **`executeService()` para el happy path HTTP:** el mapeo de los 4 errores tipados usa `try/catch` sobre `DioException` antes de delegar en el helper genérico para errores inesperados.
- **DI scoped:** cubits de formulario van como `BlocProvider` en el árbol de widgets, nunca como `@singleton` en GetIt.
- **Contracts rebuild:** si se toca `@rideglory/contracts` en backend, correr `npm run build` + `pnpm install` en cada MS afectado; si no, falla con `MODULE_NOT_FOUND`.
- **`build_runner` en worktrees/CI:** usar `--force-jit` o tener `pubspec.lock` copiado de main para evitar fallo por build hooks de `objective_c`.
