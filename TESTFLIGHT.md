# Releasing SG Sujood to TestFlight

Automated by [`.github/workflows/testflight.yml`](.github/workflows/testflight.yml): it
builds, signs and uploads a build to TestFlight on demand (or on a version tag). Setup is a
one-time task; after that a release is one click.

```
Run workflow / push tag  →  macOS runner archives (Release)  →  signs via ASC API key
                          →  exports .ipa  →  uploads to App Store Connect → TestFlight
```

---

## 1. One-time prerequisites

- A **paid Apple Developer Program** membership ($99/yr). A free Apple ID cannot use TestFlight.
- The bundle ID **`com.sgsujood.app`** registered under
  [Certificates, Identifiers & Profiles → Identifiers](https://developer.apple.com/account/resources/identifiers/list).
- An **app record** in [App Store Connect](https://appstoreconnect.apple.com) → **Apps → + →
  New App** (iOS, name "SG Sujood", bundle ID `com.sgsujood.app`, any SKU).

---

## 2. Create the two credentials

### a. Apple Distribution certificate (`.p12`)
Signs the build. Create once and reuse — don't regenerate each release (Apple caps
distribution certs at 2–3).

1. Xcode → **Settings → Accounts →** your team **→ Manage Certificates → +  → Apple
   Distribution**.
2. In **Keychain Access**, find that "Apple Distribution" cert, expand it, select **both** the
   certificate and its private key → right-click → **Export 2 items…** → save `dist.p12` and
   set a password (this becomes `DIST_CERT_PASSWORD`).

### b. App Store Connect API key (`.p8`)
Lets CI sign and upload without your Apple ID / 2FA.

1. App Store Connect → **Users and Access → Integrations → App Store Connect API → Keys → +**.
2. Name it, role **App Manager**, **Generate**.
3. **Download the `AuthKey_XXXXXXXXXX.p8`** (one time only). Note the **Key ID** and the
   **Issuer ID** shown on that page.

---

## 3. Add the repo secrets

**Settings → Secrets and variables → Actions → New repository secret** — add all six:

| Secret | Value / how to produce it |
| --- | --- |
| `DIST_CERT_P12_BASE64` | `base64 -i dist.p12 \| pbcopy` |
| `DIST_CERT_PASSWORD` | the password you set when exporting `dist.p12` |
| `KEYCHAIN_PASSWORD` | any random string (throwaway CI keychain password) |
| `ASC_KEY_ID` | the API **Key ID** |
| `ASC_ISSUER_ID` | the **Issuer ID** from the Keys page |
| `ASC_KEY_P8_BASE64` | `base64 -i AuthKey_XXXX.p8 \| pbcopy` |

(`pbcopy` puts the base64 on your clipboard; paste it as the secret value.)

---

## 3a. One command: bump → archive → export → upload

With `scripts/asc.env` filled in (Key ID + Issuer ID + `.p8` path), a full release is one command:

```bash
scripts/release.sh          # build number = git commit count (always increasing)
scripts/release.sh 57       # or force a specific build number
```

It archives (Release), exports an App Store `.ipa` into `../ipa build files/`, and uploads to
TestFlight. The build number is auto-derived so each run is higher than the last — no manual
edit. `MARKETING_VERSION` (the `1.0` version string) is read from the project; bump it there
when you want a new version.

## 3b. Upload an already-built .ipa with the API key (no CI, no Transporter)

Once you have the API key, you can upload a locally-built `.ipa` in one command:

1. `cp scripts/asc.env.example scripts/asc.env` and fill in `ASC_KEY_ID`, `ASC_ISSUER_ID`,
   and `ASC_KEY_P8` (path to your downloaded `AuthKey_XXXX.p8`). `scripts/asc.env` and
   `*.p8` are gitignored — they never get committed.
2. Run it against the App Store–signed build:
   ```bash
   scripts/upload-testflight.sh "../ipa build files/SGSujood-1.0-appstore.ipa"
   ```
   It validates, then uploads, then the build appears in TestFlight ("Processing").

(To build that `.ipa`: Xcode **Product → Archive → Distribute App → App Store Connect →
Export**, or the CI workflow below.)

---

## 4. Release a build

- **Manually:** GitHub → **Actions → TestFlight → Run workflow**.
- **Or by tag:** `git tag v1.0.1 && git push --tags`.

The build number is set to the workflow **run number**, so every upload is unique — you don't
edit it by hand. `MARKETING_VERSION` (the user-facing version, `1.0`) lives in the project;
bump it when you want a new version string.

After the run finishes, the build shows in App Store Connect → your app → **TestFlight**
("Processing" for a few minutes), then add it to **Internal Testing** and invite testers.

---

## 5. Notes & troubleshooting

- **Runner minutes:** macOS minutes bill at 10× on private repos (public repos are free).
- **Xcode version:** the workflow uses `latest-stable` on `macos-15`; the project needs
  Xcode 16+. If a runner's latest-stable lags, pin a version in the `setup-xcode` step.
- **"No signing certificate / profile":** the distribution cert or app record isn't set up —
  finish steps 1–2; that's account setup, not a workflow bug.
- **Export compliance:** already handled — `ITSAppUsesNonExemptEncryption = NO` (HTTPS only).
- **Debug hooks:** the `SGSUJOOD_SCREEN` launch-env hooks are inert in a shipped build, but
  strip them before a public App Store submission.
- Manual (no CI) steps are in [`SGSujood/BUILD_NOTES.md`](SGSujood/BUILD_NOTES.md).
