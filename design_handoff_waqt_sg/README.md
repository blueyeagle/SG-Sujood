# Handoff: Waqt SG — prayer times, prayer spaces and worship tools (iOS)

## Overview
Waqt SG is an iOS app for Muslims in Singapore. It answers the two recurring questions of a
workday — *when is the next prayer* and *where can I actually pray right now* — and carries a
small set of everyday worship tools around them: sunnah rawatib reference, a daily fardhu
tracker with a monthly qadha record, zakat nisab and haul, and a dzikir counter.

Primary users: working Muslims moving around the island, families in malls, visitors
unfamiliar with Singapore, and reverts new to prayer routines.

## About the design files
The files in this bundle are **design references created in HTML** — a prototype showing the
intended look, content and behavior. They are **not production code to copy**.

The task is to **recreate these screens natively in iOS** (SwiftUI recommended — see
"Recommended stack") using that environment's own patterns, or in whatever stack the team
already uses. Do not embed the HTML in a WebView: the widgets, the notification scheduling
and the compass all want native APIs.

`Waqt SG.dc.html` is the full prototype. Open it in a browser; the left column is a screen
index, the phone frame on the right is live — tabs, filters, toggles, the counter and the
countdown all work.

## Fidelity
**High fidelity.** Colors, type, spacing and copy are final-intent. Recreate the UI closely.
The one deliberate exception: the map on the Nearby screen is drawn as a schematic
(grid + markers) because the prototype has no map SDK — implement it with a real map
(see "Data sources").

## Recommended stack
SwiftUI, iOS 17+.

| Need | API |
| --- | --- |
| Five-tab shell | `TabView` |
| Silent reminders, pre-prayer nudge | `UserNotifications` — `UNCalendarNotificationTrigger`, no sound, interruption level `.timeSensitive` for waktu |
| Nearby sorting, "you are here" | `CoreLocation` (when-in-use) |
| Map | MapKit, or OneMap tiles (see below) |
| Qibla compass | `CLLocationManager.startUpdatingHeading` + true-north bearing to Makkah |
| Lock Screen + Home Screen widgets | `WidgetKit` (`accessoryRectangular`, `systemSmall`) |
| Local persistence | SwiftData or Core Data — prayer log, qadha counts, saved spaces, dzikir state |

Info.plist purpose strings are required in plain language for location and notifications or
App Store review will reject the build.

## Data sources
- **Prayer times** — use the MUIS published daily waktu solat rather than computing them, so
  the app agrees with the mosque. Times are identical island-wide. Bundle a full year so the
  app works offline; refresh annually.
- **Hijri date** — Islamic calendar as observed by MUIS (not a pure arithmetic calendar).
- **Zakat nisab** — MUIS publishes a daily kadar nisab in SGD (value of 86 g of gold).
- **Prayer spaces** — you need your own database. Mosques can be seeded from MUIS; mall and
  office musollah are community-submitted and need a moderation queue plus a "last confirmed"
  timestamp on every listing. OneMap (Singapore's official map API, free) has better local
  building data than Apple Maps.

## Design tokens
From the Industry design system (steel-blue wireframe on a light technical ground).

### Color
| Token | Value | Use |
| --- | --- | --- |
| bg | `#f2f2f3` | Page ground |
| surface | `#e9e9ea` | Raised card fill |
| text | `#1d1f20` | Body ink |
| accent | `#5980a6` | Steel accent — active states, primary fill, markers |
| accent-400 | `#94bce3` | Accent on dark plates |
| accent-700 | `#416180` | Accent text at paragraph size (contrast) |
| accent-900 | `#1d2d3d` | The dark "field" — hero plate, Ramadan, Dzikir, Zakat header |
| divider | `rgba(29,31,32,.16)` | Hairlines and borders |
| muted ink | `rgba(29,31,32,.55)` | Secondary text |
| paper ink on dark | `#f2f2f3`, secondary `rgba(242,242,243,.6)` | Text on accent-900 |
| border on dark | `rgba(148,188,227,.35–.4)` | Hairlines on accent-900 |

Rule: on a dark plate, never use the light-ground ink/divider values.

### Type
- Headings: **Barlow Condensed** 600. iOS equivalent: ship Barlow Condensed as a bundled font;
  do not substitute the system font — the condensed voice is the system's signature.
- Body: **Barlow** 400/500.
- Sizes in use: screen title 34, hero numeral 62–76, card title 17–22, body 13–15,
  meta 11–12.5, all-caps label 10–12 with `letter-spacing` 0.12–0.2em.
- Numerals in timetables, counters and money use tabular figures.

### Shape and framing
- **Square corners everywhere.** No rounded cards, buttons or images.
- Cards and figures are transparent line drawings: 1px divider border, no fill.
- The "blueprint" frame adds four `+` registration marks at the corners (11×11px crosshairs,
  offset −6px). Recreate as a reusable SwiftUI `ViewModifier`.
- The solid accent primary button is the one filled object on a screen.
- Photographs are duotoned into the accent (desaturate, then accent in `color` blend mode).

### Spacing
3.4 / 6.8 / 10.2 / 13.6 / 20.4 / 27.2 px scale. Screen gutter is 22px; section blocks are
separated by ~22px; list rows are 11–16px vertical padding over a 1px divider.

## Screens

### 1. Onboarding
Full dark plate (`#1d2d3d`). Kicker "WAQT SG", headline "Know the time. / Know the room.",
one paragraph. Two hairline-bordered explainer blocks: **Use your location** (timings match
your area, spaces sort by walking distance, on-device only) and **Silent reminders**
(vibration at waktu, nudge 15 min before, nothing sounds out loud). Bottom: accent primary
button "Allow and continue", ghost link "Set my location manually". Both proceed to Home.

Trigger the real `CLLocationManager` and `UNUserNotificationCenter` permission prompts from
the primary button, not on launch.

### 2. Home (tab 1)
**Dark hero plate**, 64px top padding:
- Row: location "Orchard, Singapore" (accent-400 caps) / Hijri date, right-aligned.
- "NEXT · {prayer}" label, then the time at 76px Barlow Condensed with "in {countdown}"
  beside it. Countdown ticks every second, format `0h 29m 46s`.
- A 2px progress rail showing elapsed fraction between the previous and next waktu, with
  "{prev} {time}" and "Now {clock}" underneath.

**Body on the light ground:**
- "NEAREST SPACE" label with a "SEE ALL" link to Nearby.
- A blueprint card on `#e9e9ea`: space name (22px), "Musollah · B4, beside Food Opera",
  a big walking-minutes numeral right-aligned, and tags "Open now" / "Confirmed 2 days ago".
  Tapping opens Space detail.
- **Today's fardhu tracker** — header reads "TODAY · {n} done, {n} missed, {n} to come".
  Five rows (Subuh, Zohor, Asar, Maghrib, Isyak): status dot, name, time, and a status button
  that cycles **Mark → Done → Missed → Mark** on tap.
  - Mark: transparent, divider border, muted ink.
  - Done: accent fill, paper ink.
  - Missed: `#1d2d3d` fill, paper ink.
  Entering "Missed" increments that prayer's qadha count; leaving "Missed" decrements it
  (never below 0).
- A bordered "Qadha owing / Across {month}" row showing the total, opening the Qadha screen.

### 3. Timetable (tab 2)
Title "Timetable" + "Monday 10 August 2026 · 26 Safar 1448". A blueprint note names the
source: the MUIS published daily waktu solat, identical island-wide.

Six rows — Subuh, Syuruk, Zohor, Asar, Maghrib, Isyak — each with name, a sub-note, the time,
and a `+`/`−` expander box. The next upcoming waktu is inked in accent. Under every row a
caps line summarises its sunnah ("SUNNAH · 2 rakaat before · 2 rakaat after").

**Expanded state** shows each sunnah as a block with a 2px accent left rule:
before/after + rakaat count, a "Muakkad"/"Ghair muakkad" tag, the **niat in transliteration**
(italic, accent-700, in quotes) and its English meaning.

Rawatib content (Shafi'i, as practised in Singapore):

| Waktu | Sunnah | Rakaat | Rank | Niat (transliteration) |
| --- | --- | --- | --- | --- |
| Subuh | Before | 2 | Muakkad | Usalli sunnatas Subhi rak'ataini qabliyyatan lillahi ta'ala. |
| Syuruk | Dhuha, after | 2–8 | — | Usalli sunnatad Dhuha rak'ataini lillahi ta'ala. |
| Zohor | Before | 2 or 4 | Muakkad | Usalli sunnataz Zuhri rak'ataini qabliyyatan lillahi ta'ala. |
| Zohor | After | 2 | Muakkad | Usalli sunnataz Zuhri rak'ataini ba'diyyatan lillahi ta'ala. |
| Asar | Before | 2 or 4 | Ghair muakkad | Usalli sunnatal 'Asri rak'ataini qabliyyatan lillahi ta'ala. |
| Maghrib | Before | 2 | Ghair muakkad | Usalli sunnatal Maghribi rak'ataini qabliyyatan lillahi ta'ala. |
| Maghrib | After | 2 | Muakkad | Usalli sunnatal Maghribi rak'ataini ba'diyyatan lillahi ta'ala. |
| Isyak | Before | 2 | Ghair muakkad | Usalli sunnatal 'Isyaa'i rak'ataini qabliyyatan lillahi ta'ala. |
| Isyak | After | 2 | Muakkad | Usalli sunnatal 'Isyaa'i rak'ataini ba'diyyatan lillahi ta'ala. |

Have this content reviewed by a religious authority before shipping, and consider adding the
Arabic script alongside the transliteration.

Below: "Yesterday" / "Tomorrow" buttons and a Jumu'ah note.

### 4. Nearby (tab 3)
Title, then three filter buttons — **All / Musollah / Masjid** — selected = accent fill.

A 210px map. In the prototype it is a schematic; implement with a real map showing the user's
position and pins for each space, each labelled "{short name} · {n}m".

Scrolling list below: name (19px), "{type} · {floor, landmark}", a meta line ("Confirmed 2
days ago", "Jumu'ah 12.30 pm and 1.45 pm"), and walking minutes as a large right-aligned
numeral. Sorted by walking time. Row tap opens Space detail. Footer button "Add a space you
know".

### 5. Space detail (pushed)
190px hatched image band (real photo in production, duotoned) with a back button overlaid.
Then: type kicker, name (32px), address + closing time.

A two-cell bordered grid — **Where**: floor as a big numeral ("B4") plus the landmark
sentence; **Walk**: "3 min" plus the origin ("From Orchard MRT, exit E").

"GETTING THERE": three steps on a hairline left rule with small accent squares.
Actions: accent "Directions" (opens Maps) + "Save". Footer: "Last confirmed 2 days ago by a
Waqt SG user" with a "Something changed?" link into the correction flow.

Per the brief, a space is described by **two facts only** — where it is in the building and
how long it takes to walk there. Do not add facility icons, ratings or crowding.

### 6. Qibla (tab 4)
280px circle with an inner ring, N/E/S/W marks, a 1px accent needle rotated to the bearing,
a small diamond marker, and the bearing at 48px in the centre with a compass-point label.
From Singapore the bearing is **293°** (northwest). Below, a blueprint note explains it, plus
"Recalibrate compass". In production the needle tracks live heading; show a calibration
prompt when `CLHeading.headingAccuracy` is poor.

### 7. More (tab 5)
A plain list, each row title + subtitle + chevron: Qadha record ({n} owing this month),
Dzikir counter, Zakat, Reminders, Add a prayer space, Ramadan mode, Widgets & Lock Screen,
Location.

### 8. Qadha (pushed from Home or More)
Back button, "Qadha" title with a month stepper (← Aug 2026 →). One-line explanation.

A blueprint card on `#e9e9ea`: "OUTSTANDING THIS MONTH" and the total at 52px.

A 7-column day grid for the month: days complete = accent tint `rgba(89,128,166,.18)`,
days with one or more missed = `#1d2d3d` with paper ink, future days = transparent with
faded ink. A two-item legend below.

"BY WAKTU": five rows, each with the prayer name, "{n} owing", a **"QADHA DONE"** button and
a thin progress rail. Tapping the button decrements that prayer's count by one, never below
zero; at zero the row and its button drop to a disabled tone. Footer note: recording a qadha
reduces the count only — it does not change the day it was missed.

### 9. Zakat (pushed from More)
Dark header plate: "KADAR NISAB · {date}", the figure at 62px ("$8,347" + ".00 SGD"), and a
line explaining it is the value of 86 grams of gold published daily by MUIS, and that wealth
held above it for a full haul is subject to zakat harta.

Light body:
- **End of haul** — a blueprint card with a live `{d}d {hh}h {mm}m {ss}s` countdown, the haul
  start and completion dates, a progress rail and "Day 339" / "354 days · one lunar year".
- **Your holding** — two cells: lowest balance held, and zakat at 2.5% with its due date.
  Tags "Above nisab" / "Zakat harta".
- **Nisab this week** — four dated rows with values.
- Accent "Pay zakat" (hands off to MUIS) and "Set a reminder for {due date}".
- Disclaimer: figures are an estimate for planning.

### 10. Dzikir counter (pushed from More)
Full dark plate. Top: preset chips — Subhanallah 33, Alhamdulillah 33, Allahu Akbar 34,
Astaghfirullah 100. Selected chip is accent-filled with paper ink; unselected chips use
`rgba(242,242,243,.7)` ink and `rgba(148,188,227,.4)` borders.

Centre: the whole area is the tap target. Phrase name (caps, accent-400), its meaning, the
count at 132px tabular, "of {target}", a progress rail, and "TAP ANYWHERE TO COUNT".

Reaching the target resets the count to zero and advances to the next dzikir; completing the
last one increments "full rounds completed today". Bottom bar: rounds count, **Undo**
(decrement, floor 0) and **Reset** (count, phrase and rounds to zero).

Add a haptic on each tap (`.light`) and a distinct one at each target — the screen is
designed to be used with eyes closed.

### 11. Ramadan mode (pushed from More)
Full dark plate. "RAMADAN · DAY {n}", "Iftar in {countdown}", a two-cell Imsak/Maghrib grid,
and a "TERAWIH NEARBY" list (mosque, "{n} rakaat · {time}", walking minutes). Note: the mode
switches on by itself on 1 Ramadan and off after Syawal.

### 12. Widgets & Lock Screen (pushed from More)
A specification screen previewing:
- **Lock Screen** — on the dark plate: date, clock, and two hairline cells, "ASAR / in 30m"
  and "NEAREST / ION · 3m". Build as `accessoryRectangular`.
- **Home Screen** — two square blueprint widgets: next prayer (label, time at 34px,
  "in 30 minutes") and nearest space (label, name, "B4 · 3 min walk"). Build as `systemSmall`.
- Both refresh hourly and on significant location change.

## Interactions and behavior
- **Tab bar** — five items (Home, Times, Nearby, Qibla, More) as caps labels with a 2px accent
  rule above the active one. 76px tall, 1px top divider. Hidden on every pushed screen.
- **Countdown** — 1s tick; recompute the next waktu when it passes; roll to tomorrow's Subuh
  after Isyak.
- **Fardhu tracker** — three-state cycle, writes through to qadha counts as described.
- **Qadha** — decrement only, floor 0.
- **Dzikir** — increment, auto-advance at target, undo, reset.
- **Filters and toggles** — instant, no animation. Selection is shown by accent fill, never by
  a shadow or a rounded pill.
- **Motion** — the design is deliberately still. Countdown numerals and the dzikir count change
  without transition; screen pushes use the standard iOS navigation transition.
- **Reminders** — silent by default. Per-waktu toggles plus a lead time of 10 / 15 / 30 minutes.
  The nudge names the nearest space so the user can decide whether to move.

## State
| State | Shape | Notes |
| --- | --- | --- |
| `screen` | enum of the 12 screens | tab + navigation stack |
| `now` | clock | drives countdown, next-waktu and progress |
| `dayLog` | `[prayer: pending \| done \| missed]` | per calendar day, persisted |
| `qadha` | `[prayer: Int]` | month-scoped, persisted |
| `spaceFilter` | all \| musollah \| masjid | |
| `reminderOn` | `[prayer: Bool]` | schedules/cancels notifications |
| `leadMinutes` | 10 \| 15 \| 30 | |
| `expandedWaktu` | prayer or nil | timetable sunnah disclosure |
| `dzikirIndex, dzikirCount, dzikirRounds` | Int | persisted; rounds reset daily |
| `haulStart` | date | drives the zakat countdown |

## Assets
No production assets exist yet. Needed:
- **Barlow** and **Barlow Condensed** (Google Fonts, OFL) bundled in the app.
- **Photographs** of each prayer space entrance — the prototype uses hatched placeholders.
  Community-submitted, moderated, duotoned into the accent on display.
- **Icons** — Lucide at stroke-width 1.5 if any are added. The prototype deliberately uses
  none: the tab bar is type-only.

## Content caveats
Everything in the prototype is placeholder data, plausible but unverified:
- Mall floor and landmark details (ION B4, Wisma L5, Ngee Ann B2, Paragon B1).
- Prayer times, the Hijri date, nisab figures and haul dates.
- The sunnah table and niat wording — have a religious authority review before shipping.

## Screenshots
`screenshots/all-screens.png` — all 13 screens captured at the authored 402×874, labelled and laid out in
reading order (Onboarding, Home, Timetable, Map, Space detail, Qibla, Qadha, Zakat, Dzikir,
Reminders, Add a space, Ramadan, Widgets). Use it as the visual reference alongside the live
prototype; the prototype is authoritative for interaction.

## Files
- `Waqt SG.dc.html` — the full interactive prototype (all 12 screens).
- `ios-frame.jsx` — the iPhone bezel used to present the prototype. Presentation only; nothing
  in it ships.
- `support.js` — the prototype runtime. Not part of the design.
- `_ds/industry-.../styles.css` — the Industry design system stylesheet the tokens come from.
- `_ds/industry-.../readme.md` — the design system's own guide.
