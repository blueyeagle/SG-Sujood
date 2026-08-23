#!/usr/bin/env bash
# Upload an App Store–signed .ipa to TestFlight using an App Store Connect API key.
#
#   scripts/upload-testflight.sh "../ipa build files/SGSujood-1.0-appstore.ipa"
#
# Config comes from scripts/asc.env (gitignored — copy asc.env.example and fill it in),
# or from the environment: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 (path to AuthKey_*.p8).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/asc.env" ] && source "$HERE/asc.env"

IPA="${1:-}"
[ -n "$IPA" ] || { echo "Usage: $0 <path-to-.ipa>"; exit 2; }
[ -f "$IPA" ] || { echo "Not found: $IPA"; exit 2; }
: "${ASC_KEY_ID:?Set ASC_KEY_ID (in scripts/asc.env or the environment)}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID (in scripts/asc.env or the environment)}"

# altool auto-discovers the key at ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8
KEYDIR="$HOME/.appstoreconnect/private_keys"
mkdir -p "$KEYDIR"
if [ -n "${ASC_KEY_P8:-}" ] && [ -f "$ASC_KEY_P8" ]; then
  cp -f "$ASC_KEY_P8" "$KEYDIR/AuthKey_${ASC_KEY_ID}.p8"
fi
[ -f "$KEYDIR/AuthKey_${ASC_KEY_ID}.p8" ] || {
  echo "Missing $KEYDIR/AuthKey_${ASC_KEY_ID}.p8 — set ASC_KEY_P8 to your downloaded .p8 path."; exit 1; }

echo "▶ Validating $IPA …"
xcrun altool --validate-app -f "$IPA" -t ios --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "▶ Uploading $IPA …"
xcrun altool --upload-app -f "$IPA" -t ios --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "✓ Uploaded. App Store Connect → your app → TestFlight (build shows as “Processing” for a few minutes)."
