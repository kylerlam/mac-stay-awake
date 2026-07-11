import XCTest
@testable import MacStayAwake

@MainActor
final class AwakeStoreTests: XCTestCase {
    func testStartsInNormalModeWithoutActivatingService() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)

        XCTAssertEqual(store.mode, .normal)
        XCTAssertEqual(service.activateCallCount, 0)
        XCTAssertFalse(service.isActive)
    }

    func testToggleActivatesAndThenDeactivatesService() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)

        store.toggle()
        XCTAssertEqual(store.mode, .awake)
        XCTAssertEqual(service.activateCallCount, 1)

        store.toggle()
        XCTAssertEqual(store.mode, .normal)
        XCTAssertEqual(service.deactivateCallCount, 1)
    }

    func testFailedActivationKeepsNormalModeAndShowsError() {
        let service = FakeAwakeService()
        service.activationError = AwakeServiceError.assertionCreationFailed(-1)
        let store = AwakeStore(service: service)

        store.toggle()

        XCTAssertEqual(store.mode, .normal)
        XCTAssertNotNil(store.errorMessage)
    }

    func testShutdownReleasesActiveService() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)
        store.toggle()

        store.shutDown()

        XCTAssertFalse(service.isActive)
        XCTAssertEqual(service.deactivateCallCount, 1)
        XCTAssertEqual(store.mode, .normal)
    }

    func testFailedDeactivationReturnsToServiceStateAndShowsRestoreError() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)
        store.toggle()
        service.deactivationError = AwakeServiceError.assertionReleaseFailed(-1)

        store.toggle()

        XCTAssertEqual(store.mode, .normal)
        XCTAssertEqual(store.errorMessage, "无法恢复正常模式，请重试。")
    }
}

private final class FakeAwakeService: AwakeService {
    var isActive = false
    var activationError: Error?
    var deactivationError: Error?
    var activateCallCount = 0
    var deactivateCallCount = 0

    func activate() throws {
        activateCallCount += 1
        if let activationError {
            throw activationError
        }
        isActive = true
    }

    func deactivate() throws {
        deactivateCallCount += 1
        isActive = false
        if let deactivationError {
            throw deactivationError
        }
    }
}
