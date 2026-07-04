# Decision & ledger protocol — for the implementer

> Assembled into the dispatch context pack by the controller (see SKILL.md →
> Steward Dispatch Payload). This is the implementer-facing capsule of the full
> `docs/DECISION-LIFECYCLE.md`; it repeats only what an implementer running
> headless needs. When it and the full spec disagree, the full spec wins.

You are implementing this issue without the ability to ask questions mid-run
(see the Local Execution Protocol in the footer). When you hit something the
task doesn't settle, **do not guess silently**. Work this ladder in order and
stop at the first rung that resolves it.

**Rung 0 — Read what's already decided.** Check, in order: the issue's
*Decisions & Defaults* excerpts (in the issue body included below), then the
target repo's root `DECISIONS.md` (included below if it exists). If either
answers it, proceed — no ledger entry needed, you followed standing law.

**Rung 1 — Take the most reversible option, and ledger it.** This is the normal
path for ordinary ambiguity. If nothing above settles it and the point is **not
in the hard-stop class** below, pick the option that is easiest to undo if a
reviewer disagrees, keep working, and record a ledger entry (format below). A
reversible default a reviewer can veto is cheaper than blocking.

**Rung 2 — Stop and report, for hard-stops or anything you cannot safely
default.** If the ambiguity touches the **hard-stop class**, or is consequential
and hard to reverse, do **not** default. Stop and end your run with
`STATUS: NEEDS_CONTEXT` (missing information) or `STATUS: BLOCKED` (cannot
proceed), listing the specific question. The controller escalates to the brief,
and to the human only if the brief is silent — that path is not yours to take
headless.

## The hard-stop class — never default these

Always stop and report; never assume:

- deletions,
- schema/data migrations,
- external side effects,
- anything security-shaped,
- anything that costs money.

## Ledger entry format

Write every assumption you take under Rung 1 to `.steward/runs/<issue>/ledger.md`
in the worktree (create the file/dirs if absent). One entry each:

```markdown
### L<n> — <one-line title>
- **Assumption:** <what you took as given / the option chosen>
- **Rationale:** <why; cite the source or the most-reversible argument>
- **Reversibility:** <high|medium|low — one line on the undo cost>
```

The controller folds this ledger, verbatim, into the PR for the human to review.
Logging an assumption is the expected, non-blaming way to keep moving — an
unlogged silent guess is the only wrong move.
