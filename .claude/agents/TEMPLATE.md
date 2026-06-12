---
name: my-custom-agent
description: "One-line picker description."

Examples:

- user: "Example request"
  assistant: "Example reply."
  (Launch the Agent tool with the my-custom-agent agent)

model: sonnet
color: blue
skills: []
---

# Custom agent

Define behavior below. If this maps to a framework role, read **`CLAUDE.md`** and the rg-plan / rg-exec workflow prompt, and align outputs with the closest role’s handoff format (under `docs/plans/<slug>/` or `docs/exec-runs/<slug>/`).

Optional: **`$ARGUMENTS`** from the caller.
