import Foundation
import IOKit.pwr_mgt

final class IOKitAwakeService: AwakeService {
    private var assertionID: IOPMAssertionID?

    var isActive: Bool {
        assertionID != nil
    }

    func activate() throws {
        guard assertionID == nil else { return }

        var newAssertionID = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Mac Stay Awake is keeping background tasks running" as CFString,
            &newAssertionID
        )

        guard result == kIOReturnSuccess else {
            throw AwakeServiceError.assertionCreationFailed(result)
        }

        assertionID = newAssertionID
    }

    func deactivate() throws {
        guard let assertionID else { return }

        let result = IOPMAssertionRelease(assertionID)
        self.assertionID = nil

        guard result == kIOReturnSuccess else {
            throw AwakeServiceError.assertionReleaseFailed(result)
        }
    }

    deinit {
        if let assertionID {
            IOPMAssertionRelease(assertionID)
        }
    }
}

