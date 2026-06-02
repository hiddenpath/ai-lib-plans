#!/usr/bin/env python3
"""Validate ai-lib-plans compliance registry YAML (EOS-ARCH-R5).

Phase 1: manual maintenance + structural checks (no CAC scraping).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("error: PyYAML required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

REQUIRED_TOP = ("last_updated", "source", "models")
REQUIRED_MODEL = ("name", "provider", "备案编号", "备案日期")
RECOMMENDED_MODEL = ("provider_id", "model_id")


def load_registry(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        raise ValueError("root must be a mapping")
    return data


def validate(data: dict) -> list[str]:
    errors: list[str] = []
    for key in REQUIRED_TOP:
        if key not in data:
            errors.append(f"missing top-level field: {key}")

    models = data.get("models")
    if not isinstance(models, list) or not models:
        errors.append("models must be a non-empty list")
        return errors

    seen: set[tuple[str, str]] = set()
    for i, entry in enumerate(models):
        if not isinstance(entry, dict):
            errors.append(f"models[{i}]: must be a mapping")
            continue
        for key in REQUIRED_MODEL:
            if key not in entry or not str(entry[key]).strip():
                errors.append(f"models[{i}]: missing or empty '{key}'")
        for key in RECOMMENDED_MODEL:
            if key not in entry:
                errors.append(f"models[{i}]: missing recommended '{key}'")
        pid = str(entry.get("provider_id", "")).strip()
        mid = str(entry.get("model_id", "")).strip()
        if pid and mid:
            pair = (pid, mid)
            if pair in seen:
                errors.append(f"models[{i}]: duplicate provider_id/model_id {pair}")
            seen.add(pair)

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    default = (
        Path(__file__).resolve().parent.parent / "data" / "compliance" / "registered_models.yaml"
    )
    parser.add_argument(
        "--path",
        type=Path,
        default=default,
        help=f"registry YAML (default: {default})",
    )
    args = parser.parse_args()
    path: Path = args.path

    if not path.is_file():
        print(f"error: file not found: {path}", file=sys.stderr)
        return 1

    try:
        data = load_registry(path)
        errors = validate(data)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if errors:
        for err in errors:
            print(f"invalid: {err}", file=sys.stderr)
        return 1

    n = len(data["models"])
    print(f"ok: {path} ({n} models, last_updated={data.get('last_updated')})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
