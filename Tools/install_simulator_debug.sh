#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_NAME="${DEVICE_NAME:-iPhone 17}"
DEVICE_ID="${DEVICE_ID:-}"
DERIVED_DATA="$ROOT/.derivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/TripPet.app"
BUNDLE_ID="com.qianyu.TripPet"

cd "$ROOT"

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun simctl list devices available | awk -v name="$DEVICE_NAME" '
    $0 ~ name" \\(" {
      match($0, /\(([0-9A-F-]+)\)/, found)
      if (found[1] != "") {
        print found[1]
        exit
      }
    }
  ')"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "Unable to find simulator: $DEVICE_NAME" >&2
  exit 1
fi

echo "==> Building Debug app for $DEVICE_NAME ($DEVICE_ID)"
xcodebuild build \
  -project TripPet.xcodeproj \
  -scheme TripPet \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -derivedDataPath "$DERIVED_DATA"

echo "==> Booting simulator"
xcrun simctl boot "$DEVICE_ID" || true
xcrun simctl bootstatus "$DEVICE_ID" -b

echo "==> Installing without launching"
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" || true
xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" || true
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "==> Installed app path"
xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" app
