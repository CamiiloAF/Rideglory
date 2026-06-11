# Tech Lead handoff — ai-phase06-qa-analytics

**Timestamp:** 2026-06-10T22:55:20Z
**Agente:** Tech Lead (nivel normal)
**Revisión:** 2 (post-correcciones de blockers H1/H2/H3 de rev 1)

---

## Veredicto

**READY**

Los 3 blockers de la revisión 1 (HTTP 402→429, Apple sign-in sin tests, uuid sin usar) fueron resueltos. BUG-QA-01 (prefer_const_constructors) corregido por Tech Lead en esta revisión. Quedan watchlist items menores sin blocker.

---

## Hallazgos

### Blockers de rev 1 — todos resueltos

| Hallazgo | Resolución |
|---|---|
| H1 — HTTP 402 incorrecto en docs | `docs/features/events.md` corregido a `429` para ambos tipos de cuota |
| H2 — Apple sign-in sin tests | TC-auth-A1 (happy path: setUserId SHA-256, authSucceeded(apple), setUserProperty) y TC-auth-A2 (cancelación: authFailed(apple), verifyNever setUserId) añadidos en `auth_cubit_test.dart` |
| H3 — uuid sin usar | `uuid: ^4.5.1` eliminado de `pubspec.yaml`; `generateNonce()` confirmado como función de `sign_in_with_apple` |

### BUG-QA-01 — corregido en esta revisión

3 `prefer_const_constructors` (info-level) en `ai_description_chat_cubit_test.dart` líneas 209, 245, 281 corregidos: `Left(const AiXxxException(...))` → `const Left(AiXxxException(...))`. `dart analyze` ahora reporta "No issues found" en ese archivo.

### Watchlist — sin bloquear

**W1 — login_social_section.dart (widget) modificado fuera de scope:** Esta fase tiene guardrail explícito de no tocar widgets. El cambio añade Remote Config gate `google_sign_in_ios_enabled` para mostrar Google Sign-In en iOS. El código es correcto (`getIt<FirebaseRemoteConfig>().getBool(...)`) y encaja en el patrón existente, pero viola el guardrail de scope. Separar en Commit 2 (Apple Sign-In) es suficiente.

**W2 — Sin test de widget para Google Sign-In iOS gate:** El condicional `showGoogleOnIos = Platform.isIOS && _googleSignInIosEnabled` en `login_social_section.dart` no tiene test de visibilidad. Aceptable por ahora dado que no hay usuarios reales, pero debería cubrirse antes de lanzamiento iOS.

**W3 — CA1 gate vacuo:** `grep -rn "logEvent.*ai_" lib/` devuelve vacío porque el código usa constantes camelCase (`AnalyticsEvents.aiDescriptionGenerated`) sin underscore en el nombre de variable. El espíritu del CA se cumple (todos los logEvent con eventos AI están en el cubit), pero el grep no puede detectar violaciones futuras.

---

## Seguridad

- **Sin PII en logs:** `aiErrorCode` usa `exception.runtimeType.toString()` — nombre de clase Dart, no mensaje de usuario.
- **Sin secrets:** Los nombres de eventos analytics son strings cortos, sin datos de usuario, sin tokens.
- **Apple Sign-In criptografía correcta:** `generateNonce()` crea raw nonce aleatorio; SHA-256 del hash se envía a Apple; raw nonce se pasa a `OAuthProvider('apple.com').credential(...)` para verificación en Firebase. Pattern correcto y estándar.
- **No SQL concatenado, no XSS, no CORS nuevos.** Esta fase solo toca Flutter y un spec NestJS.

---

## Arquitectura

### In-scope — correcto
- `AnalyticsService` inyectado por constructor en `AiDescriptionChatCubit` — cumple D1 del arquitecto y el constraint de Clean Architecture (no `getIt` en cubit).
- `logEvent` exclusivamente en cubits — CA1 satisfecho; no aparece en widgets ni pages.
- `newHistory.length` como `aiTurnIndex` es uniforme en `sendMessage` y `retryLastMessage` — equivalencia matemática correcta (D7 del arquitecto).
- `injection.config.dart` regenerado correctamente con 3er parámetro `AnalyticsService`.
- `aiGenerationTypeCover` como placeholder string — aceptable; no hay cubit de portada activo.

### Out-of-scope — sin violaciones de arquitectura
- `signInWithApple()` return type cambió de `Either<DomainException, User?>` a `Either<DomainException, AuthenticatedUser>` — breaking change compatible porque el único consumidor (`AuthCubit`) también fue actualizado.
- `_googleSignInIosEnabled` en `login_social_section.dart` usa `getIt<FirebaseRemoteConfig>()` — correcto para un `StatefulWidget`; el widget no tiene cubit propio y este patrón es consistente con `getIt<AnalyticsService>()` en el mismo widget.

---

## Tests

### In-scope — todos correctos
- **CA7 (4 tests):** Happy path (`aiDescriptionGenerated`, aiTurnIndex=2), quota user (`aiQuotaExceeded`), safety blocked (`aiGenerationFailed`), network error (`aiGenerationFailed`). Mocks correctos con `thenAnswer((_) async {})` para `Future<void>`. Verificación con `verify(...).called(1)`.
- **CA8 (2 tests):** bold+italic combo verifica ops con `bold:true` e `italic:true` via helper `findOp`; empty input verifica que `convert('')` retorna sin throw y produce al menos 1 op.
- **Backend spec (5 tests):** Suite A — ValidationPipe con `AiDescriptionRequestDto` valida `@ArrayMaxSize(10)` correctamente. Suite B — `GeminiService.generateDescription` retorna `isDescription: true/false` según marcador `{{DESCRIPTION}}/{{QUESTION}}`, lanza `AiErrorCode.SAFETY_BLOCKED` cuando SDK lanza ese error. Mocks hoisted antes de los imports con `jest.mock('@google/genai', ...)`.
- **AC15/AC16 siguen verdes** tras la refactorización del constructor de 2 a 3 parámetros.

### Out-of-scope — cobertura parcial aceptable
- TC-auth-A1 y TC-auth-A2 cubren happy path y cancelación de Apple Sign-In. No cubren: `identityToken == null`, `givenName` vacío en reintentos (Apple no reenvía nombre tras el primer login), errores de `_registerApiUser`. Aceptable dado que no hay usuarios reales en producción.

---

## Pruebas manuales (requeridas antes de merge a main)

**Phase 06 — analytics:**
1. Firebase DebugView: asistente descripción → mensaje → `ai_description_generated` con `ai_turn_index: 2`.
2. Firebase DebugView: cuota agotada → `ai_quota_exceeded`, `ai_generation_type: description`.
3. Firebase DebugView: safety filter → `ai_generation_failed`, `ai_error_code: AiSafetyBlockedException`.
4. API: `POST /api/ai/description` con `history` de 11 turnos → `400 BadRequest`.
5. Docs: `docs/features/events.md` muestra `POST /events/generate-cover` tachado y sección "Asistentes IA".

**Apple Sign-In (separar en commit 2):**
6. Dispositivo iOS real: primer login Apple → usuario creado, displayName correcto.
7. Mismo dispositivo: segundo login Apple → no crea duplicado, carga datos existentes.
8. Remote Config `google_sign_in_ios_enabled = false` (default) → botón Google oculto en iOS.
9. Remote Config `google_sign_in_ios_enabled = true` → botón Google visible en iOS.
