#!/usr/bin/env bash
# One-command TestFlight release: bump build number → archive → export → upload.
#
#   scripts/release.sh            # build number = git commit count (monotonic)
#   scripts/release.sh 57         # force a specific build number
#
# Requires scripts/asc.env (API key config, gitignored). See TESTFLIGHT.md.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

# App Store Connect API key — used to sign/export non-interactively (no logged-in Xcode account
# needed) and to upload. Comes from scripts/asc.env (gitignored) or the environment.
[ -f "$HERE/asc.env" ] && source "$HERE/asc.env"
AUTH=()
if [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ]; then
  KEYP8="${ASC_KEY_P8:-$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8}"
  AUTH=(-authenticationKeyPath "$KEYP8" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi
PROJ="$REPO/SGSujood/SGSujood.xcodeproj"
SCHEME="SGSujood"
EXPORT_OPTS="$REPO/SGSujood/ExportOptions.plist"
IPA_OUT_DIR="$REPO/../ipa build files"

# Build number: explicit arg, else the git commit count (always increasing).
BUILD="${1:-$(git -C "$REPO" rev-list --count HEAD)}"
[[ "$BUILD" =~ ^[0-9]+$ ]] || { echo "Build number must be an integer, got: $BUILD"; exit 2; }

# Marketing (user-facing) version, read from the project.
MKT="$(grep -m1 'MARKETING_VERSION' "$PROJ/project.pbxproj" | sed 's/.*= *//; s/;.*//' | tr -d ' ')"
MKT="${MKT:-1.0}"

WORK="${TMPDIR:-/tmp}/sgsujood-release"
ARCHIVE="$WORK/SGSujood.xcarchive"
EXPORT_DIR="$WORK/export"
rm -rf "$WORK"; mkdir -p "$WORK"

echo "▶ Releasing $SCHEME  version $MKT  build $BUILD"

echo "▶ [1/4] Archiving (Release)…"
xcodebuild archive \
  -project "$PROJ" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} \
  MARKETING_VERSION="$MKT" CURRENT_PROJECT_VERSION="$BUILD" \
  >"$WORK/archive.log" 2>&1 || { echo "✗ archive failed — see $WORK/archive.log"; tail -20 "$WORK/archive.log"; exit 1; }

echo "▶ [2/4] Exporting App Store .ipa…"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" -exportOptionsPlist "$EXPORT_OPTS" \
  -exportPath "$EXPORT_DIR" -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} \
  >"$WORK/export.log" 2>&1 || { echo "✗ export failed — see $WORK/export.log"; tail -20 "$WORK/export.log"; exit 1; }

IPA_SRC="$EXPORT_DIR/SGSujood.ipa"
[ -f "$IPA_SRC" ] || { echo "✗ no .ipa produced at $IPA_SRC"; exit 1; }

mkdir -p "$IPA_OUT_DIR"
IPA_DEST="$IPA_OUT_DIR/SGSujood-$MKT-build$BUILD-appstore.ipa"
cp -f "$IPA_SRC" "$IPA_DEST"
echo "▶ [3/4] Saved $IPA_DEST"

echo "▶ [4/4] Uploading to TestFlight…"
"$HERE/upload-testflight.sh" "$IPA_DEST"

echo "✓ Release $MKT ($BUILD) uploaded. App Store Connect → SG Sujood → TestFlight (Processing…)."
