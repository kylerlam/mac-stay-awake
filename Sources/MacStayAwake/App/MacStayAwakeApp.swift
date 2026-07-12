import AppKit
import SwiftUI

@main
struct MacStayAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = AwakeStore(service: IOKitAwakeService())
    private var statusItem: NSStatusItem?
    private var controlWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.isVisible = true
        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggleControlWindow)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.button?.title = "☕"
        statusItem.button?.toolTip = "Mac Stay Awake"
        statusItem.autosaveName = "MacStayAwakeStatusItem"
        self.statusItem = statusItem

        showControlWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.shutDown()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showControlWindow()
        return true
    }

    @objc private func toggleControlWindow() {
        if controlWindow?.isVisible == true {
            controlWindow?.orderOut(nil)
        } else {
            showControlWindow()
        }
    }

    private func showControlWindow() {
        if controlWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 220),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Mac Stay Awake"
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: MenuBarContentView(store: store))
            window.center()
            controlWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        controlWindow?.makeKeyAndOrderFront(nil)
    }
}
