---
name: mac-stay-awake-self-improve
description: Project-specific guardrails for Mac Stay Awake decisions. Use whenever analyzing, changing, testing, or discussing this project’s sleep-prevention backend, IOPM assertions, caffeinate, pmset, SleepDisabled, UI status synchronization, lid-closed operation, or the requirement that Codex remain online for about 24 hours after the MacBook lid is closed.
---

# Mac Stay Awake Self Improve

## Preserve the actual acceptance criterion

- Treat “合上 MacBook 盖子后，Codex 仍能保持约 24 小时在线” as the primary requirement unless the user explicitly changes it.
- Treat the user's observed behavior from the current version as evidence. Do not replace it with a theoretically cleaner mechanism that has different lid-close semantics.
- Do not claim equivalence until the replacement has passed a representative lid-closed test. If that test cannot be performed in the current session, say it remains unverified.

## Do not repeat the IOPM mistake

- Do not recommend or substitute `IOPMAssertionCreateWithName`, `IOPMAssertionCreateWithDescription`, `kIOPMAssertionTypePreventUserIdleSystemSleep`, or `caffeinate -i` as the solution for lid-closed 24-hour Codex availability.
- Do not describe an idle-sleep assertion as equivalent to `pmset -a disablesleep 1`. Idle-sleep assertions may still allow sleep when the lid closes, and `SleepDisabled` may remain `0` while such an assertion is active.
- Only discuss an IOPM idle-sleep assertion when the user explicitly changes the requirement to preventing idle sleep while the MacBook remains open. State the limitation before proposing it.
- Record the reason for this prohibition: this replacement was proposed twice, the user implemented the resulting development work, and it did not satisfy the real use case.

## Default implementation direction

- Preserve the current `pmset -a disablesleep 1/0` backend unless the user explicitly authorizes a behavior change.
- Make the system value the UI source of truth. Read `SleepDisabled` at app launch, whenever the control UI opens, after system wake, after every enable/disable command, and when the user presses a manual refresh button.
- Show green only after verifying `SleepDisabled = 1`; show normal/gray for `0`; show an orange mismatch or detection-error state when verification fails.
- After setting the value, read it back before reporting success. Never let an in-memory Boolean alone determine the visible system status.
- Keep the manual status command and the UI on the same measurement when the backend remains `pmset`: both should inspect `SleepDisabled`.

## Validation and communication

- Inspect the current implementation before suggesting a power-management change; names such as `IOKitAwakeService` do not prove that IOKit is actually used.
- Separate “sleep prevention is enabled” from “Codex is online.” Network loss, process failure, restart, low power, and thermal protection remain independent failure modes.
- Validate command execution, read-back behavior, UI mismatch handling, and restoration to `SleepDisabled = 0` when disabling.
- Never promise guaranteed 24-hour availability. Report exactly which conditions were tested and which remain dependent on the user's real lid-closed observation.
