# Mac Stay Awake for Windows 1.3.0

[Download Windows 1.3.0](https://github.com/kylerlam/mac-stay-awake/releases/tag/windows-v1.3.0) · [繁體中文使用指南](USER-GUIDE.zh-Hant.md) · [Validation](VALIDATION.md)

Native Windows edition, version-aligned with macOS **1.3.0**. Keeps background desktop work running with the laptop lid closed, subject to Windows policy and hardware support.

## Install and run

Download **WindowsStayAwake-v1.3.0-win-x64.exe**, or extract the ZIP containing the EXE and documentation. Run the EXE directly: its interface and icons are embedded, with no companion XAML or Assets folder required.

Requires Windows 10/11 x64 and .NET Framework 4.8 or newer. The executable is unsigned; Windows may show an unknown-publisher warning. No installer, service, scheduled task or automatic startup entry is added.

## Controls

| Action | Result |
| --- | --- |
| Enable Closed-Lid Mode | Captures the active plan and AC/DC lid actions, holds a continuous system execution request, sets both lid actions to Do Nothing, applies and verifies read-back. |
| Restore Normal Mode | Releases the request, restores owned settings, then changes remaining Do Nothing actions on the current plan to Sleep. Existing nonzero actions such as Hibernate are preserved. |
| Check Again | Reads the actual settings again. |
| Close (X) | Hides the window; the app remains in the notification area. |
| Open the EXE again | Restores the existing window instead of creating a second instance. |
| Quit / Ctrl+Q | Restores the captured baseline and exits. If the baseline was already Do Nothing, this preserves it; use Restore Normal Mode first to establish lid sleep. |

If Windows still has a Do Nothing lid action while the app is off, a warning and Restore Normal Mode action appear. Apply normal mode while the lid is open: closing the lid with Sleep selected normally interrupts remote access.

Appearance includes Default, Aurora Glass, Midnight Blue and Warm Sand. Simplified Chinese, Traditional Chinese and English preferences are saved per user. Windows retains native title bars, fonts and menus. Artwork, palette, layout and effects are ported from the macOS source; pixel-identical platform rendering is not claimed.

## Recovery and limits

A journal is persisted before power changes. A watcher restores after an unexpected main-process exit; next launch also recovers unfinished state. Failed enable operations roll back. Nonzero manual changes are preserved. Changing power plans stops the mode and restores the old plan without activating it or modifying the new plan. Failed restoration retains the journal for retry.

The app prevents automatic idle sleep, not explicit Sleep, shutdown, restart, critical-battery or thermal actions. It does not guarantee network or Codex availability. Modern Standby, OEM tools and organizational policy can impose restrictions. Local acceptance was on an HP OMEN 17-cb0xxx using S3; battery and other hardware require separate validation.

WPF uses process-local software rendering and redraws after display/compositor/resume notifications. No global graphics or registry settings are changed.

## Troubleshooting

- Remote access still works after disabling: use Restore Normal Mode to correct a pre-existing Do Nothing baseline.
- Black window: exit older copies and use this release, which includes software rendering.
- Permission/policy error: success is not reported after a rejected write. Managed settings may require IT assistance.
- Recovery warning: retry restoration; do not remove an outstanding recovery journal.
- Logs and preferences: %LOCALAPPDATA%/MacStayAwake.Windows contains app.log, preferences.txt and power-session.xml. Review logs before sharing; timestamps and power-plan identifiers are recorded. Network flags only indicate adapter availability.

## Build, test and package

Run these commands from the windows branch checkout:

    powershell -ExecutionPolicy Bypass -File Windows/build.ps1
    powershell -ExecutionPolicy Bypass -File Windows/test.ps1
    powershell -ExecutionPolicy Bypass -File Windows/package.ps1

The build uses the Windows .NET Framework C# compiler, with no NuGet packages. A Visual Studio project targets .NET Framework 4.8. Output is Windows/bin/WindowsStayAwake.exe. Packaging creates versioned EXE, ZIP and SHA256SUMS files in dist/windows/1.3.0. Tests use a fake backend and do not modify host power settings. Windows CI runs the same checks.

Release tag: **windows-v1.3.0**. The macOS tag **v1.3.0** is separate and unchanged.

## Remove

While the lid is open, use Restore Normal Mode if you want lid sleep, then Quit. Delete the downloaded EXE/folder. No system installation exists to uninstall. Preferences can be removed separately after confirming no power-session.xml recovery is pending.
