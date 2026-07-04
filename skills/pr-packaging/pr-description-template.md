<!--
  steward PR description template — the six mandatory sections (brief C6).
  Pi fills this from the run artifacts under .steward/runs/<issue>/, then opens
  the PR with it as --body-file. Every section is required; delete these comments.
-->

Closes #<issue>.

## 1. Summary

<!-- What and why. THREE SENTENCES MAX. No implementation detail. -->

## 2. Brief mapping

<!-- Which brief items / decisions this implements. Draft from the issue body and
     its Decisions & Defaults excerpts. Opus reconciles this against the actual
     brief before George is pinged — it is the implementer's blind spot. -->

- <brief item / decision> — <how this PR implements it>

## 3. Deviations & Assumptions

<!-- The run's ledger.md, VERBATIM. Every assumption, with its reversibility
     note. If none were taken, say "None — no assumptions required." -->

## 4. Uncertainties

<!-- What the author isn't sure about; where a reviewer should look harder.
     "None" is allowed but rarely true — be honest. -->

## 5. Evidence

<!-- Test output, before/after behavior, commands run. Proof the work does what
     it claims, so the reviewer reads results rather than re-reading the diff. -->

## 6. Review trail

<!-- From runlog.md: both per-task review stages (spec compliance, then code
     quality), findings AND resolutions. The record that the work was already
     verified in-run. -->

🤖 Generated with [Claude Code](https://claude.com/claude-code)
