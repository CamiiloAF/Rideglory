# PO handoff — Iteration 3

**Date:** 2026-05-12
**Status:** in progress

---

## Iteration goal

Establish Pencil (`pencil-new.pen`) as the single source of truth for all Rideglory UI by documenting all 8 existing screen flows (~30 screens), defining design token variables (primary orange, dark background, Space Grotesk, 8px radius), and producing a design handoff that the frontend agent must consult before implementing SOAT UI in Iteration 3b.

---

## Stories for this iteration

| ID | Story | Acceptance criteria | Primary agent |
|----|-------|---------------------|---------------|
| US-3-1 | As the design team, I want all 8 existing screen flows imported and labeled in `pencil-new.pen` so that Pencil is the authoritative reference for every screen in the app. | (1) `pencil-new.pen` contains 8 labeled sections, one per flow: Onboarding, Home, Events, Inscripciones, Vehículos, Mantenimiento, Rastreo en vivo, Perfil. (2) Each section contains at least one frame per canonical screen listed in PRD section 9 HU-DESIGN-01 (total ≥ 30 frames across all flows). (3) Each frame is named descriptively (e.g., `01_splash`, `02_login`, `03_registro`). (4) Screenshots or reference images from `stitch_rideglory/` are placed in the correct frames as reference layers. (5) A `docs/design/screenshots/` directory exists with at least one exported `.png` per flow (8 files minimum). | design |
| US-3-2 | As the design team, I want design token variables (primary color, background, font, border radius) defined in `pencil-new.pen` so that future design updates propagate consistently across all screens without manual color or font changes. | (1) A Pencil variable named `primary` is set to `#f98c1f` (orange). (2) A Pencil variable named `background` is set to `#0D0D0D` (dark). (3) A Pencil variable named `font-family` is set to `Space Grotesk`. (4) A Pencil variable named `radius` is set to `8` (px). (5) The variable names and values are documented in `docs/handoffs/design.md` under a "Design Tokens" section. | design |
| US-3-3 | As the design team, I want the SOAT upload flow designed as a multi-step sequence in Pencil before any Flutter widget implementation begins, so that the frontend agent has clear visual specs for each upload state. | (1) The Vehículos section of `pencil-new.pen` includes frames for all SOAT upload states: idle (Subir SOAT button), upload progress (Subiendo documento...), AI extraction loading (Extrayendo fecha con IA...), confirmation form (date pre-filled, Confirmar button), low-confidence warning banner visible on confirmation form, and manual entry fallback form (No pudimos extraer la fecha message). (2) The garage vehicle card frame shows all 4 badge variants: Vigente (green), Por vencer (yellow), Vencido (red), and no badge (no document). (3) These frames are exported as `.png` files under `docs/design/screenshots/soat/`. (4) `docs/handoffs/design.md` describes the SOAT flow screens and badge color values. | design |
| US-3-4 | As the design team, I want a `docs/handoffs/design.md` handoff document produced so that the frontend agent can read visual specs, design token keys, section names, and exported screenshot paths without opening Pencil. | (1) `docs/handoffs/design.md` exists and contains: (a) Design Tokens table with variable name, value, and usage; (b) Screen Inventory table listing every Pencil section and frame count; (c) SOAT flow spec section listing each step's expected copy, widgets, and interaction; (d) File paths for all exported screenshots; (e) Instruction: "Frontend agent must consult this document and match Pencil specs before implementing any SOAT UI widget." (2) The document is written in English. (3) The document references `pencil-new.pen` as the source of truth. | design |
| US-3-5 | As the QA team, I want a design completeness check run on the Pencil file and handoff documents so that the frontend agent is not blocked by missing specs when Iteration 3b begins. | (1) All 8 flow sections are confirmed present in Pencil (verified by design agent via Pencil MCP or screenshot review). (2) All 4 design token variables are confirmed set in Pencil. (3) SOAT flow frames (6 states + 4 badge variants) are confirmed present. (4) `docs/handoffs/design.md` is confirmed complete (all 4 sections present). (5) `docs/design/screenshots/` contains at least 8 flow screenshots plus the SOAT subfolder files. (6) `dart analyze` and `flutter test` continue to pass (no Flutter code changes in this iteration — baseline green must be maintained). | qa |

---

## Assumptions and open questions

- **No Flutter code changes:** Iteration 3 is a pure design iteration. Zero changes to `lib/`, `pubspec.yaml`, or `rideglory-api`. The only artifacts are `.pen` file changes, `docs/handoffs/design.md`, and exported screenshots.
- **Stitch reference images available:** The plan assumption is that `/Users/cami/Downloads/stitch_rideglory/` exists on the development machine. If not found, the design agent should document what is available and proceed with whatever reference material exists. Screenshots should be copied to `docs/design/stitch-references/` for version control.
- **Pencil MCP tooling:** The design agent uses Pencil MCP tools (`open_document`, `batch_design`, `get_screenshot`, `set_variables`, `export_nodes`) to interact with `pencil-new.pen`. No manual Pencil GUI work is assumed — all design operations go through the MCP server.
- **Screen count estimate:** PRD section 9 lists 8 flows totaling approximately 30 screens. The exact count may differ once the Pencil file is inspected — the acceptance criteria uses "≥ 30 frames" as the gate.
- **SOAT is the hard gate for Iteration 3b:** The frontend agent must not begin SOAT widget implementation until US-3-3 and US-3-4 are complete and QA has signed off (US-3-5). This is a blocking dependency.
- **Backend and frontend agents skip this iteration:** `backend` and `frontend` have no tasks. Only `design` and `qa` are active. `architect` is also skipped — no architectural decisions are needed for a pure design iteration.

---

## Out of scope (this iteration)

- **Flutter widget implementation of SOAT UI:** Iteration 3b (depends on this iteration being complete).
- **SOAT backend infrastructure:** Iteration 3a (planned as next iteration after 3).
- **CI/CD changes:** DevOps track already delivered the pipeline in Iteration 1; no changes needed.
- **Pencil component library (atoms/molecules):** Out of scope for v1 — frames use reference images as the canonical screen representation. Native Pencil component authoring is deferred to a future design sprint.
- **AI event cover and recommendations:** Iterations 4–5.
- **Any changes to existing Flutter code:** Explicitly forbidden in this iteration.

---

## Next agent needs to know

- **design:** Your primary deliverables are: (1) all 8 flows labeled and framed in `pencil-new.pen`, (2) 4 design token variables set in the Pencil file, (3) SOAT flow frames covering all 6 upload states and 4 badge variants, (4) exported PNGs in `docs/design/screenshots/`, and (5) `docs/handoffs/design.md` handoff document. Use Pencil MCP tools exclusively — no manual Pencil GUI. Check if `pencil-new.pen` already has some flows imported from prior work and build from that state.
- **qa:** Run `dart analyze` and `flutter test` to confirm baseline is still green (no regression from this design-only iteration). Verify the Pencil file has all 8 sections, all 4 token variables, and all required SOAT frames by reviewing `docs/handoffs/design.md` and `docs/design/screenshots/`. Sign off on completeness per US-3-5 acceptance criteria.
- **architect:** No architectural work needed in Iteration 3. You will be active in Iteration 3a (SOAT backend + Flutter domain/data layer).
- **frontend:** Do not begin SOAT widget implementation. Wait for Iteration 3a (backend + domain/data) and Iteration 3b (UI). The design handoff from this iteration is your spec for all SOAT screens.
- **backend:** No changes to `rideglory-api` in this iteration.

---

## Change log

- 2026-05-12: Initial PO handoff for Iteration 3. Iteration 3 is Track P (Design System in Pencil) promoted to a numbered iteration. 5 user stories defined (US-3-1 through US-3-5). No Flutter code or backend changes. Hard gate for Iteration 3b SOAT UI frontend work.
