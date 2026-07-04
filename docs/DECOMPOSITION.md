# steward decomposition protocol

How an approved brief becomes a set of issues. Reviewing a good list is far
cheaper than writing one, so **Opus proposes the decomposition and George
approves or edits it — in the same chat session as the brief** (D8: the session
isn't done until both the brief and its decomposition are approved). Per D1 this
is chat work; the plugin's jurisdiction starts only once the approved list
exists.

---

## Sizing heuristic

**One issue = one PR = one reviewable decision.**

Size by **conceptual load, not lines**. The unit is a single decision a reviewer
can hold in their head and rule on — not a fixed diff size. A 300-line change
that embodies one decision is one issue; two unrelated 10-line changes are two.

**Anti-goal: tiny-PR spam.** Every PR carries a *fixed* attention cost —
open it, load the context, check CI, rule on it — independent of diff size. So
splitting past the one-decision point is net-negative: it multiplies that fixed
cost without reducing the judgment required. Don't minimize diff size for its own
sake; minimize the number of *distinct decisions per PR* to one, and let the diff
be whatever that decision needs.

Symptoms you've sized wrong:
- **Too big:** the PR forces the reviewer to rule on two things that could be
  blessed or vetoed independently. Split on the decision boundary.
- **Too small:** the PR can't be reviewed without also opening its siblings, or
  its acceptance criteria are "part of" another issue's. Merge them.

## Issue template

Every issue carries:

1. **Brief link** — which brief this decomposes. May be stated once at the file
   level for a decomposition document that lists many issues, or per-issue.
2. **Scope / description** — what this issue does, in enough detail to dispatch.
3. **Acceptance criteria** — how anyone verifies it's done, tied to the brief.
4. **Relevant Decisions & Defaults** — the excerpts (or explicit citations, e.g.
   "per brief C4") of the settled decisions *this* issue turns on. Include only
   the relevant ones; an issue that turns on no specific decision carries none.
   These excerpts are what reach the implementer at dispatch (the brief itself
   does not — see `steward-local-sdd` → Steward Dispatch Payload), so a decision
   an issue depends on **must** appear here or in `DECISIONS.md`.

Skeleton:

```markdown
## Issue N — <short-title> [phase-X]  (deps: …)

**Scope:** <what this issue does>

**Deliverable:** <the concrete artifact>

**Acceptance:** <verifiable criteria>

<Relevant Decisions & Defaults excerpts or citations, if any>
```

## Flow

1. Brief reaches Approved (see the brief template's exit criterion).
2. **Opus proposes** the full issue list — titles, scope, deliverable,
   acceptance, deps, and the relevant D&D excerpts per issue.
3. **George approves or edits** the list in the same session. Editing a proposed
   list is cheap judgment; writing one from scratch is not — that asymmetry is
   the point.
4. Session ends only when brief **and** decomposition are approved (D8). The
   approved list is then filed as issues; plugin jurisdiction begins.

---

## Validation checklist (for downstream agents)

A decomposition is well-formed under steward v2 iff:

1. **Brief linked** — the decomposition names its brief, file-level or per-issue.
2. **Every issue has explicit acceptance criteria.**
3. **Decision coverage** — every issue that depends on a settled decision cites
   or excerpts it (or it lives in `DECISIONS.md`); issues that depend on none
   carry none. No issue silently relies on an un-captured decision.
4. **Sizing (judgment)** — each issue reads as one reviewable decision / one PR;
   no issue bundles two independently-vetoable decisions, and none is so small it
   can't be reviewed without its siblings.

Fail 1–3 → return the decomposition with the failing issue(s) named. Item 4 is a
judgment call raised as advisory, not a mechanical gate.
