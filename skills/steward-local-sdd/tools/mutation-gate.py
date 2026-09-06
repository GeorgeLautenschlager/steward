#!/usr/bin/env python3
"""Run a mutation gate as one call: revert each fix, require its test to fail,
restore, require it to pass — and print one table.

The gate is what makes a test trustworthy. Run turn-by-turn it is also the most
expensive kind of verification there is: an eight-row gate is sixteen runner
invocations, sixteen tool results, and sixteen turns of a context the controller
is paying for by the token. Run as one call it is the same evidence for one turn.
That difference — roughly an order of magnitude in turns on the Theseus run — is
the only reason this file exists (steward #30).

Rows file (JSON):

    {
      "cwd": "proj",                      # optional, relative to --root
      "command": ["python3","-m","pytest","-q","{selector}"],   # optional default
      "rows": [
        {"label": "splitlines not split(10)",
         "file":  "calc.py",
         "old":   "return text.splitlines()",      # the fix, as it stands now
         "new":   "return text.split(chr(10))",    # the defect it replaced
         "selector": "test_calc.py::test_split_lines",
         "command": [...]}                          # optional per-row override
      ]
    }

`old` is the text in the tree today; `new` is what the file said before the fix.
Reverting means putting `new` back and requiring the test to notice.
"""

from __future__ import annotations

import argparse
import filecmp
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

DEFAULT_COMMAND = ["python3", "-m", "pytest", "-q", "{selector}"]

# The runner's own tally line, matched by shape rather than by position. Parsing
# "the last non-warning line" instead picked up a deprecation warning on the
# Theseus run and reported seven false gate failures; a trailing line printed
# after the runner exits will do the same to anything positional.
_COUNT = (
    r"\d+\s+(?:passed|failed|error|errors|skipped|deselected"
    r"|xfailed|xpassed|warnings?|reruns?)"
)
SUMMARY_RE = re.compile(
    r"^=*\s*(?P<summary>(?:no tests ran|" + _COUNT + r")"
    r"(?:\s*,\s*" + _COUNT + r")*)"
    r"(?:\s+in\s+[\d.]+s)?\s*=*\s*$"
)

# A reverted half that dies at import or collection failed for the wrong reason:
# the mutation broke the module rather than the behaviour under test, so the row
# is not evidence that the test is sound.
COLLECTION_ERROR_RE = re.compile(
    r"^(?:ERROR\b|E\s+(?:SyntaxError|IndentationError|ImportError|ModuleNotFoundError))"
    r"|errors? during collection|INTERNALERROR",
    re.MULTILINE,
)

CAUGHT = "caught"


class RestoreFailure(Exception):
    """A source did not come back byte-identical. The tree is dirty; stop."""


def run_selector(row: dict, default_command: list[str], cwd: Path) -> tuple[str, str]:
    """Run one row's selector. Returns (summary line, full output)."""
    template = row.get("command") or default_command
    argv = [part.replace("{selector}", row.get("selector", "")) for part in template]
    proc = subprocess.run(
        argv, cwd=cwd, capture_output=True, text=True, timeout=row.get("timeout", 900)
    )
    output = proc.stdout + proc.stderr
    summary = "no summary line"
    for line in output.splitlines():
        match = SUMMARY_RE.match(line.strip())
        if match:
            summary = match.group("summary").strip()
    return summary, output


def is_pass(summary: str) -> bool:
    return "passed" in summary and "failed" not in summary and "error" not in summary


def is_fail(summary: str) -> bool:
    return "failed" in summary or "error" in summary


def apply_row(source: Path, old: str, new: str) -> str | None:
    """Substitute old -> new. Returns an error string, or None on success."""
    text = source.read_text()
    occurrences = text.count(old)
    if occurrences == 0:
        return "anchor not found"
    if occurrences > 1:
        return f"anchor ambiguous ({occurrences} matches)"
    source.write_text(text.replace(old, new, 1))
    return None


def restore(source: Path, backup: Path) -> None:
    """Put the original bytes back and prove they are back."""
    try:
        source.write_bytes(backup.read_bytes())
    except OSError as exc:
        raise RestoreFailure(f"{source}: could not write ({exc})") from exc
    if not filecmp.cmp(source, backup, shallow=False):
        raise RestoreFailure(f"{source}: restored bytes differ from the original")


def gate(rows_path: Path, root: Path) -> int:
    spec = json.loads(rows_path.read_text())
    cwd = (root / spec.get("cwd", ".")).resolve()
    default_command = spec.get("command", DEFAULT_COMMAND)
    rows = spec["rows"]

    backup_dir = Path(tempfile.mkdtemp(prefix="mutation-gate-backup-"))
    results: list[dict] = []
    touched: dict[Path, Path] = {}

    try:
        for index, row in enumerate(rows, start=1):
            source = (cwd / row["file"]).resolve()
            result = {"n": index, "label": row["label"], "reverted": "", "restored": ""}

            if source not in touched:
                backup = backup_dir / f"{index}-{source.name}"
                shutil.copy2(source, backup)
                touched[source] = backup

            problem = apply_row(source, row["old"], row["new"])
            if problem:
                result["reverted"] = problem
                result["restored"] = "not run"
                result["verdict"] = problem
                results.append(result)
                continue

            try:
                reverted_summary, reverted_output = run_selector(row, default_command, cwd)
            finally:
                restore(source, touched[source])

            restored_summary, _ = run_selector(row, default_command, cwd)
            result["reverted"] = reverted_summary
            result["restored"] = restored_summary

            if not is_fail(reverted_summary):
                result["verdict"] = "did not catch its defect"
            elif COLLECTION_ERROR_RE.search(reverted_output):
                # Failed, but at import/collection: the mutation never reached
                # the behaviour, so a green row here would be an illusion.
                result["verdict"] = "SUSPECT — reverted half failed at collection, not on the behaviour"
            elif not is_pass(restored_summary):
                result["verdict"] = "restored half did not pass"
            else:
                result["verdict"] = CAUGHT
            results.append(result)

        # The gate is only trustworthy if it left nothing behind.
        for source, backup in touched.items():
            if not filecmp.cmp(source, backup, shallow=False):
                raise RestoreFailure(f"{source}: differs from the original after the gate")

    except RestoreFailure as exc:
        print_table(results)
        print()
        print(f"RESTORE FAILED — {exc}")
        print(f"The working tree is DIRTY. Originals are in the backup dir: {backup_dir}")
        print("Restore by hand before running anything else; do not trust the rows above.")
        return 2

    shutil.rmtree(backup_dir, ignore_errors=True)
    print_table(results)
    print()

    bad = [r for r in results if r["verdict"] != CAUGHT]
    if not bad:
        print("every row caught its defect")
        return 0
    for row in bad:
        print(f"row {row['n']} ({row['label']}): {row['verdict']}")
    print()
    print(f"{len(bad)} of {len(results)} rows are not evidence. The gate does not pass.")
    return 1


def print_table(results: list[dict]) -> None:
    if not results:
        return
    label_width = max(len(r["label"]) for r in results)
    label_width = max(label_width, len("row"))
    reverted_width = max(max(len(r["reverted"]) for r in results), len("reverted"))
    header = f"{'row':<{label_width + 4}}{'reverted':<{reverted_width + 4}}restored"
    print(header)
    for r in results:
        cell = f"{r['n']}  {r['label']}"
        print(f"{cell:<{label_width + 4}}{r['reverted']:<{reverted_width + 4}}{r['restored']}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run a mutation gate as one call and print one table."
    )
    parser.add_argument("--rows", required=True, type=Path, help="JSON rows file")
    parser.add_argument(
        "--root", default=Path("."), type=Path, help="base dir the rows file's cwd is relative to"
    )
    args = parser.parse_args()
    try:
        return gate(args.rows, args.root.resolve())
    except FileNotFoundError as exc:
        print(f"mutation-gate: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
