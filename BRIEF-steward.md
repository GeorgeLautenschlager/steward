# BRIEF: Steward

**Name:** `steward` (ratified)
**Status:** Approved v1 — 2026-07-03
**Origin:** Chat session, 2026-07-03 (George + Opus)
**Successor to:** `superpowers-local-subagent` fork (to be retired)

---

## One-liner

A standalone Claude Code plugin that restructures the George → Opus → Blueberry
pipeline around a single metric: **efficiency of George's attention spend.**

---

## Context & Problem

The current workflow (idea → chat discussion → brief → GitHub issues → Opus
supervises Blueberry → PR → George reviews) works, but George is the
bottleneck. Attention leaks in four places:

1. **Brief writing** under-invests: ambiguities survive into implementation.
2. **Decomposition** produces PRs sized by convenience, not reviewability.
3. **Mid-flight clarification** interrupts George synchronously — the most
   expensive form of attention (context switch + rebuild).
4. **Final review** re-verifies work that was already verified inside the
   Claude Code session, because that evidence never reaches the PR.

The existing fork (`superpowers-local-subagent`) exists only to host a
parallel Subagent Driven Development skill that dispatches to Pi/Blueberry
instead of Claude subagents. Upstream explicitly directs fork-specific and
domain-specific work into standalone plugins.

## The Metric

**How efficiently are we spending George's limited attention?**

Attention taxonomy, in ascending cost:

| Type | Description | Who should pay it |
|---|---|---|
| Generation | Producing code, docs, descriptions | Machines |
| Translation | Turning judgment into artifacts | Machines |
| Verification | Checking mechanical correctness | Machines (CI, reviewers) |
| Judgment | Decisions only George can make | George — batched |
| Interrupt | Synchronous questions mid-flight | Nobody, if avoidable |

**Design rule:** George spends judgment only, always batched, never
interrupted between "decomposition approved" and "PR ready for review."

## Goals

1. Zero synchronous interruptions of George during implementation, except
   the hard-stop class (defined below).
2. Every clarification either pre-answered (brief, DECISIONS.md) or converted
   into a logged, reviewable assumption.
3. PRs arrive as **verification trails**, not raw diffs: George reviews
   evidence and decisions, not implementation minutiae.
4. Attention spend is measured, not vibed.
5. The fork is retired; upstream Superpowers runs vanilla.

## Non-Goals

- Modifying upstream Superpowers or maintaining a fork of it.
- Changing Pi/Blueberry internals.
- Removing George as final decider. We are optimizing his attention,
  not automating his judgment away.
- Metrics dashboards, aggregation tooling, or anything heavier than JSONL.
- Guaranteeing DECISIONS.md exists in every repo (graceful degradation).

---

## Architecture

A single standalone Claude Code plugin (`steward`) installed alongside
vanilla upstream Superpowers. Plugin provides skills; no hooks, agents, or
MCP servers in v1. The `superpowers-local-subagent` fork is deleted after
its parallel SDD skill migrates here.

Chat (claude.ai) remains the design surface: briefs are written in
conversation with Opus, on the couch, while twins refuse to sleep. This is
load-bearing and out of scope to change. The plugin's jurisdiction begins
at "approved brief + approved decomposition exist."

### Components

**C1. Brief template v2** (artifact update, not plugin code)
- Adds a **Decisions & Defaults** section: every ambiguity implementation
  could hit, pre-answered or defaulted.
- Interview protocol: Opus's job during brief writing is adversarial
  ambiguity-hunting. Mandatory closing move: a numbered list of open
  questions, each with a proposed default, for one-pass bless/veto.
- Exit criterion for the chat session: brief approved AND task
  decomposition approved. Not done until both.
- Plugin carries a copy of the template so downstream agents can validate
  incoming briefs against it.

**C2. Decomposition protocol** (skill + template guidance)
- Opus proposes the issue list; George approves/edits. Reviewing a list is
  cheaper than writing one.
- Unit of decomposition: **one issue = one PR = one reviewable decision.**
  Size by conceptual load, not lines. Anti-goal: tiny-PR spam — each PR
  carries fixed attention cost (open, load context, check CI), so
  minimizing diff size past the one-decision point is net negative.
- Each issue carries: link to brief, acceptance criteria, relevant
  Decisions & Defaults excerpts.

**C3. local-subagent-driven-development skill** (migrated from fork, extended)
- Preserves existing behavior: dispatch tasks to Pi/Blueberry, two-stage
  per-task review (spec compliance, then code quality).
- Dispatch payload now includes: brief, issue, DECISIONS.md (if present),
  and the Assumption Ledger protocol (C4).
- All per-task review findings and resolutions are captured to a run log
  for PR packaging (C6) instead of dying in-session.

**C4. Assumption Ledger protocol** (spec, embedded in C3 dispatch)
When Blueberry hits ambiguity, in order:
1. Check the issue's Decisions & Defaults excerpts, then DECISIONS.md.
2. Still ambiguous → escalate to supervising Opus, who answers **from the
   brief only**.
3. Brief is silent or self-contradictory → synchronous escalation to George
   (this is a protocol failure worth a metrics entry, not shame).
4. Otherwise: take the **most reversible option**, log it to the ledger
   with rationale.

**Hard-stop class** (always synchronous, never assumed): deletions,
schema/data migrations, external side effects, anything security-shaped,
anything that costs money.

**C5. DECISIONS.md convention**
- Repo-root file of standing decisions: date, decision, one-line rationale.
- Grown, not authored: at PR review, blessed ledger assumptions are
  promoted into it by Opus. Every question answered permanently is a
  question never asked again.
- Graceful degradation: absent file → ledger everything. Protocol must not
  require its existence. Named DECISIONS.md (not DEFAULTS.md — ambiguous;
  not folded into ARCHITECTURE.md — different query pattern: "has this
  been decided?" vs "how is this shaped?").

**C6. PR packaging skill**
- **Pi authors** the PR description via `gh` CLI; **Opus reviews** it
  against the brief before George is pinged. Author = most context;
  reviewer focuses on brief-mapping and deviations (Pi's blind spot).
- Mandatory sections:
  1. Summary (what + why, three sentences max)
  2. Brief mapping (which brief items this implements)
  3. Deviations & Assumptions (the ledger, verbatim)
  4. Uncertainties (what the author isn't sure about)
  5. Evidence (test output, before/after behavior)
  6. Review trail (per-task reviewer findings + resolutions from C3)
- Pi also posts inline self-review comments on its own diff (rationale
  lives on the diff, not as permanent code comments).

**C7. Adversarial review skill**
- A fresh-context reviewer (clean instance, sees **brief + diff only** —
  not the supervisor's plan, to avoid anchoring) reviews before George.
- Blocking on spec violations; advisory on taste.
- Findings + resolutions appended to the PR's review trail.

**C8. Metrics** (minimal v1)
- One JSONL line per PR, appended by Opus at review close, to
  `.steward/metrics.jsonl` (repo-local; aggregation is someone else's
  future problem).
- Schema (v1):
  ```json
  {"ts": "", "repo": "", "issue": 0, "pr": 0, "diff_lines": 0,
   "escalations_opus": 0, "escalations_george": 0, "hard_stops": 0,
   "ledger_entries": 0, "decisions_promoted": 0,
   "review_minutes": 0, "rework": false}
  ```
- `review_minutes` is self-reported: Opus asks George for one number at
  review close. Cheap, honest enough.

---

## End-to-end workflow (target state)

1. **Chat:** idea → discussion → Opus interviews (C1) → brief with
   Decisions & Defaults → Opus proposes decomposition (C2) → George
   approves both. Chat session ends.
2. Issues filed with brief links and D&D excerpts.
3. **Per issue:** Opus dispatches Blueberry (C3) → implementation under
   the ledger protocol (C4) → two-stage task reviews logged → Pi opens PR
   with full packaging + inline self-review (C6) → adversarial review
   (C7) → Opus verifies description against brief → George pinged.
4. **George:** reviews the verification trail, rules on deviations and
   uncertainties, blesses or vetoes. Blessed assumptions promoted to
   DECISIONS.md (C5). Opus logs metrics (C8).

## Ratified Decisions & Defaults

*(Settled in the 2026-07-03 session — this section dogfoods C1.)*

- D1. Brief writing stays in chat with Opus. Plugin jurisdiction starts
  after brief + decomposition approval.
- D2. Fork is retired; local-SDD skill migrates into this plugin; upstream
  Superpowers runs vanilla from the marketplace.
- D3. Escalation tiers and hard-stop class as specified in C4.
- D4. Adversarial reviewer: blocking for spec violations, advisory for
  taste; sees brief + diff only.
- D5. Pi authors PR descriptions; Opus reviews them against the brief.
  Both use the shared `gh` auth on the Linux server.
- D6. Standing decisions live in DECISIONS.md, grown via promotion, with
  graceful degradation when absent.
- D7. Metrics ship in v1 as repo-local JSONL, schema above.
- D8. Chat session exit criterion: brief AND decomposition approved.
- D9. Interview protocol closes with numbered proposals + defaults for
  one-pass approval.
- D10. Plugin name: `steward`.
- D11. Fork and steward run in parallel for one shakedown project; fork
  archived after a clean end-to-end run.
- D12. `gh` inline diff-comment mechanics verified by a dedicated spike
  before C6 lands.

## Open Questions

- Q4. Shakedown target project for the parallel run — to be named at
  decomposition approval.

## Acceptance Criteria

- A test issue flows end-to-end with **zero synchronous questions** to
  George outside the hard-stop class.
- The resulting PR contains all six C6 sections, inline self-review
  comments, and an adversarial review trail.
- At least one ledger assumption is promoted to DECISIONS.md through the
  review flow.
- A metrics line exists for the PR and parses.
- Upstream Superpowers is running unmodified; the fork repo is archived.

## Out of Scope for v1 (parking lot)

- Metrics aggregation/visualization across repos.
- Auto-sizing decomposition from historical review_minutes data.
- Any integration with Theseus (tempting; resist).
