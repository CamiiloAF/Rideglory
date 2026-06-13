# REVIEW CHECKLIST — observability-sentry-phase01

**Fecha (UTC):** 2026-06-11T20:35:54Z
**Estado:** APROBADO — listo para commit (segunda iteración, correcciones aplicadas)

Pasos de verificación manual antes de commitear.

---

## Verificación automatizada (ya pasada — confirmar con una corrida local)

```bash
# 1. Rebuild common-lib y correr tests
cd /Users/cami/Developer/Personal/rideglory-api/rideglory-common-lib
npm run build && npm test
# Esperado: 35 pass / 0 fail

# 2. Gateway unit + e2e observability
cd ../api-gateway
npx jest --forceExit
# Esperado: 98/98 unit
npx jest --config test/jest-e2e.json --testPathPatterns observability --forceExit
# Esperado: 6/6 e2e

# 3. Guardrails de scope
grep -r '@sentry/' api-gateway/src events-ms/src users-ms/src vehicles-ms/src maintenances-ms/src notifications-ms/src | grep -v node_modules
# → 0 resultados

grep -rn 'http-logger.middleware\|HttpLoggerMiddleware' api-gateway/src/
# → 0 resultados

git -C rideglory-contracts diff
# → 0 líneas
```

---

## Verificación manual (recomendada antes de deploy a producción)

```bash
# 1. AC-1 correlación cross-service
curl -H "x-request-id: test-trace-001" http://localhost:3000/api/health
# Gateway log: traceId: "test-trace-001"
# users-ms log: traceId: "test-trace-001" (via mixin)
# Response header: x-trace-id: test-trace-001

# 2. AC-4 formato prod
NODE_ENV=production node dist/src/main  # (api-gateway)
# stdout: JSON one-line por evento, sin pino-pretty

# 3. AC-5 PII en login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"secret123"}'
# Gateway logs: email y password aparecen como [REDACTED]

# 4. AC-11 Smoke ×6
# En cada servicio: node dist/src/main
# → 0 líneas con ERROR ni "No CLS context available" en primeros 5 seg
```

---

## Scope check: no incluir en este commit

Los siguientes archivos del working tree de Rideglory Flutter pertenecen a `event-form-stepper` y NO deben incluirse:

- `lib/features/events/presentation/form/cubit/event_form_cubit.dart`
- `lib/features/events/presentation/form/widgets/sections/details/difficulty_picker.dart` (deleted)
- `lib/features/events/presentation/form/widgets/sections/details/event_type_picker.dart` (deleted)
- `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart` (deleted)
- `lib/l10n/app_es.arb`, `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_es.dart`

El commit va en el repo `rideglory-api` (submodules dirty + `package-lock.json` raíz).

---

## Scope check: no incluir en este commit

Los siguientes archivos del working tree de Rideglory Flutter pertenecen a otra feature y NO deben incluirse:
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart`
- `lib/features/events/presentation/form/sections/details/difficulty_picker.dart` (deleted)
- `lib/features/events/presentation/form/sections/details/event_type_picker.dart` (deleted)
- `lib/features/events/presentation/form/sections/event_form_details_section.dart` (deleted)
- `lib/l10n/app_es.arb`, `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_es.dart`

Commitear solo los submodules del backend rideglory-api.
