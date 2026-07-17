import AppKit
import Combine
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: AwakeStore
    private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
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
                ? "允许 Mac 按系统设置休眠"
                : "开启合盖运行模式")

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

            Text("每 5 秒自动检测 · 仅窗口打开时")
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

                Button("退出") {
                    store.shutDown()
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
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

    private var statusView: some View {
        HStack(spacing: 12) {
            Image(systemName: store.menuBarIconName)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 42, height: 42)
                .background(.quaternary, in: Circle())
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
        .accessibilityLabel("当前状态")
        .accessibilityValue(store.statusTitle)
    }

    private var systemStatusView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("防止系统休眠")
                Spacer()
                Text(store.protectionStatusTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
            }

            Divider()

            HStack {
                Text("最后检测")
                Spacer()
                Text(store.lastCheckedTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("系统实际状态")
        .accessibilityValue("防止系统休眠\(store.protectionStatusTitle)，最后检测\(store.lastCheckedTitle)")
    }

    private var statusColor: Color {
        if store.isWarning { return .orange }
        return store.isAwake ? .green : .secondary
    }
}
