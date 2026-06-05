#!/usr/bin/env python3
"""Send a plain-text file from tools/outbox/ via email_skill (Linux/WSL: uses send_mail_simple.py)."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from email_skill import send_quick

def main() -> int:
    parser = argparse.ArgumentParser(description="Send outbox email body file")
    parser.add_argument("file", type=Path, help="Path to body .txt under tools/outbox/")
    parser.add_argument("--subject", required=True, help="Email subject")
    args = parser.parse_args()
    if not args.file.is_file():
        print(f"Missing file: {args.file}", file=sys.stderr)
        return 1
    body = args.file.read_text(encoding="utf-8")
    return 0 if send_quick(args.subject, body) else 1


if __name__ == "__main__":
    raise SystemExit(main())
