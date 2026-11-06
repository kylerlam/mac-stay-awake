import IOKit.pwr_mgt
import XCTest
@testable import MacStayAwake

final class DisplayAwakeServiceTests: XCTestCase {
    func testActivationIsVerifiedIdempotentAndReleased() throws {
        let service = DisplayAwakeService()
        defer { try? service.deactivate() }
        let initialCount = try ownedAssertionCount()

        XCTAssertFalse(service.isActive)
        XCTAssertFalse(try service.currentStatus())

        try service.activate()
        XCTAssertTrue(service.isActive)
        XCTAssertTrue(try service.currentStatus())
        XCTAssertEqual(try ownedAssertionCount(), initialCount + 1)

        try service.activate()
        XCTAssertEqual(try ownedAssertionCount(), initialCount + 1)

        try service.deactivate()
        XCTAssertFalse(service.isActive)
        XCTAssertFalse(try service.currentStatus())
        XCTAssertEqual(try ownedAssertionCount(), initialCount)

        try service.deactivate()
        XCTAssertEqual(try ownedAssertionCount(), initialCount)
    }

    func testDeinitializationReleasesAssertion() throws {
        let initialCount = try ownedAssertionCount()
        var service: DisplayAwakeService? = DisplayAwakeService()
        try service?.activate()
        XCTAssertEqual(try ownedAssertionCount(), initialCount + 1)

        service = nil

        XCTAssertEqual(try ownedAssertionCount(), initialCount)
    }

    private func ownedAssertionCount() throws -> Int {
        var unmanagedAssertions: Unmanaged<CFDictionary>?
        let result = IOPMCopyAssertionsByProcess(&unmanagedAssertions)
        guard result == kIOReturnSuccess,
              let assertions = unmanagedAssertions?.takeRetainedValue() as? [NSNumber: [[String: Any]]]
        else {
            throw AwakeServiceError.statusUnavailable
        }
        let ownedAssertions = assertions[NSNumber(value: ProcessInfo.processInfo.processIdentifier)] ?? []
        return ownedAssertions.filter {
            $0[kIOPMAssertionNameKey] as? String == DisplayAwakeService.assertionName
                && (($0[kIOPMAssertionLevelKey] as? NSNumber)?.uint32Value ?? 0) == kIOPMAssertionLevelOn
        }.count
    }
}
