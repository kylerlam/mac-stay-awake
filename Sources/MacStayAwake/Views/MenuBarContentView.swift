import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: AwakeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            statusView

            Button {
                store.toggle()
            } label: {
                Text(store.actionTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(store.isAwake ? .green : .gray)
            .controlSize(.large)
            .accessibilityHint(store.isAwake
                ? "允许 Mac 按系统设置休眠"
                : "防止 Mac 因闲置自动休眠")

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
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
        .frame(width: 320)
    }

    private var statusView: some View {
        HStack(spacing: 12) {
            Image(systemName: store.menuBarIconName)
                .font(.title2)
                .foregroundStyle(store.isAwake ? Color.green : Color.secondary)
                .frame(width: 42, height: 42)
                .background(.quaternary, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(store.statusTitle)
                    .font(.headline)
                    .foregroundStyle(store.isAwake ? Color.green : Color.primary)

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
}
