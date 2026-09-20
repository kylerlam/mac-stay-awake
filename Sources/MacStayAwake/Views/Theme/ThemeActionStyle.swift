import SwiftUI

struct ThemeActionStyle: ButtonStyle {
    let appearance: AppAppearance
    var prominent = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(prominent ? appearance.buttonText : appearance.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, prominent ? 11 : 9)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .background {
                if prominent {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(
                            colors: [appearance.accent, appearance.accent.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                        }
                        .shadow(color: appearance.accent.opacity(0.14), radius: 8, y: 3)
                } else {
                    ThemeSurface(appearance: appearance, radius: 12)
                }
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
