# Iteration checkpoint (in-flight)

**Purpose:** Human-readable **resume trail**. After **each** phase completes, update this file in the same session as `workflow/state.json` → `phase_complete`. Powers quick orientation for `/resume-iter` when a run stops mid-way (tokens, crash, context limit).

**Machine-readable file trail:** `workflow/artifact_log.json` — agents append paths via `scripts/log_artifact.py` so resumes see every generated/changed file, including mid-phase.

**Not the same as** `docs/ITERATION_HISTORY.md` — that file is **append-only when an iteration fully closes** (`po_close`), not after every agent.

---

## Status: active — Iteration 2

**Iteration goal:** Wire the existing filter bottom sheet to real backend query parameters and enable riders to navigate to other riders' profiles from the attendee list.

**Stories:** HU-EVENT-FILTER-01, HU-EVENT-FILTER-02, HU-ATTENDEE-PROFILE-01

| Phase | Agent | Status |
|-------|-------|--------|
| po_scope | po | complete |
| architect | architect | pending |
| design | design | pending |
| backend | backend | pending |
| frontend | frontend | pending |
| qa | qa | pending |
| devops | devops | pending |
| pr | system | pending |
| tech_lead | tech_lead | pending |
| po_close | po | pending |

**Last completed phase:** po_scope (3 user stories, 50 acceptance criteria, 10 tasks, 9 l10n keys)
**Next phase:** architect

*Last closed: Iteration 1 (PR #8 merged, tech_lead approved)*
