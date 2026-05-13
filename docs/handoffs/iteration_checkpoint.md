# Iteration checkpoint — Iteration 4 (AI Event Cover Image Generation)

**Purpose:** Human-readable resume trail. After each phase completes, update this file in the same session as `workflow/state.json` → `phase_complete`. Powers `/resume-iter`.

---

## Status: in-flight — Iteration 4

**Goal:** Wire 'Generar portada con IA' button to backend endpoint using Claude Haiku + Unsplash API to generate relevant event cover images.

| Phase | Agent | Status | Completed |
|-------|-------|--------|-----------|
| po_scope | po | ✓ complete | 2026-05-13T01:15:30Z |
| architect | architect | ✓ complete | 2026-05-13T02:30:30Z |
| design | design | ✓ complete | 2026-05-13T03:30:00Z |
| backend | backend | pending | — |
| frontend | frontend | pending | — |
| qa | qa | pending | — |
| devops | devops | pending | — |
| pr | system | pending | — |
| tech_lead | tech_lead | pending | — |
| po_close | po | pending | — |

**Last completed phase:** design (design)
**Next phase:** backend

*Started: 2026-05-13T00:45:41Z*

---

## PO Phase Summary (just completed)

**Iteration:** 4 — AI Event Cover Image Generation

**Deliverables:**
- ✓ `docs/handoffs/po.md` — Iteration 4 PO handoff document (iteration goal, 4 user stories, task breakdown, assumptions, scope decisions, dependencies)
- ✓ `workflow/state.json` — 10 iteration 4 tasks (T-4-1 through T-4-10) added with pending status; po_plan + phase_complete events recorded
- ✓ `docs/handoffs/contracts/iter-4/po_scope.json` — Phase contract (status: pass, 5 quality gates, metrics)
- ✓ `.claude/skills/po-skill.md` — Updated changelog (2 lines appended)

**User Stories Defined (4 total):**
1. US-4-1: AI cover generation with loading and preview
2. US-4-2: Regenerate and custom image replacement
3. US-4-3: Backend cover generation endpoint (Claude Haiku + Unsplash)
4. US-4-4: EventFormCubit state refactor for cover generation

**Tasks Created (10 total):**
- Backend: T-4-1 (endpoint implementation), T-4-2 (unit tests)
- Frontend: T-4-3 (cubit refactor), T-4-4 (use case + service + DTO), T-4-5 (button wiring), T-4-6 (preview UI), T-4-7 (ARB keys)
- QA: T-4-8 (use case tests), T-4-9 (widget tests), T-4-10 (QA gate)

**Quality Gates (all pass):**
- ✓ required_artifacts_present: po.md, state.json, contract present and complete
- ✓ scope_defined: 4 stories with acceptance criteria, in-scope/out-of-scope clearly delineated
- ✓ user_stories_clear: All 4 stories written in mobile interaction language with testable criteria
- ✓ task_breakdown_complete: 10 tasks created, all mapped to stories and agents
- ✓ dependencies_documented: Depends on Iter-3a (ClaudeService); no design gate

---

## What Comes Next

**Immediate (Next Phase: architect):**
- **Architect:** Review Iteration 4 PO handoff; confirm technical feasibility; produce architecture contracts (backend DTO shape, frontend `EventFormState` freezed class, service/use case interfaces); document ADRs
- **Backend agent:** Implement `POST /events/generate-cover` endpoint (Claude Haiku query → Unsplash API → return imageUrl)
- **Frontend agent:** Refactor `EventFormCubit` to `@freezed EventFormState`; implement use case + service + DTO; wire button and preview UI
- **QA agent:** Write backend unit tests (happy path + error paths), frontend use case tests, widget tests for cover generation UI

**Assumptions for Architect & Engineers:**
- Iteration 3a (ClaudeService) is complete and working
- EventFormCubit and EventFormPage pre-exist from earlier iterations
- No Pencil design gate for Iteration 4 (unlike 3b)
- Unsplash free API tier sufficient for pilot usage (50 req/hour)
- 16:9 aspect ratio matches existing event list card ratio

**Context for Backend Agent:**
- Reuse existing `ClaudeService` (from Iter 3a) to generate Unsplash search query
- Prompt: "Given this motorcycle event — title: {title}, type: {eventType}, city: {city} — generate a 3–5 word English phrase to search for a relevant background photo on Unsplash. Return only the phrase, nothing else."
- Call Unsplash API: `GET /search/photos?query={query}&per_page=1&orientation=landscape`
- Return: `{ imageUrl: string, source: "unsplash", query: string }`
- Error handling: 503 on Claude fail, Unsplash fail, or timeout (15s limit)
- Environment variable: `UNSPLASH_ACCESS_KEY` in `.env.example` and CI secrets
