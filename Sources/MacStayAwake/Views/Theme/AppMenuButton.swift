import AppKit
import SwiftUI

// Native attributed menu titles keep the color preview after the name while
// retaining AppKit's checkmarks, keyboard navigation, and menu-item actions.
struct AppMenuButton: NSViewRepresentable {
    @ObservedObject var store: AwakeStore
    @Binding var appearanceValue: String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: true)
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.preferredEdge = .minY
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        if coordinator.renderedAppearance != appearanceValue || coordinator.renderedLanguage != store.language {
            button.menu = coordinator.makeMenu()
            coordinator.renderedAppearance = appearanceValue
            coordinator.renderedLanguage = store.language
        }
        let appearance = AppAppearance(rawValue: appearanceValue) ?? .standard
        button.contentTintColor = NSColor(appearance.primaryText)
        button.setAccessibilityLabel(store.text(.appMenu))
        button.toolTip = store.text(.appMenu)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: AppMenuButton
        var renderedAppearance: String?
        var renderedLanguage: AppLanguage?

        init(parent: AppMenuButton) {
            self.parent = parent
        }

        func makeMenu() -> NSMenu {
            let menu = NSMenu()
            let buttonItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            buttonItem.image = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: nil)
            menu.addItem(buttonItem)
            let appearanceMenu = NSMenu(title: parent.store.text(.appearance))
            let font = NSFont.menuFont(ofSize: 0)
            let titleWidth = AppAppearance.allCases.map {
                (parent.store.text($0.titleKey) as NSString).size(withAttributes: [.font: font]).width
            }.max() ?? 0

            for option in AppAppearance.allCases {
                let title = parent.store.text(option.titleKey)
                let item = NSMenuItem(title: title, action: #selector(selectAppearance(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = option.rawValue
                item.state = parent.appearanceValue == option.rawValue ? .on : .off

                let paragraph = NSMutableParagraphStyle()
                paragraph.tabStops = [NSTextTab(textAlignment: .right, location: ceil(titleWidth) + 36)]
                let label = NSMutableAttributedString(
                    string: title + "\t",
                    attributes: [.font: font, .paragraphStyle: paragraph]
                )
                let attachment = NSTextAttachment()
                attachment.image = swatchImage(for: option)
                attachment.bounds = NSRect(x: 0, y: -3, width: 17, height: 17)
                label.append(NSAttributedString(attachment: attachment))
                item.attributedTitle = label
                item.setAccessibilityLabel(title)
                appearanceMenu.addItem(item)
            }

            let appearanceItem = NSMenuItem(title: appearanceMenu.title, action: nil, keyEquivalent: "")
            appearanceItem.image = NSImage(systemSymbolName: "paintbrush", accessibilityDescription: nil)
            appearanceItem.submenu = appearanceMenu
            menu.addItem(appearanceItem)

            let languageMenu = NSMenu(title: parent.store.text(.switchLanguage))
            for language in AppLanguage.allCases {
                let item = NSMenuItem(title: language.nativeName, action: #selector(selectLanguage(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = language.rawValue
                item.state = parent.store.language == language ? .on : .off
                languageMenu.addItem(item)
            }
            let languageItem = NSMenuItem(title: languageMenu.title, action: nil, keyEquivalent: "")
            languageItem.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
            languageItem.submenu = languageMenu
            menu.addItem(languageItem)
            menu.addItem(.separator())

            let quitItem = NSMenuItem(title: parent.store.text(.quit), action: #selector(quit), keyEquivalent: "q")
            quitItem.target = self
            quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
            menu.addItem(quitItem)
            return menu
        }

        @objc private func selectAppearance(_ item: NSMenuItem) {
            guard let rawValue = item.representedObject as? String,
                  let appearance = AppAppearance(rawValue: rawValue) else { return }
            parent.appearanceValue = appearance.rawValue
        }

        @objc private func selectLanguage(_ item: NSMenuItem) {
            guard let rawValue = item.representedObject as? String,
                  let language = AppLanguage(rawValue: rawValue) else { return }
            parent.store.language = language
        }

        @objc private func quit() {
            parent.store.shutDown()
            NSApplication.shared.terminate(nil)
        }

        private func swatchImage(for appearance: AppAppearance) -> NSImage? {
            let swatch = Circle()
                .fill(LinearGradient(colors: appearance.swatch, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { Circle().strokeBorder(.black.opacity(0.16), lineWidth: 0.5) }
                .frame(width: 17, height: 17)
            let renderer = ImageRenderer(content: swatch)
            renderer.scale = 2
            return renderer.nsImage
        }
    }
}
