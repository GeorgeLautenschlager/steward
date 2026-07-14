# steward

A standalone Claude Code plugin that restructures the George → Opus → Blueberry
pipeline around a single metric: **efficiency of George's attention spend.**

Successor to the `superpowers-local-subagent` fork.

- **Brief:** [BRIEF-steward.md](BRIEF-steward.md) (Approved v1, 2026-07-03)
- **Decomposition / issues:** [ISSUES.md](ISSUES.md)

## What it does

George is the bottleneck in the pipeline, and his attention leaks in four
places: under-invested briefs, decomposition sized by convenience, synchronous
mid-flight interruptions, and final review that re-verifies work already
verified in-session. Steward closes those leaks so George spends **judgment
only, always batched, never interrupted** between "decomposition approved" and
"PR ready for review."

It does this as a set of skills and conventions that run over the existing
chat → brief → issues → dispatch → PR → review flow. Chat (claude.ai) stays the
design surface; the plugin's jurisdiction begins once an approved brief and an
approved decomposition exist. See the brief for the full attention taxonomy and
design rules.

## Status

**Operational.** All v1 components (C1–C8 in the brief) have landed: the
local-SDD dispatch, the decision lifecycle, PR packaging, adversarial review,
and metrics are all in place. See [ISSUES.md](ISSUES.md) for the build-out
record; the remaining work is the end-to-end shakedown on `face-dancer`
(issue #12) and the go/no-go on archiving the fork.

## Skills

| Skill | When it runs | What it does |
|---|---|---|
| [`steward-local-sdd`](skills/steward-local-sdd/SKILL.md) | Executing an implementation plan | A variant of `superpowers:subagent-driven-development`: frontier brain plans and runs the two-stage review, a local headless `pi -p` process writes the code. Dispatches each task with the issue, `DECISIONS.md`, and the ledger protocol; captures both review stages to the runlog. |
| [`pr-packaging`](skills/pr-packaging/SKILL.md) | Run finished, all tasks passed review | Turns run artifacts into the PR as a **verification trail**: Pi authors a six-section description and inline self-review comments; Opus reviews it against the brief before George is pinged. |
| [`adversarial-review`](skills/adversarial-review/SKILL.md) | After packaging, before George | A fresh-context reviewer sees **only the brief and the diff** — never the plan — and returns blocking findings for spec violations, advisory for taste. Anchoring is the enemy. |
| [`metrics`](skills/metrics/SKILL.md) | Review close, after George rules | Appends one JSONL line per PR to `.steward/metrics.jsonl` (asking George only for `review_minutes`). Measured, not vibed. |

## Conventions & templates

- [`docs/DECISION-LIFECYCLE.md`](docs/DECISION-LIFECYCLE.md) — how ambiguity
  becomes standing law: the assumption ledger, escalation tiers, the hard-stop
  class, and promotion of blessed assumptions into `DECISIONS.md`.
- [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) — where steward's state lives
  (`.steward/runs/<issue>/` ephemeral, `.steward/metrics.jsonl` committed) and
  the gitignore policy behind it.
- [`docs/DECOMPOSITION.md`](docs/DECOMPOSITION.md) — the decomposition protocol:
  one issue = one PR = one reviewable decision, sized by conceptual load.
- [`templates/BRIEF-TEMPLATE.md`](templates/BRIEF-TEMPLATE.md) — canonical brief
  template v2, with the Decisions & Defaults section and the closing interview
  protocol.
- [`DECISIONS.md`](DECISIONS.md) — this repo's own standing decisions, grown by
  promotion (steward dogfoods its own convention).

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
- `docs/` — conventions and protocols the skills reference.
- `templates/` — artifacts (like the brief template) the pipeline validates against.
