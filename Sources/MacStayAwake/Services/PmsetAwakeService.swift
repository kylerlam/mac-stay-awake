import Foundation

final class PmsetAwakeService: AwakeService {
    private var active = false

    var isActive: Bool {
        active
    }

    func currentStatus() throws -> Bool {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        process.standardOutput = output
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

        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else {
            throw AwakeServiceError.statusUnavailable
        }

        for line in text.split(separator: "\n") {
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            guard fields.first == "SleepDisabled", fields.count >= 2 else { continue }

            if fields[1] == "1" { return true }
            if fields[1] == "0" { return false }
        }

        throw AwakeServiceError.statusUnavailable
    }

    func activate() throws {
        try setDisableSleep(true)
        active = true
    }

    func deactivate() throws {
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
