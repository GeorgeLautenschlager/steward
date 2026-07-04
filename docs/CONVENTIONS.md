# steward filesystem conventions

Where steward's state lives, and which parts are durable vs ephemeral. This
doc is the single source of truth for these paths — other skills and issues
(#6, #10, #11) reference it rather than restating them.

All steward state lives under a single top-level directory, `.steward/`, in
the **target repository** (the repo being worked on), not in the plugin. There
are exactly two kinds of state, split by lifetime:

```
<repo root>/
├── .steward/
│   ├── runs/
│   │   └── <issue-number>/          # ephemeral, gitignored — one dir per issue
│   │       ├── ledger.md            #   assumption ledger (C4)
│   │       └── runlog.md            #   per-task review findings + resolutions (C3/C6)
│   └── metrics.jsonl                # durable, committed — one line per PR (C8)
└── .gitignore                       # ignores .steward/runs/ (see policy below)
```

---

## Ephemeral run state — `.steward/runs/<issue-number>/`

One directory per issue, keyed by the **GitHub issue number** it implements.
These files are working memory for a single run. They are **gitignored** and
never committed; their contents are **folded into the PR** at packaging time
(brief C6) and thereby preserved in the durable review trail. When the PR is
open, the run directory has done its job — it can be deleted or left to rot.

**Rationale:** these artifacts are verbose, run-local, and only meaningful
mid-flight. Committing them would bloat history and duplicate what the PR
already carries in a reader-friendly form. The PR is the durable copy; the
run dir is scratch.

### `ledger.md` — the assumption ledger (brief C4)

Every assumption Blueberry (or the supervisor) takes under the decision-lifecycle
protocol, logged as it happens. Each entry records **assumption, rationale, and
a reversibility note**. At PR packaging, the ledger is reproduced **verbatim**
in the PR's *Deviations & Assumptions* section; at review close, blessed entries
are promoted to `DECISIONS.md` (brief C5). The exact entry format is owned by
the decision-lifecycle spec (issue #5); this doc only fixes the file's location
and lifetime.

### `runlog.md` — the review trail (brief C3/C6)

Both stages of every per-task review (spec compliance, then code quality) —
**findings and their resolutions** — captured here instead of dying in-session.
At PR packaging, this becomes the PR's *Review trail* section. The dispatch/
capture mechanics are owned by issue #6.

---

## Durable metrics — `.steward/metrics.jsonl`

A single append-only JSONL file at `.steward/` root. **Committed** — it is
durable, greppable, and consumable later by Opus, Pi, or tooling. One line is
appended per PR by the supervising Opus at review close (brief C8). No
directory nesting, no per-issue split: one flat file the whole repo shares, so
`jq`/`grep` over the full history is trivial.

**Rationale:** metrics are the one steward artifact meant to outlive the run
and accumulate across PRs — the whole point is longitudinal measurement of
attention spend. JSONL keeps it append-only, diff-friendly, and toolable
without a schema migration story. The line schema is owned by issue #11
(brief C8); this doc only fixes that the file is committed and lives here.

---

## gitignore policy

The policy is exactly: **ignore the ephemeral run state, commit everything
else under `.steward/`.** One line implements it:

```gitignore
.steward/runs/
```

`.steward/metrics.jsonl` is *not* ignored, so it is tracked and committed by
default. No allow-list negation is needed because `runs/` is the only ignored
path under `.steward/` — anything else added there later is committed unless a
future convention says otherwise.

---

## Deviating from these conventions

This layout is the ratified default (brief C4–C8). An implementer may deviate
for a specific run, but only via a **ledger entry** (`assumption, rationale,
reversibility`) in that run's `ledger.md`, so the deviation surfaces in the PR.
Silent divergence from these paths is a defect — downstream skills hard-code
none of them except through this document.
