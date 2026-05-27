# Iteration checkpoint (in-flight)

**Purpose:** Human-readable **resume trail**. After **each** phase completes, update this file in the same session as `workflow/state.json` → `phase_complete`. Powers quick orientation for `/resume-iter` when a run stops mid-way (tokens, crash, context limit).

**Machine-readable file trail:** `workflow/artifact_log.json` — agents append paths via `scripts/log_artifact.py` so resumes see every generated/changed file, including mid-phase.

**Not the same as** `docs/ITERATION_HISTORY.md` — that file is **append-only when an iteration fully closes** (`po_close`), not after every agent.

---

## Status: active — Iteration 6 (refactor-01)

**Current iteration:** 6
**Codename:** refactor-01 — Refactor & Cleanup Extremo
**Type:** REFACTORING ONLY — zero new features, zero API changes

**Last completed phase:** po_scope (PO)
**Next phase:** architect

**Phase sequence for refactor-01:**
1. ✅ `po_scope` — PO: 17 stories + 19 tasks written; handoff complete
2. ⬜ `architect` — API for AppFormNavHeader molecule; unnamed-route decisions; REFACTOR-12 confirmation
3. ⬜ `frontend` — 17 implementation tasks in linear order (T-6-1 → T-6-17)
4. ⬜ `qa` — T-6-18: baseline capture + DoD grep checks + 7 smoke tests + AI cover + Mapbox regressions
5. ⬜ `devops` — T-6-19: CI no-op verification on iter-6 branch
6. ⬜ `tech_lead` — code review; Clean Architecture compliance; DoD grep verification
7. ⬜ `po_close` — iteration summary, history, product status, next context

**Note:** Backend is fully stand-down this iteration. Design is light (AppFormNavHeader spec only — no Pencil frames, no HTML mockups).

*Last closed: —*
