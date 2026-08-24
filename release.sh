#!/usr/bin/env bash
#
# release.sh — archive "Just Did It" for release and upload it to App Store
# Connect, where it can be handed to TestFlight testers.
#
# Nothing account-specific lives in this file. Everything comes from the
# environment, so whoever holds the Apple Developer Program membership runs:
#
#   DEVELOPMENT_TEAM=ABCDE12345 \
#   ASC_KEY_ID=XXXXXXXXXX \
#   ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000 \
#   ./release.sh
#
# The App Store Connect API key (AuthKey_<ASC_KEY_ID>.p8) belongs in
# ~/.appstoreconnect/private_keys/ on that machine — never in this repo.
#
# Full walkthrough: docs/RELEASING.md
# For everyday local installs onto your own phone, use ./deploy.sh instead.

set -euo pipefail
cd "$(dirname "$0")"

: "${DEVELOPMENT_TEAM:?set DEVELOPMENT_TEAM to your 10-character Apple Team ID}"

PROJECT="JustDidIt.xcodeproj"
SCHEME="JustDidIt"
DERIVED="build"
ARCHIVE="$DERIVED/$SCHEME.xcarchive"
EXPORT_DIR="$DERIVED/export"
OPTIONS="$DERIVED/ExportOptions.plist"

# App Store Connect refuses a build number it has already accepted, and a
# timestamp always moves forward — no commit or file edit needed per upload.
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d).$(date +%H%M)}"

echo "▶ Archiving $SCHEME (Release, build $BUILD_NUMBER)…"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  | grep -E "error:|warning: .*sign|ARCHIVE (SUCCEEDED|FAILED)" || true

if [ ! -d "$ARCHIVE" ]; then
  echo "✗ No archive at $ARCHIVE — the build failed (re-run without the grep to see why)."
  exit 1
fi

# Written fresh each run so nothing containing a Team ID is ever left to commit.
echo "▶ Exporting .ipa…"
cat > "$OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>$DEVELOPMENT_TEAM</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>uploadSymbols</key>
	<true/>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$OPTIONS" \
  -allowProvisioningUpdates \
  | grep -E "error:|EXPORT (SUCCEEDED|FAILED)" || true

IPA=$(find "$EXPORT_DIR" -name "*.ipa" -maxdepth 1 | head -1 || true)
if [ -z "${IPA:-}" ]; then
  echo "✗ No .ipa produced — export failed."
  exit 1
fi
echo "  $IPA"

if [ -z "${ASC_KEY_ID:-}" ] || [ -z "${ASC_ISSUER_ID:-}" ]; then
  echo "▶ ASC_KEY_ID / ASC_ISSUER_ID not set — skipping upload."
  echo "  Upload the .ipa above by hand with the Transporter app, or set both and re-run."
  exit 0
fi

echo "▶ Uploading to App Store Connect…"
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "✓ Uploaded build $BUILD_NUMBER. It appears in TestFlight once Apple finishes processing (usually 5–30 min)."
