# feat(iter-4): AI Event Cover Image Generation

## Stories delivered

| Story | Description | Status |
|-------|-------------|--------|
| US-4-1 | AI cover generation with loading overlay and 16:9 preview | ✅ Delivered |
| US-4-2 | Regenerate and custom image replacement flows | ✅ Delivered |
| US-4-3 | Backend `POST /events/generate-cover` (Claude Haiku + Unsplash) | ✅ Delivered |
| US-4-4 | `EventFormCubit` refactored to `@freezed EventFormState` with independent `coverGenerationResult` | ✅ Delivered |

## Stories deferred

- Cover image caching (v2)
- Alternative image sources beyond Unsplash (v2)
- Photo credits/Unsplash attribution display (v2)

## What changed

### Backend (`rideglory-api/api-gateway`)
- `POST /events/generate-cover` — new endpoint; accepts `{ title, eventType, city }`, calls Claude Haiku to generate a 3–5 word English Unsplash search query, fetches `results[0].urls.regular`, returns `{ imageUrl, source: "unsplash", query }`
- `ClaudeService` + `UnsplashService` — new common services (Anthropic SDK + axios)
- 15s timeout on Unsplash; 503 on Claude/Unsplash failure; 400 on bad request
- `UNSPLASH_ACCESS_KEY` added to `.env.example` and CI secrets

### Flutter (`lib/features/events/`)
- **Domain:** `EventCoverRepository` + `GetGenerateCoverUseCase`
- **Data:** `CoverGenerationDto`, `EventCoverService` (Retrofit), `EventCoverRepositoryImpl`
- **Presentation:** `EventFormState` (@freezed, two independent `ResultState` fields), `CoverPreviewWidget` (4 states: initial, loading overlay, preview + Regenerar, error SnackBar)
- **l10n:** 5 new `event_cover*` keys in `app_es.arb`

### Design
- 4 Pencil frames added in `pencil-new.pen` section "10 — Cover Generation (Iter 4)"
- 4 HTML mockups in `docs/design/html-mockups/iter-4/`

### DevOps
- `UNSPLASH_ACCESS_KEY` injected in CI (`analyze-and-test` + `build-apk` jobs)
- `docs/DEPLOY.md` updated with new secret

## Test results

| Suite | Result |
|-------|--------|
| Backend unit tests | 10/10 ✅ |
| Flutter unit tests (GetGenerateCoverUseCase) | 2/2 ✅ |
| Flutter widget tests | 7/7 ✅ (no regressions) |
| dart analyze | 0 new violations ✅ |

## Handoff links

- [PO handoff](docs/handoffs/po.md)
- [Architect handoff](docs/handoffs/architect.md)
- [Design handoff](docs/handoffs/design.md)
- [Backend handoff](docs/handoffs/backend.md)
- [Frontend handoff](docs/handoffs/frontend.md)
- [QA sign-off](docs/handoffs/qa.md)

---
🤖 Generated with [Claude Code](https://claude.ai/claude-code)
