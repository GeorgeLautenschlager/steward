<!--
  steward BRIEF TEMPLATE (v2)

  This file is BOTH:
    1. a fill-in skeleton for writing a project brief with Opus in chat, and
    2. a spec a downstream agent can validate an incoming brief against
       (see "Validation checklist" at the bottom).

  How to use: copy this into `BRIEF-<project>.md`, replace every «placeholder»,
  delete the HTML-comment guidance, and keep the section headings. A brief is
  "done" only when it passes the Validation checklist AND its decomposition is
  approved (see Exit criterion).

  D1 — Brief writing stays in chat with Opus. The steward plugin's jurisdiction
  begins only after BOTH the brief and its task decomposition are approved;
  nothing below is dispatched to an implementer until then.
-->

# BRIEF: «project»

**Name:** «ratified name»
**Status:** «Draft | Approved vN — YYYY-MM-DD»
**Origin:** «chat session, YYYY-MM-DD (George + Opus)»

---

## One-liner

«One or two sentences: what this is and the single thing it optimizes for.»

## Context & Problem

«Why this exists. The status quo and where it hurts. Ground the reader in the
problem before any solution.»

## Goals

«Numbered, verifiable outcomes. What "done and working" looks like.»

## Non-Goals

«Explicitly out of scope, so the implementer doesn't gold-plate. Say what you
are *not* doing and, where useful, why.»

## Architecture / Approach

«The shape of the solution: components, boundaries, key mechanisms. Enough that
decomposition into issues is obvious. Omit if a pure-doc/spec project.»

## Decisions & Defaults

<!--
  THE load-bearing section (brief component C1). Every ambiguity an implementer
  could hit, pre-answered or defaulted, in DIRECTIVE form — not discursive
  reasoning. These excerpts are what get pasted into each issue and reach the
  implementer; the rest of the brief does not (settled decisions travel as
  excerpts + DECISIONS.md, never the whole brief). Ratify these before approval.
-->

- **D1.** «decision — one line, settled».
- **D2.** «decision …».
- «…as many as the project needs. Each must be actionable without the reader
  seeing the rest of the brief.»

## Open Questions

<!--
  D9 — Interview closing move. When the brief is otherwise complete, Opus lists
  every remaining open question as a NUMBERED item, each with a PROPOSED DEFAULT,
  so George can bless or veto the whole set in one pass. An empty list here is
  the goal; a question with no proposed default is not done.
-->

- **Q1.** «question?» — *proposed default:* «what we'll do unless vetoed».
- «…»

## Acceptance Criteria

«How anyone verifies the finished work meets the brief. Testable statements,
tied to the Goals.»

## Out of Scope (parking lot)

«Tempting-but-deferred ideas, captured so they stop recurring in discussion.»

---

<!--
  ========================  INTERVIEW PROTOCOL  ========================
  Guidance for Opus while writing the brief in chat (delete when filling in a
  real brief, or keep as a trailing appendix — it is not part of the brief body).

  Opus's job during brief-writing is ADVERSARIAL AMBIGUITY-HUNTING, not
  transcription. Actively look for anything an implementer could interpret two
  ways, and drive each to a Decision & Default. Assume the implementer will read
  ONLY the issue's Decisions & Defaults excerpts and DECISIONS.md — never this
  brief — so any decision not captured as an excerpt is a decision that won't
  reach them.

  Mandatory closing move (D9): present the remaining Open Questions as a numbered
  list, each with a proposed default, for one-pass bless/veto. Do not end the
  interview by asking open-ended "anything else?" — force the defaults.

  EXIT CRITERION (D8): the chat session ends only when BOTH the brief AND its
  task decomposition are approved by George. A brief approved without an approved
  decomposition is not done — decomposition is part of the same session.
-->

## Validation checklist (for downstream agents)

An incoming brief is well-formed under steward v2 iff:

1. **Header** present: name, status (`Approved vN — date` for a live brief), origin.
2. **One-liner, Context & Problem, Goals, Non-Goals, Acceptance Criteria** all present and non-empty.
3. **Decisions & Defaults** present, each entry directive and self-contained (readable without the rest of the brief).
4. **Open Questions** either empty, or every item carries a proposed default (D9).
5. **Status is `Approved`** — and an approved task decomposition exists for it (D8). A brief without an approved decomposition is not dispatchable (D1).

Fail any item → the brief is not ready for dispatch; return it with the failing item(s) named.
