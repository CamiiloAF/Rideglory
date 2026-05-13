---
description: Run the full autonomous SDLC flow for a specific iteration (Rideglory Flutter)
allowed-tools: Agent, Read, Write, Bash, Glob, Grep
---

**Target iteration: $ARGUMENTS**

You are the **SDLC orchestrator** for iteration **$ARGUMENTS**. Spawn each phase as a real subagent via the Agent tool; wait for completion before spawning the next.

### State.json partial read rule (all agents)
Read **only**: `currentIteration`, `planStatus`, `existingSystem`, the `iterations[]` row where `id === $ARGUMENTS`, `tasks[]` for this iteration, and the **last 5** `events[]`.

### Contract format rule (all agents)
Every phase contract MUST have: `iteration`, `phase`, `status` ("pass"/"fail"), `updatedAt` (ISO Z), `summary`, `metrics` {tokens:int, costUsd:float}, `artifacts[]` (non-empty), `qualityGates[]` as objects `{name, status ("pass"/"fail"/"warn"), notes}`.

---

## Pre-flight (orchestrator executes directly)

1. Read `workflow/state.json`
2. Confirm `planStatus === "approved"`. Abort if not.
3. Find iteration `$ARGUMENTS` in `iterations[]`: missing→stop, `done`→stop, `active`→tell human `/resume-iter`, `blocked`→stop, `planned`→proceed.
4. Edit `workflow/state.json`: set `currentIteration=$ARGUMENTS`, iteration `status="active"`, append `{type:"iteration_started", iteration:$ARGUMENTS, at:"<ISO>", agent:"system", detail:"Full /iter $ARGUMENTS run starting."}`.
5. Initialize `docs/handoffs/iteration_checkpoint.md` from `scripts/templates/iteration_checkpoint.md`.
6. Confirm `iter-$ARGUMENTS` branch exists (`git branch --list iter-$ARGUMENTS`); if missing stop and tell human to run `/solo-approve`.
7. `git checkout iter-$ARGUMENTS`.

## Gates (run after every phase before spawning next)

```bash
python3 scripts/phase_gate.py --iteration $ARGUMENTS --phase <phase>
python3 scripts/validate_workflow_state.py
```

Both must pass. Fix contract/state issues inline if gate fails — do not re-spawn the agent.

---

## Phase 1 — PO | haiku

- **description:** `"[PO] — scope iter $ARGUMENTS"`
- **model:** `"haiku"`
- **prompt:**

```
You are the PO — Phase 1 of iteration $ARGUMENTS for rideglory (Flutter mobile app).

READ (in order, stop early if you have enough context):
1. `docs/handoffs/iteration_context.md` — if exists and not idle template, read first
2. `docs/PRD.md` — sections for iteration $ARGUMENTS stories only (skim headings, read relevant sections)
3. `docs/PLAN.md` — iteration $ARGUMENTS row
4. `workflow/state.json` — partial read (state.json partial read rule applies)
5. `.claude/skills/po-skill.md` — last 30 lines only

WORK:
- Confirm iteration $ARGUMENTS goal from PLAN.md
- Write detailed user stories US-$ARGUMENTS-N with acceptance criteria
- Add tasks to workflow/state.json tasks[] including at least one QA gate task (agent:"qa")
- Document scope decisions and out-of-scope items

OUTPUTS:
- `docs/handoffs/po.md` — full handoff
- `workflow/state.json` — agents.po.status="idle", tasks updated, event {type:"po_plan", iteration:$ARGUMENTS, phase:"po_scope", agent:"po", at:"<ISO>", detail:"<summary>"}
- `docs/handoffs/contracts/iter-$ARGUMENTS/po_scope.json` — contract (see contract format rule; required gate names: "required_artifacts_present", "scope_defined")

SKILL: append 1-2 lines to `.claude/skills/po-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase po_scope --agent po --path docs/handoffs/po.md --path workflow/state.json --path docs/handoffs/iteration_checkpoint.md --path docs/handoffs/contracts/iter-$ARGUMENTS/po_scope.json --path .claude/skills/po-skill.md

GIT: git add docs/handoffs/po.md workflow/state.json docs/handoffs/iteration_checkpoint.md docs/handoffs/contracts/iter-$ARGUMENTS/po_scope.json .claude/skills/po-skill.md && git commit -m "feat(iter-$ARGUMENTS): po — scope"

PHASE COMPLETE: append {type:"phase_complete", iteration:$ARGUMENTS, phase:"po_scope", agent:"po", at:"<ISO>", detail:"<one-line>"} to workflow/state.json events. Update checkpoint: Last=po_scope, Next=architect.
```

---

## Phase 2 — Architect | sonnet
<!-- Restore iter.md.opus-backup for complex cross-cutting patterns (new auth/WebSocket). -->

- **description:** `"[Architect] — iter $ARGUMENTS feature arch"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Architect — Phase 2 of iteration $ARGUMENTS for rideglory (Flutter + NestJS).

READ (in order):
1. `docs/handoffs/po.md` — stories to map to layers
2. `docs/handoffs/iteration_context.md` — if exists and not idle
3. `docs/handoffs/architect.md` — if exists (your prior decisions, reuse patterns)
4. `workflow/state.json` — partial read (check existingSystem.basePath and .backend)
5. `.claude/skills/architect-skill.md` — last 30 lines only
6. Scan `lib/features/` directory tree (ls -R, not full file reads) to understand existing structure

WORK:
- git checkout iter-$ARGUMENTS
- Map each PO story to Flutter layer changes (domain/data/presentation)
- Define API contracts for rideglory-api changes (or confirm none needed)
- Define new domain models, DTOs, Retrofit endpoints, l10n keys
- Write slim downstream handoffs (≤80 lines each)
- Update architect-skill.md

OUTPUTS:
- `docs/handoffs/architect.md` — full handoff
- `docs/handoffs/architect-for-backend.md` — NestJS changes (≤80 lines; write "No changes" if none)
- `docs/handoffs/architect-for-frontend.md` — Flutter structure, models, DTOs, cubit pattern, l10n keys (≤80 lines)
- `docs/handoffs/architect-for-devops.md` — CI/env changes (≤40 lines; write "No changes" if none)
- `docs/handoffs/architect-for-qa.md` — test commands + AC traceability (≤80 lines)
- `docs/architecture/DIAGRAMS.md` — Mermaid diagrams only if data model changes
- `workflow/state.json` — agents.architect.status="idle", event {type:"architect_plan",...}
- `docs/handoffs/contracts/iter-$ARGUMENTS/architect.json` — contract (required gate names: "required_artifacts_present", "architecture_contracts_defined")

SKILL: append to `.claude/skills/architect-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase architect --agent architect --path docs/handoffs/architect.md --path docs/handoffs/architect-for-backend.md --path docs/handoffs/architect-for-frontend.md --path docs/handoffs/architect-for-devops.md --path docs/handoffs/architect-for-qa.md --path docs/architecture/DIAGRAMS.md --path workflow/state.json --path docs/handoffs/iteration_checkpoint.md --path docs/handoffs/contracts/iter-$ARGUMENTS/architect.json --path .claude/skills/architect-skill.md

GIT: git add docs/handoffs/architect.md docs/handoffs/architect-for-*.md docs/architecture/ workflow/state.json docs/handoffs/iteration_checkpoint.md docs/handoffs/contracts/iter-$ARGUMENTS/architect.json .claude/skills/architect-skill.md && git commit -m "feat(iter-$ARGUMENTS): architect — feature arch + contracts"

PHASE COMPLETE: append {type:"phase_complete", iteration:$ARGUMENTS, phase:"architect", agent:"architect", at:"<ISO>", detail:"<one-line>"} to workflow/state.json events. Update checkpoint: Last=architect, Next=design.
```

---

## Phase 3 — Design | sonnet

- **description:** `"[Design] — iter $ARGUMENTS screens"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Design agent — Phase 3 of iteration $ARGUMENTS for rideglory (Flutter mobile app, dark theme).

READ (in order):
1. `docs/handoffs/architect-for-frontend.md` — screens needed, error shapes, l10n keys
2. `docs/handoffs/po.md` — stories and acceptance criteria
3. `docs/handoffs/design.md` — if exists: locked decisions, screen inventory (continuation mode)
4. `docs/design/html-mockups/iter-$ARGUMENTS/shared/styles.css` — if exists, reuse verbatim
5. `.claude/skills/design-skill.md` — last 30 lines only

CONTINUATION RULE: If design.md or prior mockups exist — do NOT redesign. Classify each story UI as NEW/EXTEND/UPDATE. Reuse styles.css from prior iteration; modify only what this iteration requires.

Dark theme tokens: bg=#111111, primary=#f98c1f, font=Space Grotesk, radius=8px.

WORK:
1. Classify stories as NEW/EXTEND/UPDATE
2. Map to mobile screens (375×812px viewport), consider go_router routes
3. Design loading/success/error/empty states per screen
4. Define component hierarchy (which lib/shared/widgets/ to reuse; what's new)
5. All UI copy in Spanish, sentence case buttons
6. HTML/CSS mockups → docs/design/html-mockups/iter-$ARGUMENTS/ (one file per state)
7. Do NOT write Flutter/Dart code

OUTPUTS:
- `docs/handoffs/design.md`
- `docs/design/html-mockups/iter-$ARGUMENTS/` — mockups + shared/styles.css
- `workflow/state.json` — agents.design.status="idle", event {type:"design_iteration",...}
- `docs/handoffs/contracts/iter-$ARGUMENTS/design.json` — contract (required gate names: "required_artifacts_present", "design_coverage_complete")

SKILL: append to `.claude/skills/design-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase design --agent design --path docs/handoffs/design.md --path workflow/state.json --path docs/handoffs/iteration_checkpoint.md --path docs/handoffs/contracts/iter-$ARGUMENTS/design.json --path .claude/skills/design-skill.md --path docs/design/

GIT: git add docs/handoffs/design.md docs/design/ workflow/state.json docs/handoffs/iteration_checkpoint.md docs/handoffs/contracts/iter-$ARGUMENTS/design.json .claude/skills/design-skill.md && git commit -m "feat(iter-$ARGUMENTS): design — screens + mockups"

PHASE COMPLETE: append {type:"phase_complete", iteration:$ARGUMENTS, phase:"design", agent:"design", at:"<ISO>", detail:"<one-line>"} to events. Update checkpoint: Last=design, Next=backend.
```

---

## Phase 4 — Backend | sonnet

**Skip if `docs/handoffs/architect-for-backend.md` says "No changes".** Write pass-through contract at `docs/handoffs/contracts/iter-$ARGUMENTS/backend.json` (status:"pass", artifacts:["docs/handoffs/backend.md"], qualityGates with names "required_artifacts_present"+"tests_passed_or_accepted"+"security_checks" all pass), create `docs/handoffs/backend.md` with one-liner, append phase_complete event, update checkpoint Last=backend Next=frontend — then proceed to Phase 5.

- **description:** `"[Backend] — iter $ARGUMENTS API endpoints"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Backend Developer — Phase 4 of iteration $ARGUMENTS for rideglory.
Work in: /Users/cami/Developer/Personal/rideglory-api

READ (in order):
1. `docs/handoffs/architect-for-backend.md` — NestJS changes, contracts, env vars (primary spec)
2. `docs/handoffs/po.md` — acceptance criteria for backend stories
3. `docs/handoffs/backend.md` — if exists (prior patterns to reuse)
4. `workflow/state.json` — partial read
5. `.claude/skills/backend-skill.md` — last 30 lines only

WORK:
- Read existing NestJS code before touching anything (brownfield)
- Implement only endpoints in architect-for-backend.md
- Follow existing module/controller/service/guard/dto structure
- Firebase ID token validation on every protected endpoint
- Write unit + e2e tests; all must pass
- Update rideglory-api/.env.example with any new vars

OUTPUTS:
- `docs/handoffs/backend.md` (written in Rideglory repo)
- `workflow/state.json` — agents.backend.status="idle", event appended
- `docs/handoffs/contracts/iter-$ARGUMENTS/backend.json` — contract (required gate names: "required_artifacts_present", "tests_passed_or_accepted", "security_checks")
- Code in /Users/cami/Developer/Personal/rideglory-api

SKILL: append to `.claude/skills/backend-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase backend --agent backend --path docs/handoffs/backend.md --path workflow/state.json --path docs/handoffs/iteration_checkpoint.md --path docs/handoffs/contracts/iter-$ARGUMENTS/backend.json --path .claude/skills/backend-skill.md

GIT:
  cd /Users/cami/Developer/Personal/rideglory-api && git add -A && git commit -m "feat(iter-$ARGUMENTS): backend — <endpoints>"
  cd /Users/cami/Developer/Personal/Rideglory && git add docs/handoffs/backend.md workflow/state.json docs/handoffs/iteration_checkpoint.md docs/handoffs/contracts/iter-$ARGUMENTS/backend.json .claude/skills/backend-skill.md && git commit -m "feat(iter-$ARGUMENTS): backend handoff"

PHASE COMPLETE: append {type:"phase_complete", iteration:$ARGUMENTS, phase:"backend", agent:"backend", at:"<ISO>", detail:"<one-line>"} to events. Update checkpoint: Last=backend, Next=frontend.
```

---

## Phase 5 — Flutter Developer | sonnet

- **description:** `"[Flutter Dev] — iter $ARGUMENTS implementation"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Flutter Developer — Phase 5 of iteration $ARGUMENTS for rideglory.
Work in: /Users/cami/Developer/Personal/Rideglory/lib/

READ (in order):
1. `docs/handoffs/architect-for-frontend.md` — feature path, models, DTOs, cubit pattern, l10n keys (primary spec)
2. `docs/handoffs/po.md` — stories and acceptance criteria
3. `docs/handoffs/design.md` — screens, component hierarchy, Spanish copy
4. `docs/handoffs/backend.md` — actual implemented endpoints
5. `docs/handoffs/frontend.md` — if exists (prior patterns to reuse)
6. `workflow/state.json` — partial read
7. `.claude/skills/frontend-skill.md` — last 30 lines only
8. `docs/design/html-mockups/iter-$ARGUMENTS/` — visual reference (read HTML files)

BROWNFIELD: Read existing lib/features/<feature>/ before touching anything. EXTEND, never rebuild.

STANDARDS (blocking — tech_lead will reject violations):
- One widget per file, no _buildXxx helpers
- All strings via context.l10n (no hardcoded Spanish)
- AppButton not ElevatedButton; AppDialog not showDialog()
- ResultState<T> for all async state
- context.pushNamed() for navigation
- Theme.of(context).colorScheme for colors

LAYER ORDER: domain model → repository interface → DTO → Retrofit → repo impl → use case → cubit → page → widgets.

AFTER CODING:
- dart run build_runner build --delete-conflicting-outputs
- dart analyze — fix ALL violations (zero tolerance)
- flutter test — must pass

OUTPUTS:
- `docs/handoffs/frontend.md`
- `workflow/state.json` — agents.frontend.status="idle", tasks updated, event appended
- `docs/handoffs/contracts/iter-$ARGUMENTS/frontend.json` — contract (required gate names: "required_artifacts_present", "tests_passed_or_accepted")
- Flutter code in lib/

SKILL: append to `.claude/skills/frontend-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase frontend --agent frontend --path docs/handoffs/frontend.md --path workflow/state.json --path docs/handoffs/iteration_checkpoint.md --path docs/handoffs/contracts/iter-$ARGUMENTS/frontend.json --path .claude/skills/frontend-skill.md --path lib/

GIT: git add lib/ pubspec.yaml docs/handoffs/frontend.md workflow/state.json docs/handoffs/iteration_checkpoint.md docs/handoffs/contracts/iter-$ARGUMENTS/frontend.json .claude/skills/frontend-skill.md && git commit -m "feat(iter-$ARGUMENTS): flutter — <features>"

PHASE COMPLETE: append {type:"phase_complete", iteration:$ARGUMENTS, phase:"frontend", agent:"frontend", at:"<ISO>", detail:"<one-line>"} to events. Update checkpoint: Last=frontend, Next=qa.
```

---

## Phase 6 — QA | haiku

- **description:** `"[QA] — iter $ARGUMENTS analyze + test + sign-off"`
- **model:** `"haiku"`
- **prompt:**

```
You are the QA agent — Phase 6 of iteration $ARGUMENTS for rideglory.

READ (in order):
1. `docs/handoffs/architect-for-qa.md` — test commands + AC traceability
2. `docs/handoffs/po.md` — acceptance criteria
3. `docs/handoffs/frontend.md` — what was implemented
4. `docs/handoffs/backend.md` — API changes (if exists)
5. `workflow/state.json` — partial read
6. `.claude/skills/qa-skill.md` — last 20 lines only

WORK:
- Write test catalog TC-$ARGUMENTS-N for each acceptance criterion
- Run: dart analyze — file BUG-$ARGUMENTS-N task for every NEW violation
- Run: flutter test — file BUG task for every failure
- File bugs in workflow/state.json tasks[] (status:"backlog", agent:"frontend"|"backend")
- Do not mark complete until all ACs pass or deferrals explicitly documented

OUTPUTS:
- `docs/handoffs/qa.md` — catalog + ## Sign-off section + ## Bugs filed section
- `workflow/state.json` — agents.qa.status="idle", BUG tasks added, event appended
- `docs/handoffs/contracts/iter-$ARGUMENTS/qa.json` — contract (required gate names: "required_artifacts_present", "tests_passed_or_accepted", "acceptance_criteria_verified")

SKILL: append to `.claude/skills/qa-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase qa --agent qa --path docs/handoffs/qa.md --path workflow/state.json --path docs/handoffs/iteration_checkpoint.md --path docs/handoffs/contracts/iter-$ARGUMENTS/qa.json --path .claude/skills/qa-skill.md --path test/

GIT: git add docs/handoffs/qa.md workflow/state.json docs/handoffs/iteration_checkpoint.md docs/handoffs/contracts/iter-$ARGUMENTS/qa.json test/ .claude/skills/qa-skill.md && git commit -m "feat(iter-$ARGUMENTS): qa — test catalog + results"

PHASE COMPLETE: append {type:"phase_complete", iteration:$ARGUMENTS, phase:"qa", agent:"qa", at:"<ISO>", detail:"<N tests pass, M bugs filed>"} to events. Update checkpoint: Last=qa, Next=devops.
```

Wait for QA. Read `docs/handoffs/qa.md` → `## Sign-off` and `## Bugs filed`.
- **Blocking bugs**: spawn fix agent (prepend "BUG FIX MODE — fix only bugs in qa.md § Bugs filed. Run dart analyze && flutter test.") using Phase 5 or 4 prompt. Re-spawn QA. Max 2 fix cycles; surface to human if still failing.
- No blocking bugs → proceed.

---

## Phase 7 — DevOps | haiku

- **description:** `"[DevOps] — iter $ARGUMENTS CI"`
- **model:** `"haiku"`
- **prompt:**

```
You are the DevOps agent — Phase 7 of iteration $ARGUMENTS for rideglory.

READ (in order):
1. `docs/handoffs/architect-for-devops.md` — CI changes, new env vars
2. `docs/handoffs/devops.md` — if exists (your prior CI config; update, don't rewrite)
3. `.claude/skills/devops-skill.md` — last 20 lines only

WORK:
- Update .github/workflows/ci.yml if architect-for-devops.md lists changes; otherwise verify existing YAML is still correct and skip rewrite
- Update docs/DEPLOY.md only for new env vars or secrets
- Push branch: git push -u origin iter-$ARGUMENTS

OUTPUTS:
- `docs/handoffs/devops.md`
- `workflow/state.json` — agents.devops.status="idle", event appended
- `docs/handoffs/contracts/iter-$ARGUMENTS/devops.json` — contract (required gate names: "required_artifacts_present", "ci_checks_passed_or_accepted", "security_checks")
- `.github/workflows/ci.yml` (if changed), `docs/DEPLOY.md` (if changed)

SKILL: append to `.claude/skills/devops-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase devops --agent devops --path docs/handoffs/devops.md --path workflow/state.json --path docs/handoffs/iteration_checkpoint.md --path docs/handoffs/contracts/iter-$ARGUMENTS/devops.json --path .claude/skills/devops-skill.md --path .github/workflows/ci.yml --path docs/DEPLOY.md

GIT: git add .github/ docs/handoffs/devops.md docs/DEPLOY.md workflow/state.json docs/handoffs/iteration_checkpoint.md docs/handoffs/contracts/iter-$ARGUMENTS/devops.json .claude/skills/devops-skill.md && git commit -m "feat(iter-$ARGUMENTS): devops — CI update" && git push -u origin iter-$ARGUMENTS

PHASE COMPLETE: append {type:"phase_complete", iteration:$ARGUMENTS, phase:"devops", agent:"devops", at:"<ISO>", detail:"<one-line>"} to events. Update checkpoint: Last=devops, Next=pr.
```

---

## Phase 8 — PR (orchestrator executes directly)

1. Read `docs/handoffs/po.md` (stories) and `docs/handoffs/qa.md` (test results).
2. Write `docs/PULL_REQUEST_BODY_ITER_$ARGUMENTS.md`: stories delivered, deferred, test results, handoff links.
3. `gh pr create --base main --head iter-$ARGUMENTS --title "feat(iter-$ARGUMENTS): <goal>" --body-file docs/PULL_REQUEST_BODY_ITER_$ARGUMENTS.md`
4. Record PR number + URL.
5. Append `{type:"phase_complete", iteration:$ARGUMENTS, phase:"pr", agent:"system", at:"<ISO>", detail:"PR #N opened: <url>"}` to events.
6. Write `docs/handoffs/contracts/iter-$ARGUMENTS/pr.json` (required gate names: "required_artifacts_present", "pr_opened").
7. Update checkpoint: Last=pr, Next=tech_lead.
8. `python3 scripts/phase_gate.py --iteration $ARGUMENTS --phase pr`

---

## Phase 9 — Tech Lead | sonnet

- **description:** `"[Tech Lead] — iter $ARGUMENTS PR review"`
- **model:** `"sonnet"`
- **prompt:**

```
You are the Tech Lead — Phase 9 of iteration $ARGUMENTS for rideglory (Flutter mobile app).

READ (in order):
1. `.cursor/rules/rideglory-coding-standards.mdc` — the mandatory style/architecture law
2. `docs/handoffs/architect-for-frontend.md` — what was planned
3. `docs/handoffs/frontend.md` — what was built
4. `docs/handoffs/qa.md` — test results and known issues
5. `docs/handoffs/tech_lead.md` — if exists (prior decisions to stay consistent)
6. `workflow/state.json` — partial read (find PR number in last 5 events)
7. Full PR diff: run `gh pr list --head iter-$ARGUMENTS` then `gh pr diff <number>`

REVIEW (fix blocking issues directly — don't just comment):
- Clean Architecture: domain no Flutter/HTTP; data no widgets/BuildContext; presentation no HTTP/DTOs; deps inward
- Coding standards: one widget per file, no _buildXxx, ARB strings, AppButton, AppDialog, ResultState<T>, pushNamed, colorScheme
- dart analyze: zero new violations (run it)
- flutter test: all pass (run it)
- Security: Firebase token on every protected endpoint, no secrets committed

OUTPUTS:
- `docs/handoffs/tech_lead.md` — ## Overall signal + ## Blocking issues sections
- `docs/architecture/code-review-iter$ARGUMENTS.md` — findings table (file, issue, severity, fix)
- `workflow/state.json` — agents.tech_lead.status="idle", event {type:"tech_lead_review",...}
- `docs/handoffs/contracts/iter-$ARGUMENTS/tech_lead.json` — contract (required gate names: "required_artifacts_present", "review_completed", "security_checks")

SKILL: append to `.claude/skills/tech_lead-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase tech_lead --agent tech_lead --path docs/handoffs/tech_lead.md --path docs/architecture/ --path workflow/state.json --path docs/handoffs/iteration_checkpoint.md --path docs/handoffs/contracts/iter-$ARGUMENTS/tech_lead.json --path .claude/skills/tech_lead-skill.md

GIT: git add docs/handoffs/tech_lead.md docs/architecture/ workflow/state.json docs/handoffs/iteration_checkpoint.md docs/handoffs/contracts/iter-$ARGUMENTS/tech_lead.json .claude/skills/tech_lead-skill.md lib/ && git commit -m "feat(iter-$ARGUMENTS): tech_lead — <approved|blocked>" && git push

PHASE COMPLETE: append {type:"phase_complete", iteration:$ARGUMENTS, phase:"tech_lead", agent:"tech_lead", at:"<ISO>", detail:"<approved|blocked> — <reason>"} to events. Update checkpoint: Last=tech_lead, Next=po_close.
```

Wait for Tech Lead. Read `## Overall signal` and `## Blocking issues`.
- **Blocked**: spawn fix agent(s), re-spawn Tech Lead. Max 2 cycles.
- **Approved**: `gh pr merge <pr-number> --merge` → record merge SHA in events.

---

## Phase 10 — PO Close-out | haiku

- **description:** `"[PO] — iter $ARGUMENTS close-out"`
- **model:** `"haiku"`
- **prompt:**

```
You are the PO (close-out) — Phase 10 of iteration $ARGUMENTS for rideglory.

READ (in order — lean set):
1. `docs/handoffs/po.md` — stories delivered vs deferred
2. `docs/handoffs/qa.md` — test results
3. `docs/handoffs/tech_lead.md` — PR verdict (scan for PR number and merge SHA)
4. `workflow/state.json` — partial read (last 5 events for PR/merge info)
5. `docs/ITERATION_HISTORY.md` — if exists (to append correctly)
6. `scripts/templates/iteration_checkpoint.md` — reset template

WRITE:
1. `docs/ITERATION_SUMMARY_$ARGUMENTS.md` — goal, delivered, deferred, QA results, PR link
2. `docs/ITERATION_HISTORY.md` — append one row: id | date | one-liner | link
3. `docs/PRODUCT_STATUS.md` — update "what's shipped" section
4. `docs/handoffs/iteration_context.md` — bridge for iteration $ARGUMENTS+1 (deferred work, known blockers, tech debt)
5. `README.md` — update shipped/links block only (read existing first)
6. `docs/handoffs/iteration_checkpoint.md` — reset to idle; "Last closed: Iteration $ARGUMENTS"

ALSO: set `workflow/state.json` iterations[$ARGUMENTS].status = "done", agents.po.status="idle", append {type:"phase_complete", iteration:$ARGUMENTS, phase:"po_close", agent:"po", at:"<ISO>", detail:"Iteration $ARGUMENTS closed."}.

OUTPUTS:
- All 6 docs above
- `workflow/state.json`
- `docs/handoffs/contracts/iter-$ARGUMENTS/po_close.json` — contract (required gate names: "required_artifacts_present", "iteration_docs_published")

SKILL: append to `.claude/skills/po-skill.md` § Change log.

ARTIFACT LOG:
  python3 scripts/log_artifact.py --iteration $ARGUMENTS --phase po_close --agent po --path docs/ITERATION_SUMMARY_$ARGUMENTS.md --path docs/ITERATION_HISTORY.md --path docs/PRODUCT_STATUS.md --path docs/handoffs/iteration_context.md --path README.md --path docs/handoffs/iteration_checkpoint.md --path workflow/state.json --path docs/handoffs/contracts/iter-$ARGUMENTS/po_close.json --path .claude/skills/po-skill.md

GIT: git add docs/ README.md workflow/state.json docs/handoffs/contracts/iter-$ARGUMENTS/po_close.json .claude/skills/po-skill.md && git commit -m "feat(iter-$ARGUMENTS): po — close-out" && git push
```

---

## Iteration close (orchestrator executes directly)

1. Compress events: remove all `phase_complete` events for iteration $ARGUMENTS, append one `iteration_summary` event with phase chain + PR link.
2. Set `workflow/state.json`: `iterations[$ARGUMENTS].status="done"`, all `agents.*.status="idle"`, `currentIteration=$ARGUMENTS+1`.
3. `python3 scripts/validate_workflow_state.py` — fix any issues.
4. `git add workflow/state.json && git commit -m "chore(iter-$ARGUMENTS): compress events, mark done" && git push`
5. Print: what was built (per story), PR URL, tech lead verdict, test results, next command.
