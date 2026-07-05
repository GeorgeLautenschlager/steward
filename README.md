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

To auto-load it in every session instead of passing `--plugin-dir`, register
the repo as a local `directory` marketplace in `~/.claude/settings.json`
(`extraKnownMarketplaces` + `enabledPlugins: { "steward@steward-dev": true }`)
— the manifest below makes it self-installable. Don't pass `--plugin-dir` as
well when it's enabled this way, or the plugin loads twice.

## Layout

- `.claude-plugin/plugin.json` — plugin manifest.
- `.claude-plugin/marketplace.json` — self-listing so the repo is installable as
  a one-plugin `directory` marketplace. These two are the only things inside
  `.claude-plugin/`.
- `skills/` — plugin skills; lives at plugin root.
