#!/usr/bin/env python3
"""Build the combined prayer_times.json feed from the per-year source files.

Reads every prayer-times/*.json (each a flat array of day records) and merges them into a
single, date-sorted prayer_times.json at the repo root — which the data Worker serves and the
app fetches. Adding a new year is just: drop prayer-times/<year>.json in and push.

Each day record:
    {"d": "YYYY-MM-DD", "subuh": "HH:mm", "syuruk": ..., "zohor": ..., "asar": ...,
     "maghrib": ..., "isyak": ...}
"""
import glob
import json
import os
import re
import sys

SRC_DIR = "prayer-times"
OUT = "prayer_times.json"
FIELDS = ["subuh", "syuruk", "zohor", "asar", "maghrib", "isyak"]
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
TIME_RE = re.compile(r"^\d{2}:\d{2}$")


def valid(rec, where):
    if not isinstance(rec, dict):
        sys.exit(f"{where}: record is not an object: {rec!r}")
    d = rec.get("d")
    if not (isinstance(d, str) and DATE_RE.match(d)):
        sys.exit(f"{where}: bad or missing date 'd': {rec!r}")
    for f in FIELDS:
        v = rec.get(f)
        if not (isinstance(v, str) and TIME_RE.match(v)):
            sys.exit(f"{where}: field '{f}' must be HH:mm, got {v!r} (date {d})")
    return d


def main():
    files = sorted(glob.glob(os.path.join(SRC_DIR, "*.json")))
    if not files:
        sys.exit(f"No source files in {SRC_DIR}/")

    by_date = {}
    for path in files:
        with open(path, encoding="utf-8") as fh:
            rows = json.load(fh)
        if not isinstance(rows, list) or not rows:
            sys.exit(f"{path}: expected a non-empty JSON array")
        for i, rec in enumerate(rows):
            d = valid(rec, f"{path}[{i}]")
            # Keep only the canonical keys, in a stable order.
            by_date[d] = {"d": d, **{f: rec[f] for f in FIELDS}}

    merged = [by_date[d] for d in sorted(by_date)]

    # Only rewrite if the content actually changed (keeps the Action a no-op otherwise).
    new = json.dumps(merged, ensure_ascii=False, separators=(",", ":"))
    old = None
    if os.path.exists(OUT):
        with open(OUT, encoding="utf-8") as fh:
            old = fh.read()
    if old is not None and json.loads(old) == merged:
        print(f"{OUT} already up to date ({len(merged)} days across "
              f"{len(files)} year file(s)).")
        return

    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(new)
    years = sorted({d[:4] for d in by_date})
    print(f"Wrote {OUT}: {len(merged)} days, years {', '.join(years)}.")


if __name__ == "__main__":
    main()
