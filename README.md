# Pomodoro

A tiny macOS menu bar pomodoro timer.
The menu bar shows the time left, and clicking it opens a retro timer device with a pixel cat that sleeps while you focus and wakes up on breaks.

## Install

```bash
brew install --cask maokner/tap/pomodoro
```

Requires macOS 14 or later on Apple silicon.

## Features

- Focus length: 10, 25, 60, 90 or 120 minutes. Break length: 5, 10, 15, 30 or 60 minutes. Defaults to 25 / 5.
- When a phase ends you get a notification, and the next phase waits for you to press Start.
- Reset rewinds the current phase. Pressing Reset on a break that hasn't started skips it.
- Open at login.
- The timer runs on an absolute end time, so it stays correct across sleep and app restarts.

## Shortcuts (panel open)

- Space: start or pause
- Cmd+,: settings
- Esc: close settings, or the popup
- Cmd+Q: quit (from settings)

Right-click the menu bar time for Settings and Quit.

## Build

Requires macOS 14+ and Xcode 16+.

```bash
./scripts/build-app.sh
```

That produces `build/Pomodoro.app`.
Add `--install` to also copy it to `~/Applications`.

## Release

1. Bump `CFBundleShortVersionString` in `Resources/Info.plist`.
2. Run `./scripts/make-release.sh`, which builds `build/Pomodoro.dmg` and prints its SHA-256.
3. Create a GitHub release tagged `v<version>` with the DMG attached.
4. Update `version` and `sha256` in `Casks/pomodoro.rb` in [maokner/homebrew-tap](https://github.com/maokner/homebrew-tap).

## Test

```bash
swift test
```

## Layout

- `Sources/PomodoroCore`: the timer state machine, daily session tally, and pixel-art sprites. No UI.
- `Sources/PomodoroUI`: the device, settings card and app model (SwiftUI).
- `Sources/Pomodoro`: the menu bar item and the borderless popup that hosts the device.
- `Sources/snapshot`: renders the popup in each state to PNGs (`swift run snapshot <dir>`), for checking the UI without clicking through it.
- `Sources/make-icon`: renders the app icon from the same cat sprite.
