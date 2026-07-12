# Release Workflow

Follow this sequence for a Mac Stay Awake release. Preserve unrelated worktree changes and stop on any failed validation.

## 1. Prepare

1. Inspect `git status --short --branch`, recent commits, existing tags, and the remote.
2. Determine the semantic version from the user request or current release work. Never silently overwrite an existing tag or Release.
3. Confirm the source contains the intended version and release notes.
4. Run:

   ```bash
   ./script/build_and_run.sh --verify
   swift test
   ```

5. Commit only the intended tracked changes. Push the release commit before tagging.

## 2. Tag

Create an annotated tag on the verified release commit and push it:

```bash
git tag -a "v$VERSION" -m "Mac Stay Awake v$VERSION"
git push origin main
git push origin "v$VERSION"
```

Before creating the tag, check `git tag --list "v$VERSION"`. If it exists, inspect it instead of replacing it.

## 3. Build the DMG

Run the bundled script from the repository root:

```bash
.codex/skills/mac-stay-awake-development/scripts/build_dmg.sh "$VERSION"
```

The script must produce `dist/MacStayAwake-v$VERSION.dmg`, verify the image checksum, mount it read-only, confirm both `MacStayAwake.app` and the `Applications` symlink, detach it, and print SHA-256 plus size.

Do not distribute a DMG that fails any of these checks. Do not claim the app is signed or notarized unless `codesign` and Apple notarization verification prove it.

## 4. Publish to GitHub

Create or update the GitHub Release for tag `v$VERSION`. Prefer, in order:

1. `gh release create` or `gh release upload` when GitHub CLI is installed and authenticated.
2. GitHub REST API using the existing `osxkeychain` Git credential without printing or storing the credential.
3. An already authenticated browser session when no authenticated command-line route exists.

Upload `dist/MacStayAwake-v$VERSION.dmg` as `application/x-apple-diskimage`. If an asset with the same name already exists, replace it only when the user asked to update that release.

Release notes must include:

- A concise summary and highlights.
- Installation steps: download DMG, open it, drag the app to `Applications`.
- Minimum supported macOS version.
- The DMG SHA-256.
- A clear unsigned/notarization warning when applicable.

Creating or updating a public Release is an external side effect. Follow the active tool's confirmation policy immediately before the final publish or update action.

## 5. Verify and report

After publishing, use the GitHub API or public Release page to verify:

- The Release URL resolves and has the expected tag and title.
- The DMG asset state is `uploaded`.
- The public asset name, size, and download URL are correct.
- The release notes show the matching SHA-256 and installation instructions.

Report the Release URL, direct DMG URL, SHA-256, build/test results, and signing/notarization status. Keep generated files in ignored `dist/`; do not commit release binaries unless the repository policy changes.
