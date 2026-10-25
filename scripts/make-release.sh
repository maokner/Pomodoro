#!/usr/bin/env bash
# Builds build/Pomodoro.dmg for a GitHub release and prints its SHA-256 for the Homebrew cask.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build-app.sh

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
ditto build/Pomodoro.app "$STAGING/Pomodoro.app"
ln -s /Applications "$STAGING/Applications"

DMG=build/Pomodoro.dmg
rm -f "$DMG"
hdiutil create -volname "Pomodoro" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null

echo "Built $DMG (version $VERSION)"
shasum -a 256 "$DMG"
