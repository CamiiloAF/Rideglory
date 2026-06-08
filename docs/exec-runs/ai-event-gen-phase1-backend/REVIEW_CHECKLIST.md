# Review Checklist — ai-event-gen-phase1-backend

**Timestamp:** 2026-06-05T22:59:24Z

Pasos manuales antes de commitear. Los tests automatizados ya pasaron (78/78).

---

## Pre-commit (automatizado — ya ejecutado)

- [x] `cd api-gateway && npx jest` → 78/78 PASS
- [x] `cd rideglory-contracts && npm run build` → exit 0
- [x] `cd api-gateway && npm run build` → exit 0
- [x] `dart analyze` en Flutter → No issues found
- [x] BUG-1 corregido: `gemini.service.ts:71` — ternario `SAFETY_BLOCKED ? SAFETY_BLOCKED : NETWORK_ERROR`

---

## Manual con servidor corriendo

Requiere `GEMINI_API_KEY` real y token Firebase válido.

- [ ] **401 sin token**: `POST /ai/description` sin `Authorization` → 401 Unauthorized
- [ ] **400 body inválido**: body sin `eventContext.title` → 400 Bad Request
- [ ] **200 success**: body completo válido → `{ "markdown": "...", "remainingGenerations": -1 }`
- [ ] **Sin regresión generate-cover**: `POST /events/generate-cover` sigue funcionando

---

## Variables de entorno

- [ ] `GEMINI_API_KEY` agregada a `.env` local (api-gateway)
- [ ] `GEMINI_API_KEY` agregada a los secrets del entorno de producción / staging
- [ ] `GEMINI_TEXT_MODEL` (opcional — default `gemini-2.5-flash`)

---

## Commits a crear (en orden)

1. `rideglory-contracts/` — contratos AI nuevos + `src/index.ts`
2. `api-gateway/` — AiModule + GeminiService + tests + .env.example + package.json
3. `rideglory-api/` (root) — bump submodule pointers
