# Iteration context — Bridge from iter-6 to iter-4

> Last closed: Iteration 6 (Refactor & Cleanup Extremo, codename `refactor-01`)
> Next planned: Iteration 4 — Seguidores + Perfil Completo (status: `planned` in `workflow/state.json`)
> Updated: 2026-05-27

## What iter-6 leaves behind for the next iteration

### New design system primitives — USE THESE

- **`AppCircleIconButton`** (`lib/design_system/atoms/buttons/`): 36×36 circular icon button. Variants: `surface` (default dark card), `accent` (orange primary), `translucent` (overlay). Convenience factory `.back()` for back-arrows. **DO NOT create per-feature back-button widgets** — use this atom.
- **`AppFormNavHeader`** (`lib/design_system/molecules/layout/`): centralized form-screen header. Sealed `AppFormNavAction` (text / icon / pillText). Use for any new form's top bar.
- **Color tokens**: `AppColors.statusGreen`, `AppColors.statusWarning`, `AppColors.statusError` are now available for status badges.

### Architectural conventions reinforced

- One widget class per file across all of `lib/features/`. No `Widget _build*` helpers.
- `context.pop()` / `context.push()` everywhere; `Navigator.of(context).*` and `Navigator.pop(context)` require a `// Custom: <reason>` annotation. Modal bottom sheets opened via `showModalBottomSheet` still use `Navigator.pop` because they live in the Material navigator stack.
- Hardcoded colors (`Color(0x...)`, `Colors.*`) are not allowed in `lib/features/` without `// Intentional:` annotation. Use `colorScheme.*` (semantic) or `AppColors.*` (non-scheme tokens).
- For primary-filled buttons, foreground colors use `colorScheme.onPrimary` (auto-dark via Material 3) — not `AppColors.textOnDarkPrimary` (white).

### Known follow-ups (open at iter-6 close)

1. **`event_detail_cta_bar`** 8 state variants still have no widget tests.
2. **`lucide_icons 0.257.0`** extends Flutter's now-`final` `IconData` class. CI is pinned to Flutter `3.38.5` as a workaround. When upgrading Flutter, migrate `lucide_icons` usages (14 references in 6 files in `lib/features/events/`) to a maintained alternative or Material icons.
3. **l10n keys reduced by 43.4%** in iter-6. Spot-check production push payloads for any silently-broken dynamic key references.

## Next planned iteration: iter-4 — Seguidores + Perfil Completo

Goal: activate the social layer (follow / unfollow), complete public profiles, and provision the deep link domain (hard blocker for iter-5).

5 stories (4.1–4.5) already scoped in `workflow/state.json` and `docs/PLAN.md`. Backend introduces a `Follow` entity in `users-ms`. Flutter introduces `FollowCubit` with optimistic state (documented exception to the `ResultState<T>` pattern, per Architect handoff on file).

Action item during iter-4: provision the deep-link domain — hard blocker for iter-5.

## Quick orientation

- Branch `main` is the deployment trunk.
- Branch `iter-6` is closed via PR #23 — APPROVED by tech_lead.
- Branches `iter-4` and `iter-5` already exist locally.

Run `/iter 4` (or `/resume-iter` if anything is mid-flight) to start the next iteration.
