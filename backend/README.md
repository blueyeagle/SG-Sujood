# Waqt SG — submission backend

A tiny Cloudflare Worker that lets the app accept "Add a space" submissions from **anyone**
(no GitHub account needed). It receives a JSON POST and opens a GitHub issue using a token
held only on the server; the repo's `space-submission` Action then appends the row to
`Prayer Space for Review.xlsx`.

```
App ──POST /submit──▶ Worker ──creates issue (server token)──▶ GitHub Action ──▶ workbook row
```

## Deploy (Cloudflare, free)

1. **Create a GitHub token** (this lives only in Cloudflare, never in the app):
   github.com/settings/tokens → **Fine-grained** → repo access **Only select repos → SG-Sujood**
   → Permissions → **Issues: Read and write** → Generate. Copy it.

2. **Deploy the Worker** (from this `backend/` folder):
   ```bash
   npm i -g wrangler
   wrangler login
   wrangler deploy
   wrangler secret put GITHUB_TOKEN     # paste the token when prompted
   # optional abuse deterrent:
   # wrangler secret put APP_KEY        # any random string; also set it in the app
   ```
   Or paste `worker.js` into the Cloudflare dashboard (Workers & Pages → Create → Worker),
   then add the variable `REPO=blueyeagle/SG-Sujood` and secret `GITHUB_TOKEN`.

3. **Copy the Worker URL** (e.g. `https://waqtsg-submit.<you>.workers.dev`) and set it in the
   app: `WaqtSG/WaqtSG/SubmissionService.swift` → `endpoint = ".../submit"`. Until you do, the
   app falls back to opening a prefilled GitHub issue in the browser.

4. Make sure the repo has **Settings → Actions → General → Workflow permissions → Read and
   write** so the Action can commit the workbook.

## Test

```bash
curl -X POST https://waqtsg-submit.<you>.workers.dev/submit \
  -H 'Content-Type: application/json' \
  -d '{"building":"Suntec City","floor":"B1, Tower 2","walk":"7 minutes","type":"Musollah"}'
# => {"ok":true,"issue":43}
```

A row should appear in `Prayer Space for Review.xlsx` within a minute.

## Vercel alternative

Prefer Vercel? Create `api/submit.js` with the same logic (`export default async function
handler(req,res){…}`), set `GITHUB_TOKEN` and `REPO` as project env vars, and point the app
at `https://<project>.vercel.app/api/submit`.

## Notes

- The endpoint is public; `APP_KEY` only deters casual abuse (the app key is extractable).
  For real protection add rate limiting (Cloudflare rules) or a CAPTCHA/Turnstile.
- The token is never shipped in the app — it lives only in the Worker's secrets.
