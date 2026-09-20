import AppKit
import Combine
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: AwakeStore
    @AppStorage("appAppearance") private var appearanceValue = AppAppearance.standard.rawValue
    private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceValue) ?? .standard
    }

    var body: some View {
        VStack(spacing: 22) {
            statusView
            systemStatusView
            actionsView

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(appearance.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            footerView
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .frame(width: 390)
        .foregroundStyle(appearance.primaryText)
        .background { ThemeBackground(appearance: appearance) }
        .background { ThemeWindowAppearance(appearance: appearance) }
        .preferredColorScheme(appearance.colorScheme)
        .environment(\.locale, store.language.locale)
        .onAppear { store.refreshStatus() }
        .onReceive(refreshTimer) { _ in
            guard NSApp.windows.contains(where: { $0.title == "Mac Stay Awake" && $0.isVisible }) else {
                return
            }
            store.refreshStatus()
        }
    }

    private var statusView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(appearance.accent.opacity(0.12), lineWidth: 1)
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(statusColor.opacity(0.08))
                    .frame(width: 76, height: 76)
                Image(systemName: store.menuBarIconName)
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(statusColor)
                .frame(width: 64, height: 64)
                .background { ThemeSurface(appearance: appearance, radius: 24) }
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(store.statusTitle)
                    .font(.system(size: 23, weight: .semibold, design: appearance == .warmSand ? .serif : .rounded))
                    .foregroundStyle(store.isWarning ? statusColor : appearance.primaryText)
                Text(store.statusDetail)
                    .font(.system(size: 12))
                    .foregroundStyle(appearance.secondaryText)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(store.text(.currentStatus))
        .accessibilityValue("\(store.statusTitle). \(store.statusDetail)")
    }

    private var systemStatusView: some View {
        VStack(spacing: 14) {
            HStack {
                Label(store.text(.preventSystemSleep), systemImage: "moon.zzz")
                    .foregroundStyle(appearance.secondaryText)
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    Circle().fill(statusColor).frame(width: 5, height: 5)
                    Text(store.protectionStatusTitle)
                        .fontWeight(.semibold)
                }
                .font(.system(size: 11))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(statusColor.opacity(0.10), in: Capsule())
            }

            Rectangle().fill(appearance.border).frame(height: 1)

            HStack {
                Label(store.text(.lastChecked), systemImage: "clock")
                    .foregroundStyle(appearance.secondaryText)
                Spacer(minLength: 8)
                Text(store.lastCheckedTitle)
                    .monospacedDigit()
                    .fontWeight(.medium)
            }
        }
        .font(.system(size: 12))
        .padding(16)
        .background { ThemeSurface(appearance: appearance) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(store.text(.actualSystemStatus))
        .accessibilityValue("\(store.text(.preventSystemSleep)): \(store.protectionStatusTitle); \(store.text(.lastChecked)): \(store.lastCheckedTitle)")
    }

    private var actionsView: some View {
        VStack(spacing: 10) {
            Button {
                store.toggle()
            } label: {
                Label(store.actionTitle, systemImage: store.mode == .unknown ? "arrow.clockwise" : "power")
            }
            .buttonStyle(ThemeActionStyle(appearance: appearance, prominent: true))
            .disabled(store.isChecking)
            .accessibilityHint(store.text(store.isAwake ? .allowSleepHint : .enableAwakeHint))

            if let secondaryActionTitle = store.secondaryActionTitle {
                Button(secondaryActionTitle) { store.acceptDetectedStatus() }
                    .buttonStyle(ThemeActionStyle(appearance: appearance))
            }

            if store.mode != .unknown {
                Button { store.refreshStatus() } label: {
                    Label(store.refreshActionTitle, systemImage: "arrow.clockwise")
                }
                .buttonStyle(ThemeActionStyle(appearance: appearance))
                .disabled(store.isChecking)
            }

            Text(store.text(.autoCheck))
                .font(.system(size: 10))
                .foregroundStyle(appearance.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    private var footerView: some View {
        VStack(spacing: 14) {
            Rectangle().fill(appearance.border).frame(height: 1)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Mac Stay Awake")
                        .font(.system(size: 10, weight: .medium))
                    Text(store.text(appearance.titleKey))
                        .font(.system(size: 10))
                        .foregroundStyle(appearance.secondaryText)
                }
                Spacer(minLength: 4)
                appMenu
            }
        }
    }

    private var appMenu: some View {
        AppMenuButton(store: store, appearanceValue: $appearanceValue)
            .frame(width: 38, height: 28)
            .background { ThemeSurface(appearance: appearance, radius: 9) }
    }

    private var statusColor: Color {
        if store.isWarning { return appearance.warning }
        return store.isAwake ? appearance.success : appearance.secondaryText
    }
}
