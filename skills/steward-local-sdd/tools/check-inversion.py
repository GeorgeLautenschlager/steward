#!/usr/bin/env python3
"""Refuse a dispatch whose prompt already contains the module it is asking for.

The inversion this guards against — the frontier writing the code and the local
model transcribing it — ran for two days on the Theseus run without being
noticed, because it is invisible in every signal the pipeline reports. Sixteen
dispatches: 12 DONE, 2 DONE_WITH_CONCERNS, 0 BLOCKED, 0 NEEDS_CONTEXT. A
transcriber never escalates; there is nothing for it to be blocked on. "No
escalations" is not evidence of health (steward #31).

So the check is mechanical and runs before the dispatch, not after it: if a
fenced block in the prompt holds the target module's source, the skill has
inverted. Tests and contract are what the prompt is *supposed* to carry, so a
block that is test code never trips it.

    check-inversion.py --prompt PROMPT --root WORKTREE --target src/foo.py [...]

Exit 0 = clean (or --warn-only), 1 = inverted, 2 = usage error. Always prints
`prompt_bytes=N` for the runlog's scaffolding-to-code ratio line.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# A run this long is source being handed over; shorter runs are the signature
# fragments and single lines a contract legitimately quotes.
MIN_RUN = 5

# How far above a fence to look for the path it is attributed to. Kept tight on
# purpose: a plan that mentions the module in prose three paragraphs up has not
# handed over its source, and treating that as an inversion would make the check
# something to route around rather than something to trust.
ATTRIBUTION_WINDOW = 3

FENCE_RE = re.compile(r"^([ \t]*)(`{3,}|~{3,})[ \t]*([^\n]*)$")

TEST_MARKER_RE = re.compile(r"^\s*(?:def test_|async def test_|class Test|it\(|test\()|^\s*assert\s", re.MULTILINE)
BODY_RE = re.compile(r"^\s*(?:def |class |func |function |fn )", re.MULTILINE)
DIFF_RE = re.compile(r"^(?:diff --git |@@ -\d|\+\+\+ |--- )", re.MULTILINE)


class Block:
    def __init__(self, lines: list[str], info: str, preceding: list[str]) -> None:
        self.lines = lines
        self.info = info
        self.preceding = preceding

    @property
    def text(self) -> str:
        return "\n".join(self.lines)

    def is_test_code(self) -> bool:
        """Tests are the contract. They belong in the prompt; never flag them."""
        return bool(TEST_MARKER_RE.search(self.text))

    def is_diff(self) -> bool:
        """A unified diff of work already in the tree.

        Every fix re-dispatch carries `git diff BASE_SHA..HEAD` so the fresh run
        can see what it is fixing, and a diff of the module necessarily contains
        the module. Its unprefixed context lines match the file exactly, so
        without this exemption the second round of every task trips the check —
        and a check that cries wolf on the common path is one people route
        around. The residual gap is stated in SKILL.md: source smuggled inside a
        ```diff fence is not caught, so the fenced-diff block belongs to the fix
        loop and nothing else.
        """
        return self.info.lower() in ("diff", "patch") or bool(DIFF_RE.search(self.text))

    def has_bodies(self) -> bool:
        return bool(BODY_RE.search(self.text))


def significant(lines: list[str]) -> list[str]:
    """Strip blanks and trivia so indentation and closers cannot pad a run."""
    return [line.strip() for line in lines if len(line.strip()) >= 4]


def parse_blocks(prompt: str) -> list[Block]:
    blocks: list[Block] = []
    lines = prompt.splitlines()
    index = 0
    while index < len(lines):
        opening = FENCE_RE.match(lines[index])
        if not opening:
            index += 1
            continue
        indent, marker, info = opening.groups()
        body: list[str] = []
        index += 1
        while index < len(lines):
            closing = FENCE_RE.match(lines[index])
            if closing and closing.group(2)[0] == marker[0] and len(closing.group(2)) >= len(marker):
                break
            body.append(lines[index][len(indent):] if lines[index].startswith(indent) else lines[index])
            index += 1
        index += 1
        preceding = [line for line in lines[: max(0, index - len(body) - 2)] if line.strip()]
        blocks.append(Block(body, info.strip(), preceding[-ATTRIBUTION_WINDOW:]))
    return blocks


def longest_shared_run(file_lines: list[str], block_lines: list[str]) -> int:
    """Longest run of consecutive significant lines the two have in common."""
    left, right = significant(file_lines), significant(block_lines)
    if not left or not right:
        return 0
    best = 0
    previous = [0] * (len(right) + 1)
    for i in range(1, len(left) + 1):
        current = [0] * (len(right) + 1)
        for j in range(1, len(right) + 1):
            if left[i - 1] == right[j - 1]:
                current[j] = previous[j - 1] + 1
                best = max(best, current[j])
        previous = current
    return best


def attributed_to(block: Block, target: str) -> bool:
    """Does this block announce itself as the content of `target`?"""
    name = Path(target).name
    haystack = "\n".join(block.preceding + [block.info] + block.lines[:1])
    return target in haystack or name in haystack


def is_test_path(target: str) -> bool:
    parts = Path(target).parts
    name = Path(target).name
    return any(p in ("test", "tests", "spec", "specs") for p in parts) or name.startswith(
        ("test_", "spec_")
    ) or name.endswith(("_test.py", "_spec.py", ".test.ts", ".spec.ts"))


def check(prompt_path: Path, root: Path, targets: list[str]) -> list[str]:
    """Returns one finding string per inverted target; empty means clean."""
    prompt = prompt_path.read_text()
    blocks = parse_blocks(prompt)
    findings: list[str] = []

    for target in targets:
        if is_test_path(target):
            continue
        source = root / target
        for block in blocks:
            if block.is_test_code() or block.is_diff():
                continue

            if source.is_file():
                run = longest_shared_run(source.read_text().splitlines(), block.lines)
                if run >= MIN_RUN:
                    findings.append(
                        f"{target}: {run} consecutive lines of the file appear verbatim in a "
                        f"fenced block (threshold {MIN_RUN})"
                    )
                    break

            if attributed_to(block, target) and block.has_bodies():
                if len(significant(block.lines)) >= MIN_RUN:
                    findings.append(
                        f"{target}: a fenced block attributed to this path carries "
                        f"{len(significant(block.lines))} lines of implementation "
                        f"(threshold {MIN_RUN})"
                    )
                    break
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Refuse a dispatch whose prompt embeds the target module's source."
    )
    parser.add_argument("--prompt", required=True, type=Path, help="assembled dispatch prompt")
    parser.add_argument("--root", default=Path("."), type=Path, help="worktree the targets live in")
    parser.add_argument(
        "--target",
        action="append",
        default=[],
        metavar="PATH",
        help="a file the task creates or modifies (repeatable)",
    )
    parser.add_argument(
        "--warn-only",
        action="store_true",
        help="report and exit 0 instead of refusing the dispatch",
    )
    args = parser.parse_args()

    if not args.target:
        print("check-inversion: no --target given; nothing to check", file=sys.stderr)
        return 2
    if not args.prompt.is_file():
        print(f"check-inversion: no such prompt: {args.prompt}", file=sys.stderr)
        return 2

    prompt_bytes = args.prompt.stat().st_size
    findings = check(args.prompt, args.root.resolve(), args.target)

    if not findings:
        print(
            f"check-inversion: no embedded source for {len(args.target)} target(s)  "
            f"prompt_bytes={prompt_bytes}"
        )
        return 0

    label = "WARNING" if args.warn_only else "INVERTED"
    print(f"{label}: the dispatch prompt already contains the code it is asking for.")
    for finding in findings:
        print(f"  - {finding}")
    print()
    print(
        "The frontier is implementing and the local model would be transcribing. Replace the "
        "embedded source with behaviour, interfaces, and test cases (SKILL.md -> Plan "
        "Requirements) and re-check."
    )
    print(f"prompt_bytes={prompt_bytes}")
    return 0 if args.warn_only else 1


if __name__ == "__main__":
    sys.exit(main())
