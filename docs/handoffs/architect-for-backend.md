# Architect → Backend handoff — Iteration 4

**Date:** 2026-05-13
**Iteration:** 4 — AI Event Cover Image Generation

---

## Your deliverable

Implement `POST /events/generate-cover` in `api-gateway/src/events/events.controller.ts`.

---

## Endpoint spec

| | |
|--|--|
| Method | POST |
| Path | `/events/generate-cover` |
| Auth | Firebase ID token (already enforced by `FirebaseAuthGuard`) |
| Request body | `{ title: string, eventType: string, city: string }` |
| Success | HTTP 200 `{ imageUrl: string, source: "unsplash", query: string }` |
| Error — malformed | HTTP 400 (`BadRequestException`) |
| Error — Claude/Unsplash fails | HTTP 503 (`ServiceUnavailableException`) |
| Timeout | 15 s on Unsplash call |

---

## Implementation steps

1. **Create `ClaudeService`** in `api-gateway/src/common/claude.service.ts` (if not already from iter-3a):
   - Inject Anthropic Node.js SDK (`@anthropic-ai/sdk`)
   - Method `generateSearchQuery(title, eventType, city): Promise<string>`
   - Prompt: `"Generate a 3-5 word English search query for Unsplash to find a high-quality landscape photo for a motorcycle event. Event title: {title}. Event type: {eventType}. City: {city}. Return only the search query, nothing else."`
   - Model: `claude-haiku-4-5` (or latest Haiku alias)
   - On Anthropic SDK error → throw `ServiceUnavailableException`

2. **Create `UnsplashService`** in `api-gateway/src/common/unsplash.service.ts`:
   - Use `axios` (already in node_modules) for `GET https://api.unsplash.com/search/photos?query={query}&per_page=1&orientation=landscape`
   - Header: `Authorization: Client-ID ${process.env.UNSPLASH_ACCESS_KEY}`
   - 15 s timeout via axios `timeout` option
   - Return `results[0].urls.regular`
   - If no results or axios error → throw `ServiceUnavailableException`

3. **Add `@Post('generate-cover')` to `EventsController`**:
   - Validate body with class-validator DTO `GenerateCoverDto { title, eventType, city }` — all `@IsString() @IsNotEmpty()`
   - Call `ClaudeService.generateSearchQuery()` → query
   - Call `UnsplashService.searchPhoto(query)` → imageUrl
   - Return `{ imageUrl, source: 'unsplash', query }`

4. **Add `UNSPLASH_ACCESS_KEY` to `.env.example`** (placeholder only — never commit real key)

5. **Register both services in `EventsModule`**

---

## Unit tests required (T-4-2)

File: `api-gateway/test/events/generate-cover.spec.ts`

| Test | Expected |
|------|----------|
| Happy path | HTTP 200 `{ imageUrl, source: 'unsplash', query }` |
| Claude SDK throws | HTTP 503 |
| Unsplash axios throws | HTTP 503 |
| Unsplash 15 s timeout exceeded | HTTP 503 |
| Missing `title` in body | HTTP 400 |

---

## Change log

- 2026-05-13 (iter-4): New backend handoff. POST /events/generate-cover endpoint: ClaudeService (query gen) + UnsplashService (photo fetch).
