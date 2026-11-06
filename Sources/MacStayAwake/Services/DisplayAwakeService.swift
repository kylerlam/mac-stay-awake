import Foundation
import IOKit.pwr_mgt

final class DisplayAwakeService: AwakeService {
    static let assertionName = "Mac Stay Awake - Prevent Automatic Screen Lock"
    private var assertionID: IOPMAssertionID?

    var isActive: Bool {
        assertionID != nil
    }

    func currentStatus() throws -> Bool {
        guard let assertionID else { return false }
        guard let properties = IOPMAssertionCopyProperties(assertionID)?.takeRetainedValue() else {
            return false
        }
        guard let level = (properties as NSDictionary)[kIOPMAssertionLevelKey] as? NSNumber else {
            throw AwakeServiceError.statusUnavailable
        }
        return level.uint32Value == kIOPMAssertionLevelOn
    }

    func activate() throws {
        guard try !currentStatus() else { return }
        try deactivate()

        var newAssertionID = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            Self.assertionName as CFString,
            &newAssertionID
        )
        guard result == kIOReturnSuccess else {
            throw AwakeServiceError.commandFailed(result)
        }
        assertionID = newAssertionID
    }

    func deactivate() throws {
        guard let assertionID else { return }
        let result = IOPMAssertionRelease(assertionID)
        guard result == kIOReturnSuccess || result == kIOReturnNotFound else {
            throw AwakeServiceError.commandFailed(result)
        }
        self.assertionID = nil
    }

    deinit {
        if let assertionID {
            IOPMAssertionRelease(assertionID)
        }
    }
}
