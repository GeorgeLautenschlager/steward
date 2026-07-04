# ISSUES: steward v1

**Brief:** BRIEF-steward.md (Approved v1, 2026-07-03)
**Repo:** `GeorgeLautenschlager/steward`
**Q4 resolved:** shakedown target = **face-dancer** (NPC agent project)

This file is the decomposition record. Commit it at repo root next to the
brief. File the issues in order on the fresh repo and the GitHub numbers
will match the numbers below.

**Filing instructions (for supervising Opus in Claude Code):**
1. Prereq: `gh repo create GeorgeLautenschlager/steward --private --clone`
2. Commit BRIEF-steward.md and this file at root.
3. For each `## Issue N` section below, in order:
   `gh issue create --repo GeorgeLautenschlager/steward --title "<title>" --body "<body>"`
   using the section body verbatim. Add label `phase-<N>` per the heading.
4. Do not start Phase 1+ work until #1 is merged.

**Dependency summary:** 1 → everything · 2 → 9 · {3,4,5} → 6 → 9 ·
4 → {10, 11} · all → 12. Phase 0 items are parallelizable.

---

## Issue 1 — walking-skeleton [phase-0]

**Scope:** The plugin exists and loads. Create the repo with
`.claude-plugin/plugin.json` (name `steward`, version 0.1.0), an empty
`skills/` directory at plugin root, a README stub, and BRIEF-steward.md +
ISSUES.md committed at root.

Guardrail: only `plugin.json` lives inside `.claude-plugin/`; `skills/`
and everything else sit at plugin root. Load locally via
`claude --plugin-dir` for development; `/reload-plugins` picks up edits
mid-session.

**Deliverable:** A fresh Claude Code session loads steward with zero
skills and zero errors.

**Acceptance:**
- Plugin visible/loaded in a fresh session via `--plugin-dir`.
- Brief and this file present at repo root.

---

## Issue 2 — spike-gh-inline [phase-0] [spike]

**Scope:** From Blueberry's environment on the Linux server (shared `gh`
auth), against a scratch PR: (a) post a PR-level comment, (b) post an
**inline review comment** on a specific file + line (expect `gh api` on
the pulls review-comment endpoints; note required fields such as
commit_id, path, line/side), (c) confirm the auth scopes suffice.

Timebox: half a day. Output is knowledge, not code. Resolves D12.

**Deliverable:** `docs/SPIKE-gh-inline.md` — working incantations,
required fields, limitations, and anything that surprised you.

**Acceptance:**
- Doc merged; supervisor reproduces the inline-comment command once.
- Blocks #9; unblock it by linking the doc there.

---

## Issue 3 — migrate-local-sdd [phase-1]

**Scope:** Copy the parallel Subagent Driven Development skill
**verbatim** from `superpowers-local-subagent` into steward's `skills/`.
Change only what loading requires (frontmatter/name). No behavior changes.

Transition note (pre-seeded ledger decision): the fork stays installed
during the parallel period (D11), so give steward's copy a distinct
frontmatter name (e.g. `steward-local-sdd`) to avoid a name collision —
most reversible option; log it in the ledger.

**Deliverable:** Steward-provided SDD skill, parity-checked by running
one trivial task through it.

**Acceptance:**
- Trivial task completes identically to the fork's skill.
- Diff vs the fork's skill file is load-related only.
- face-dancer work uses steward's copy from this point forward.

---

## Issue 4 — fs-conventions [phase-1]

**Scope:** One decision: where steward's state lives. Spec doc covering:
- `.steward/runs/<issue-number>/` → `ledger.md`, `runlog.md` (ephemeral,
  gitignored; contents get folded into the PR).
- `.steward/metrics.jsonl` → committed (durable, greppable, consumable
  by Opus/Pi/somebody later).
- gitignore policy implementing the above.

Proposal above is the default; implementer may deviate via ledger entry.

**Deliverable:** `docs/CONVENTIONS.md`.

**Acceptance:** Doc merged; #6, #10, #11 reference it rather than
restating paths.

---

## Issue 5 — decision-lifecycle [phase-1]

**Scope:** One decision: how ambiguity becomes standing law. Spec doc
covering, per brief C4/C5:
- Ledger entry format: assumption, rationale, reversibility note.
- Escalation tiers: Blueberry → supervising Opus (answers **from the
  brief only**) → George (only if brief is silent or self-contradictory;
  log it as a protocol failure in metrics, not shame).
- Hard-stop class, verbatim: deletions, schema/data migrations, external
  side effects, anything security-shaped, anything that costs money.
- DECISIONS.md format: date, decision, one-line rationale.
- Promotion mechanic: blessed ledger entries promoted by Opus at review
  close.
- Graceful degradation: no DECISIONS.md → ledger everything.

**Deliverable:** `docs/DECISION-LIFECYCLE.md`, readable by an agent with
zero other context.

**Acceptance:** Doc merged; every C4/C5 clause represented; a cold-read
by a fresh instance raises no clarifying questions.

---

## Issue 6 — dispatch-payload [phase-2] *(deps: 3, 4, 5)*

**Scope:** Extend steward's SDD skill so every dispatch to Blueberry
includes: the brief, the issue body, DECISIONS.md (if present), and the
decision-lifecycle spec. Capture both stages of the existing per-task
review (spec compliance, then code quality) — findings **and**
resolutions — to `.steward/runs/<issue>/runlog.md` instead of letting
them die in-session.

**Deliverable:** Updated skill.

**Acceptance:**
- A sample dispatch shows the complete payload.
- On a toy task, runlog contains both review stages with resolutions.

---

## Issue 7 — brief-template-v2 [phase-2]

**Scope:** Commit `templates/BRIEF-TEMPLATE.md` to the plugin. The
template update itself happens with George in chat first (out of band);
this issue lands the canonical copy, which must include:
- Decisions & Defaults section.
- Interview protocol: adversarial ambiguity-hunting; mandatory closing
  move = numbered open questions, each with a proposed default, for
  one-pass bless/veto (D9).
- Exit criterion: chat session ends only when brief AND decomposition
  are approved (D8).

**Deliverable:** Committed template.

**Acceptance:** Template matches D1/D8/D9; downstream agents can
validate an incoming brief against it.

---

## Issue 8 — decomposition-protocol [phase-2]

**Scope:** Skill (or doc — implementer's call, ledger it) covering:
- Sizing heuristic: one issue = one PR = one reviewable decision; size
  by conceptual load, not lines; anti-goal is tiny-PR spam (each PR has
  fixed attention cost).
- Issue template: brief link, acceptance criteria, relevant Decisions &
  Defaults excerpts.
- Flow: Opus proposes the list; George approves/edits in the same chat
  session as the brief.

**Deliverable:** `skills/decomposition/` or `docs/DECOMPOSITION.md`.

**Acceptance:** Merged; this very ISSUES.md validates against the issue
template (self-referential check intended).

---

## Issue 9 — pr-packaging [phase-3] *(deps: 2, 6)*

**Scope:** The PR as verification trail. Skill directing that:
- **Pi authors** the PR description from run artifacts, with six
  mandatory sections: (1) Summary — three sentences max; (2) Brief
  mapping; (3) Deviations & Assumptions — the ledger, verbatim;
  (4) Uncertainties; (5) Evidence — test output, before/after;
  (6) Review trail — from runlog.
- Pi posts inline self-review comments on its own diff per the spike doc
  (rationale lives on the diff, not as permanent code comments).
- **Opus reviews** the description against the brief before George is
  pinged, focusing on brief-mapping and deviations (Pi's blind spot).

**Deliverable:** Packaging skill + Opus review checklist.

**Acceptance:** A toy PR ships with all six sections and ≥1 inline
self-review comment; checklist run once and captured in runlog.

---

## Issue 10 — adversarial-review [phase-3] *(deps: 4)*

**Scope:** Fresh-context reviewer skill. The reviewer receives **brief +
diff only** — never the supervisor's plan (anchoring). Verdict classes:
**blocking** for spec violations, **advisory** for taste. Findings and
resolutions appended to runlog → PR review trail.

**Deliverable:** Reviewer skill.

**Acceptance:** A seeded spec violation produces a block; a seeded taste
nit produces an advisory; both land in the review trail.

---

## Issue 11 — metrics [phase-3] *(deps: 4)*

**Scope:** At review close, Opus asks George for one number
(`review_minutes`) and appends a line to `.steward/metrics.jsonl` using
the brief's schema verbatim:

```json
{"ts": "", "repo": "", "issue": 0, "pr": 0, "diff_lines": 0,
 "escalations_opus": 0, "escalations_george": 0, "hard_stops": 0,
 "ledger_entries": 0, "decisions_promoted": 0,
 "review_minutes": 0, "rework": false}
```

**Deliverable:** Metrics step in the review-close flow.

**Acceptance:** Line appended on a toy review; parses with `jq`.

---

## Issue 12 — acceptance-run [phase-4] *(deps: all)*

**Scope:** Full shakedown on **face-dancer**. Pick one real, small issue
there and run it end-to-end: dispatch → ledger → two-stage reviews →
packaged PR → adversarial review → George. This issue lives in steward;
the work PR lands in face-dancer.

Verify the brief's acceptance criteria:
- Zero synchronous questions to George outside the hard-stop class.
- PR carries all six sections, inline self-review, adversarial trail.
- ≥1 ledger assumption promoted to face-dancer's DECISIONS.md.
- Metrics line exists and parses.

**Deliverable:** The shakedown PR + a short retro note in the issue.

**Acceptance:** Criteria above verified → **go/no-go decision on
archiving `superpowers-local-subagent`** recorded here.
