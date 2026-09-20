import AppKit
import Combine
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: AwakeStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appAppearance") private var appearanceValue = AppAppearance.standard.rawValue
    private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceValue) ?? .standard
    }

    var body: some View {
        VStack(spacing: 14) {
            ScrollView {
                VStack(spacing: 16) {
                    statusView
                    systemStatusView
                    actionsView

                    if let errorMessage = store.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(appearance.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            footerView
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .frame(width: 360)
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
        HStack(spacing: 14) {
            Group {
                if store.isWarning {
                    Image(systemName: store.menuBarIconName)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(statusColor)
                } else {
                    Image(nsImage: AppLogo.templateImage)
                        .resizable()
                        .renderingMode(.template)
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle((appearance.colorScheme ?? colorScheme) == .dark
                            ? Color.white : Color(white: 0.14))
                }
            }
            .frame(width: 56, height: 56)
            .background { ThemeSurface(appearance: appearance, radius: 18) }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(store.statusTitle)
                    .font(.system(size: 19, weight: .semibold, design: appearance == .warmSand ? .serif : .rounded))
                    .foregroundStyle(store.isWarning ? statusColor : appearance.primaryText)
                Text(store.statusDetail)
                    .font(.system(size: 12))
                    .foregroundStyle(appearance.secondaryText)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(store.text(.currentStatus))
        .accessibilityValue("\(store.statusTitle). \(store.statusDetail)")
    }

    private var systemStatusView: some View {
        VStack(spacing: 11) {
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
        .padding(14)
        .background { ThemeSurface(appearance: appearance) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(store.text(.actualSystemStatus))
        .accessibilityValue("\(store.text(.preventSystemSleep)): \(store.protectionStatusTitle); \(store.text(.lastChecked)): \(store.lastCheckedTitle)")
    }

    private var actionsView: some View {
        VStack(spacing: 9) {
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
        VStack(spacing: 10) {
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
