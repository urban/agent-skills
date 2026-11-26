#!/usr/bin/env python3
"""Check an ATX Markdown spec's mechanics, never its approval or readiness."""

import argparse
from collections import Counter
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit


HEADING = re.compile(r"^ {0,3}(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
CRITERION = re.compile(r"^\s*(?:[-*]\s+)?(AC-\d{2,}):\s*(.*)$")
AC_ID = re.compile(r"\bAC-\d{2,}\b")
PLACEHOLDER = re.compile(r"\{\{[^{}]*\}\}|\[TODO:", re.IGNORECASE)
BLOCKER = re.compile(r"\b(?:TODO\s*:\s*Confirm\b|BLOCKED\s*:)", re.IGNORECASE)
LINK = re.compile(r"\[[^\]\n]*\]\(([^\s)]+)(?:\s+\"[^\"]*\")?\)")


def document_lines(markdown):
    """Separate structure from fenced examples; keep raw bodies for emptiness checks."""
    raw = markdown.splitlines()
    visible = []
    opened = None
    for line in raw:
        marker = FENCE.match(line)
        if opened:
            if (marker and marker[1][0] == opened[0]
                    and len(marker[1]) >= len(opened) and not marker[2].strip()):
                opened = None
            visible.append("")
        elif marker:
            opened = marker[1]
            visible.append("")
        else:
            visible.append(line)
    return raw, visible, opened is not None


def check(markdown, source, check_blockers=False):
    """Return bounded mechanical findings without enforcing a section schema."""
    problems = []
    raw, visible, unclosed = document_lines(markdown)
    if unclosed:
        problems.append("Close the fenced code block.")
    headings = [(index, match) for index, line in enumerate(visible)
                if (match := HEADING.match(line))]
    titles = [(index, match) for index, match in headings if len(match[1]) == 1]
    first_content = next((index for index, line in enumerate(raw) if line.strip()), -1)
    if len(titles) != 1 or titles[0][0] != first_content or not titles[0][1][2].strip():
        problems.append("Begin with one nonempty level-one title (# Title).")
    for position, (index, heading) in enumerate(headings):
        if not heading[2].strip():
            problems.append(f"Line {index + 1}: heading is empty.")
        end = headings[position + 1][0] if position + 1 < len(headings) else len(raw)
        # A parent heading may introduce subsections without an intervening paragraph.
        has_child = position + 1 < len(headings) and len(headings[position + 1][1][1]) > len(heading[1])
        if not has_child and not any(line.strip() for line in raw[index + 1:end]):
            problems.append(f"Line {index + 1}: section has no content.")

    definitions = [match for line in visible if (match := CRITERION.match(line))]
    if not definitions:
        problems.append("Define at least one acceptance criterion, for example '- AC-01: observable outcome'.")
    counts = Counter(match[1] for match in definitions)
    for identifier, count in sorted(counts.items()):
        if count > 1:
            problems.append(f"Acceptance ID defined more than once: {identifier}.")
    for match in definitions:
        if not match[2].strip():
            problems.append(f"Acceptance criterion has no content: {match[1]}.")
    referenced = set(AC_ID.findall("\n".join(visible)))
    for identifier in sorted(referenced - counts.keys()):
        problems.append(f"Acceptance reference has no definition: {identifier}.")

    if PLACEHOLDER.search(markdown):
        problems.append("Replace drafting placeholders ({{...}} or [TODO: ...]).")
    if check_blockers and BLOCKER.search(markdown):
        problems.append("Unresolved marker found (TODO: Confirm or BLOCKED:); inspect its scope manually.")

    for target in LINK.findall("\n".join(visible)):
        try:
            url = urlsplit(target)
            if url.scheme or url.netloc or not url.path:
                continue
            path = Path(unquote(url.path))
            resolved = path if path.is_absolute() else source.parent / path
            if not resolved.exists():
                problems.append(f"Local link target does not exist: {target}.")
        except (ValueError, OSError) as error:
            problems.append(f"Cannot inspect local link {target}: {error}.")
    return problems


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path, help="UTF-8 ATX Markdown file")
    parser.add_argument("--check-blockers", action="store_true",
                        help="also report unresolved markers; this is not a readiness gate")
    arguments = parser.parse_args()
    try:
        problems = check(arguments.spec.read_text(encoding="utf-8"),
                         arguments.spec.resolve(), arguments.check_blockers)
    except (OSError, UnicodeError) as error:
        print(f"CHECK FAILED: {error}", file=sys.stderr)
        return 1
    if problems:
        for problem in problems:
            print(f"CHECK FAILED: {problem}", file=sys.stderr)
        return 1
    print("Mechanical checks passed; approval, evidence quality, and readiness were not evaluated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
