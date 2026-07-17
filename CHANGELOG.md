# Changelog

## 1.1.0 - 2026-07-17

- Show the verified macOS sleep-prevention state directly in the app.
- Automatically refresh status on launch, when the control window opens, after system wake, and every five seconds while the window is visible.
- Add a manual recheck action and an orange recovery state when the requested and detected values do not match.
- Use user-facing Chinese labels instead of exposing the `SleepDisabled` command-line key.
- Preserve the tested `pmset -a disablesleep 1/0` backend for lid-closed operation.

## 1.0.0 - 2026-07-15

- Initial release.
