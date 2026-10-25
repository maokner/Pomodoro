#!/usr/bin/env bash
# Builds build/Pomodoro.app. Pass --install to also copy it to ~/Applications.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
BIN="$(swift build -c release --show-bin-path)"

ICONSET=.build/AppIcon.iconset
rm -rf "$ICONSET"
"$BIN/make-icon" "$ICONSET"

APP=build/Pomodoro.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Pomodoro" "$APP/Contents/MacOS/Pomodoro"
cp Resources/Info.plist "$APP/Contents/Info.plist"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    mkdir -p "$HOME/Applications"
    rm -rf "$HOME/Applications/Pomodoro.app"
    cp -R "$APP" "$HOME/Applications/"
    echo "Installed to ~/Applications/Pomodoro.app"
fi
