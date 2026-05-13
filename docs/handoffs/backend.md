# Backend handoff — Iteration 4

**Date:** 2026-05-13
**Status:** complete
**Agent:** backend

---

## Deliverable

`POST /events/generate-cover` implemented and tested in `api-gateway`.

---

## Files changed (rideglory-api)

| File | Action |
|------|--------|
| `api-gateway/src/common/claude.service.ts` | Created — Anthropic SDK wrapper, `generateSearchQuery()` |
| `api-gateway/src/common/unsplash.service.ts` | Created — axios HTTP wrapper, `searchPhoto()`, 15 s timeout |
| `api-gateway/src/events/dto/generate-cover.dto.ts` | Created — `GenerateCoverDto` with class-validator decorators |
| `api-gateway/src/events/events.controller.ts` | Updated — `@Post('generate-cover')` endpoint added before `@Post()` |
| `api-gateway/src/events/events.module.ts` | Updated — `ClaudeService` and `UnsplashService` registered as providers |
| `api-gateway/.env.example` | Created — includes `ANTHROPIC_API_KEY` and `UNSPLASH_ACCESS_KEY` placeholders |
| `api-gateway/src/events/generate-cover.spec.ts` | Created — 10 unit tests covering all required paths |

---

## Endpoint contract

```
POST /api/events/generate-cover
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

Body:   { "title": string, "eventType": string, "city": string }

200:    { "imageUrl": string, "source": "unsplash", "query": string }
400:    Missing or empty field (class-validator enforced by global ValidationPipe)
503:    Claude SDK error OR Unsplash axios error OR 15 s timeout exceeded
```

---

## Architecture notes

- `ClaudeService` and `UnsplashService` are registered in `EventsModule` as standard NestJS providers (no global module needed — only events endpoint uses them).
- Firebase auth guard applies globally; the new endpoint is protected without extra decoration.
- Axios timeout is set to `15_000 ms` via the `timeout` option in the axios GET call.
- All external errors (Anthropic, axios network, axios timeout, empty Unsplash results) are mapped to `ServiceUnavailableException` (HTTP 503).
- No env validation schema changes were needed — both new keys are read directly from `process.env` inside the services (consistent with `GOOGLE_PLACES_API_KEY` pattern).

---

## Test results

```
Test Suites: 1 passed, 1 total
Tests:       10 passed, 10 total
```

Test coverage:
1. Happy path — HTTP 200 `{ imageUrl, source: 'unsplash', query }` ✓
2. Claude SDK throws — HTTP 503 ✓
3. Unsplash axios throws — HTTP 503 ✓
4. Unsplash 15 s timeout — HTTP 503 ✓
5. Missing `title` in body — HTTP 400 (ValidationPipe) ✓
6. Missing `eventType` in body — HTTP 400 ✓
7. Missing `city` in body — HTTP 400 ✓
8. ClaudeService unit — Anthropic SDK error → ServiceUnavailableException ✓
9. UnsplashService unit — axios throws → ServiceUnavailableException ✓
10. UnsplashService unit — empty results → ServiceUnavailableException ✓

---

## New env vars required

| Variable | Where | Notes |
|----------|-------|-------|
| `ANTHROPIC_API_KEY` | api-gateway `.env` | Anthropic Console — never commit |
| `UNSPLASH_ACCESS_KEY` | api-gateway `.env` | Unsplash Developer Dashboard — never commit |

---

## Handoff to frontend

Frontend needs to call `POST /api/events/generate-cover` with `{ title, eventType, city }` from the event form. The response shape is `{ imageUrl: string, source: "unsplash", query: string }`. On HTTP 503 or network error, display Spanish error SnackBar per US-4-1 AC #7.

---

## Change log

- 2026-05-13 (iter-4): Initial backend handoff. POST /events/generate-cover implemented. ClaudeService + UnsplashService created. 10 unit tests all pass. Zero lint errors in new code.
