# steward

A standalone Claude Code plugin that restructures the George → Opus → Blueberry
pipeline around a single metric: **efficiency of George's attention spend.**

Successor to the `superpowers-local-subagent` fork.

- **Brief:** [BRIEF-steward.md](BRIEF-steward.md) (Approved v1, 2026-07-03)
- **Decomposition / issues:** [ISSUES.md](ISSUES.md)

## Status

v0.1.0 — walking skeleton. Plugin loads with zero skills. See the issues for
the phased build-out.

## Local development

Load locally for development:

```
claude --plugin-dir /path/to/steward
```

`/reload-plugins` picks up edits mid-session.

## Layout

- `.claude-plugin/plugin.json` — plugin manifest (the only thing inside `.claude-plugin/`).
- `skills/` — plugin skills (empty at v0.1.0); lives at plugin root.
