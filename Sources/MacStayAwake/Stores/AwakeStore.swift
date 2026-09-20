import Combine
import Foundation

@MainActor
final class AwakeStore: ObservableObject {
    @Published private(set) var mode: AwakeMode = .normal
    @Published private var errorMessageKey: AppText?
    @Published private(set) var isChecking = false
    @Published private(set) var lastCheckedAt: Date?
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: "appLanguage") }
    }

    private let service: AwakeService
    private let defaults: UserDefaults

    init(service: AwakeService, defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
        self.language = defaults.string(forKey: "appLanguage")
            .flatMap(AppLanguage.init(rawValue:)) ?? .simplifiedChinese
    }

    func text(_ key: AppText) -> String {
        language.text(key)
    }

    var errorMessage: String? {
        errorMessageKey.map { text($0) }
    }

    var isAwake: Bool {
        mode == .awake
    }

    var isWarning: Bool {
        switch mode {
        case .mismatch, .unknown:
            return true
        case .normal, .awake:
            return false
        }
    }

    var statusTitle: String {
        switch mode {
        case .normal:
            return text(.normalMode)
        case .awake:
            return text(.awakeMode)
        case .mismatch(let expectedAwake, _):
            return text(expectedAwake ? .awakeNotApplied : .normalNotRestored)
        case .unknown:
            return text(.statusUnknown)
        }
    }

    var statusDetail: String {
        switch mode {
        case .normal:
            return text(.normalDetail)
        case .awake:
            return text(.awakeDetail)
        case .mismatch(_, let actualAwake):
            return text(actualAwake ? .stillPreventingSleep : .sleepAllowed)
        case .unknown:
            return text(.unknownDetail)
        }
    }

    var actionTitle: String {
        switch mode {
        case .normal:
            return text(.enableAwake)
        case .awake:
            return text(.restoreNormal)
        case .mismatch(let expectedAwake, _):
            return text(expectedAwake ? .retryAwake : .retryNormal)
        case .unknown:
            return text(.refresh)
        }
    }

    var menuBarIconName: String {
        switch mode {
        case .normal:
            return "cup.and.saucer"
        case .awake:
            return "cup.and.saucer.fill"
        case .mismatch, .unknown:
            return "exclamationmark.triangle.fill"
        }
    }

    var menuBarAccessibilityLabel: String {
        "Mac Stay Awake, \(statusTitle)"
    }

    var protectionStatusTitle: String {
        switch mode {
        case .normal:
            return text(.disabled)
        case .awake:
            return text(.enabled)
        case .mismatch(_, let actualAwake):
            return text(actualAwake ? .enabled : .disabled)
        case .unknown:
            return text(.unconfirmed)
        }
    }

    var lastCheckedTitle: String {
        lastCheckedAt?.formatted(
            Date.FormatStyle(date: .omitted, time: .standard).locale(language.locale)
        ) ?? text(.notChecked)
    }

    var secondaryActionTitle: String? {
        guard case .mismatch(_, let actualAwake) = mode else { return nil }
        return text(actualAwake ? .keepAwake : .useNormal)
    }

    var refreshActionTitle: String {
        text(isChecking ? .checking : .refresh)
    }

    func toggle() {
        if mode == .unknown {
            refreshStatus()
            return
        }

        let expectedAwake: Bool
        switch mode {
        case .normal:
            expectedAwake = true
        case .awake:
            expectedAwake = false
        case .mismatch(let expected, _):
            expectedAwake = expected
        case .unknown:
            return
        }

        apply(expectedAwake: expectedAwake)
    }

    func refreshStatus() {
        guard !isChecking else { return }

        let previousMode = mode
        errorMessageKey = nil
        isChecking = true
        defer { isChecking = false }

        do {
            let actualAwake = try service.currentStatus()
            lastCheckedAt = Date()

            switch previousMode {
            case .awake where !actualAwake:
                mode = .mismatch(expectedAwake: true, actualAwake: false)
            case .mismatch(let expectedAwake, _) where expectedAwake != actualAwake:
                mode = .mismatch(expectedAwake: expectedAwake, actualAwake: actualAwake)
            default:
                mode = actualAwake ? .awake : .normal
            }
        } catch {
            mode = .unknown
            errorMessageKey = .readStatusFailed
        }
    }

    func acceptDetectedStatus() {
        guard case .mismatch(_, let actualAwake) = mode else { return }
        mode = actualAwake ? .awake : .normal
        errorMessageKey = nil
    }

    func shutDown() {
        guard service.isActive else { return }

        do {
            try service.deactivate()
        } catch {
            // Preserve the system value when the privileged reset command fails.
        }
        mode = .normal
    }

    private func apply(expectedAwake: Bool) {
        guard !isChecking else { return }

        errorMessageKey = nil
        isChecking = true
        defer { isChecking = false }

        do {
            if expectedAwake {
                try service.activate()
            } else {
                try service.deactivate()
            }

            let actualAwake = try service.currentStatus()
            lastCheckedAt = Date()
            mode = actualAwake == expectedAwake
                ? (actualAwake ? .awake : .normal)
                : .mismatch(expectedAwake: expectedAwake, actualAwake: actualAwake)
        } catch {
            reconcileAfterFailure(expectedAwake: expectedAwake)
        }
    }

    private func reconcileAfterFailure(expectedAwake: Bool) {
        do {
            let actualAwake = try service.currentStatus()
            lastCheckedAt = Date()

            if actualAwake == expectedAwake {
                mode = actualAwake ? .awake : .normal
            } else {
                mode = .mismatch(expectedAwake: expectedAwake, actualAwake: actualAwake)
                errorMessageKey = expectedAwake ? .enableFailed : .restoreFailed
            }
        } catch {
            mode = .unknown
            errorMessageKey = .confirmStatusFailed
        }
    }
}
