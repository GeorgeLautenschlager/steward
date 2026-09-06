#!/usr/bin/env bash
# Acceptance tests for the steward-local-sdd controller tools.
#
# Every case below is an acceptance criterion from issue #30 (mutation-gate.py)
# or #31 (check-inversion.py), stated as a command and an assertion on its
# output. Run from anywhere:  ./skills/steward-local-sdd/tools/tests/run-tests.sh
#
# Requires: python3, pytest (the gate's default runner is pytest).

set -uo pipefail

TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$TOOLS/mutation-gate.py"
TRIPWIRE="$TOOLS/check-inversion.py"

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf '  \033[32mok\033[0m   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1";
         [ $# -gt 1 ] && printf '       %s\n' "$2"; }

# assert_contains <needle> <haystack> <name>
assert_contains() {
  case "$2" in
    *"$1"*) ok "$3" ;;
    *)      bad "$3" "expected to find: $1" ;;
  esac
}

# assert_not_contains <needle> <haystack> <name>
assert_not_contains() {
  case "$2" in
    *"$1"*) bad "$3" "did not expect to find: $1" ;;
    *)      ok "$3" ;;
  esac
}

# assert_rc <expected> <actual> <name>
assert_rc() {
  if [ "$1" = "$2" ]; then ok "$3"; else bad "$3" "expected rc $1, got $2"; fi
}

WS="$(mktemp -d)"
trap 'chmod -R u+w "$WS" 2>/dev/null; rm -rf "$WS"' EXIT

# ---------------------------------------------------------------------------
# Fixture: a small project with eight independently testable behaviours, each
# with a test that pins it. The gate rows revert each behaviour in turn.
# ---------------------------------------------------------------------------
mkdir -p "$WS/proj"
cat > "$WS/proj/calc.py" <<'PY'
"""Eight small behaviours, one per gate row."""


def depth_limit(n):
    if n > 100:
        raise ValueError("too deep")
    return n


def split_lines(text):
    return text.splitlines()


def clamp(value, lo, hi):
    return max(lo, min(hi, value))


def dedupe(items):
    seen = set()
    out = []
    for item in items:
        if item not in seen:
            seen.add(item)
            out.append(item)
    return out


def safe_div(a, b):
    if b == 0:
        return None
    return a / b


def normalise(name):
    return name.strip().lower()


def merge(left, right):
    merged = dict(left)
    merged.update(right)
    return merged


def percent(part, whole):
    if whole == 0:
        return 0.0
    return round(100.0 * part / whole, 2)


def unpinned(flag):
    # Behaviour with a deliberately weak test — used by the weak-test case.
    return "on" if flag else "off"
PY

cat > "$WS/proj/test_calc.py" <<'PY'
import pytest

import calc


def test_depth_limit():
    with pytest.raises(ValueError):
        calc.depth_limit(101)


def test_split_lines():
    assert calc.split_lines("a\nb\n") == ["a", "b"]


def test_clamp():
    assert calc.clamp(15, 0, 10) == 10


def test_dedupe():
    assert calc.dedupe([1, 1, 2]) == [1, 2]


def test_safe_div():
    assert calc.safe_div(1, 0) is None


def test_normalise():
    assert calc.normalise("  Ada  ") == "ada"


def test_merge():
    assert calc.merge({"a": 1}, {"a": 2}) == {"a": 2}


def test_percent():
    assert calc.percent(1, 3) == 33.33


def test_unpinned():
    # Weak on purpose: asserts nothing about the mapping.
    assert calc.unpinned(True) in ("on", "off")
PY

rows_file() { printf '%s' "$1" > "$WS/rows.json"; echo "$WS/rows.json"; }

# ---------------------------------------------------------------------------
# #30 acceptance 1: an eight-row gate runs in ONE call and reports both halves
# per row.
# ---------------------------------------------------------------------------
echo
echo "mutation-gate.py — #30"

EIGHT_ROWS=$(cat <<'JSON'
{
  "cwd": "proj",
  "rows": [
    {"label": "depth limit raises",      "file": "calc.py", "selector": "test_calc.py::test_depth_limit",
     "old": "    if n > 100:\n        raise ValueError(\"too deep\")\n", "new": ""},
    {"label": "splitlines not split(10)", "file": "calc.py", "selector": "test_calc.py::test_split_lines",
     "old": "return text.splitlines()", "new": "return text.split(chr(10))"},
    {"label": "clamp upper bound",       "file": "calc.py", "selector": "test_calc.py::test_clamp",
     "old": "return max(lo, min(hi, value))", "new": "return max(lo, value)"},
    {"label": "dedupe preserves order",  "file": "calc.py", "selector": "test_calc.py::test_dedupe",
     "old": "        if item not in seen:\n            seen.add(item)\n            out.append(item)\n",
     "new": "        out.append(item)\n"},
    {"label": "safe_div guards zero",    "file": "calc.py", "selector": "test_calc.py::test_safe_div",
     "old": "    if b == 0:\n        return None\n", "new": ""},
    {"label": "normalise lowercases",    "file": "calc.py", "selector": "test_calc.py::test_normalise",
     "old": "return name.strip().lower()", "new": "return name.strip()"},
    {"label": "merge right wins",        "file": "calc.py", "selector": "test_calc.py::test_merge",
     "old": "    merged.update(right)\n", "new": ""},
    {"label": "percent rounds to 2dp",   "file": "calc.py", "selector": "test_calc.py::test_percent",
     "old": "return round(100.0 * part / whole, 2)", "new": "return 100.0 * part / whole"}
  ]
}
JSON
)
ROWS=$(rows_file "$EIGHT_ROWS")
BEFORE=$(md5sum "$WS/proj/calc.py" | cut -d' ' -f1)
OUT=$("$GATE" --rows "$ROWS" --root "$WS" 2>&1); RC=$?
AFTER=$(md5sum "$WS/proj/calc.py" | cut -d' ' -f1)

assert_rc 0 "$RC" "eight-row gate exits 0"
assert_contains "reverted" "$OUT" "table has a reverted column"
assert_contains "restored" "$OUT" "table has a restored column"
assert_contains "every row caught its defect" "$OUT" "clean gate says so"
for n in 1 2 3 4 5 6 7 8; do
  case "$OUT" in
    *"$n  "*|*"$n "*) : ;;
    *) bad "row $n present in table" ;;
  esac
done
ok "all eight rows present in one table"
if [ "$BEFORE" = "$AFTER" ]; then ok "source byte-identical after the gate"
else bad "source byte-identical after the gate"; fi
# Both halves reported per row: eight reverted-fail + eight restored-pass cells.
REVERTED_FAILS=$(printf '%s\n' "$OUT" | grep -c '1 failed')
assert_contains "1 passed" "$OUT" "restored half reports a pytest summary"
if [ "$REVERTED_FAILS" -ge 8 ]; then ok "eight reverted halves reported"
else bad "eight reverted halves reported" "found $REVERTED_FAILS rows with '1 failed'"; fi

# ---------------------------------------------------------------------------
# #30 acceptance 3: a row whose anchor is not found reports "anchor not found"
# rather than passing.
# ---------------------------------------------------------------------------
ROWS=$(rows_file '{
  "cwd": "proj",
  "rows": [
    {"label": "anchor that is not there", "file": "calc.py", "selector": "test_calc.py::test_clamp",
     "old": "return this_text_does_not_exist()", "new": "pass"}
  ]
}')
OUT=$("$GATE" --rows "$ROWS" --root "$WS" 2>&1); RC=$?
assert_contains "anchor not found" "$OUT" "missing anchor is named"
assert_not_contains "every row caught its defect" "$OUT" "missing anchor is not a clean gate"
if [ "$RC" -ne 0 ]; then ok "missing anchor exits non-zero"; else bad "missing anchor exits non-zero"; fi

# An anchor occurring more than once is ambiguous, not a silent first-match.
ROWS=$(rows_file '{
  "cwd": "proj",
  "rows": [
    {"label": "ambiguous anchor", "file": "calc.py", "selector": "test_calc.py::test_clamp",
     "old": "    return ", "new": "    return "}
  ]
}')
OUT=$("$GATE" --rows "$ROWS" --root "$WS" 2>&1); RC=$?
assert_contains "anchor ambiguous" "$OUT" "ambiguous anchor is named"
if [ "$RC" -ne 0 ]; then ok "ambiguous anchor exits non-zero"; else bad "ambiguous anchor exits non-zero"; fi

# ---------------------------------------------------------------------------
# #30 acceptance 2: a mis-restored source fails loudly rather than silently
# leaving the tree dirty. Simulated by making the file unwritable, so the
# restore write genuinely fails.
# ---------------------------------------------------------------------------
cat > "$WS/proj/frozen.py" <<'PY'
def value():
    return 1
PY
cat > "$WS/proj/test_frozen.py" <<'PY'
import frozen


def test_value():
    assert frozen.value() == 1
PY
ROWS=$(rows_file '{
  "cwd": "proj",
  "rows": [
    {"label": "restore into a read-only file", "file": "frozen.py",
     "selector": "test_frozen.py::test_value",
     "command": ["bash", "-c", "chmod 0444 frozen.py; python3 -m pytest -q {selector}"],
     "old": "return 1", "new": "return 2"}
  ]
}')
OUT=$("$GATE" --rows "$ROWS" --root "$WS" 2>&1); RC=$?
chmod u+w "$WS/proj/frozen.py" 2>/dev/null
assert_contains "RESTORE FAILED" "$OUT" "mis-restore is loud"
assert_contains "frozen.py" "$OUT" "mis-restore names the file"
assert_contains "backup" "$OUT" "mis-restore names the backup holding the original"
if [ "$RC" -ne 0 ]; then ok "mis-restore exits non-zero"; else bad "mis-restore exits non-zero"; fi

# ---------------------------------------------------------------------------
# #30 lesson: a test that does not catch its own reverted fix is a RED row —
# this is the whole point of the gate.
# ---------------------------------------------------------------------------
ROWS=$(rows_file '{
  "cwd": "proj",
  "rows": [
    {"label": "weak test does not catch it", "file": "calc.py", "selector": "test_calc.py::test_unpinned",
     "old": "return \"on\" if flag else \"off\"", "new": "return \"off\""}
  ]
}')
OUT=$("$GATE" --rows "$ROWS" --root "$WS" 2>&1); RC=$?
assert_contains "did not catch" "$OUT" "weak test is reported as not catching its defect"
if [ "$RC" -ne 0 ]; then ok "weak test exits non-zero"; else bad "weak test exits non-zero"; fi

# ---------------------------------------------------------------------------
# #30 lesson: a green row is only evidence if the mutation reaches the
# behaviour. A reverted half that fails at collection (import/syntax) failed
# for the wrong reason — flag it rather than counting it as caught.
# ---------------------------------------------------------------------------
ROWS=$(rows_file '{
  "cwd": "proj",
  "rows": [
    {"label": "mutation breaks the module, not the behaviour", "file": "calc.py",
     "selector": "test_calc.py::test_clamp",
     "old": "return max(lo, min(hi, value))", "new": "return max(lo, min(hi, value)"}
  ]
}')
OUT=$("$GATE" --rows "$ROWS" --root "$WS" 2>&1); RC=$?
assert_contains "SUSPECT" "$OUT" "collection-error failure is flagged SUSPECT"
if [ "$RC" -ne 0 ]; then ok "suspect row exits non-zero"; else bad "suspect row exits non-zero"; fi

# ---------------------------------------------------------------------------
# #30 lesson: assert the summary line by regex, not "last non-warning line".
# The runner below prints a deprecation warning AFTER its own summary, so any
# positional parse reads the warning as the result — the exact misparse that
# reported seven false gate failures on the Theseus run.
# ---------------------------------------------------------------------------
cat > "$WS/proj/test_noisy.py" <<'PY'
import calc


def test_noisy():
    assert calc.clamp(15, 0, 10) == 10
PY
ROWS=$(rows_file '{
  "cwd": "proj",
  "rows": [
    {"label": "trailing warning does not fool the parser", "file": "calc.py",
     "selector": "test_noisy.py::test_noisy",
     "command": ["bash", "-c", "python3 -m pytest -q {selector}; echo DeprecationWarning:-not-the-result"],
     "old": "return max(lo, min(hi, value))", "new": "return max(lo, value)"}
  ]
}')
OUT=$("$GATE" --rows "$ROWS" --root "$WS" 2>&1); RC=$?
assert_rc 0 "$RC" "noisy-output row still reads its summary line"
assert_not_contains "DeprecationWarning" "$OUT" "table reports the summary line, not trailing noise"

# ---------------------------------------------------------------------------
# check-inversion.py — #31
# ---------------------------------------------------------------------------
echo
echo "check-inversion.py — #31"

mkdir -p "$WS/repo/src"
cat > "$WS/repo/src/replication.py" <<'PY'
def replicate(batch, rng):
    out = []
    for item in batch:
        out.append(rng.choice(item.variants))
    return out


def summarise(rows):
    return {"n": len(rows), "kinds": sorted({r.kind for r in rows})}
PY

# 1. A prompt that embeds the target module's source trips the check.
{
  printf '# Dispatch context\n\n## Task\n\nUpdate the replication batch.\n\n'
  printf 'Here is `src/replication.py` as it stands:\n\n```python\n'
  cat "$WS/repo/src/replication.py"
  printf '```\n'
} > "$WS/prompt-inverted.md"
OUT=$("$TRIPWIRE" --prompt "$WS/prompt-inverted.md" --root "$WS/repo" \
        --target src/replication.py 2>&1); RC=$?
assert_contains "src/replication.py" "$OUT" "tripwire names the embedded file"
if [ "$RC" -ne 0 ]; then ok "embedded existing source trips the check"
else bad "embedded existing source trips the check"; fi

# 2. A prompt carrying only tests and contract does not trip.
cat > "$WS/prompt-clean.md" <<'MD'
# Dispatch context

## Task

Create `src/replication.py`.

**Behaviour:** `replicate(batch, rng)` returns one variant per item, chosen with
`rng`. `summarise(rows)` returns the row count and the sorted distinct kinds.

**Interfaces:** `replicate(batch, rng) -> list`, `summarise(rows) -> dict`.

**Test cases** — these run as `pytest tests/test_replication.py`:

```python
def test_replicate_picks_one_variant_per_item():
    out = replication.replicate([item(["a", "b"])], rng=FixedRng("a"))
    assert out == ["a"]


def test_summarise_counts_and_sorts_kinds():
    assert replication.summarise([row("b"), row("a")]) == {"n": 2, "kinds": ["a", "b"]}
```
MD
OUT=$("$TRIPWIRE" --prompt "$WS/prompt-clean.md" --root "$WS/repo" \
        --target src/replication.py 2>&1); RC=$?
assert_rc 0 "$RC" "tests-and-contract prompt does not trip"
assert_contains "no embedded source" "$OUT" "clean prompt says so"

# 3. A create-target (file does not exist yet) whose source is handed over in a
#    block attributed to that path still trips.
cat > "$WS/prompt-newfile.md" <<'MD'
# Dispatch context

## Task

Create `src/scoring.py` with this content:

```python
def score(rows, weights):
    total = 0.0
    for row in rows:
        total += weights.get(row.kind, 0.0) * row.value
    return total


def rank(rows, weights):
    return sorted(rows, key=lambda r: score([r], weights), reverse=True)
```
MD
OUT=$("$TRIPWIRE" --prompt "$WS/prompt-newfile.md" --root "$WS/repo" \
        --target src/scoring.py 2>&1); RC=$?
assert_contains "src/scoring.py" "$OUT" "tripwire names the attributed new file"
if [ "$RC" -ne 0 ]; then ok "source for a not-yet-created target trips the check"
else bad "source for a not-yet-created target trips the check"; fi

# 4. The check emits the prompt byte count, so the runlog ratio line needs no
#    second pass over the prompt.
OUT=$("$TRIPWIRE" --prompt "$WS/prompt-clean.md" --root "$WS/repo" \
        --target src/replication.py 2>&1)
assert_contains "prompt_bytes=" "$OUT" "prompt byte count is emitted for the runlog"
BYTES=$(printf '%s\n' "$OUT" | sed -n 's/.*prompt_bytes=\([0-9]*\).*/\1/p' | head -1)
REAL=$(wc -c < "$WS/prompt-clean.md")
if [ "$BYTES" = "$REAL" ]; then ok "prompt byte count is the real size ($REAL)"
else bad "prompt byte count is the real size" "reported $BYTES, actual $REAL"; fi

# 6. A fix re-dispatch carries `git diff BASE..HEAD`, whose context lines match
#    the file exactly. That must not trip the check — it is the fix loop working.
#    The paired case below proves the diff exemption is what saves it, not the
#    run-length threshold: the same lines in a python fence do trip.
BIG=$WS/repo/src/wide.py
cat > "$BIG" <<'MD'
def alpha(rows):
    total = 0
    for row in rows:
        total += row.value
    return total


def beta(rows):
    return [row for row in rows if row.value]


def gamma(rows):
    return sorted(rows, key=lambda row: row.value)
MD
{ printf 'Fix the findings below.\n\n```diff\n'
  printf 'diff --git a/src/wide.py b/src/wide.py\n@@ -1,13 +1,13 @@\n'
  sed 's/^/ /' "$BIG"
  printf '```\n'; } > "$WS/prompt-fixdiff.md"
OUT=$("$TRIPWIRE" --prompt "$WS/prompt-fixdiff.md" --root "$WS/repo" \
        --target src/wide.py 2>&1); RC=$?
assert_rc 0 "$RC" "a fix re-dispatch's git diff does not trip the check"

{ printf 'Here is the module.\n\n```python\n'; cat "$BIG"; printf '```\n'; } \
  > "$WS/prompt-samelines.md"
OUT=$("$TRIPWIRE" --prompt "$WS/prompt-samelines.md" --root "$WS/repo" \
        --target src/wide.py 2>&1); RC=$?
if [ "$RC" -ne 0 ]; then ok "the same lines outside a diff fence do trip"
else bad "the same lines outside a diff fence do trip" "$OUT"; fi

# 7. A test file named as a target is never flagged — tests are the contract.
OUT=$("$TRIPWIRE" --prompt "$WS/prompt-samelines.md" --root "$WS/repo" \
        --target tests/test_wide.py 2>&1); RC=$?
assert_rc 0 "$RC" "a test path target is never flagged"

# 5. --warn-only downgrades the refusal to a warning (the "loudly warns" half of
#    the deliverable) but still says what it found.
OUT=$("$TRIPWIRE" --prompt "$WS/prompt-inverted.md" --root "$WS/repo" \
        --target src/replication.py --warn-only 2>&1); RC=$?
assert_rc 0 "$RC" "--warn-only exits 0"
assert_contains "WARNING" "$OUT" "--warn-only still reports the finding"

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ]
