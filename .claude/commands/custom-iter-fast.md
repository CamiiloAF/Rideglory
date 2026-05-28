---
description: Run the full agent SDLC for ANY improvement PRD in one fast pass — a light Phase 0 normalizes any raw note into the required structure (no heavy PO repo-walk), then Architect → [Design] → [Backend] → [Frontend] → QA → Tech Lead (+close). No commits, no PR, no protected-file writes.
allowed-tools: Agent, Read, Write, Bash, Glob, Grep
---

**Source improvement PRD (any format): $ARGUMENTS**

You are the **Custom-Iter-Fast orchestrator**. Input is a _path_ to an improvement note in **any** shape — a one-liner, a rough sketch, or an already-normalized PRD. A light **Phase 0 (PRD Normalize)** turns it into the canonical `PRD_NORMALIZED.md` in one cheap step (no exhaustive repo walk — the Architect already reads the code authoritatively in Phase 1). You skip the heavy `/custom-iter` PO phase and the PO close-out; Tech Lead absorbs the close.

How this differs from `/custom-iter`:

1. **Phase 0 normalize is lightweight and inline** — it structures §1–§3, §5–§9 from the raw note + product constraints and leaves §4 (Affected areas / exact code paths) for the Architect to fill from the real code. `/custom-iter`'s PO walks the whole repo first; fast does not.
2. **No PO close-out.** Tech Lead writes `REVIEW_CHECKLIST.md` + `SUMMARY.md` alongside its technical review.
3. **Architect sets `_meta.json.decisions`** (gates Design / Backend / Frontend), reading `PRD_NORMALIZED.md`.

Everything else (no commits, no PR, workspace isolation under `docs/custom-iters/<SLUG>/`, protected-file rules, two-cycle fix cap) is identical to `/custom-iter`.

**Token discipline (super-optimized):** the raw source PRD is read in full **once** (Phase 0 only). Every later phase reads `PRD_NORMALIZED.md` (small, structured) — and the heavy phases read the Architect's slim handoff first, opening the full normalized PRD only to resolve a specific ambiguity. Inherited product constraints come from `docs/handoffs/prd-digest.md` (latest `/iter` digest) when it exists, not the full `docs/PRD.md`.

---

## Pre-flight (you execute this directly before spawning any agent)

1. **Resolve the source PRD path:**
   - `SOURCE_PRD = $ARGUMENTS` (treat as repo-relative if not absolute).
   - `test -f "$SOURCE_PRD"` — if missing, stop and tell the human the exact path tried.
   - **Sanity check only:** the file is non-empty and describes a concrete change (`test -s "$SOURCE_PRD"` and a quick skim). Do **not** require it to be pre-normalized — Phase 0 normalizes any shape. Do not read it fully here; Phase 0 owns the deep read.

2. **Derive `SLUG`:**
   - Basename without `.md`, lowercase, replace `_` with `-`. Strip a leading `improvement-prd-` if present. Example: `custom_iterations/improvement-prd-total-mt-sync-and-card-ux.md` → `total-mt-sync-and-card-ux`.

3. **Resolve workspace:**
   - `WORKSPACE = docs/custom-iters/<SLUG>`
   - If `WORKSPACE` exists with `_meta.json.status` in {`ready_for_human_review`, `in_progress`}: stop and tell the human.
   - Otherwise create the skeleton:
     ```bash
     mkdir -p docs/custom-iters/<SLUG>/handoffs
     mkdir -p docs/custom-iters/<SLUG>/contracts
     mkdir -p docs/custom-iters/<SLUG>/analysis
     ```

4. **Read project context (minimal, read-only — do NOT load the whole state file):**
   - `python3 -c "import json,sys;d=json.load(open('workflow/state.json'));print(d.get('project','') or 'this project');print((d.get('existingSystem') or {}).get('basePath',''))"`
   - Line 1 → **PROJECT**, line 2 → **EXISTING_BASE** (may be empty).
   - **You do NOT modify `workflow/state.json`** at any point.

5. **Working tree check:**
   - `git status --short` — if dirty, warn and ask the human to confirm. If yes, record the pre-existing state in `_meta.json`.

6. **Initialize `_meta.json`:**
   Write `docs/custom-iters/<SLUG>/_meta.json`:

   ```json
   {
     "slug": "<SLUG>",
     "sourcePrdPath": "<SOURCE_PRD>",
     "project": "<PROJECT>",
     "existingBase": "<EXISTING_BASE or empty>",
     "startedAt": "<ISO UTC now>",
     "status": "in_progress",
     "flow": "custom-iter-fast",
     "phaseLog": [],
     "decisions": {
       "uiChanges": null,
       "backendChanges": null,
       "frontendChanges": null,
       "dbChanges": null,
       "needsDesign": null
     },
     "preExistingDirtyTree": <true|false>
   }
   ```

7. **Print the gate to the user:**
   ```
   ▶ /custom-iter-fast — <SLUG>
     source: <SOURCE_PRD>  (any shape — Phase 0 normalizes)
     workspace: docs/custom-iters/<SLUG>/
     flow: Normalize ➜ Architect ➜ [Design] ➜ [Backend] ➜ [Frontend] ➜ QA ➜ Tech Lead (+close)
     ─ no commits, no push, no PR
     ─ Backend/Frontend will modify code in place; you review with `git diff`
   ```

---

## Helper: phase contract for fast runs

Every phase agent writes `docs/custom-iters/<SLUG>/contracts/<phase>.json`:

```json
{
  "slug": "<SLUG>",
  "phase": "<phase_key>",
  "status": "pass|fail",
  "updatedAt": "<ISO UTC>",
  "summary": "<one-line>",
  "metrics": { "tokens": 0, "costUsd": 0.0 },
  "artifacts": ["<repo-relative path>", "..."],
  "qualityGates": [
    { "name": "required_artifacts_present", "status": "pass", "detail": "..." },
    { "name": "no_protected_files_touched", "status": "pass", "detail": "..." }
  ]
}
```

After every phase, append to `_meta.json.phaseLog`:

```json
{
  "phase": "<phase_key>",
  "agent": "<role>",
  "at": "<ISO UTC>",
  "summary": "<one-line>"
}
```

---

## Hard rules every phase agent must follow (paste verbatim into every prompt)

```
HARD RULES — do NOT violate any of these:

1. NEVER run: `git add`, `git commit`, `git push`, `git merge`, `git rebase`, `git restore`, `git reset`, `gh pr create`, `gh pr merge`, `gh pr review`.
2. NEVER modify any of these files:
   - docs/PRD.md
   - docs/PLAN.md
   - docs/PLAN_FEEDBACK.md
   - docs/ITERATION_HISTORY.md
   - docs/PRODUCT_STATUS.md
   - docs/DEPLOY.md
   - docs/handoffs/iteration_checkpoint.md
   - docs/handoffs/iteration_context.md
   - docs/handoffs/<role>.md  (those belong to /iter; use docs/custom-iters/<SLUG>/handoffs/<role>.md instead)
   - workflow/state.json
   - workflow/artifact_log.json
   - any file under .claude/skills/
   - the raw source PRD at $ARGUMENTS (read-only for EVERY agent including Phase 0 — only Phase 0 reads it in full; the run's contract is `docs/custom-iters/<SLUG>/PRD_NORMALIZED.md`, not the raw file)
3. Write all analysis artifacts under `docs/custom-iters/<SLUG>/`.
4. Backend / Frontend agents (only) MAY modify application source code (apps/, src/, etc.) to implement the improvement. They MUST NOT commit.
5. Read your role playbook at `.claude/agents/<role>.md` for general guidance, but the OUTPUT LOCATIONS for this run are the ones in this prompt — they OVERRIDE the playbook's default paths.
6. If something in the playbook conflicts with these rules, the rules win. Surface the conflict in your handoff under `## Notes for orchestrator`.
7. End your run by writing the phase contract at `docs/custom-iters/<SLUG>/contracts/<phase>.json` with status `pass` or `fail`. Do not write a summary event to workflow/state.json.
```

---

## Phase 0 — PRD Normalize (light, one-step) | model: sonnet

Turns ANY raw note at `<SOURCE_PRD>` into the canonical `PRD_NORMALIZED.md`. **Light by design:** it does NOT walk the whole repo (that is the expensive thing `/custom-iter`'s PO does and the reason the fast flow exists). §4 (exact code paths) is seeded best-effort and explicitly handed to the Architect, who reads the real code authoritatively in Phase 1.

Spawn an Agent with:

- **description:** `"[Normalize / sonnet] — PRD_NORMALIZED for <SLUG>"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the PRD Normalizer for the /custom-iter-fast run on <SLUG> (project: <project>). One fast pass — no exhaustive repo scan.

Raw source PRD (read-only): <SOURCE_PRD>
Workspace: docs/custom-iters/<SLUG>/

<HARD RULES BLOCK — paste verbatim>

CONTEXT — read in this order:
1. <SOURCE_PRD> — read in FULL (you are the ONLY phase that does). This is the human's raw input, any shape.
2. scripts/templates/improvement-prd.md — the exact structure your output must follow.
3. docs/handoffs/prd-digest.md — if it exists, use it for §8 inherited constraints. ONLY if absent, read docs/PRD.md (do NOT modify it).
4. A SHALLOW orientation only: `git ls-files` + at most a few `grep`/`glob` lookups for the concrete terms the note names — just enough to make §4 plausible. Do NOT open and trace modules; that is the Architect's job in Phase 1.

YOUR WORK — write `docs/custom-iters/<SLUG>/PRD_NORMALIZED.md` from `scripts/templates/improvement-prd.md`:
- §1 Source / §2 Goal (one sentence) / §3 Why now — from the raw note.
- §4 Affected areas — best-effort from the note + shallow lookup. Mark the table header note: "Architect to verify/expand every row against the real code in Phase 1." Do NOT fabricate exact line numbers.
- §5 Out of scope — explicit; infer conservatively if the note is silent.
- §6 Acceptance criteria — numbered, testable, observable. **If the raw note already has good AC, preserve them verbatim.** If it has none, derive them from the goal. This section is mandatory and non-empty.
- §7 Regression guardrails — list flows/endpoints/screens near the change that must not break.
- §8 Constraints inherited from the product — from prd-digest.md (or docs/PRD.md): auth, stack, security, perf budgets relevant to this change.
- §9 Open questions — anything you could not resolve; record the assumption taken so the flow never blocks.
- If the raw note is ALREADY normalized (already follows the template with non-empty §6), do a light clean/validate pass instead of rewriting — keep the human's content.

REQUIRED OUTPUTS:
- docs/custom-iters/<SLUG>/PRD_NORMALIZED.md  (non-empty §6 mandatory)
- Append a phaseLog row to docs/custom-iters/<SLUG>/_meta.json: { "phase": "normalize", "agent": "po", "at": "<ISO UTC>", "summary": "<one-line: normalized N AC, M guardrails>" }
- docs/custom-iters/<SLUG>/contracts/normalize.json  (phase contract; qualityGates include required_artifacts_present + no_protected_files_touched)

DO NOT:
- Modify the raw source PRD ($ARGUMENTS) or docs/PRD.md or workflow/state.json or .claude/skills/*.
- Do a deep repo trace. Stay shallow — the Architect owns code analysis.
- Commit anything.
```

Wait for Normalize. Verify `docs/custom-iters/<SLUG>/PRD_NORMALIZED.md` exists with a non-empty `## 6. Acceptance criteria`. If missing/empty, stop and surface to the human (the note may be too vague even for fast — suggest `/custom-iter`).

From here on, **`NORMALIZED_PRD = docs/custom-iters/<SLUG>/PRD_NORMALIZED.md`** is the run contract. No phase reads the raw `<SOURCE_PRD>` again.

---

## Phase 1 — Architect | model: opus

Spawn an Agent with:

- **description:** `"[Architect / opus] — change map for <SLUG> (fast)"`
- **model:** `"opus"`
- **prompt:**

```
You are the Architect agent for the /custom-iter-fast run on <SLUG> (project: <project>).

Workspace: docs/custom-iters/<SLUG>/
Run contract: docs/custom-iters/<SLUG>/PRD_NORMALIZED.md  (Phase 0 output; the raw source PRD is NOT read here)

<HARD RULES BLOCK — paste verbatim>

⚠️ FAST-FLOW NOTE: Phase 0 produced PRD_NORMALIZED.md — that is the contract. Its §4 is best-effort and explicitly yours to verify/expand against the real code. You ALSO own setting `_meta.json.decisions.{uiChanges, backendChanges, frontendChanges, dbChanges, needsDesign}` FIRST — orchestrator uses these to gate Design / Backend / Frontend. Be decisive: read §4 (Affected areas), §6 (AC), §5 (Out of scope), then commit to the flags.

CONTEXT — read in this order:
1. docs/custom-iters/<SLUG>/PRD_NORMALIZED.md — the contract. Read in full.
2. .claude/agents/architect.md — sections [general] and [impl]. IGNORE its default output paths; use workspace paths below.
3. docs/handoffs/prd-digest.md — inherited product constraints (latest /iter digest). ONLY if absent, read docs/PRD.md in full. Do NOT modify either.
4. docs/architecture/DIAGRAMS.md — current ERD / data model (read-only). For sequence/flow context read docs/architecture/DIAGRAMS-flows.md. Do NOT modify the global files; propose diagram changes in `docs/custom-iters/<SLUG>/analysis/DIAGRAMS_PROPOSED.md`.
5. docs/handoffs/architect.md — read-only, existing architectural decisions.
6. .claude/skills/architect-skill.md — read-only.
7. The actual code at every path PRD_NORMALIZED.md §4 names — open each, trace dependencies, and CORRECT §4 against reality (it was seeded shallow by Phase 0).

YOUR WORK:
1. **Decide and write `_meta.json.decisions` FIRST** — read the PRD, then set the 5 booleans honestly. Append a phaseLog row noting the decisions.
2. Produce a **change map**: every file you propose to modify or create, with one-line "what changes and why". Include data migrations, env vars, contracts. This is the master list — Backend/Frontend will only touch files that appear here.
3. Identify **risks**: per-file breaking-change risk, backward compat, perf, security.
4. Define the **regression test surface**: which existing tests cover the changed code today; gaps to fill.
5. If schema / migration is needed: write the migration plan in `analysis/MIGRATION_PLAN.md`. Do NOT execute migrations.
6. If new env vars / config required: list them in `analysis/ENV_DELTA.md`. Do NOT write to `.env.example` directly.
7. Write slim handoffs (≤120 lines each):
   - `docs/custom-iters/<SLUG>/handoffs/architect-for-backend.md` (only if decisions.backendChanges)
   - `docs/custom-iters/<SLUG>/handoffs/architect-for-frontend.md` (only if decisions.frontendChanges)
   - `docs/custom-iters/<SLUG>/handoffs/architect-for-qa.md`
   Each starts with: `> Slim handoff for /custom-iter-fast <SLUG>. Full detail in architect.md (read only if ambiguous).`
8. Write `docs/custom-iters/<SLUG>/handoffs/architect.md` containing:
   - `## Goal acknowledgement` — confirm goal from PRD §2
   - `## Decisions set` — list of 5 flags + rationale per flag
   - `## Change map` — table: file | action | reason | risk
   - `## Data model impact` — ERD delta or "none"
   - `## Contract impact` — API/contract changes per endpoint, or "none"
   - `## Env / config delta` — new vars or "none"
   - `## Risk register` — numbered risks + mitigation
   - `## Regression test surface` — current coverage + gaps
   - `## Implementation order` — ordered steps Backend/Frontend follow
   - `## Open questions resolved` — for every Q in PRD §9, state the decision taken (use the PRD's recommended assumption if no human input)
   - `## Out of scope` — what you intentionally did NOT change
   - `## Notes for orchestrator` — any phase flag flips or surprises
9. Update `_meta.json.phaseLog` (append "architect").
10. Write phase contract `docs/custom-iters/<SLUG>/contracts/architect.json`.

REQUIRED OUTPUTS:
- docs/custom-iters/<SLUG>/handoffs/architect.md
- docs/custom-iters/<SLUG>/handoffs/architect-for-backend.md (if backendChanges)
- docs/custom-iters/<SLUG>/handoffs/architect-for-frontend.md (if frontendChanges)
- docs/custom-iters/<SLUG>/handoffs/architect-for-qa.md
- docs/custom-iters/<SLUG>/analysis/MIGRATION_PLAN.md (if dbChanges)
- docs/custom-iters/<SLUG>/analysis/ENV_DELTA.md (if env changes)
- docs/custom-iters/<SLUG>/analysis/DIAGRAMS_PROPOSED.md (if diagrams change)
- docs/custom-iters/<SLUG>/contracts/architect.json
- docs/custom-iters/<SLUG>/_meta.json (decisions block populated)

DO NOT:
- Modify the source PRD ($ARGUMENTS).
- Modify the global docs/architecture/DIAGRAMS.md, .env.example, migrations directories, or any application code.
- Touch workflow/state.json.
- Commit anything.
```

Wait for Architect. Read `_meta.json.decisions` — they drive the next phases.

---

## Phase 2 — Design | model: sonnet _(conditional)_

**Skip** if `_meta.json.decisions.needsDesign === false` AND `decisions.uiChanges === false`. Log skip to `_meta.json.phaseLog`.

Otherwise spawn an Agent with:

- **description:** `"[Design / sonnet] — UX for <SLUG> (fast)"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Design agent for /custom-iter-fast <SLUG> (project: <project>).

Workspace: docs/custom-iters/<SLUG>/
Run contract: docs/custom-iters/<SLUG>/PRD_NORMALIZED.md  (the raw source PRD is NOT read in this phase)

<HARD RULES BLOCK — paste verbatim>

CONTEXT — read in this order:
1. docs/custom-iters/<SLUG>/PRD_NORMALIZED.md — the contract (read §2 goal, §5 out-of-scope, §6 AC)
2. docs/custom-iters/<SLUG>/handoffs/architect.md
3. docs/custom-iters/<SLUG>/handoffs/architect-for-frontend.md (if present)
4. .claude/agents/design.md — sections [general] and [impl]. Output paths below override defaults.
5. .claude/skills/design-skill.md — read-only.
6. docs/design/ (read-only) — existing screen inventory, mockups, pencil files.
7. The actual screens / components in Architect's change map.

YOUR WORK:
1. Identify touched screens/components: NEW | EXTEND | UPDATE.
2. UX states (idle, loading, success, every error) for each touched screen.
3. Components needed (reuse first; name them).
4. UI copy: labels, placeholders, errors, button text. Match existing tone.
5. Accessibility: keyboard, labels, contrast.
6. If Pencil MCP available: update / create screens. Export under `docs/custom-iters/<SLUG>/analysis/design/pencil/`.
7. If Pencil unavailable: HTML mockups under `docs/custom-iters/<SLUG>/analysis/design/html-mockups/`. Use existing tokens.
8. Write `docs/custom-iters/<SLUG>/handoffs/design.md`:
   - `## Touched screens`, `## UX flows`, `## Components`, `## Copy`, `## Accessibility checklist`, `## Tool used`, `## Notes for Frontend`.
9. Update `_meta.json.phaseLog`. Write `contracts/design.json`.

DO NOT:
- Write code into app/web. Frontend's job.
- Modify global design files unless architect.md explicitly authorizes.
- Commit anything.
```

Wait for Design.

---

## Phase 3 — Backend | model: sonnet _(conditional)_

**Skip** if `_meta.json.decisions.backendChanges === false`. Log skip.

Otherwise spawn an Agent with:

- **description:** `"[Backend / sonnet] — implement <SLUG> (fast)"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Backend agent for /custom-iter-fast <SLUG> (project: <project>).

Workspace: docs/custom-iters/<SLUG>/
Run contract: docs/custom-iters/<SLUG>/PRD_NORMALIZED.md  (the raw source PRD is NOT read in this phase)

<HARD RULES BLOCK — paste verbatim>

⚠️ YOU WILL MODIFY APPLICATION SOURCE CODE. You will NOT commit. Working tree must end up containing a correct, complete, tested implementation.

CONTEXT — read in this order:
1. docs/custom-iters/<SLUG>/handoffs/architect-for-backend.md — **read first** (carries the AC + scope you need). Open docs/custom-iters/<SLUG>/PRD_NORMALIZED.md only for a specific ambiguity; full architect.md only if the slim says so.
2. docs/custom-iters/<SLUG>/analysis/MIGRATION_PLAN.md (if present)
3. docs/custom-iters/<SLUG>/analysis/ENV_DELTA.md (if present)
4. .claude/agents/backend.md — sections [general] and [impl]. Output paths below override.
5. .claude/skills/backend-skill.md — read-only.
6. The current backend code at every path in architect's change map.
7. Existing tests for touched modules — run them first to confirm green baseline.

YOUR WORK:
1. **Baseline check:** run existing backend tests. If red BEFORE your changes, stop and report — do not pile on a broken baseline.
2. Apply changes file-by-file in architect.md § Implementation order.
3. If migrations: write at architect-specified path. Do NOT execute against prod-like envs; local dev only.
4. Env vars: add to `.env.example` only if ENV_DELTA.md says so. NEVER touch real `.env` files.
5. Implement endpoints / business logic / DB calls per architect's contract.
6. Validate inputs, parameterize SQL, hash passwords if relevant, return contract-shape responses.
7. Add or update unit + integration tests for every new code path. Cover every PRD §7 (Regression guardrail) item that maps to backend.
8. Run full backend test suite — must pass.
9. Write `docs/custom-iters/<SLUG>/handoffs/backend.md`:
   - `## Baseline test result` — green | red (+ details)
   - `## Files changed` — list + one-line per file
   - `## New tests added` — list, mapped to AC and guardrail IDs
   - `## Final test result` — pass count, fail count (must be 0), command
   - `## Manual verification steps` — curl examples, sample requests
   - `## Notes for Frontend` — contract subtleties
   - `## Notes for QA`
   - `## Pre-existing failures` (if any)
10. Update `_meta.json.phaseLog`. Write `contracts/backend.json` (status pass only if final test result is green).

DO NOT:
- Commit. Not even --no-verify.
- Modify files outside architect's change map. If a needed change is missing, surface in handoff § Notes for orchestrator.
- Touch frontend code, workflow/state.json, .claude/skills/*.
```

Wait for Backend. If `contracts/backend.json.status === "fail"`, stop and surface to human.

---

## Phase 4 — Frontend | model: sonnet _(conditional)_

**Skip** if `_meta.json.decisions.frontendChanges === false`. Log skip.

Otherwise spawn an Agent with:

- **description:** `"[Frontend / sonnet] — implement <SLUG> (fast)"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Frontend agent for /custom-iter-fast <SLUG> (project: <project>).

Workspace: docs/custom-iters/<SLUG>/
Run contract: docs/custom-iters/<SLUG>/PRD_NORMALIZED.md  (the raw source PRD is NOT read in this phase)

<HARD RULES BLOCK — paste verbatim>

⚠️ YOU WILL MODIFY APPLICATION SOURCE CODE. You will NOT commit.

CONTEXT — read in this order:
1. docs/custom-iters/<SLUG>/handoffs/architect-for-frontend.md — **read first** (carries AC + scope). Open docs/custom-iters/<SLUG>/PRD_NORMALIZED.md only for a specific ambiguity; full architect.md only if the slim says so.
2. docs/custom-iters/<SLUG>/handoffs/design.md (if Design ran)
3. docs/custom-iters/<SLUG>/handoffs/backend.md (if Backend ran — for contract specifics)
4. docs/custom-iters/<SLUG>/analysis/design/ (if Design produced mockups)
5. .claude/agents/frontend.md — sections [general] and [impl]. Output paths below override.
6. .claude/skills/frontend-skill.md — read-only.
7. The current frontend code at every path in architect's change map.
8. Existing frontend tests — green baseline before touching anything.

YOUR WORK:
1. **Baseline check:** run frontend tests. Record result.
2. Apply changes file-by-file per architect's implementation order.
3. Wire API using env var base URL (never hardcode URLs).
4. All UI states (idle, loading, success, every error). Match Design exactly for copy / components.
5. Client-side validation mirrors server-side rules.
6. Add or update component / integration tests for every new code path.
7. Run full frontend test suite. Must end green.
8. Write `docs/custom-iters/<SLUG>/handoffs/frontend.md`:
   - `## Baseline test result`, `## Files changed`, `## New tests added`, `## Final test result`, `## Manual verification steps`, `## Notes for QA`, `## Pre-existing failures` (if any).
9. Update `_meta.json.phaseLog`. Write `contracts/frontend.json`.

DO NOT:
- Commit.
- Modify files outside architect's change map without surfacing.
- Touch backend code, workflow/state.json, .claude/skills/*.
```

Wait for Frontend. If `contracts/frontend.json.status === "fail"`, stop and surface.

---

## Phase 5 — QA | model: sonnet

Spawn an Agent with:

- **description:** `"[QA / sonnet] — verify <SLUG> (fast)"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the QA agent for /custom-iter-fast <SLUG> (project: <project>).

Workspace: docs/custom-iters/<SLUG>/
Run contract: docs/custom-iters/<SLUG>/PRD_NORMALIZED.md  (the raw source PRD is NOT read in this phase)

<HARD RULES BLOCK — paste verbatim>

CONTEXT — read in this order:
1. docs/custom-iters/<SLUG>/handoffs/architect-for-qa.md — **read first** (it maps AC + regression guardrails). Open docs/custom-iters/<SLUG>/PRD_NORMALIZED.md §6/§7 only if the slim is ambiguous; full architect.md only if needed.
2. docs/custom-iters/<SLUG>/handoffs/backend.md (if Backend ran)
3. docs/custom-iters/<SLUG>/handoffs/frontend.md (if Frontend ran)
4. docs/custom-iters/<SLUG>/handoffs/design.md (if Design ran)
5. .claude/agents/qa.md — sections [general] and [impl]. Output paths below override.
6. .claude/skills/qa-skill.md — read-only.
7. The actual code changes in the working tree (`git diff --stat`).

YOUR WORK:
1. Build a **test catalog** mapping each AC in PRD §6 → tests covering it (existing, new, gaps).
2. Build a **regression matrix** mapping each item in PRD §7 → verification mechanism (existing test | new test | manual probe).
3. Run the full test suite. Record results. Mark pre-existing failures (per Backend/Frontend baselines) as `pre_existing`; regressions caused by this run are BUGs.
4. If Playwright MCP is available and the change is user-facing, run a basic E2E probe of the primary AC.
5. Walk through Backend/Frontend manual verification steps yourself.
6. Write `docs/custom-iters/<SLUG>/handoffs/qa.md`:
   - `## Test catalog` — table: AC-N | tests | pass/fail
   - `## Regression matrix` — table: guardrail | mechanism | result
   - `## Test execution` — exact commands + counts
   - `## Bugs found` — file/line + which agent should fix
   - `## Manual probes for human` — anything not covered by automation
   - `## How to verify` — copy-paste commands for the REVIEW_CHECKLIST
   - `## Sign-off` — green | blocked | conditional (+ reason)
7. Update `_meta.json.phaseLog`. Write `contracts/qa.json` (pass only if sign-off green or documented-conditional).

DO NOT:
- Commit.
- Mark green if a non-pre-existing test is failing.
- Touch workflow/state.json or .claude/skills/*.
```

Wait for QA. If `Sign-off === "blocked"` with backend/frontend bugs:

1. Spawn a Backend or Frontend **fix agent** (Phase 3 / Phase 4 prompt with prepend: "FIX MODE — read `docs/custom-iters/<SLUG>/handoffs/qa.md § Bugs found`. Fix ONLY those items. Run tests. Do not commit.").
2. Re-spawn QA after the fix.
3. **Two-cycle cap.** If after two fix+re-QA rounds bugs remain, stop and surface to the human.

---

## Phase 6 — Tech Lead (+ close-out) | model: sonnet

This is the **combined** phase that replaces the old `/custom-iter` Phase 7 (Tech Lead) + Phase 8 (PO close-out). Tech Lead does the full technical review AND writes the human-facing review checklist + summary in the same pass.

Spawn an Agent with:

- **description:** `"[Tech Lead / sonnet] — review + close <SLUG> (fast)"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Tech Lead for /custom-iter-fast <SLUG> (project: <project>). This is the FINAL phase. There is no PO close-out — you absorb it. There is NO Pull Request; you review the working tree directly via `git diff` and produce the human-facing artifacts.

Workspace: docs/custom-iters/<SLUG>/
Run contract: docs/custom-iters/<SLUG>/PRD_NORMALIZED.md  (the raw source PRD is NOT read in this phase)

<HARD RULES BLOCK — paste verbatim>

CONTEXT — read in this order:
1. docs/custom-iters/<SLUG>/PRD_NORMALIZED.md — the contract (verify delivery against §6 AC + §7 guardrails)
2. docs/custom-iters/<SLUG>/handoffs/architect.md (and slim variants)
3. docs/custom-iters/<SLUG>/handoffs/design.md (if present)
4. docs/custom-iters/<SLUG>/handoffs/backend.md (if present)
5. docs/custom-iters/<SLUG>/handoffs/frontend.md (if present)
6. docs/custom-iters/<SLUG>/handoffs/qa.md
7. .claude/agents/tech_lead.md — sections [general] and [impl]. Output paths below override.
8. .claude/skills/tech_lead-skill.md — read-only.
9. The full diff of the working tree: `git diff` and `git diff --stat`. Read EVERY changed file in full.
10. `git status --short` — confirm nothing is committed (it shouldn't be).
11. scripts/templates/custom-iter-review-checklist.md — the template you'll fill into REVIEW_CHECKLIST.md.

YOUR WORK — TECHNICAL REVIEW:
- Walk every diff hunk against the architect's change map. Flag any file not in the map.
- Security sweep: no secrets committed, no SQL string concat, no XSS sinks, no PII in logs, auth respected, CORS respected.
- Architecture adherence: repo layout intact, env vars used (no hardcoded URLs), API shape matches contract, ERD vs migration consistent.
- Test adequacy: every AC has a test that would fail without the change; not trivially-true assertions.
- Regression risk: read `qa.md § Regression matrix` and confirm no `fail` rows. For `manual_verify_needed` rows, list them clearly so the human runs them.
- Verify HARD RULES were followed: no git commits, no PR creation, no touches to protected files. If any rule was violated, verdict = needs_changes.

YOUR WORK — CLOSE-OUT (absorbing the old PO close-out):
- Fill the review checklist template into `docs/custom-iters/<SLUG>/REVIEW_CHECKLIST.md`. Replace every `<...>` placeholder. The Phase chain comes from `_meta.json.phaseLog`. Optional follow-ups are collected from every handoff's "Notes" / "Out of scope" / "Follow-ups" sections.
- Write `docs/custom-iters/<SLUG>/SUMMARY.md`:
  - `## Goal` (from PRD §2)
  - `## What changed` — bulleted list of high-level changes, grouped by area
  - `## Files modified` — output of `git diff --stat`
  - `## Tests` — counts from QA handoff
  - `## Risks / regression watchlist` — anything you flagged as needs_human_verify
  - `## Recommended commit message` — for the human to copy when they decide to commit
  - `## Workspace files to keep` — confirm `docs/custom-iters/<SLUG>/` should be committed with the change as the analysis trail
- Write `docs/custom-iters/<SLUG>/handoffs/tech_lead.md`:
  - `## Verdict` — ready_for_human_review | needs_changes
  - `## Files reviewed` — full list from git diff --stat
  - `## Findings` — table: file:line | severity (blocker|major|minor|nit) | issue | required fix
  - `## Security findings` — separate section
  - `## Architecture adherence` — pass/fail per item
  - `## Test adequacy` — pass/fail per AC
  - `## Regression risk summary` — pass | needs_human_verify | fail
  - `## Manual probes the human must run before commit`
  - `## Limitations / known-edge-cases the human should be aware of`
  - `## Recommended commit message` — for the human to copy when they decide to commit (must match SUMMARY.md)
- Update `_meta.json`:
  - `status: "ready_for_human_review"` (only if verdict === "ready_for_human_review"; if `needs_changes`, keep `in_progress`)
  - `completedAt: "<ISO UTC>"`
  - Append final phaseLog row for "tech_lead_close".
- Write `contracts/tech_lead.json` and `contracts/po_close.json` (the second one for backward compat with the old artifact tree — same contents as tech_lead.json, just status=pass on the close-out).

REQUIRED OUTPUTS:
- docs/custom-iters/<SLUG>/handoffs/tech_lead.md
- docs/custom-iters/<SLUG>/REVIEW_CHECKLIST.md
- docs/custom-iters/<SLUG>/SUMMARY.md
- docs/custom-iters/<SLUG>/contracts/tech_lead.json
- docs/custom-iters/<SLUG>/contracts/po_close.json (mirror for tree compat)
- Updated `_meta.json` (status + completedAt + phaseLog)

DO NOT:
- Commit anything.
- Open a PR. There is no PR in /custom-iter-fast.
- Modify code yourself. If you find an issue, set verdict = needs_changes and let the orchestrator spawn a fix agent.
- Touch the source PRD, workflow/state.json, .claude/skills/*.
```

Wait for Tech Lead to complete. Then:

1. Read `handoffs/tech_lead.md § Verdict`.
2. If **needs_changes** with blocker / major findings:
   - For backend findings: spawn a Backend fix agent (Phase 3 prompt with prepend: "TECH LEAD FIX MODE — read `docs/custom-iters/<SLUG>/handoffs/tech_lead.md § Findings`. Fix the listed items only. No commits.")
   - For frontend findings: same for Phase 4.
   - Re-spawn Tech Lead.
   - **Two-cycle cap.** If unresolved after two cycles, stop and surface to the human.
3. Only proceed when Verdict = `ready_for_human_review`.

---

## Final wrap-up (you execute this directly)

1. Verify the workspace contains all required artifacts. Minimum tree:

   ```
   docs/custom-iters/<SLUG>/
     _meta.json (status: ready_for_human_review)
     PRD_NORMALIZED.md (Phase 0 output — the run contract)
     SUMMARY.md
     REVIEW_CHECKLIST.md
     handoffs/architect.md
     handoffs/[architect-for-*.md when applicable]
     handoffs/[design.md if Design ran]
     handoffs/[backend.md if Backend ran]
     handoffs/[frontend.md if Frontend ran]
     handoffs/qa.md
     handoffs/tech_lead.md
     contracts/<phase>.json (one per phase that ran)
     contracts/po_close.json (mirror)
     analysis/* (any extra artifacts agents produced)
   ```

   Note: `PRD_NORMALIZED.md` (Phase 0, light) is the run contract — there is no `handoffs/po.md` (no heavy PO phase). The raw `$ARGUMENTS` note stays untouched and read-only.

2. Run `git status --short` and `git diff --stat`. Print both to the user.

3. Print the final report:

   ```
   ▶ /custom-iter-fast — <SLUG> complete (status: ready_for_human_review)
     workspace : docs/custom-iters/<SLUG>/
     phases    : <phase chain from _meta.json> (no PO; Tech Lead absorbed close)
     verdict   : <ready_for_human_review|needs_changes>  ← from tech_lead.md
     test sign-off: <green|conditional|blocked>          ← from qa.md
     working tree: <N> files changed (run `git diff` to inspect)

   Next steps for you:
   1. Open docs/custom-iters/<SLUG>/REVIEW_CHECKLIST.md and walk it top-to-bottom.
   2. If accepted: commit the working tree with your own message. Recommended message is in docs/custom-iters/<SLUG>/SUMMARY.md § Recommended commit message.
   3. If rejected: `git restore .` to discard, then `rm -rf docs/custom-iters/<SLUG>/` and re-run with an edited source PRD.

   This run did NOT touch: docs/PRD.md, docs/PLAN.md, docs/ITERATION_HISTORY.md, docs/PRODUCT_STATUS.md, workflow/state.json, .claude/skills/.
   ```

4. Do NOT run `git commit`, `git push`, or `gh pr create`. Ever. The human commits.

---

## When to use `/custom-iter-fast` vs `/custom-iter`

| Situation                                                                                    | Use this                                        |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Any improvement note — one-liner, rough sketch, or already-normalized PRD                    | **`/custom-iter-fast`** (Phase 0 normalizes it) |
| Speed matters; PO + PO-close consolidated; light normalize is enough                         | **`/custom-iter-fast`**                         |
| The change needs a deep PO repo-walk to even define §4 before the Architect (high-ambiguity) | `/custom-iter`                                  |
| Run requires a separate, standalone PO close-out artifact (e.g. multi-stakeholder sign-off)  | `/custom-iter`                                  |
