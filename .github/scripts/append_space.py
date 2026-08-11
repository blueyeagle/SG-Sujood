#!/usr/bin/env python3
"""Append a prayer-space submission (from a GitHub issue) to the review workbook.

Reads the issue via environment variables set by the workflow and appends one row to
"Prayer Space for Review.xlsx". The issue body is expected to contain lines like:

    Building / mall: Suntec City
    Floor & landmark: B1, Tower 2
    Walk from nearest MRT exit: 7 minutes
    Type: Musollah
"""
import os
import re
import openpyxl

WORKBOOK = "Prayer Space for Review.xlsx"

body = os.environ.get("ISSUE_BODY", "") or ""
user = os.environ.get("ISSUE_USER", "")
number = os.environ.get("ISSUE_NUMBER", "")
created = os.environ.get("ISSUE_CREATED", "")


def field(label):
    # match "Label: value" on a single line. Use [ \t] (not \s) around the colon so an empty
    # value can't let the match spill onto the next line and capture a different field.
    pattern = re.compile(rf"^[ \t]*{re.escape(label)}[ \t]*:[ \t]*(.*)$", re.IGNORECASE | re.MULTILINE)
    m = pattern.search(body)
    return m.group(1).strip() if m else ""


building = field("Building / mall") or field("Building")
floor = field("Floor & landmark") or field("Floor")
walk = field("Walk from nearest MRT exit") or field("Walk from MRT") or field("Walk")
stype = field("Type")

wb = openpyxl.load_workbook(WORKBOOK)
ws = wb["Submissions"] if "Submissions" in wb.sheetnames else wb.active
ws.append([created, user, f"#{number}" if number else "", building, floor, walk, stype, "New"])
wb.save(WORKBOOK)
print(f"Appended submission from #{number}: {building!r}")
