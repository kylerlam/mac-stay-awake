import Combine
import Foundation

@MainActor
final class AwakeStore: ObservableObject {
    @Published private(set) var mode: AwakeMode = .normal
    @Published private(set) var errorMessage: String?
    @Published private(set) var isChecking = false
    @Published private(set) var lastCheckedAt: Date?

    private let service: AwakeService

    init(service: AwakeService) {
        self.service = service
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
            return "正常模式"
        case .awake:
            return "合盖运行模式"
        case .mismatch(let expectedAwake, _):
            return expectedAwake ? "合盖运行未生效" : "未能恢复正常模式"
        case .unknown:
            return "无法确认系统状态"
        }
    }

    var statusDetail: String {
        switch mode {
        case .normal:
            return "Mac 会遵循系统休眠设置"
        case .awake:
            return "系统实际状态已确认"
        case .mismatch(_, let actualAwake):
            return actualAwake ? "系统仍在阻止休眠" : "系统当前允许休眠"
        case .unknown:
            return "请重新检测后再决定是否合盖"
        }
    }

    var actionTitle: String {
        switch mode {
        case .normal:
            return "开启合盖运行"
        case .awake:
            return "恢复正常模式"
        case .mismatch(let expectedAwake, _):
            return expectedAwake ? "重新开启合盖运行" : "重新恢复正常模式"
        case .unknown:
            return "重新检测"
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
        "Mac Stay Awake，\(statusTitle)"
    }

    var protectionStatusTitle: String {
        switch mode {
        case .normal:
            return "未开启"
        case .awake:
            return "已开启"
        case .mismatch(_, let actualAwake):
            return actualAwake ? "已开启" : "未开启"
        case .unknown:
            return "无法确认"
        }
    }

    var lastCheckedTitle: String {
        lastCheckedAt?.formatted(date: .omitted, time: .standard) ?? "尚未检测"
    }

    var secondaryActionTitle: String? {
        guard case .mismatch(_, let actualAwake) = mode else { return nil }
        return actualAwake ? "保持合盖运行" : "使用正常模式"
    }

    var refreshActionTitle: String {
        isChecking ? "正在检测…" : "重新检测"
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
        errorMessage = nil
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
            errorMessage = "无法读取系统休眠状态，请重新检测。"
        }
    }

    func acceptDetectedStatus() {
        guard case .mismatch(_, let actualAwake) = mode else { return }
        mode = actualAwake ? .awake : .normal
        errorMessage = nil
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

        errorMessage = nil
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
                errorMessage = expectedAwake
                    ? "无法开启合盖运行，请重试。"
                    : "无法恢复正常模式，请重试。"
            }
        } catch {
            mode = .unknown
            errorMessage = "无法确认系统状态，请重新检测。"
        }
    }
}
