# Architect → DevOps handoff — Iteration 4

**Date:** 2026-05-13
**Iteration:** 4 — AI Event Cover Image Generation

---

## CI/env changes required

### New secret: `UNSPLASH_ACCESS_KEY`

Add to GitHub Actions secrets (repository settings → Secrets and variables → Actions):
- Secret name: `UNSPLASH_ACCESS_KEY`
- Value: Unsplash API access key from https://unsplash.com/developers

**Backend `.env.example` update** (done by backend agent — DevOps confirms it exists in the file before CI runs):
```
UNSPLASH_ACCESS_KEY=your_unsplash_access_key_here
```

### CI job update for backend (api-gateway)

If a backend CI job exists, inject `UNSPLASH_ACCESS_KEY` as an env var in the `api-gateway` test step:
```yaml
env:
  UNSPLASH_ACCESS_KEY: ${{ secrets.UNSPLASH_ACCESS_KEY }}
```

### Flutter CI — no changes

No new Flutter packages require CI changes. `CachedNetworkImage` already in deps.

---

## Change log

- 2026-05-13 (iter-4): Add UNSPLASH_ACCESS_KEY to CI secrets. No Flutter CI changes.
