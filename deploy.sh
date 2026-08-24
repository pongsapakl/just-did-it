#!/usr/bin/env bash
#
# deploy.sh — build "Just Did It" and install it on a connected iPhone,
# no Xcode UI required. Just plug in the phone (unlocked) and run: ./deploy.sh
#
# Relies on the signing already configured in the project (Automatic signing,
# DEVELOPMENT_TEAM set). Re-run any time — this is also how you renew the app
# before the free-signing 7-day expiry.
#
# This is the fast loop: a code change is on the phone in about a minute. To cut
# a build for TestFlight instead, use ./release.sh (see docs/RELEASING.md).

set -euo pipefail
cd "$(dirname "$0")"

PROJECT="JustDidIt.xcodeproj"
SCHEME="JustDidIt"
BUNDLE_ID="com.pongsapakl.justdidit"
DERIVED="build"
APP="$DERIVED/Build/Products/Debug-iphoneos/$SCHEME.app"

echo "▶ Finding connected iPhone…"
DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null \
  | grep -iE 'connected|available' \
  | grep -oE '[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}' \
  | head -1 || true)
if [ -z "${DEVICE_ID:-}" ]; then
  echo "✗ No connected iPhone found. Plug it in, unlock it, tap Trust, and retry."
  exit 1
fi
echo "  device: $DEVICE_ID"

echo "▶ Building (signed for device)…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  build \
  | grep -E "error:|warning: .*sign|BUILD (SUCCEEDED|FAILED)" || true

if [ ! -d "$APP" ]; then
  echo "✗ Build product not found at $APP — build likely failed (run without the grep to see why)."
  exit 1
fi

echo "▶ Installing…"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP" >/dev/null

echo "▶ Launching…"
if xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1; then
  echo "✓ Installed & launched on your iPhone."
else
  echo "✓ Installed — but it wouldn't launch."
  echo "  Usually the profile just isn't trusted yet: on the iPhone, open"
  echo "  Settings → General → VPN & Device Management → tap the developer"
  echo "  certificate → Trust. Then launch the app from the home screen."
  exit 1
fi
