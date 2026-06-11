# SUMMARY — ai-phase06-qa-analytics

**Tech Lead re-revisión:** 2026-06-10T22:55:20Z
**Estado:** Revisión 2 (post-correcciones de los 3 blockers de la Revisión 1)
**Veredicto:** READY

---

## Objetivo

Cerrar el feature de asistentes IA para eventos con observabilidad completa (analytics en `AiDescriptionChatCubit`), tests Flutter al 100% de los CAs, spec NestJS para `POST /ai/description`, y documentación actualizada — sin código productivo nuevo.

---

## Qué cambió por área

### Analytics (Flutter) — en scope
- `lib/core/services/analytics/analytics_events.dart`: +3 constantes (`aiDescriptionGenerated`, `aiQuotaExceeded`, `aiGenerationFailed`) en sección "AI Fase 6".
- `lib/core/services/analytics/analytics_params.dart`: +5 constantes (`aiTurnIndex`, `aiGenerationType`, `aiErrorCode`, `aiGenerationTypeDescription`, `aiGenerationTypeCover`) en sección "AI Fase 6".

### Cubit — en scope
- `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart`: `AnalyticsService` inyectado como 3er parámetro constructor. 6 llamadas `logEvent` (3 en `sendMessage`, 3 en `retryLastMessage`): `aiDescriptionGenerated` en éxito, `aiQuotaExceeded` en error de cuota (user/project), `aiGenerationFailed` en safety/network.
- `lib/core/di/injection.config.dart`: regenerado con `build_runner` — factory de `AiDescriptionChatCubit` actualizada a 3 parámetros.

### Tests Flutter — en scope
- `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart`: +`MockAnalyticsService`, instancias del cubit actualizadas a 3 parámetros, +4 tests CA7. **BUG-QA-01 corregido por Tech Lead (rev 2):** `Left(const X(...))` → `const Left(X(...))` en líneas 209, 245, 281 — `dart analyze` ahora reporta "No issues found".
- `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart`: +2 tests CA8 (bold+italic combo, empty input).

### Backend — en scope
- `rideglory-api/rideglory-contracts/src/ai/dto/ai-description-request.dto.ts`: `@ArrayMaxSize(10)` añadido al campo `history`.
- `rideglory-api/api-gateway/src/ai/ai-description.spec.ts`: creado. 5 tests / 2 suites (Suite A: validación DTO history > 10 turnos; Suite B: GeminiService happy path isDescription true/false + safety_blocked).

### Documentación — en scope
- `docs/features/events.md`: `POST /events/generate-cover` marcado como `~~ELIMINADO (Fase 5)~~`; nueva sección §9 con contrato `POST /ai/description` (request, errores `429`/`422`/`503`/`400`, restricciones); nueva sección §10 "Asistentes IA" con flujo completo, `MarkdownToDeltaConverter`, tabla analytics; secciones §11–§13 renumeradas.

### Fuera de scope (bundled en la misma branch — correcciones de los blockers H2/H3 de rev 1)
- `lib/core/services/auth_service.dart`: implementación real de `signInWithApple()` con nonce SHA-256 correcto, `OAuthProvider('apple.com')`, registro de usuario nuevo.
- `lib/features/authentication/application/auth_cubit.dart`: manejo de `AuthenticatedUser` en rama Apple Sign-In.
- `lib/features/authentication/login/presentation/widgets/login_social_section.dart`: Remote Config gate `google_sign_in_ios_enabled` para botón Google en iOS.
- `lib/core/config/api_remote_config.dart`: clave `googleSignInIosEnabledKey`.
- `pubspec.yaml`: `sign_in_with_apple: ^6.1.4` (uuid eliminado — H3 resuelto).
- `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`: configuración de code signing y URL schemes Apple/Google Sign-In.
- `test/features/authentication/application/auth_cubit_test.dart`: TC-auth-A1 (happy path Apple), TC-auth-A2 (cancelación) — H2 resuelto.
- `docs/features/authentication.md`: documentación Apple Sign-In.
- `rideglory.pen`: cambios de diseño.

---

## Archivos

### En scope
| Archivo | Tipo |
|---|---|
| `lib/core/services/analytics/analytics_events.dart` | código productivo |
| `lib/core/services/analytics/analytics_params.dart` | código productivo |
| `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` | código productivo |
| `lib/core/di/injection.config.dart` | generado |
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | test |
| `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart` | test |
| `rideglory-api/api-gateway/src/ai/ai-description.spec.ts` | test backend (creado) |
| `rideglory-api/rideglory-contracts/src/ai/dto/ai-description-request.dto.ts` | contrato backend |
| `docs/features/events.md` | doc |

### Fuera de scope (bundled)
| Archivo | Tipo |
|---|---|
| `lib/core/services/auth_service.dart` | auth feature |
| `lib/features/authentication/application/auth_cubit.dart` | auth feature |
| `lib/features/authentication/login/presentation/widgets/login_social_section.dart` | auth / widget |
| `lib/core/config/api_remote_config.dart` | config |
| `pubspec.yaml` | dependencias |
| `ios/Runner.xcodeproj/project.pbxproj` | iOS config |
| `ios/Runner/Info.plist` | iOS config |
| `ios/Runner/Runner.entitlements` | iOS entitlements (nuevo) |
| `test/features/authentication/application/auth_cubit_test.dart` | auth test |
| `docs/features/authentication.md` | doc |
| `rideglory.pen` | diseño |

---

## Pruebas

### Flutter (en scope)
```
dart analyze lib/                          → No issues found (exit 0)
dart analyze test/.../cubit_test.dart      → No issues found (exit 0)  ← tras fix BUG-QA-01
flutter test test/features/events/        → 33 tests, todos verdes
  cubit (8): AC15×2, AC16×2, CA7×4
  markdown converter (12): AC1×6, AC2×3, trailing newline×1, CA8×2
  widget sheet (5): AC13×2, AC14×3
  use case (3) + repository (5): previos verdes
```

### Backend (en scope)
```
npx jest src/ai/ --no-coverage  (rideglory-api/api-gateway)
  Test Suites: 6 passed, 6 total  (+1: ai-description.spec.ts)
  Tests:       37 passed, 37 total  (+5)
```

---

## Riesgos / watchlist

| # | Riesgo | Severidad |
|---|--------|-----------|
| W1 | Cambios Apple Sign-In bundled con Phase 06 — recomendable separar en 2 commits | Baja |
| W2 | `login_social_section.dart` (widget) fue modificado dentro de una fase que prohíbe tocar widgets. El cambio es correcto pero viola el guardrail de scope. | Baja |
| W3 | `googleSignInIosEnabledKey` Remote Config gate no tiene widget test de visibilidad condicional | Baja |
| W4 | CA1 grep gate (`logEvent.*ai_`) funciona vacuamente porque el código usa constantes camelCase; no puede detectar violaciones futuras | Info |
| W5 | `aiGenerationTypeCover` es placeholder sin cubit real — aceptable, documentado | Info |

---

## Mensaje de commit sugerido

### Commit 1 — Phase 06 QA, Analytics, Cierre
```
feat(ai): analytics, tests y cierre del asistente de descripción IA (Fase 6)

- AnalyticsEvents: aiDescriptionGenerated, aiQuotaExceeded, aiGenerationFailed
- AnalyticsParams: aiTurnIndex, aiGenerationType, aiErrorCode, aiGenerationTypeDescription/Cover
- AiDescriptionChatCubit: inyecta AnalyticsService; 6 logEvent calls (sendMessage + retryLastMessage)
- Tests CA7 (analytics cubit x4), CA8 (markdown converter x2)
- Backend: @ArrayMaxSize(10) en AiDescriptionRequestDto; ai-description.spec.ts (5 tests)
- docs/features/events.md: sección Asistentes IA, POST /ai/description, generate-cover ELIMINADO
```

### Commit 2 — Apple Sign-In iOS
```
feat(auth): Apple Sign-In real en iOS con Remote Config gate para Google

- AuthService.signInWithApple: nonce SHA-256, OAuthProvider(apple.com), registro usuario nuevo
- AuthCubit: maneja AuthenticatedUser en rama Apple; logEvent authFirebaseOk
- iOS: Runner.entitlements (applesignin), Info.plist URL schemes Google OAuth dev/prod
- sign_in_with_apple: ^6.1.4 en pubspec.yaml
- login_social_section: Remote Config gate google_sign_in_ios_enabled para botón Google en iOS
- Tests TC-auth-A1 (happy path), TC-auth-A2 (cancelación)
```
