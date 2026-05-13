# Iteration Context Bridge — Iteration 5 & Beyond

**Generated:** 2026-05-13 (Iteration 4 close)

---

## State Handoff to Iteration 5

### What Works (No Rework Needed)

- ✓ **AI service pattern established:** ClaudeService (rideglory-api) for prompt execution; reusable in Iteration 5
- ✓ **Cover generation state machine:** `EventFormCubit` refactored to `@freezed EventFormState` with `ResultState<T>` fields; pattern template for Iteration 5 state design
- ✓ **DTO mapping for AI endpoints:** `CoverGenerationDto` shows how to structure backend response DTOs; follow same pattern for recommendations API
- ✓ **Unsplash API integration:** Free tier endpoint patterns documented in rideglory-api; error handling (15s timeout, 503 fallback) proven stable
- ✓ **ARB localization keys:** `event_` prefix namespace established; 5 keys created; add more under same prefix
- ✓ **Widget library extended:** `CoverPreviewWidget` (4-state UI), loading overlay patterns, `CachedNetworkImage` + `AspectRatio` layout proven
- ✓ **CI/CD secrets injection:** `UNSPLASH_ACCESS_KEY` injected via GitHub Secrets; Iteration 5 can add `CLAUDE_API_KEY` or `RECOMMENDATIONS_SECRET` via same pattern

### Deferred Work (Explicitly Out-of-Scope for v1)

- **Cover image caching:** Generated images re-fetched on each form open. Caching deferred to v2 (would require local disk/memory store + invalidation logic)
- **Alternative image sources:** Only Unsplash. Pexels, Pixabay, other APIs deferred to v2
- **Claude prompt refinement:** Fixed prompt in Iteration 4. A/B testing of different prompt variations deferred to v2
- **Exif metadata / photo credits:** Generated images not inspected for photographer credits or license details; Unsplash attribution not displayed in app
- **SOAT document management:** Backend schema + Flutter domain/data incomplete; full UI (with multi-step upload flow + badges) deferred post-4
- **Push notifications:** FCM infrastructure designed but APNs key + iOS capability not yet configured; scheduled for Iteration 6
- **Profile photo upload:** `profilePhotoUrl` not in Prisma User schema; requires DB schema change + backend endpoint; post-6b feature
- **Organizer SOS dismiss:** Only SOS sender can cancel in v1; organizer/admin cancellation deferred to v2

---

## Known Blockers & Tech Debt

### No Blockers at Close
✓ Iteration 4 shipped cleanly. All stories merged. Zero blocking bugs.

### Low-Priority Tech Debt (Can Fix Anytime)

| Item | Severity | Effort | Notes |
|------|----------|--------|-------|
| `withOpacity` deprecation (34 instances) | Info | M | Pre-existing in `lib/shared/widgets/`. Batch refactor to `.withValues()` in dedicated cleanup PR. Not blocking any feature. |
| `_PlaceholderView` private widget in `cover_preview_widget.dart` | Style | XS | One-widget-per-file rule slightly bent. Widget is 30 lines and private; extract if grows beyond 50 lines. Acceptable deferred. |
| Test automation for widget states | QA | M | `CoverPreviewWidget` states verified via code review (manual). Automate with golden images or visual regression tests in v2. |

---

## Iteration 5 Preparation Checklist

### For PO (Next Iteration Start)
- [ ] Read Iteration 4 ITERATION_SUMMARY_4.md and verify shipped features
- [ ] Review deferred list above; prioritize for post-v1 roadmap
- [ ] Clarify Iteration 5 recommendations algorithm with product team (deterministic score v1)
- [ ] Schedule design review with design agent for Iteration 5 home dashboard recommendations card

### For Architect (Before Frontend/Backend Handoff)
- [ ] Review Iteration 4 architecture decisions (ADRs 7–9); apply patterns to Iteration 5
- [ ] Define `RecommendationDto` shape for backend `GET /events/recommendations` endpoint
- [ ] Define Iteration 5 `HomeRecommendationsCubit` state machine (likely `@freezed` with `ResultState<List<RecommendationModel>>`)
- [ ] ADR-10 (optional): Deterministic vs. personalized scoring trade-offs; document decision

### For Backend (Iteration 5 Start)
- [ ] Implement `GET /events/recommendations?userId={id}` endpoint in events-ms or new recommendations-ms
- [ ] Scoring algorithm: distance (city radius) + vehicle type match + event type preference (profile data)
- [ ] Return JSON: `[ { eventId, eventName, coverImageUrl, score, reason } ]`
- [ ] Add rate limiting to prevent abuse (e.g., 30 req/min per user)
- [ ] Unit tests: happy path (user with profile) + edge cases (new user, no preferences)

### For Frontend (Iteration 5 Start)
- [ ] Implement `GetRecommendationsUseCase` (domain)
- [ ] Implement `RecommendationService` (Retrofit) + `RecommendationDto` (data)
- [ ] Implement `HomeRecommendationsCubit` (presentation)
- [ ] Build `RecommendationCardWidget` (4-state UI: idle, loading, data, error)
- [ ] Wire to `HomePage`; add new localization keys (`home_recommendations_title`, `home_empty_recommendations`)
- [ ] Update existing tests to verify recommendation state integration

### For QA (Iteration 5 Start)
- [ ] Write backend unit tests (happy path + 4 error scenarios)
- [ ] Write frontend unit tests (`GetRecommendationsUseCase` happy + error)
- [ ] Write widget tests for `RecommendationCardWidget` (all states)
- [ ] Verify no lint regressions (`dart analyze`, `npm run lint`)
- [ ] Verify `flutter test` and `npm run test` pass

### For DevOps (Iteration 5 Start)
- [ ] No new secrets expected (recommendations endpoint likely internal to rideglory-api)
- [ ] Update CI/CD if any new env vars needed
- [ ] Update DEPLOY.md with recommendations feature summary

---

## Localization Keys Added (Reference for Iteration 5)

**Iteration 4 keys (do not modify):**
```
event_coverGenerating
event_coverGenerated
event_coverGenerateError
event_coverRegenerate
event_coverGeneratingOverlay
```

**Iteration 5 should add (estimate):**
```
home_recommendationsTitle = "Eventos para ti"
home_recommendationsSubtitle = "Basado en tu perfil"
home_emptyRecommendations = "No hay eventos recomendados. Explora más."
home_recommendationError = "No pudimos cargar recomendaciones"
home_recommendationCard_distance = "{distance} km"
home_recommendationCard_date = "Evento en {days} días"
```

---

## Change log

- **2026-05-13 23:59:59Z** — Generated at Iteration 4 close. Iteration 5 recommendations feature setup, deferred work documented, tech debt backlog, API contracts carry-forward, localization keys reference.
