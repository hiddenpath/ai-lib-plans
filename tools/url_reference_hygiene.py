#!/usr/bin/env python3
"""
Public URL hygiene checker/autofixer for ai-lib ecosystem repositories.

Default behavior:
- Scan files for hiddenpath public URL patterns
- Print findings and return non-zero if violations exist

Optional:
- --fix: apply replacements in-place
"""

from __future__ import annotations

import argparse
import fnmatch
import sys
from pathlib import Path


TEXT_EXTENSIONS = {
    ".md",
    ".mdx",
    ".yaml",
    ".yml",
    ".json",
    ".toml",
    ".py",
    ".ts",
    ".tsx",
    ".js",
    ".jsx",
    ".go",
    ".rs",
    ".sh",
    ".ps1",
    ".astro",
    ".txt",
    ".ini",
    ".cfg",
}

REPLACEMENTS = (
    ("https://github.com/hiddenpath/", "https://github.com/ailib-official/"),
    (
        "https://raw.githubusercontent.com/hiddenpath/",
        "https://raw.githubusercontent.com/ailib-official/",
    ),
    (
        "https://api.github.com/repos/hiddenpath/",
        "https://api.github.com/repos/ailib-official/",
    ),
)

DEFAULT_EXCLUDES = (
    ".git/**",
    "node_modules/**",
    "target/**",
    ".venv/**",
    ".github/workflows/**",
    "**/go.mod",
)


def is_excluded(path: Path, root: Path, exclude_globs: tuple[str, ...]) -> bool:
    rel = path.relative_to(root).as_posix()
    return any(fnmatch.fnmatch(rel, pattern) for pattern in exclude_globs)


def scan_file(path: Path) -> list[str]:
    try:
        content = path.read_text(encoding="utf-8")
    except Exception:
        return []
    hits = []
    for bad, _ in REPLACEMENTS:
        if bad in content:
            hits.append(bad)
    return hits


def fix_file(path: Path) -> bool:
    content = path.read_text(encoding="utf-8")
    updated = content
    for bad, good in REPLACEMENTS:
        updated = updated.replace(bad, good)
    if updated != content:
        path.write_text(updated, encoding="utf-8")
        return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Check/fix hiddenpath public URLs.")
    parser.add_argument(
        "roots",
        nargs="*",
        default=["."],
        help="Directories or files to scan (default: current directory).",
    )
    parser.add_argument("--fix", action="store_true", help="Apply replacements in-place.")
    args = parser.parse_args()

    violations: list[tuple[Path, list[str]]] = []
    fixed_files = 0

    for root_input in args.roots:
        root = Path(root_input).resolve()
        if root.is_file():
            candidates = [root]
            base = root.parent
        else:
            candidates = [p for p in root.rglob("*") if p.is_file()]
            base = root

        for path in candidates:
            if path.suffix.lower() not in TEXT_EXTENSIONS:
                continue
            if is_excluded(path, base, DEFAULT_EXCLUDES):
                continue

            hits = scan_file(path)
            if not hits:
                continue

            violations.append((path, hits))
            if args.fix and fix_file(path):
                fixed_files += 1

    if violations:
        print(f"Found {len(violations)} files with hiddenpath public URLs:")
        for path, hits in violations:
            print(f"- {path}")
            for hit in sorted(set(hits)):
                print(f"  - {hit}")
    else:
        print("No hiddenpath public URL violations found.")

    if args.fix:
        print(f"Fixed files: {fixed_files}")

    return 1 if violations and not args.fix else 0


if __name__ == "__main__":
    sys.exit(main())
