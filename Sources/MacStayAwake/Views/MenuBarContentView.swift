import AppKit
import Combine
import SwiftUI

private enum AppAppearance: String {
    case standard
    case frostedGlass
}

struct MenuBarContentView: View {
    @ObservedObject var store: AwakeStore
    @AppStorage("appAppearance") private var appearance = AppAppearance.standard.rawValue
    private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var usesFrostedGlass: Bool {
        appearance == AppAppearance.frostedGlass.rawValue
    }

    var body: some View {
        content
            .background {
                if usesFrostedGlass {
                    FrostedGlassBackground()
                } else {
                    Color(nsColor: .windowBackgroundColor)
                }
            }
            .environment(\.locale, store.language.locale)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusView

            systemStatusView

            Button {
                store.toggle()
            } label: {
                Text(store.actionTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(statusColor)
            .controlSize(.large)
            .disabled(store.isChecking)
            .accessibilityHint(store.isAwake
                ? store.text(.allowSleepHint)
                : store.text(.enableAwakeHint))

            if let secondaryActionTitle = store.secondaryActionTitle {
                Button(secondaryActionTitle) {
                    store.acceptDetectedStatus()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }

            if store.mode != .unknown {
                Button {
                    store.refreshStatus()
                } label: {
                    Label(store.refreshActionTitle, systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(store.isChecking)
            }

            Text(store.text(.autoCheck))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                Text("Mac Stay Awake")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    Menu {
                        appearanceButton(store.text(.standardAppearance), appearance: .standard)
                        appearanceButton(store.text(.frostedGlass), appearance: .frostedGlass)
                    } label: {
                        Label(store.text(.appearance), systemImage: "paintbrush")
                    }

                    Menu {
                        Picker(store.text(.switchLanguage), selection: $store.language) {
                            ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                                Text(language.nativeName).tag(language)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } label: {
                        Label(store.text(.switchLanguage), systemImage: "globe")
                    }

                    Divider()

                    Button {
                        store.shutDown()
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Label(store.text(.quit), systemImage: "power")
                    }
                    .keyboardShortcut("q")
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .frame(width: 22, height: 22)
                        .padding(5)
                        .background {
                            if usesFrostedGlass {
                                Circle()
                                    .fill(.regularMaterial)
                                    .overlay {
                                        Circle()
                                            .stroke(.white.opacity(0.32), lineWidth: 1)
                                    }
                                    .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
                            }
                        }
                }
                .menuStyle(.borderlessButton)
                .buttonStyle(.plain)
                .accessibilityLabel(store.text(.appMenu))
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            store.refreshStatus()
        }
        .onReceive(refreshTimer) { _ in
            guard NSApp.windows.contains(where: { $0.title == "Mac Stay Awake" && $0.isVisible }) else {
                return
            }
            store.refreshStatus()
        }
    }

    private func appearanceButton(_ title: String, appearance option: AppAppearance) -> some View {
        Button {
            appearance = option.rawValue
        } label: {
            if appearance == option.rawValue {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }

    private var statusView: some View {
        HStack(spacing: 12) {
            Image(systemName: store.menuBarIconName)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 42, height: 42)
                .background {
                    if usesFrostedGlass {
                        Circle()
                            .fill(.regularMaterial)
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(0.38), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.14), radius: 10, y: 5)
                    } else {
                        Circle()
                            .fill(.quaternary)
                    }
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(store.statusTitle)
                    .font(.headline)
                    .foregroundStyle(store.isWarning ? statusColor : Color.primary)

                Text(store.statusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(store.text(.currentStatus))
        .accessibilityValue(store.statusTitle)
    }

    private var systemStatusView: some View {
        VStack(spacing: 10) {
            HStack {
                Text(store.text(.preventSystemSleep))
                Spacer()
                Text(store.protectionStatusTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
            }

            Divider()

            HStack {
                Text(store.text(.lastChecked))
                Spacer()
                Text(store.lastCheckedTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .padding(12)
        .background {
            let shape = RoundedRectangle(cornerRadius: usesFrostedGlass ? 16 : 10)

            if usesFrostedGlass {
                shape
                    .fill(.regularMaterial)
                    .overlay {
                        shape
                            .stroke(.white.opacity(0.34), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
            } else {
                shape
                    .fill(.quaternary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(store.text(.actualSystemStatus))
        .accessibilityValue("\(store.text(.preventSystemSleep)): \(store.protectionStatusTitle); \(store.text(.lastChecked)): \(store.lastCheckedTitle)")
    }

    private var statusColor: Color {
        if store.isWarning { return .orange }
        return store.isAwake ? .green : .secondary
    }
}

private struct FrostedGlassBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Group {
            if reduceTransparency {
                Color(nsColor: .windowBackgroundColor).opacity(0.94)
            } else {
                NativeWindowBlur()
                    .overlay {
                        Color(nsColor: .windowBackgroundColor).opacity(0.12)
                    }
                    .overlay(alignment: .top) {
                        Color.white.opacity(0.32)
                            .frame(height: 1)
                    }
            }
        }
        .ignoresSafeArea()
    }
}

private struct NativeWindowBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
