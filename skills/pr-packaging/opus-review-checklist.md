# Opus review checklist — PR description vs. brief

Run this against a Pi-authored PR description **before George is pinged**, with
the **brief open**. You are not re-reviewing the code — the per-task spec and
code-quality reviewers already did. You are catching what the implementer
structurally cannot, because it never saw the brief: an untruthful **brief
mapping** and unsurfaced **deviations**. Those are Pi's blind spots; they are
your whole job here.

Capture the result (pass, or gaps found + fixes) to
`.steward/runs/<issue>/runlog.md` as `## PR packaging — Opus review`.

## Checks

1. **All six sections present and non-empty** — Summary, Brief mapping,
   Deviations & Assumptions, Uncertainties, Evidence, Review trail. An empty
   required section fails.
2. **Summary is ≤ 3 sentences** and free of implementation detail.
3. **Brief mapping is truthful against the actual brief** (your focus). Every
   claim "implements brief item X" actually matches X. Nothing the brief required
   for this issue is silently missing. The mapping isn't padded with items this
   PR doesn't touch.
4. **Deviations are complete and honest** (your focus). Every ledger assumption
   appears in §3 verbatim. Nothing that deviated from the brief or the issue is
   omitted. Each deviation's reversibility note is present and plausible.
5. **Hard-stop check** — no change in the hard-stop class (deletions, schema/data
   migrations, external side effects, security-shaped, costs money) shipped as an
   assumption instead of a synchronous George decision.
6. **Evidence substantiates the claims** — the tests/output shown actually cover
   what the Summary and Brief mapping assert. Not "tests pass" with no output.
7. **Review trail is real** — both stages present with findings *and* resolutions,
   matching `runlog.md`. Not a rubber-stamp "LGTM".
8. **≥ 1 inline self-review comment** posted on the diff where rationale is
   non-obvious.

## Outcome

- **All pass →** log the pass to the runlog, then ping George.
- **Any fail →** return to Pi with the specific failing check(s) to fix the
  description (or the code, if §5/§7 reveal a real gap), re-run this checklist,
  and only then ping George. Log both the finding and the fix.
