import AppKit
import SwiftUI

struct ThemeBackground: View {
    let appearance: AppAppearance
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch appearance {
                case .standard:
                    Color(nsColor: .windowBackgroundColor)
                case .frostedGlass:
                    if reduceTransparency {
                        Color(red: 0.86, green: 0.92, blue: 0.97)
                    } else {
                        NativeWindowBlur()
                        LinearGradient(
                            colors: [.white.opacity(0.48), Color(red: 0.77, green: 0.86, blue: 0.98).opacity(0.36)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    Ellipse()
                        .fill(Color(red: 0.37, green: 0.84, blue: 0.86).opacity(0.42))
                        .frame(width: 310, height: 230)
                        .blur(radius: 48)
                        .position(x: 45, y: 65)
                    Ellipse()
                        .fill(Color(red: 0.63, green: 0.62, blue: 0.96).opacity(0.35))
                        .frame(width: 280, height: 320)
                        .blur(radius: 56)
                        .position(x: geometry.size.width, y: geometry.size.height * 0.72)
                case .midnight:
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.14, blue: 0.22), Color(red: 0.055, green: 0.075, blue: 0.13)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(Color(red: 0.28, green: 0.37, blue: 0.70).opacity(0.24))
                        .frame(width: 300, height: 300)
                        .blur(radius: 70)
                        .position(x: geometry.size.width / 2, y: 75)
                case .warmSand:
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.95, blue: 0.87), Color(red: 0.92, green: 0.86, blue: 0.76)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct ThemeSurface: View {
    let appearance: AppAppearance
    var radius: CGFloat = 20
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            if appearance == .frostedGlass && !reduceTransparency {
                shape.fill(.ultraThinMaterial)
            }
            shape.fill(appearance.surface)
            shape.strokeBorder(appearance.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(appearance == .frostedGlass ? 0.07 : 0.025), radius: 16, y: 6)
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

// The NSWindow is owned by AppDelegate, so keep its title bar and native menus
// in sync with the SwiftUI theme through this small view-level bridge.
struct ThemeWindowAppearance: NSViewRepresentable {
    let appearance: AppAppearance

    func makeNSView(context: Context) -> AppearanceView {
        AppearanceView()
    }

    func updateNSView(_ nsView: AppearanceView, context: Context) {
        let name: NSAppearance.Name?
        switch appearance.colorScheme {
        case .dark: name = .darkAqua
        case .light: name = .aqua
        default: name = nil
        }
        nsView.appearanceName = name
        nsView.applyAppearance()
    }

    final class AppearanceView: NSView {
        var appearanceName: NSAppearance.Name?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyAppearance()
        }

        func applyAppearance() {
            guard let window, window.appearance?.name != appearanceName else { return }
            window.appearance = appearanceName.flatMap(NSAppearance.init(named:))
        }
    }
}
