---
name: metrics
description: Use at review close, after George has ruled on a PR, to append one JSONL metrics line (asking George only for review_minutes) to .steward/metrics.jsonl
---

# Metrics — one line per PR at review close

Steward exists to spend George's attention efficiently; this is where that spend
gets **measured, not vibed**. At review close — after George has ruled on the PR
— Opus appends exactly one JSONL line to `.steward/metrics.jsonl`. Cheap, honest,
append-only, greppable later.

`.steward/metrics.jsonl` is **committed** (durable — see `docs/CONVENTIONS.md`);
it is created by the first append (no need to seed it, same graceful-degradation
spirit as `DECISIONS.md`).

## When

The review-close step, once George's verdict is in. This runs alongside decision
promotion (blessed ledger entries → `DECISIONS.md`, per
`docs/DECISION-LIFECYCLE.md`); do both, then the run is closed.

## The one question for George

Ask George for a single number: **`review_minutes`** — how long his review took.
Self-reported, one number, no precision theater. That is the only synchronous ask
at close; every other field is gathered from the run artifacts.

## The schema (verbatim, brief C8)

```json
{"ts": "", "repo": "", "issue": 0, "pr": 0, "diff_lines": 0,
 "escalations_opus": 0, "escalations_george": 0, "hard_stops": 0,
 "ledger_entries": 0, "decisions_promoted": 0,
 "review_minutes": 0, "rework": false}
```

## Where each field comes from

| field | source |
|---|---|
| `ts` | now, UTC ISO-8601: `date -u +%FT%TZ` |
| `repo` | the target repo, `owner/name` |
| `issue` | the issue number implemented |
| `pr` | the PR number |
| `diff_lines` | changed lines: `git diff --numstat <BASE>..HEAD` summed (added + deleted) |
| `escalations_opus` | count of Rung-1 escalations (Opus answered from the brief) this run |
| `escalations_george` | count of Rung-3 escalations (synchronous to George) — protocol failures |
| `hard_stops` | count of hard-stop-class stops this run |
| `ledger_entries` | number of entries in `.steward/runs/<issue>/ledger.md` |
| `decisions_promoted` | ledger entries promoted to `DECISIONS.md` at this close |
| `review_minutes` | George's self-reported number (above) |
| `rework` | `true` if the PR needed changes after George's review, else `false` |

Escalation / hard-stop counts come from the run's ledger and runlog (the ledger
protocol records them as they happen); default 0 when clean.

## Appending safely

Build the line with `jq` so it is always valid JSON in the schema's field order
— never hand-concatenate:

```bash
mkdir -p .steward
jq -cn \
  --arg     ts                 "$(date -u +%FT%TZ)" \
  --arg     repo               "$REPO" \
  --argjson issue              "$ISSUE" \
  --argjson pr                 "$PR" \
  --argjson diff_lines         "$DIFF_LINES" \
  --argjson escalations_opus   "$ESC_OPUS" \
  --argjson escalations_george "$ESC_GEORGE" \
  --argjson hard_stops         "$HARD_STOPS" \
  --argjson ledger_entries     "$LEDGER_ENTRIES" \
  --argjson decisions_promoted "$DECISIONS_PROMOTED" \
  --argjson review_minutes     "$REVIEW_MINUTES" \
  --argjson rework             "$REWORK" \
  '{ts:$ts, repo:$repo, issue:$issue, pr:$pr, diff_lines:$diff_lines,
    escalations_opus:$escalations_opus, escalations_george:$escalations_george,
    hard_stops:$hard_stops, ledger_entries:$ledger_entries,
    decisions_promoted:$decisions_promoted, review_minutes:$review_minutes,
    rework:$rework}' \
  >> .steward/metrics.jsonl
```

`diff_lines` example: `DIFF_LINES=$(git diff --numstat "$BASE".."HEAD" | awk '{a+=$1+$2} END{print a+0}')`.
`rework` is a JSON boolean (`true`/`false`), so pass it via `--argjson`.

## Validating

The line must parse. After appending:

```bash
tail -1 .steward/metrics.jsonl | jq -e . >/dev/null && echo "metrics line OK"
```

For a schema check, confirm all keys are present:

```bash
tail -1 .steward/metrics.jsonl | jq -e '
  has("ts") and has("repo") and has("issue") and has("pr") and has("diff_lines")
  and has("escalations_opus") and has("escalations_george") and has("hard_stops")
  and has("ledger_entries") and has("decisions_promoted") and has("review_minutes")
  and has("rework")' >/dev/null && echo "schema OK"
```

## Red flags

- **Hand-building the JSON string** — use `jq`; a stray quote corrupts the file.
- **Asking George for anything but `review_minutes`** — every other field is
  derivable from the run; don't spend his attention on them.
- **Skipping the append because a run was clean** — a zero-escalation line is the
  most valuable data point steward collects.
- **Putting `.steward/metrics.jsonl` behind gitignore** — it is committed
  (`docs/CONVENTIONS.md`); only `.steward/runs/` is ignored.

## Integration

- **`docs/CONVENTIONS.md`** — `.steward/metrics.jsonl` is the durable, committed
  artifact; `.steward/runs/<issue>/` (ledger, runlog) feeds the counts.
- **`docs/DECISION-LIFECYCLE.md`** — the same review-close step promotes blessed
  ledger entries to `DECISIONS.md`; `decisions_promoted` is that count.
- **`pr-packaging` / `adversarial-review`** — precede review close; George's
  verdict on their output is what this measures.
