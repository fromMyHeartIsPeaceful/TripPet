#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DESTINATION="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

cd "$ROOT"

echo "==> Validating postcard assets and visual contracts"
node Tools/validate_postcard_assets.js

echo "==> Running XCTest suite on ${TEST_DESTINATION}"
xcodebuild test \
  -project TripPet.xcodeproj \
  -scheme TripPet \
  -destination "$TEST_DESTINATION"

echo "==> Verifying Release build has no Debug-only surface"
xcodebuild build \
  -project TripPet.xcodeproj \
  -scheme TripPet \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator'

echo "==> Full TripPet test suite passed"
