# Windows 1.3.0 validation

- Windows build succeeded with the .NET Framework compiler.
- 13 regression checks passed: verification, original restoration, manual nonzero changes, partial-write rollback, plan changes, persisted recovery, zero-baseline normalization, failure retention and retry.
- Actual enable/restore API calls and read-back were exercised.
- Hidden-window reactivation, normal quit and crash-watcher recovery were exercised.
- All four themes and three languages were rendered in local testing.
- Reported black-window and zero-baseline issues were corrected.
- The user accepted the corrected candidate on 2026-10-09 and authorized release.

The local hardware is HP OMEN 17-cb0xxx with S3 and no S0 Modern Standby. User acceptance applies to that setup; exhaustive battery/Modern Standby/DPI/accessibility coverage is not claimed. A network-adapter flag is not end-to-end Internet or Codex validation.

## Repeatable physical test

With the lid open, enable and verify AC/DC values are zero. Run a real background workload, close the lid for at least five minutes, reopen and check progress and connectivity. Restore normal mode with the lid open, verify the applicable action is Sleep or an existing nonzero action, then close and verify expected suspension. Test battery separately. A remote connection timeout alone does not prove sleep.
