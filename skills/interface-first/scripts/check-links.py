#!/usr/bin/env python3
"""Check local inline Markdown link paths and Markdown heading fragments.

Uses only Python's standard library. Ignores fenced examples and external URLs.
Does not validate YAML fields, external links, runtime entries or design approval.
"""

import argparse
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


def prose(text):
    fence = None
    for line in text.splitlines():
        match = re.match(r"^\s*(`{3,}|~{3,})(.*)$", line)
        if match:
            marker = match.group(1)
            if fence is None:
                fence = marker
            elif marker[0] == fence[0] and len(marker) >= len(fence) and not match.group(2).strip():
                fence = None
            continue
        if fence is None:
            yield line


def anchors(text):
    counts = {}
    result = set()
    for line in prose(text):
        heading = re.match(r"^#{1,6}\s+(.+?)(?:\s+#+)?$", line)
        if not heading:
            continue
        label = re.sub(r"\[([^]]+)\]\([^)]+\)", r"\1", heading.group(1)).lower()
        slug = re.sub(r"[^\w\- ]", "", label).replace(" ", "-")
        count = counts.get(slug, 0)
        counts[slug] = count + 1
        result.add(f"{slug}-{count}" if count else slug)
    return result


def check(paths):
    errors = []
    files = set()
    for path in paths:
        if path.is_dir():
            files.update(path.rglob("*.md"))
        elif path.is_file():
            files.add(path)
        else:
            errors.append(f"{path}: input does not exist")
    links = 0
    for source in sorted(files):
        for line in prose(source.read_text()):
            for match in re.finditer(r"!?\[[^\]]*\]\((<[^>]+>|[^\s)]+)(?:\s+\"[^\"]*\")?\)", line):
                raw = match.group(1).strip("<>")
                url = urlsplit(raw)
                if url.scheme or url.netloc:
                    continue
                links += 1
                target = source if not url.path else source.parent / unquote(url.path)
                if not target.exists():
                    errors.append(f"{source}: missing path {raw}")
                elif url.fragment and target.suffix.lower() in (".md", ".markdown"):
                    if unquote(url.fragment) not in anchors(target.read_text()):
                        errors.append(f"{source}: missing heading {raw}")
    return files, links, errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()
    paths = args.paths or [Path(__file__).resolve().parent.parent]
    files, links, errors = check(paths)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"PASS: {len(files)} Markdown files, {links} local link paths/fragments")
    return 0


if __name__ == "__main__":
    sys.exit(main())
