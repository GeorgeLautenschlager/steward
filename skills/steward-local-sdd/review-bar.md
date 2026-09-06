# Review Bar — two bars, two schedules

> Appended **last** by the controller to the **unchanged** upstream reviewer prompt at dispatch
> time. The upstream reviewer templates are never edited (see SKILL.md → Prompt Templates).
> **Read this last — it overrides the grading scope and the verdict of anything above.** The
> upstream template grades correctness and prose as one bar and returns one verdict for both;
> this capsule splits them, and where the two disagree this capsule wins. Find your pass below
> before you grade.

The review bar has two parts, graded on different schedules:

- **Blocking bar — every round:** correctness. Anything that would produce a wrong result or an
  escaping exception: behaviour vs the spec and the contract, the tests, interfaces, error paths.
- **Prose bar — once, at the final pass:** docstring accuracy, comment quality, naming, the
  explanation of *why*.

Why the split (measured, not assumed): a per-round prose finding costs a full fix cycle —
re-author, rebuilt dispatch prompt, re-verify, re-review — and a local model cannot be held to
house-style *why*-prose anyway, so grading it per round pushes every module back to frontier
authoring no matter how the plan is decomposed. Prose is therefore graded **once, over the
finished module**, not N times over N drafts.

## If you are a per-round reviewer (Spec compliance or Code quality)

- Grade **only the blocking bar**. Your verdict — and any fix cycle — is based on blocking
  findings only. A correctness defect is never deferred, no matter how small or how late it
  appears.
- You will still notice prose issues; that is expected and useful. Do **not** block on them.
  Report each under a separate heading, exactly this form:

      ## Deferred (final pass)
      - <file:line> — <one-line finding> [prose bar: docstring accuracy | comment quality | naming | why-explanation]

- The controller records these in the runlog and hands them to the final pass. **No fix cycle
  will be dispatched for them** — do not phrase them as blockers or wait on one.
- If you have no blocking findings, approve; the deferred list rides along with your approval.
- **Reconciling with the upstream output format.** Keep the structure the template asked for
  (`Strengths` / `Issues` / `Recommendations` / `Assessment`), with two amendments. Everything
  under **Issues** is a blocking finding, so a prose item never goes there — not under *Minor*,
  not as *documentation polish*, not as a *Recommendation*; it goes under the
  `## Deferred (final pass)` heading and nowhere else. And **Ready to merge** answers the
  blocking bar alone: a round with prose findings and none on the blocking bar is
  `Ready to merge: Yes` with a non-empty deferred list underneath. `With fixes` is read by the
  controller as "dispatch a fix cycle", so spend it only on the blocking bar.

## If you are the final-pass reviewer (reviewing the entire implementation, after all tasks)

You are the **prose pass**: one pass over the finished implementation, and the only pass that
grades prose.

- Your prompt carries the accumulated `Deferred (final pass)` items from the per-round runlogs.
  Verify each: is it accurate? already fixed? If an item is wrong or still present, report it as
  a finding.
- Sweep the whole diff for prose-bar issues beyond the accumulated list.
- Your findings **block** — but they are mechanical rewrites, not re-authoring. State each one
  as the exact change to make (file, current text → required text, or the precise correction),
  so a local fix dispatch can apply it without judgment.
- One fix cycle is allowed for this pass; if it does not converge, escalate per the convergence
  guard. Do not open a second prose round — note the remainder and let the controller decide.
- Use the upstream output format as written: at this pass prose findings *are* the blocking bar,
  so they belong under **Issues**, and `Ready to merge` covers both bars.
