import SwiftUI

enum AppAppearance: String, CaseIterable {
    case standard
    case frostedGlass
    case midnight
    case warmSand

    var titleKey: AppText {
        switch self {
        case .standard: return .standardAppearance
        case .frostedGlass: return .frostedGlass
        case .midnight: return .midnight
        case .warmSand: return .warmSand
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .standard: return nil
        case .frostedGlass, .warmSand: return .light
        case .midnight: return .dark
        }
    }

    var accent: Color {
        switch self {
        case .standard: return .accentColor
        case .frostedGlass: return Color(red: 0.23, green: 0.36, blue: 0.75)
        case .midnight: return Color(red: 0.67, green: 0.74, blue: 1)
        case .warmSand: return Color(red: 0.48, green: 0.31, blue: 0.21)
        }
    }

    var primaryText: Color {
        switch self {
        case .standard: return .primary
        case .frostedGlass: return Color(red: 0.12, green: 0.20, blue: 0.32)
        case .midnight: return Color(red: 0.93, green: 0.95, blue: 1)
        case .warmSand: return Color(red: 0.27, green: 0.20, blue: 0.15)
        }
    }

    var secondaryText: Color {
        switch self {
        case .standard: return .secondary
        case .frostedGlass: return Color(red: 0.32, green: 0.40, blue: 0.51)
        case .midnight: return Color(red: 0.62, green: 0.68, blue: 0.79)
        case .warmSand: return Color(red: 0.48, green: 0.39, blue: 0.31)
        }
    }

    var surface: Color {
        switch self {
        case .standard: return Color(nsColor: .controlBackgroundColor)
        case .frostedGlass: return .white.opacity(0.34)
        case .midnight: return Color(red: 0.12, green: 0.16, blue: 0.24)
        case .warmSand: return Color(red: 1, green: 0.98, blue: 0.92)
        }
    }

    var border: Color {
        switch self {
        case .standard: return .primary.opacity(0.08)
        case .frostedGlass: return .white.opacity(0.78)
        case .midnight: return .white.opacity(0.12)
        case .warmSand: return Color(red: 0.49, green: 0.36, blue: 0.23).opacity(0.19)
        }
    }

    var success: Color {
        switch self {
        case .standard: return Color(nsColor: .systemGreen)
        case .frostedGlass: return Color(red: 0.10, green: 0.43, blue: 0.31)
        case .midnight: return Color(red: 0.44, green: 0.88, blue: 0.69)
        case .warmSand: return Color(red: 0.25, green: 0.42, blue: 0.29)
        }
    }

    var warning: Color {
        self == .midnight
            ? Color(red: 1, green: 0.74, blue: 0.40)
            : Color(red: 0.66, green: 0.31, blue: 0.04)
    }

    var buttonText: Color {
        self == .midnight ? Color(red: 0.08, green: 0.12, blue: 0.23) : .white
    }

    var swatch: [Color] {
        switch self {
        case .standard: return [Color(white: 0.98), Color(white: 0.68)]
        case .frostedGlass: return [Color(red: 0.57, green: 0.91, blue: 0.91), Color(red: 0.61, green: 0.66, blue: 0.96)]
        case .midnight: return [Color(red: 0.25, green: 0.33, blue: 0.52), Color(red: 0.06, green: 0.09, blue: 0.16)]
        case .warmSand: return [Color(red: 0.97, green: 0.88, blue: 0.70), Color(red: 0.69, green: 0.48, blue: 0.31)]
        }
    }
}
