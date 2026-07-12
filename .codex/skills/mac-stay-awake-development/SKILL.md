---
name: mac-stay-awake-development
description: Develop, test, package, or release the Mac Stay Awake SwiftPM macOS app. Use for changes to Swift source, tests, Package.swift, assets, build scripts, app bundle configuration, project-local Codex files, DMG packaging, version tags, or GitHub Releases; always compile after changes and verify release artifacts before publishing.
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

## Release workflow

When the user asks to package, publish, release, create a DMG, tag a version, or update a GitHub Release, read and follow [references/release.md](references/release.md) completely.

Use the bundled DMG builder instead of rewriting packaging commands:

```bash
.codex/skills/mac-stay-awake-development/scripts/build_dmg.sh <version>
```

Do not publish a release until the canonical build succeeds and the DMG passes image verification plus a real mount-content check.

## macOS app constraints

- Preserve both Dock visibility and the right-side menu bar status item unless the user requests otherwise.
- Keep `NSApp.setActivationPolicy(.regular)` for Dock visibility.
- Keep `LSUIElement` false in the generated app bundle.
- Launch the GUI through the `.app` bundle, not the raw SwiftPM executable.
