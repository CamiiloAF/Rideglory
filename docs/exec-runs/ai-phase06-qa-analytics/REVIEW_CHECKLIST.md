# REVIEW CHECKLIST — ai-phase06-qa-analytics

**Tech Lead re-revisión:** 2026-06-10T22:55:20Z
**Estado:** Revisión 2 — todos los blockers de rev 1 resueltos

---

## Blockers resueltos (ya no son bloqueantes)

| Blocker (rev 1) | Estado |
|---|---|
| B1 — HTTP 402 incorrecto en docs → debe ser 429 | RESUELTO: docs/features/events.md ya muestra `429` |
| B2 — Apple sign-in bundled sin tests | RESUELTO: TC-auth-A1 y TC-auth-A2 añadidos en `auth_cubit_test.dart` |
| B3 — uuid declarado sin usar | RESUELTO: eliminado de `pubspec.yaml` |
| BUG-QA-01 — 3 prefer_const_constructors en test code | RESUELTO: corregido por Tech Lead en rev 2 (const Left) |

---

## Pendientes antes de commitear

### P1 — Separar commits (recomendado)

El árbol de trabajo contiene dos concerns independientes. Commitear por separado mejora trazabilidad:

**Commit 1 (Phase 06):** archivos en-scope únicamente:
- `lib/core/services/analytics/analytics_events.dart`
- `lib/core/services/analytics/analytics_params.dart`
- `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart`
- `lib/core/di/injection.config.dart`
- `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart`
- `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart`
- `docs/features/events.md`

**Commit 2 (Apple Sign-In):** resto de archivos:
- `lib/core/services/auth_service.dart`
- `lib/features/authentication/application/auth_cubit.dart`
- `lib/features/authentication/login/presentation/widgets/login_social_section.dart`
- `lib/core/config/api_remote_config.dart`
- `pubspec.yaml`
- `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`, `ios/Podfile.lock`
- `test/features/authentication/application/auth_cubit_test.dart`
- `docs/features/authentication.md`
- `rideglory.pen`

---

## Verificaciones automáticas (re-ejecutar antes de commitear)

- [ ] `dart analyze lib/` → exit code 0, "No issues found"
- [ ] `dart analyze test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` → "No issues found" (BUG-QA-01 corregido)
- [ ] `flutter test test/features/events/` → exit code 0, todos verdes
- [ ] `flutter test test/features/authentication/` → exit code 0, todos verdes
- [ ] `cd rideglory-api/api-gateway && npx jest src/ai/ --no-coverage` → 37/37
- [ ] `grep -rn "logEvent.*ai_" lib/ --include="*.dart"` → solo resultados en `*_cubit.dart`
- [ ] `grep -c "ai_error_quota_exceeded_user" lib/l10n/app_es.arb` → devuelve exactamente `1`
- [ ] `grep "aiImageGenerated\|aiCoverUsed" lib/core/services/analytics/analytics_events.dart` → sin resultados
- [ ] `grep "uuid" pubspec.yaml` → sin resultados (uuid eliminado)

---

## Verificación manual en dispositivo (tras deploy dev)

1. **Analytics happy path:** Abrir asistente de descripción, enviar mensaje → Firebase DebugView: `ai_description_generated` con `ai_turn_index: 2`.
2. **Analytics quota:** Agotar cuota diaria → `ai_quota_exceeded` con `ai_generation_type: description`, `ai_error_code: AiQuotaExceededUserException`.
3. **Analytics safety:** Prompt que active safety filter → `ai_generation_failed` con `ai_error_code: AiSafetyBlockedException`.
4. **Backend DTO validation:** `POST /api/ai/description` con `history` de 11 turnos → respuesta `400`.
5. **Apple Sign-In iOS:** Dispositivo real iOS, cuenta Apple nueva → usuario creado correctamente con displayName.
6. **Apple Sign-In iOS reinicio:** Misma cuenta → no crea duplicado, carga datos existentes.
7. **Google Sign-In iOS:** Verificar que el botón Google aparece en iOS solo cuando `google_sign_in_ios_enabled = true` en Remote Config.
