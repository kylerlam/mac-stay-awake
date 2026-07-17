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

    func testRefreshUsesSystemStatusAsSourceOfTruth() {
        let service = FakeAwakeService()
        service.systemStatus = true
        let store = AwakeStore(service: service)

        store.refreshStatus()

        XCTAssertEqual(store.mode, .awake)
        XCTAssertEqual(service.statusCallCount, 1)
        XCTAssertNotNil(store.lastCheckedAt)
    }

    func testToggleActivatesAndVerifiesThenDeactivatesAndVerifies() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)

        store.toggle()
        XCTAssertEqual(store.mode, .awake)
        XCTAssertEqual(service.activateCallCount, 1)
        XCTAssertEqual(service.statusCallCount, 1)

        store.toggle()
        XCTAssertEqual(store.mode, .normal)
        XCTAssertEqual(service.deactivateCallCount, 1)
        XCTAssertEqual(service.statusCallCount, 2)
    }

    func testRefreshShowsMismatchWhenPreviouslyAwakeButSystemIsDisabled() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)
        store.toggle()
        service.systemStatus = false

        store.refreshStatus()

        XCTAssertEqual(store.mode, .mismatch(expectedAwake: true, actualAwake: false))
        XCTAssertEqual(store.statusTitle, "合盖运行未生效")
        XCTAssertEqual(store.secondaryActionTitle, "使用正常模式")
    }

    func testAcceptDetectedStatusClearsMismatchToNormalMode() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)
        store.toggle()
        service.systemStatus = false
        store.refreshStatus()

        store.acceptDetectedStatus()

        XCTAssertEqual(store.mode, .normal)
        XCTAssertNil(store.errorMessage)
    }

    func testMismatchPrimaryActionRetriesExpectedState() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)
        store.toggle()
        service.systemStatus = false
        store.refreshStatus()

        store.toggle()

        XCTAssertEqual(store.mode, .awake)
        XCTAssertEqual(service.activateCallCount, 2)
    }

    func testStatusFailureShowsUnknownWarning() {
        let service = FakeAwakeService()
        service.statusError = AwakeServiceError.statusUnavailable
        let store = AwakeStore(service: service)

        store.refreshStatus()

        XCTAssertEqual(store.mode, .unknown)
        XCTAssertTrue(store.isWarning)
        XCTAssertEqual(store.errorMessage, "无法读取系统休眠状态，请重新检测。")
    }

    func testFailedActivationShowsMismatchWhenSystemRemainsDisabled() {
        let service = FakeAwakeService()
        service.activationError = AwakeServiceError.commandFailed(-1)
        let store = AwakeStore(service: service)

        store.toggle()

        XCTAssertEqual(store.mode, .mismatch(expectedAwake: true, actualAwake: false))
        XCTAssertEqual(store.errorMessage, "无法开启合盖运行，请重试。")
    }

    func testFailedDeactivationShowsMismatchWhenSystemRemainsEnabled() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)
        store.toggle()
        service.deactivationError = AwakeServiceError.commandFailed(-1)

        store.toggle()

        XCTAssertEqual(store.mode, .mismatch(expectedAwake: false, actualAwake: true))
        XCTAssertEqual(store.errorMessage, "无法恢复正常模式，请重试。")
        XCTAssertEqual(store.secondaryActionTitle, "保持合盖运行")
    }

    func testShutdownReleasesSettingEnabledByThisSession() {
        let service = FakeAwakeService()
        let store = AwakeStore(service: service)
        store.toggle()

        store.shutDown()

        XCTAssertFalse(service.isActive)
        XCTAssertFalse(service.systemStatus)
        XCTAssertEqual(service.deactivateCallCount, 1)
        XCTAssertEqual(store.mode, .normal)
    }
}

private final class FakeAwakeService: AwakeService {
    var isActive = false
    var systemStatus = false
    var statusError: Error?
    var activationError: Error?
    var deactivationError: Error?
    var statusCallCount = 0
    var activateCallCount = 0
    var deactivateCallCount = 0

    func currentStatus() throws -> Bool {
        statusCallCount += 1
        if let statusError {
            throw statusError
        }
        return systemStatus
    }

    func activate() throws {
        activateCallCount += 1
        if let activationError {
            throw activationError
        }
        isActive = true
        systemStatus = true
    }

    func deactivate() throws {
        deactivateCallCount += 1
        if let deactivationError {
            throw deactivationError
        }
        isActive = false
        systemStatus = false
    }
}
