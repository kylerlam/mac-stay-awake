import Combine

@MainActor
final class AwakeStore: ObservableObject {
    @Published private(set) var mode: AwakeMode = .normal
    @Published private(set) var errorMessage: String?

    private let service: AwakeService

    init(service: AwakeService) {
        self.service = service
    }

    var isAwake: Bool {
        mode == .awake
    }

    var statusTitle: String {
        isAwake ? "正在保持唤醒" : "正常模式"
    }

    var statusDetail: String {
        isAwake ? "锁屏后后台任务仍可继续运行" : "Mac 会遵循系统休眠设置"
    }

    var actionTitle: String {
        isAwake ? "恢复正常模式" : "保持唤醒"
    }

    var menuBarIconName: String {
        isAwake ? "cup.and.saucer.fill" : "cup.and.saucer"
    }

    var menuBarAccessibilityLabel: String {
        "Mac Stay Awake，\(statusTitle)"
    }

    func toggle() {
        errorMessage = nil
        let wasAwake = isAwake

        do {
            if wasAwake {
                try service.deactivate()
                mode = .normal
            } else {
                try service.activate()
                mode = .awake
            }
        } catch {
            mode = service.isActive ? .awake : .normal
            errorMessage = wasAwake
                ? "无法恢复正常模式，请重试。"
                : "无法开启保持唤醒，请重试。"
        }
    }

    func shutDown() {
        guard service.isActive else { return }

        do {
            try service.deactivate()
        } catch {
            // The process exit still causes macOS to release its assertion.
        }
        mode = .normal
    }
}
