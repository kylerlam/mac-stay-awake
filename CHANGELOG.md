# Changelog

## 1.3.0 - 2026-09-20

- Add persistent language switching for Simplified Chinese, Traditional Chinese, and English, including status messages, errors, menus, and time formatting.
- Add Aurora Glass, Midnight Blue, and Warm Sand appearances alongside the default theme, with color previews inside the Appearance menu.
- Replace the app and menu bar icons with a monochrome coffee logo that adapts to light and dark appearances.
- Restore the compact 360 × 420 window with a smaller horizontal status header, refined spacing, and scrollable overflow for longer messages.
- Add an app preview, download link, and installation instructions to the README.

## 1.2.1 - 2026-07-28

- Replace the footer quit button with a compact application menu.
- Add an appearance submenu with the original default interface and a persistent frosted-glass option.
- Use native macOS behind-window blur, translucent status surfaces, subtle highlights, borders, and shadows for the frosted appearance.
- Respect the macOS Reduce Transparency accessibility setting with a more opaque fallback.

## 1.1.0 - 2026-07-17

- Show the verified macOS sleep-prevention state directly in the app.
- Automatically refresh status on launch, when the control window opens, after system wake, and every five seconds while the window is visible.
- Add a manual recheck action and an orange recovery state when the requested and detected values do not match.
- Use user-facing Chinese labels instead of exposing the `SleepDisabled` command-line key.
- Preserve the tested `pmset -a disablesleep 1/0` backend for lid-closed operation.

## 1.0.0 - 2026-07-15

- Initial release.
