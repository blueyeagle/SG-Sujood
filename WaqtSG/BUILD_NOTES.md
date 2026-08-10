# Waqt SG — iOS app

Native SwiftUI recreation of the `design_handoff_waqt_sg` prototype. Prayer times, prayer
spaces and everyday worship tools for Muslims in Singapore.

## Open & run

```bash
open "WaqtSG.xcodeproj"
```

Then pick an iPhone simulator and press ⌘R. Command-line build:

```bash
xcodebuild -project WaqtSG.xcodeproj -scheme WaqtSG -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Requires Xcode 16+ (built and verified on Xcode 26.6, iOS 26.5 simulator). Deployment
target iOS 17. The project uses a **synchronized file group**, so new files dropped into
`WaqtSG/` are picked up automatically — no pbxproj editing.

## What's implemented

All 13 screens from the handoff, native, with the Industry design system:

- **Onboarding** — dark plate; the primary button triggers the real `CLLocationManager`
  and `UNUserNotificationCenter` permission prompts (not on launch).
- **Home** — dark hero with a **live 1-second countdown**, progress rail, nearest-space
  blueprint card, three-state fardhu tracker (Mark → Done → Missed) that writes through to
  qadha counts, and a qadha-owing row.
- **Timetable** — six waktu rows, next inked in accent, expandable sunnah rawatib with niat
  transliteration + meaning.
- **Nearby** — filter chips + a **real MapKit map** (you-are-here + labelled pins), list
  sorted by walking time.
- **Space detail**, **Qibla** (live `CLHeading`, needle to 293°), **More**, **Qadha**
  (day grid + decrement-only records), **Zakat** (live haul countdown), **Dzikir**
  (tap-to-count with haptics, auto-advance, undo/reset), **Ramadan**, **Reminders**,
  **Add a space**, **Widgets** spec.

Design system lives in `Theme.swift`, `Blueprint.swift`, `Components.swift`: exact color
tokens, the 3.4-based spacing scale, square corners everywhere, the blueprint frame with
corner registration marks, and the type-only tab bar. **Barlow / Barlow Condensed** (OFL)
are bundled in `WaqtSG/Fonts/` and registered at launch (`FontRegistrar.swift`).

## Data

**Prayer times are real.** `prayer_times_2026.json` holds all 365 days of the official
**MUIS "Prayer timetable 2026"** (parsed from the PDF in the SG Sujood folder), loaded by
`PrayerData.swift` and used everywhere via `AppState.time(for:)`. The countdown, next-waktu,
timetable and widgets all reflect the true published times for the current date; the
displayed Gregorian/Hijri dates are computed live. **Refresh annually** by dropping in next
year's JSON. (Hijri uses the Umm al-Qura calendar and can differ ±1 day from MUIS's observed
calendar until wired to a MUIS source.)

**Nisab is remote-configurable.** MUIS publishes the nisab (86 g gold) **monthly** on
zakat.sg — there's no public API and the site blocks scraping, so the app reads a JSON you
host instead. `NisabStore.swift` resolves in this order: cached (last good remote) → bundled
`nisab.json` seed → hard-coded fallback, then does an async refresh from
`NisabStore.remoteURL`. A bad/oversized value is rejected (sanity range $1k–$1M) so a broken
remote payload can't corrupt the screen. The Zakat header shows where the figure came from
("Updated from MUIS config" / "From last synced MUIS figure" / "Built-in figure").

To go live:
1. Host a file matching `nisab.json`'s schema (see its `_note`). Update it each month — read
   the new figure off <https://www.zakat.sg/current-past-nisab-values/> and prepend it to
   `history`, and set `current`.
2. Set `NisabStore.remoteURL` to that file's URL.

The seed currently holds the last figure known at build time (**May 2026 = $17,017**) — the
in-app value is only as fresh as your hosted config. `lowestBalance` on the Zakat screen is
still an illustrative holding; wire it to real balances / manual entry.

**Prayer spaces are real & remote-configurable.** `spaces.json` holds 165 spaces (75 mosques
from the MUIS directory + 90 community musollah across Central/East/West/North), parsed from
the "SG Prayer Spaces" workbook and **geocoded via OneMap** (Singapore's official map API).
`SpacesStore.swift` mirrors `NisabStore`: bundled seed → cached → async refresh from
`SpacesStore.remoteURL` (the repo's `spaces.json`). Nearby sorts by real walking distance
(`LocationProvider` → straight-line metres ÷ 80 m/min); the map plots geocoded pins. Update
the directory by editing `spaces.json` and re-pushing — no App Store release.

To refresh the directory from a new workbook, re-run the parser/geocoder
(`scratchpad/build_spaces.py` pattern) and replace `spaces.json`.

**Walking times are routed** via `RouteService` (MapKit `MKDirections`, transport `.walking`).
Apple throttles Directions, so routes are computed on demand — the Space detail (1 request)
and the nearest ~10 rows in Nearby — through a serial, cached queue; every other row shows
the instant straight-line estimate (metres ÷ 80) until/unless routed. The Nearby list then
re-sorts by *effective* minutes (routed when known, estimate otherwise) so the quickest walk
leads, animating the reflow as routes resolve. Routing and map pins key off a separate
stable straight-line order (`sorted`) to avoid a re-sort feedback loop.

The rest is still placeholder per the handoff's "Content caveats". Before shipping:

- Consider a MUIS Hijri source (currently computed Umm al-Qura, ±1 day).
- "Add a space" form still doesn't submit anywhere — needs a backend + moderation queue.
- Build the moderated **prayer-space database** (mosques seeded from MUIS; mall/office
  musollah community-submitted with a "last confirmed" timestamp). Consider OneMap tiles.
- Have the **sunnah table and niat wording reviewed by a religious authority**; consider
  adding Arabic script alongside the transliteration.
- Persist state with SwiftData/Core Data (currently in-memory `AppState`).
- Add the **WidgetKit extension** (`accessoryRectangular` + `systemSmall`) — the in-app
  Widgets screen is a spec/preview only.
- Schedule the actual silent notifications (`UNCalendarNotificationTrigger`, no sound,
  `.timeSensitive`) from the Reminders toggles.

## Note

`WaqtSGApp.swift` contains a `DebugScreen` reachable only via the `WAQT_SCREEN` launch
environment variable — used for headless screenshot verification, never wired into the
shipping UI. Safe to delete.
