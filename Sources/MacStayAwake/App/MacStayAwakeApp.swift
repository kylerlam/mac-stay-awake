import AppKit
import SwiftUI

@main
struct MacStayAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AwakeStore(service: IOKitAwakeService())

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(store: store)
        } label: {
            Label("Mac Stay Awake", systemImage: store.menuBarIconName)
                .accessibilityLabel(store.menuBarAccessibilityLabel)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

