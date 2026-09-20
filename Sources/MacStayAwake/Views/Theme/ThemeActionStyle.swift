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
            .padding(.vertical, prominent ? 14 : 11)
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .background {
                if prominent {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(
                            colors: [appearance.accent, appearance.accent.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                        }
                        .shadow(color: appearance.accent.opacity(0.18), radius: 12, y: 5)
                } else {
                    ThemeSurface(appearance: appearance, radius: 14)
                }
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
