# SG Sujood — data Worker

Serves the app's remote-config JSON from Cloudflare's edge instead of `raw.githubusercontent.com`:

| App reads | Worker serves (proxied + edge-cached from the repo) |
| --- | --- |
| `nisab.json` | kadar nisab (monthly MUIS figure) |
| `spaces.json` | prayer-space directory (165 spaces) |
| `terawih.json` | terawih venues (Ramadan) |
| `prayer_times.json` | **MUIS prayer timetable — all years** |

GitHub stays the source of truth. Editing a file in the repo (directly or via the existing
publish Actions) updates the app within the cache window — no App Store release.

## Deploy (one time, then on any change to `worker.js`)

```bash
cd backend-data
npx wrangler login        # once, opens the browser
npx wrangler deploy
```

That publishes to `https://sgsujood-data.<your-subdomain>.workers.dev`. The app already points
at `sgsujood-data.xphyton.workers.dev` (see `RemoteConfig.swift`); if your subdomain differs,
update `RemoteConfig.host` to match.

Verify:

```bash
curl https://sgsujood-data.xphyton.workers.dev/health
curl https://sgsujood-data.xphyton.workers.dev/nisab.json
```

## Adding a new year of prayer times

The core feature depends on this — the bundled data only covers 2026.

1. Parse next year's MUIS timetable into day records (`{"d":"2027-01-01","subuh":"05:52",…}`).
2. Append them to **`prayer_times.json`** in the repo root (keep all prior years in the file).
3. Commit + push. Within ~10 minutes every installed app picks up 2027 automatically; offline
   devices keep working from their last cached copy.

No app update, no reinstall. (Optionally also drop `prayer_times_2027.json` into the app bundle
and add `"2027"` to `PrayerData.bundledYears` so fresh installs have it offline before first
fetch.)

## Notes

- **Not an open proxy** — only the four whitelisted filenames are served (`ALLOW` in `worker.js`).
- **Caching** — 5 min at the edge, 10 min in the client. Lower `EDGE_TTL`/`BROWSER_TTL` for
  faster propagation, raise them to cut origin hits.
- **Private repo** — if you make the repo private, add a read-only `GITHUB_TOKEN` secret and an
  `Authorization: token …` header on the upstream `fetch`; nothing else changes.
- **Custom domain** — add a route in the Cloudflare dashboard (e.g. `data.sgsujood.app/*`) and
  set `RemoteConfig.host` to it.
