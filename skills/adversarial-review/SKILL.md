---
name: adversarial-review
description: Use after PR packaging and before George is pinged, to run a fresh-context reviewer that sees only the brief and the diff — never the supervisor's plan — and returns blocking findings for spec violations and advisory findings for taste
---

# Adversarial Review — the fresh-context gate before George

The last check before George is a reviewer that **cannot be anchored**. The
per-task reviewers (in `steward-local-sdd`) and the packaging review (in
`pr-packaging`) all ran *with* the supervisor's framing — they know how the work
was meant to be built. That shared context is exactly what makes them miss a
diff that is internally consistent but wrong against the brief. This reviewer is
handed **the brief and the diff, and nothing else**, and asked one question:
*does this diff satisfy the brief?*

**Anchoring is the enemy.** Do not give the reviewer the supervisor's plan, the
dispatch payload, the ledger, the PR description, the runlog, or the per-task
review results. Every one of those carries the author's story about why the code
is right, and a reviewer who reads the story grades the story. A clean instance
that has never seen the story grades the code.

## What the reviewer receives — and what it must not

**Gets:**
- **The brief** — the ground truth for what's wanted (its Decisions & Defaults
  especially).
- **The diff** — `git diff <BASE_SHA>..HEAD`, the whole change under review.
- **The issue's acceptance criteria** — the scoping lens, so the reviewer judges
  *this* PR's slice of the brief and doesn't flag other issues' work as missing.
  (This is spec, not plan — it says *what*, never *how*.)

**Must NOT get (anchoring vectors):**
- the supervisor's plan or dispatch reasoning,
- the ledger / assumptions,
- the PR description,
- the runlog or per-task review findings,
- anything narrating *how* or *why* the code was built.

Run it as a **fresh subagent on the most capable model** (a clean Task instance),
with the prompt in [`./adversarial-reviewer-prompt.md`](./adversarial-reviewer-prompt.md).

## Verdict classes

Every finding is exactly one of:

- **BLOCKING** — a **spec violation**: the diff contradicts, or fails to meet, a
  brief requirement or a Decisions & Defaults entry (or the issue's acceptance
  criteria). Blocking findings must be resolved before George — fixed, or
  escalated if the spec itself is the problem.
- **ADVISORY** — a **taste** matter: clarity, naming, structure, idiom — anything
  the brief does *not* mandate. The author may address it or defer it with a
  reason. Advisory never blocks.

The line is: **does the brief require it?** Required and unmet → blocking.
Preference not in the brief → advisory. When genuinely unsure which side a
finding falls on, mark it blocking and say why — a false block costs a
conversation; a false pass ships a spec violation.

## Findings and resolutions → review trail

Append the review to `.steward/runs/<issue>/runlog.md` (path per
`docs/CONVENTIONS.md`) as a `## Adversarial review` section, so it becomes part
of the PR's Review trail (C6/#9). For each finding record:

- verdict class (BLOCKING / ADVISORY),
- the `file:line`,
- for a block, the brief clause it violates,
- the **resolution**: the fix (commit sha) for a block, or the author's
  disposition (addressed / deferred-with-reason) for an advisory.

A blocking finding with no resolution is an open gate: George is not pinged until
every block is resolved and logged.

## Where it sits

`steward-local-sdd` (implement + per-task review) → `pr-packaging` (six-section
description + Opus review) → **`adversarial-review`** (this, fresh gate) → George.

## Red flags

- **Feeding the reviewer anything but brief + diff (+ acceptance criteria)** —
  that reanchors it and defeats the purpose.
- **Reusing a subagent that already saw the plan/PR** — it's contaminated; spawn a
  clean one.
- **Letting a block through as advisory to avoid a fix** — if the brief requires
  it, it blocks.
- **Pinging George with an unresolved blocking finding.**

## Integration

- **`pr-packaging`** — runs before this; its runlog is where this appends.
- **`docs/DECISION-LIFECYCLE.md`** — a block on a spec the brief got wrong is
  escalated per the ladder, not silently "fixed" to match a bad spec.
- **`docs/CONVENTIONS.md`** — the runlog path.
