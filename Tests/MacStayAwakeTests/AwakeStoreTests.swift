import XCTest
@testable import MacStayAwake

@MainActor
final class AwakeStoreTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "MacStayAwakeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    private func makeStore(service: FakeAwakeService) -> AwakeStore {
        AwakeStore(service: service, defaults: makeDefaults())
    }

    func testLanguageDefaultsToSimplifiedChineseAndPersistsSelection() {
        let defaults = makeDefaults()
        let store = AwakeStore(service: FakeAwakeService(), defaults: defaults)
        XCTAssertEqual(store.language, .simplifiedChinese)

        store.language = .traditionalChinese
        let reopenedStore = AwakeStore(service: FakeAwakeService(), defaults: defaults)
        XCTAssertEqual(reopenedStore.language, .traditionalChinese)
        XCTAssertEqual(reopenedStore.actionTitle, "開啟闔蓋運行")

        reopenedStore.language = .english
        let nextStore = AwakeStore(service: FakeAwakeService(), defaults: defaults)
        XCTAssertEqual(nextStore.language, .english)
        XCTAssertEqual(nextStore.statusTitle, "Normal Mode")

        defaults.set("unsupported", forKey: "appLanguage")
        XCTAssertEqual(AwakeStore(service: FakeAwakeService(), defaults: defaults).language, .simplifiedChinese)
    }

    func testLanguageChangeUpdatesExistingErrorWithoutCallingService() {
        let service = FakeAwakeService()
        service.activationError = AwakeServiceError.commandFailed(-1)
        let store = makeStore(service: service)
        store.toggle()
        let checkedAt = store.lastCheckedAt
        let statusCalls = service.statusCallCount

        store.language = .english
        XCTAssertEqual(store.statusTitle, "Closed-Lid Mode Not Applied")
        XCTAssertEqual(store.statusDetail, "The system currently allows sleep")
        XCTAssertEqual(store.actionTitle, "Retry Closed-Lid Mode")
        XCTAssertEqual(store.secondaryActionTitle, "Use Normal Mode")
        XCTAssertEqual(store.errorMessage, "Could not enable closed-lid mode. Please try again.")
        XCTAssertEqual(store.protectionStatusTitle, "Off")

        store.language = .traditionalChinese
        XCTAssertEqual(store.statusTitle, "闔蓋運行未生效")
        XCTAssertEqual(store.errorMessage, "無法開啟闔蓋運行，請重試。")

        store.language = .simplifiedChinese
        XCTAssertEqual(store.statusTitle, "合盖运行未生效")
        XCTAssertEqual(store.errorMessage, "无法开启合盖运行，请重试。")
        XCTAssertEqual(store.mode, .mismatch(expectedAwake: true, actualAwake: false))
        XCTAssertEqual(store.lastCheckedAt, checkedAt)
        XCTAssertEqual(service.statusCallCount, statusCalls)
        XCTAssertEqual(service.activateCallCount, 1)
        XCTAssertEqual(service.deactivateCallCount, 0)
    }

    func testLanguageChangeUpdatesUnknownStatusAndUncheckedTime() {
        let service = FakeAwakeService()
        service.statusError = AwakeServiceError.statusUnavailable
        let store = makeStore(service: service)
        store.refreshStatus()

        store.language = .traditionalChinese
        XCTAssertEqual(store.statusTitle, "無法確認系統狀態")
        XCTAssertEqual(store.errorMessage, "無法讀取系統睡眠狀態，請重新檢查。")
        XCTAssertEqual(store.lastCheckedTitle, "尚未檢查")

        store.language = .english
        XCTAssertEqual(store.statusTitle, "System Status Unknown")
        XCTAssertEqual(store.errorMessage, "Could not read the system sleep status. Please check again.")
        XCTAssertEqual(store.lastCheckedTitle, "Not Yet Checked")
        XCTAssertEqual(store.refreshActionTitle, "Check Again")
    }

    func testLastCheckedTimeUsesSelectedLanguage() throws {
        let store = makeStore(service: FakeAwakeService())
        store.refreshStatus()
        let checkedAt = try XCTUnwrap(store.lastCheckedAt)
        // DateFormatter rounds fractional seconds; Date.FormatStyle truncates them.
        let wholeSecond = Date(timeIntervalSinceReferenceDate: floor(checkedAt.timeIntervalSinceReferenceDate))
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium

        for (language, localeID) in [(AppLanguage.simplifiedChinese, "zh_CN"), (.traditionalChinese, "zh_TW"), (.english, "en_US")] {
            store.language = language
            formatter.locale = Locale(identifier: localeID)
            XCTAssertEqual(store.lastCheckedTitle, formatter.string(from: wholeSecond))
        }
    }

    func testStartsInNormalModeWithoutActivatingService() {
        let service = FakeAwakeService()
        let store = makeStore(service: service)

        XCTAssertEqual(store.mode, .normal)
        XCTAssertEqual(service.activateCallCount, 0)
        XCTAssertFalse(service.isActive)
    }

    func testRefreshUsesSystemStatusAsSourceOfTruth() {
        let service = FakeAwakeService()
        service.systemStatus = true
        let store = makeStore(service: service)

        store.refreshStatus()

        XCTAssertEqual(store.mode, .awake)
        XCTAssertEqual(service.statusCallCount, 1)
        XCTAssertNotNil(store.lastCheckedAt)
    }

    func testToggleActivatesAndVerifiesThenDeactivatesAndVerifies() {
        let service = FakeAwakeService()
        let store = makeStore(service: service)

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
        let store = makeStore(service: service)
        store.toggle()
        service.systemStatus = false

        store.refreshStatus()

        XCTAssertEqual(store.mode, .mismatch(expectedAwake: true, actualAwake: false))
        XCTAssertEqual(store.statusTitle, "合盖运行未生效")
        XCTAssertEqual(store.secondaryActionTitle, "使用正常模式")
    }

    func testAcceptDetectedStatusClearsMismatchToNormalMode() {
        let service = FakeAwakeService()
        let store = makeStore(service: service)
        store.toggle()
        service.systemStatus = false
        store.refreshStatus()

        store.acceptDetectedStatus()

        XCTAssertEqual(store.mode, .normal)
        XCTAssertNil(store.errorMessage)
    }

    func testMismatchPrimaryActionRetriesExpectedState() {
        let service = FakeAwakeService()
        let store = makeStore(service: service)
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
        let store = makeStore(service: service)

        store.refreshStatus()

        XCTAssertEqual(store.mode, .unknown)
        XCTAssertTrue(store.isWarning)
        XCTAssertEqual(store.errorMessage, "无法读取系统休眠状态，请重新检测。")
    }

    func testFailedActivationShowsMismatchWhenSystemRemainsDisabled() {
        let service = FakeAwakeService()
        service.activationError = AwakeServiceError.commandFailed(-1)
        let store = makeStore(service: service)

        store.toggle()

        XCTAssertEqual(store.mode, .mismatch(expectedAwake: true, actualAwake: false))
        XCTAssertEqual(store.errorMessage, "无法开启合盖运行，请重试。")
    }

    func testFailedDeactivationShowsMismatchWhenSystemRemainsEnabled() {
        let service = FakeAwakeService()
        let store = makeStore(service: service)
        store.toggle()
        service.deactivationError = AwakeServiceError.commandFailed(-1)

        store.toggle()

        XCTAssertEqual(store.mode, .mismatch(expectedAwake: false, actualAwake: true))
        XCTAssertEqual(store.errorMessage, "无法恢复正常模式，请重试。")
        XCTAssertEqual(store.secondaryActionTitle, "保持合盖运行")
    }

    func testShutdownReleasesSettingEnabledByThisSession() {
        let service = FakeAwakeService()
        let store = makeStore(service: service)
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
