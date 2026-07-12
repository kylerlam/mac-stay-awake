import Foundation

final class IOKitAwakeService: AwakeService {
    private var active = false

    var isActive: Bool {
        active
    }

    func activate() throws {
        guard !active else { return }
        try setDisableSleep(true)
        active = true
    }

    func deactivate() throws {
        guard active else { return }
        try setDisableSleep(false)
        active = false
    }

    private func setDisableSleep(_ disabled: Bool) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e",
            "do shell script \"/usr/bin/pmset -a disablesleep \(disabled ? 1 : 0)\" with administrator privileges"
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw AwakeServiceError.commandFailed(-1)
        }

        guard process.terminationStatus == 0 else {
            throw AwakeServiceError.commandFailed(process.terminationStatus)
        }
    }
}
