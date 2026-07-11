# Mac Stay Awake

A lightweight native macOS menu bar app that prevents idle system sleep while background tasks are running.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools with Swift 6

## Build and run

```bash
./script/build_and_run.sh
```

The script builds the Swift package, creates `dist/MacStayAwake.app`, and launches it as a menu-bar-only app.

## Usage

1. Click the cup icon in the menu bar.
2. Click **保持唤醒** to prevent idle system sleep.
3. Click **恢复正常模式** when the background task is complete.

The app always starts in normal mode. It does not change permanent macOS power settings.

## Lid-closed limitation

Mac Stay Awake keeps background work running when the screen is locked and the Mac remains open. It does not guarantee that a MacBook continues running after its lid is closed. Lid-closed behavior is controlled by macOS, the hardware, power, and external-display conditions.

## Test

```bash
swift test
```
