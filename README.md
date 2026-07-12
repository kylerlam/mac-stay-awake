# Mac Stay Awake

A lightweight native macOS app that prevents idle system sleep while background tasks are running. It stays available from both the Dock and the menu bar.

## Features

- Prevent idle system sleep with one click.
- Restore normal sleep behavior at any time.
- Keep controls available in a standard, minimizable window and the menu bar.
- Check the current macOS `SleepDisabled` value with a bundled script.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools with Swift 6

## Build and run

```bash
./script/build_and_run.sh
```

The script builds the Swift package, creates `dist/MacStayAwake.app`, and launches the app bundle.

## Usage

1. Click the cup icon in the menu bar.
2. Click **保持唤醒** to prevent idle system sleep.
3. Click **恢复正常模式** when the background task is complete.

The app always starts in normal mode. It does not change permanent macOS power settings.

## Check system status

```bash
./script/status.sh
```

This runs `pmset -g | grep SleepDisabled`. A value of `1` means sleep is disabled; `0` means normal sleep behavior is enabled.

## Lid-closed limitation

Mac Stay Awake keeps background work running when the screen is locked and the Mac remains open. It does not guarantee that a MacBook continues running after its lid is closed. Lid-closed behavior is controlled by macOS, the hardware, power, and external-display conditions.

## Development

```bash
swift test
./script/build_and_run.sh --verify
```
