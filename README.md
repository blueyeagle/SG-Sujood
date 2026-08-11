# SG-Sujood — Waqt SG

Native SwiftUI iOS app for Muslims in Singapore: MUIS prayer times, nearby prayer spaces
(musollah / masjid), qibla compass, fardhu & qadha tracking, dzikir counter, zakat and a
Ramadan mode. Built from the design handoff in [`design_handoff_waqt_sg/`](design_handoff_waqt_sg/).

## Repo contents

| Path | What |
| --- | --- |
| [`WaqtSG/`](WaqtSG/) | The Xcode project. Open `WaqtSG/WaqtSG.xcodeproj` and ⌘R. See [`WaqtSG/BUILD_NOTES.md`](WaqtSG/BUILD_NOTES.md). |
| [`nisab.json`](nisab.json) | **Live nisab config** the app fetches (see below). |
| [`spaces.json`](spaces.json) | **Live prayer-space directory** (165 spaces, geocoded) the app fetches. |
| [`SG Prayer Spaces.xlsx`](SG%20Prayer%20Spaces.xlsx) | Source workbook for the directory. |
| [`Prayer timetable 2026.pdf`](Prayer%20timetable%202026.pdf) | Official MUIS source for the bundled prayer times. |
| [`design_handoff_waqt_sg/`](design_handoff_waqt_sg/) | Original design reference (HTML prototype, tokens, screenshots). |

## Prayer times

Real MUIS 2026 times for all 365 days, parsed from the PDF into
`WaqtSG/WaqtSG/prayer_times_2026.json`. Refresh annually with the next year's timetable.

## Nisab (remote config)

MUIS publishes the nisab (86 g gold) **monthly** on
[zakat.sg](https://www.zakat.sg/current-past-nisab-values/). The app reads **this repo's
[`nisab.json`](nisab.json)** at launch, so you can update the figure without an App Store
release. The app fetches it from:

```
https://raw.githubusercontent.com/blueyeagle/SG-Sujood/main/nisab.json
```

**To update each month:** edit `nisab.json` here — set `current` to the new figure and
prepend the same entry to `history` — then commit. Keep this repo public so the raw URL
serves without a token.

## Prayer-space submissions

"Add a space" in the app posts to a small backend ([`backend/`](backend/) — a Cloudflare
Worker) that opens a GitHub issue; the [`space-submission`](.github/workflows/space-submission.yml)
Action appends the row to [`Prayer Space for Review.xlsx`](Prayer%20Space%20for%20Review.xlsx)
and closes the issue. Deploy steps are in [`backend/README.md`](backend/README.md). Until the
backend URL is set in `SubmissionService.swift`, the app falls back to opening a prefilled
GitHub issue in the browser.

## Prayer spaces (remote config)

[`spaces.json`](spaces.json) lists 165 prayer spaces (mosques + musollah) with coordinates
from OneMap. The app fetches it from
`https://raw.githubusercontent.com/blueyeagle/SG-Sujood/main/spaces.json` and falls back to a
bundled copy. Edit and commit to add/correct a listing without an app release.

---

*Prayer times, the nisab, the space directory and the sunnah/niat content should be verified
against MUIS / a religious authority before public release. See `WaqtSG/BUILD_NOTES.md`.*
