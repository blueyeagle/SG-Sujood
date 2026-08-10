# SG-Sujood — Waqt SG

Native SwiftUI iOS app for Muslims in Singapore: MUIS prayer times, nearby prayer spaces
(musollah / masjid), qibla compass, fardhu & qadha tracking, dzikir counter, zakat and a
Ramadan mode. Built from the design handoff in [`design_handoff_waqt_sg/`](design_handoff_waqt_sg/).

## Repo contents

| Path | What |
| --- | --- |
| [`WaqtSG/`](WaqtSG/) | The Xcode project. Open `WaqtSG/WaqtSG.xcodeproj` and ⌘R. See [`WaqtSG/BUILD_NOTES.md`](WaqtSG/BUILD_NOTES.md). |
| [`nisab.json`](nisab.json) | **Live nisab config** the app fetches (see below). |
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

---

*Prayer times, the nisab and the sunnah/niat content should be verified against MUIS / a
religious authority before public release. See `WaqtSG/BUILD_NOTES.md`.*
