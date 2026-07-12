---
name: mac-stay-awake-development
description: Develop, fix, refactor, or configure the Mac Stay Awake SwiftPM macOS app. Use for any change to Swift source, tests, Package.swift, assets, build scripts, app bundle configuration, or project-local Codex files in this repository; always compile after every change without waiting for the user to request it.
---

# Mac Stay Awake Development

Keep changes narrow and preserve existing behavior outside the request.

## Required workflow

1. Inspect the current Git status before editing and preserve unrelated user changes.
2. Make the smallest change that satisfies the request.
3. After every source, test, asset, packaging, or build-script change, run:

   ```bash
   ./script/build_and_run.sh --verify
   ```

   This is the canonical build path because it compiles the SwiftPM executable, rebuilds `dist/MacStayAwake.app`, launches it, and verifies the process.
4. Run `swift test` when behavior or testable logic changes.
5. After changing only project-local documentation or Skill files, run at least:

   ```bash
   swift build
   ```

6. Do not report completion if compilation fails. Diagnose and fix the failure, then compile again.
7. In the final response, state which build command ran and whether it succeeded.

## macOS app constraints

- Preserve both Dock visibility and the right-side menu bar status item unless the user requests otherwise.
- Keep `NSApp.setActivationPolicy(.regular)` for Dock visibility.
- Keep `LSUIElement` false in the generated app bundle.
- Launch the GUI through the `.app` bundle, not the raw SwiftPM executable.
