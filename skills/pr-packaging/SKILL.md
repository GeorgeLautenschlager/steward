---
name: pr-packaging
description: Use at the end of a steward run, after all tasks pass review, to package the PR as a verification trail — Pi authors the six-section description from run artifacts and posts inline self-review comments; Opus reviews it against the brief before George is pinged
---

# PR Packaging — the PR as verification trail

A steward PR is not a raw diff for George to re-review. It is a **verification
trail**: the evidence and decisions he needs to rule on the work in one batched
pass, so he never re-derives what was already verified inside the run. This skill
turns the run artifacts (`ledger.md`, `runlog.md`, test output, the diff) into
that trail.

**Division of labor** (brief C6):
- **Pi authors** the PR description and posts inline self-review comments — Pi
  has the most context on what it built.
- **Opus reviews** the description against the **brief** before George is pinged,
  focusing on **brief-mapping and deviations** — precisely Pi's blind spot,
  because the implementer never saw the brief (context isolation, see
  `steward-local-sdd` → Steward Dispatch Payload).
- **George** rules last, on evidence and decisions, not minutiae.

## Inputs — the run artifacts

All under `.steward/runs/<issue>/` (see `docs/CONVENTIONS.md`):
- **`ledger.md`** — the assumptions taken (→ section 3, verbatim).
- **`runlog.md`** — both review stages' findings + resolutions (→ section 6).
- **Test output / before-after** — captured during the run (→ section 5).
- **The diff** — `git diff <BASE_SHA>..HEAD` (→ inline self-review targets).

## The six mandatory sections

Pi authors the description from the [template](./pr-description-template.md).
Every section is required; an empty one is a defect, not an omission.

1. **Summary** — what and why, **three sentences max**. No implementation detail.
2. **Brief mapping** — which brief items this implements. Pi drafts this from the
   issue body and its Decisions & Defaults excerpts (Pi's only view of the
   brief); **Opus reconciles it against the actual brief** at review (§Opus
   review). This is the section most likely to be wrong in Pi's hands — flag it.
3. **Deviations & Assumptions** — the run's `ledger.md`, **verbatim**. Every
   assumption George should bless or veto, with its reversibility note.
4. **Uncertainties** — what the author isn't sure about; anything a reviewer
   should look at harder. Honesty here is cheaper than a missed bug.
5. **Evidence** — test output, before/after behavior, commands run. The proof the
   work does what it claims, so George reads results, not the diff.
6. **Review trail** — from `runlog.md`: both review stages, findings **and**
   resolutions. The record that the work was already verified in-run.

## Inline self-review comments (Pi, on its own diff)

Rationale that explains *why a line is the way it is* belongs **on the diff as a
review comment**, not as a permanent code comment that outlives its usefulness.
Pi posts at least the non-obvious ones on its own PR.

Verified incantation (spike #2; single inline comment on the PR):

```bash
gh api -X POST "repos/$OWNER/$REPO/pulls/$PR/comments" \
  -f body="<why this line is like this>" \
  -f commit_id="$HEAD_SHA" \
  -f path="<file path>" \
  -F line=<line number on the RIGHT/new side> \
  -f side="RIGHT"
```

- `commit_id` is the PR head SHA (`git rev-parse HEAD`).
- `-F line=` takes an integer (line in the file's new version); `side=RIGHT` for
  added/changed lines, `LEFT` for a deleted line's old position.
- For a range, add `-F start_line=<n> -f start_side=RIGHT`.
- To batch several comments as one review instead of individually, POST to
  `pulls/$PR/reviews` with a `comments[]` array (`path`, `line`, `body`) and
  `event=COMMENT`; the per-comment endpoint above is enough for most runs.

## Authoring + posting flow (Pi)

1. Fill `./pr-description-template.md` from the run artifacts. Keep Summary ≤ 3
   sentences; paste the ledger verbatim (§3) and the runlog stages (§6).
2. Open the PR with the assembled body:
   `gh pr create --base <default> --head <branch> --title "…" --body-file <file>`.
3. Post inline self-review comments on the non-obvious lines of the diff (above).

> **Editing an existing PR body:** on this repo `gh pr edit --body-file` silently
> no-ops (classic-projects GraphQL bug). Use REST instead:
> `gh api -X PATCH repos/$OWNER/$REPO/pulls/$PR -F body=@file.md`, then verify.

## Opus review (before George is pinged)

Run [`./opus-review-checklist.md`](./opus-review-checklist.md) against the PR
description **with the brief open**. Opus's job is not to re-review the code (the
per-task reviewers did that) but to catch what Pi structurally cannot: whether
the **Brief mapping** is truthful against the real brief, and whether every
**Deviation** is surfaced and correctly characterized.

Capture the checklist result — pass, or the gaps found and how they were fixed —
to `.steward/runs/<issue>/runlog.md` as a final `## PR packaging — Opus review`
entry, so the review trail records that the description itself was verified.
Only after the checklist passes is George pinged.

## Red flags

- **A raw-diff PR with no six-section body** — George should never be the first
  to assemble the verification trail.
- **An empty required section** — especially Evidence or Review trail. Fill it or
  the work isn't done.
- **Brief mapping written and shipped without Opus reconciling it against the
  brief** — Pi never saw the brief; unreviewed mapping is a guess.
- **Rationale buried as permanent code comments** instead of inline PR comments.
- **Pinging George before the Opus checklist passes and is logged.**

## Integration

- **`steward-local-sdd`** — produces the `ledger.md` and `runlog.md` this skill
  consumes; runs before this.
- **`docs/CONVENTIONS.md`** — the run-artifact paths.
- **`docs/DECISION-LIFECYCLE.md`** — the ledger whose entries fill §3 and get
  promoted to `DECISIONS.md` at review close.
- **`superpowers:finishing-a-development-branch`** — the surrounding completion
  flow; this skill is the packaging step within it.
