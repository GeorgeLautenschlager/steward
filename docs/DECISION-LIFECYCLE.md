# steward decision lifecycle

How ambiguity becomes standing law — the protocol that lets implementation
proceed without interrupting George, and turns each resolved ambiguity into a
decision never re-litigated.

This doc is self-contained: an agent with no other context can follow it. It
governs what an implementer (Blueberry) does the moment it is unsure, how far
that escalates, and how a one-time answer becomes permanent.

Paths (`.steward/runs/<issue>/ledger.md`, etc.) are defined in
[CONVENTIONS.md](CONVENTIONS.md); this doc defines what goes *in* them.

---

## The lifecycle in one line

**Ambiguity → resolved at the lowest tier that can answer → logged as a ledger
assumption → promoted (if blessed) into `DECISIONS.md` → never asked again.**

---

## When you hit ambiguity: the resolution ladder

You are implementing an issue and you are unsure about something. Work down
this ladder **in order** and stop at the first rung that resolves it. Do not
skip to a higher-cost rung.

**Rung 0 — Read what's already decided.**
Check, in this order:
1. The issue's **Decisions & Defaults** excerpts (pasted into the issue body).
2. The repo-root **`DECISIONS.md`** (if present — see graceful degradation).

If either answers the question, you are done. No ledger entry needed — you
followed standing law, you didn't assume anything.

**Rung 1 — Ask the supervising Opus, who answers *from the brief only*.**
If Rung 0 is silent, escalate to the supervising Opus. Opus resolves it **using
the brief as the sole source** — Opus does not invent policy or ask George on a
whim. If the brief settles it, Opus tells you and the answer is treated as a
ledger assumption (Rung 3 format), sourced to the brief.

**Rung 2 — Default to the most reversible option, and ledger it.**
This is the **normal terminus** for ordinary ambiguity. If the brief doesn't
explicitly answer but the question is *not* in the hard-stop class, do **not**
interrupt George. Take the **most reversible option**, keep moving, and record
a ledger entry (assumption, rationale, reversibility) so the choice surfaces in
the PR for review. A reversible default that a reviewer can veto costs George
far less than a synchronous question.

**Rung 3 — Escalate to George, synchronously — last resort only.**
Go here **only** when both are true: the brief is **silent or
self-contradictory** on the point, **and** you cannot safely default because the
decision is consequential and hard to reverse (typically because it falls in
the **hard-stop class** below, or genuinely requires George's judgment).

A George escalation is a **protocol failure worth measuring, not shame** — it
means the brief should have answered and didn't. Log it: increment
`escalations_george` in metrics (schema owned by issue #11). The fix is a better
brief next time, never blaming the implementer for stopping.

```
Rung 0  standing decisions   →  free, always try first
Rung 1  Opus, from the brief  →  cheap, no George interrupt
Rung 2  reversible default    →  normal path; ledger it, reviewer vetoes if wrong
Rung 3  George, synchronous   →  last resort; a measured protocol failure
```

## The hard-stop class (verbatim)

These are **always** synchronous to George and **never** assumed or defaulted,
regardless of how reversible they look — Rung 2 does not apply to them:

- deletions,
- schema/data migrations,
- external side effects,
- anything security-shaped,
- anything that costs money.

If the ambiguity touches any of these, jump straight to Rung 3.

---

## Ledger entry format

Every assumption taken (Rung 1 brief-sourced answers and Rung 2 reversible
defaults) is logged to that run's `.steward/runs/<issue>/ledger.md`. Each entry
has exactly three parts:

- **Assumption** — what you decided to treat as true / the option you took.
- **Rationale** — why, and what source (brief clause, most-reversible reasoning).
- **Reversibility** — how hard it is to undo if the reviewer disagrees
  (high / medium / low, with a word on the cost).

```markdown
### L<n> — <one-line title>
- **Assumption:** <what you took as given / the option chosen>
- **Rationale:** <why; cite the brief clause or the reversibility argument>
- **Reversibility:** <high|medium|low — one line on the undo cost>
```

The ledger is reproduced **verbatim** in the PR's *Deviations & Assumptions*
section (brief C6), so George reviews every assumption in one batched pass.

---

## DECISIONS.md — standing law

A file at the **repo root**, `DECISIONS.md`, holding decisions that are now
permanent. Format — one entry per line-item:

```markdown
- <YYYY-MM-DD> — <the decision> — <one-line rationale>
```

Three properties:

**Grown, not authored.** No one sits down to write `DECISIONS.md`. It grows by
**promotion**: at PR review close, the supervising Opus takes the ledger
assumptions George **blessed** during review and appends them here (incrementing
`decisions_promoted` in metrics). Every question answered permanently is a
question never asked again — the next run finds it at Rung 0.

**Named `DECISIONS.md` deliberately.** Not `DEFAULTS.md` (ambiguous — these are
settled, not fallbacks), and not folded into an `ARCHITECTURE.md` (different
query pattern: "has this been decided?" vs. "how is this shaped?").

**Graceful degradation.** The protocol must **not** require `DECISIONS.md` to
exist. If it's absent, Rung 0 simply skips it and you **ledger everything** —
promotion just has nowhere to write yet, which is fine. The first blessed
promotion creates the file. No repo is ever blocked for lacking one.

---

## How it fits together (worked path)

1. Implementer hits ambiguity → checks D&D excerpts + `DECISIONS.md` (Rung 0).
2. Not covered → Opus checks the brief (Rung 1). Brief settles it → proceed,
   logged as a brief-sourced ledger entry.
3. Brief silent, not hard-stop → most reversible option + ledger entry (Rung 2).
4. Brief silent *and* hard-stop / high-stakes → George (Rung 3), counted as a
   protocol failure in metrics.
5. PR packaging folds the ledger into *Deviations & Assumptions* verbatim.
6. George reviews, blesses/vetoes each assumption.
7. Opus promotes blessed entries into `DECISIONS.md` and logs
   `decisions_promoted`. Those questions are now standing law.
