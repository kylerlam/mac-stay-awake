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

    private func makeStore(service: FakeAwakeService, displayService: FakeAwakeService = FakeAwakeService()) -> AwakeStore {
        AwakeStore(service: service, displayService: displayService, defaults: makeDefaults())
    }

    func testLanguageDefaultsToSimplifiedChineseAndPersistsSelection() {
        let defaults = makeDefaults()
        let store = AwakeStore(service: FakeAwakeService(), displayService: FakeAwakeService(), defaults: defaults)
        XCTAssertEqual(store.language, .simplifiedChinese)

        store.language = .traditionalChinese
        let reopenedStore = AwakeStore(service: FakeAwakeService(), displayService: FakeAwakeService(), defaults: defaults)
        XCTAssertEqual(reopenedStore.language, .traditionalChinese)
        XCTAssertEqual(reopenedStore.actionTitle, "開啟闔蓋運行")

        reopenedStore.language = .english
        let nextStore = AwakeStore(service: FakeAwakeService(), displayService: FakeAwakeService(), defaults: defaults)
        XCTAssertEqual(nextStore.language, .english)
        XCTAssertEqual(nextStore.statusTitle, "Normal Mode")

        defaults.set("unsupported", forKey: "appLanguage")
        XCTAssertEqual(AwakeStore(service: FakeAwakeService(), displayService: FakeAwakeService(), defaults: defaults).language, .simplifiedChinese)
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
        let displayService = FakeAwakeService()
        let store = makeStore(service: service, displayService: displayService)

        store.refreshStatus()

        XCTAssertEqual(store.mode, .awake)
        XCTAssertEqual(service.statusCallCount, 1)
        XCTAssertEqual(service.activateCallCount, 0)
        XCTAssertEqual(displayService.activateCallCount, 1)
        XCTAssertEqual(displayService.statusCallCount, 1)
        XCTAssertTrue(store.isAutoLockPrevented)
        XCTAssertFalse(store.isWarning)
        XCTAssertNotNil(store.lastCheckedAt)
    }

    func testToggleActivatesAndVerifiesThenDeactivatesAndVerifies() {
        let service = FakeAwakeService()
        let displayService = FakeAwakeService()
        let store = makeStore(service: service, displayService: displayService)

        store.toggle()
        XCTAssertEqual(store.mode, .awake)
        XCTAssertEqual(service.activateCallCount, 1)
        XCTAssertEqual(service.statusCallCount, 1)
        XCTAssertTrue(store.isAutoLockPrevented)
        XCTAssertEqual(displayService.activateCallCount, 1)
        XCTAssertEqual(displayService.statusCallCount, 1)

        store.toggle()
        XCTAssertEqual(store.mode, .normal)
        XCTAssertEqual(service.deactivateCallCount, 1)
        XCTAssertEqual(service.statusCallCount, 2)
        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertEqual(displayService.deactivateCallCount, 1)
        XCTAssertEqual(displayService.statusCallCount, 2)
    }

    func testRefreshShowsMismatchWhenPreviouslyAwakeButSystemIsDisabled() {
        let service = FakeAwakeService()
        let displayService = FakeAwakeService()
        let store = makeStore(service: service, displayService: displayService)
        store.toggle()
        service.systemStatus = false

        store.refreshStatus()

        XCTAssertEqual(store.mode, .mismatch(expectedAwake: true, actualAwake: false))
        XCTAssertEqual(store.statusTitle, "合盖运行未生效")
        XCTAssertEqual(store.secondaryActionTitle, "使用正常模式")
        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertFalse(displayService.isActive)
        XCTAssertEqual(displayService.deactivateCallCount, 1)
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
        let displayService = FakeAwakeService()
        let store = makeStore(service: service, displayService: displayService)
        store.toggle()
        service.deactivationError = AwakeServiceError.commandFailed(-1)

        store.toggle()

        XCTAssertEqual(store.mode, .mismatch(expectedAwake: false, actualAwake: true))
        XCTAssertEqual(store.errorMessage, "无法恢复正常模式，请重试。")
        XCTAssertEqual(store.secondaryActionTitle, "保持合盖运行")
        XCTAssertTrue(store.isAutoLockPrevented)
        XCTAssertTrue(displayService.isActive)
        XCTAssertEqual(displayService.deactivateCallCount, 0)
    }

    func testShutdownReleasesSettingEnabledByThisSession() {
        let service = FakeAwakeService()
        let displayService = FakeAwakeService()
        let store = makeStore(service: service, displayService: displayService)
        store.toggle()

        store.shutDown()

        XCTAssertFalse(service.isActive)
        XCTAssertFalse(service.systemStatus)
        XCTAssertEqual(service.deactivateCallCount, 1)
        XCTAssertEqual(store.mode, .normal)
        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertFalse(displayService.isActive)
        XCTAssertEqual(displayService.deactivateCallCount, 1)
    }

    func testShutdownReleasesDisplayWithoutChangingInheritedSleepPrevention() {
        let service = FakeAwakeService()
        service.systemStatus = true
        let displayService = FakeAwakeService()
        let store = makeStore(service: service, displayService: displayService)
        store.refreshStatus()

        store.shutDown()

        XCTAssertTrue(service.systemStatus)
        XCTAssertEqual(service.activateCallCount, 0)
        XCTAssertEqual(service.deactivateCallCount, 0)
        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertFalse(displayService.isActive)
        XCTAssertEqual(displayService.deactivateCallCount, 1)
    }

    func testDisplayActivationFailureShowsWarningAndRefreshCanRecover() {
        let service = FakeAwakeService()
        let displayService = FakeAwakeService()
        displayService.activationError = AwakeServiceError.commandFailed(-1)
        let store = makeStore(service: service, displayService: displayService)

        store.toggle()

        XCTAssertEqual(store.mode, .awake)
        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertTrue(store.isWarning)
        XCTAssertEqual(store.errorMessage, "无法确认防自动锁屏状态，请重新检测。")

        displayService.activationError = nil
        store.refreshStatus()

        XCTAssertTrue(store.isAutoLockPrevented)
        XCTAssertFalse(store.isWarning)
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(service.activateCallCount, 1)
    }

    func testDisplayActivationRequiresVerifiedStatus() {
        let displayService = FakeAwakeService()
        displayService.activationApplies = false
        let store = makeStore(service: FakeAwakeService(), displayService: displayService)

        store.toggle()

        XCTAssertEqual(store.mode, .awake)
        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertTrue(store.isWarning)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertEqual(displayService.statusCallCount, 1)
    }

    func testDisplayStatusReadFailureShowsWarning() {
        let displayService = FakeAwakeService()
        displayService.statusError = AwakeServiceError.statusUnavailable
        let store = makeStore(service: FakeAwakeService(), displayService: displayService)

        store.toggle()

        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertTrue(store.isWarning)
        XCTAssertNotNil(store.errorMessage)
    }

    func testSleepStatusReadFailureStillRefreshesDisplayStatus() {
        let service = FakeAwakeService()
        let displayService = FakeAwakeService()
        let store = makeStore(service: service, displayService: displayService)
        store.toggle()
        displayService.systemStatus = false
        service.statusError = AwakeServiceError.statusUnavailable

        store.refreshStatus()

        XCTAssertEqual(store.mode, .unknown)
        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertTrue(store.isWarning)
    }

    func testDisplayDeactivationFailureKeepsVerifiedOnStateAndWarns() {
        let displayService = FakeAwakeService()
        let store = makeStore(service: FakeAwakeService(), displayService: displayService)
        store.toggle()
        displayService.deactivationError = AwakeServiceError.commandFailed(-1)

        store.toggle()

        XCTAssertEqual(store.mode, .normal)
        XCTAssertTrue(store.isAutoLockPrevented)
        XCTAssertTrue(displayService.isActive)
        XCTAssertTrue(store.isWarning)
        XCTAssertEqual(store.errorMessage, "无法确认防自动锁屏状态，请重新检测。")

        displayService.deactivationError = nil
        store.refreshStatus()

        XCTAssertFalse(store.isAutoLockPrevented)
        XCTAssertFalse(store.isWarning)
        XCTAssertNil(store.errorMessage)
    }

    func testDisplayDeactivationRequiresVerifiedStatus() {
        let displayService = FakeAwakeService()
        let store = makeStore(service: FakeAwakeService(), displayService: displayService)
        store.toggle()
        displayService.deactivationApplies = false

        store.toggle()

        XCTAssertEqual(store.mode, .normal)
        XCTAssertTrue(store.isAutoLockPrevented)
        XCTAssertTrue(store.isWarning)
        XCTAssertNotNil(store.errorMessage)
    }

    func testAutoLockStatusAndFailureUseSelectedLanguage() {
        let displayService = FakeAwakeService()
        let store = makeStore(service: FakeAwakeService(), displayService: displayService)
        store.refreshStatus()

        for (language, off, on, error) in [
            (AppLanguage.simplifiedChinese, "未开启", "已开启", "无法确认防自动锁屏状态，请重新检测。"),
            (.traditionalChinese, "未開啟", "已開啟", "無法確認防自動鎖屏狀態，請重新檢查。"),
            (.english, "Off", "On", "Could not confirm automatic screen lock prevention. Please check again.")
        ] {
            store.language = language
            XCTAssertEqual(store.autoLockStatusTitle, off)
            store.toggle()
            XCTAssertEqual(store.autoLockStatusTitle, on)
            store.toggle()
            displayService.activationError = AwakeServiceError.commandFailed(-1)
            store.toggle()
            XCTAssertEqual(store.autoLockStatusTitle, off)
            XCTAssertEqual(store.errorMessage, error)
            displayService.activationError = nil
            store.toggle()
        }
    }
}

private final class FakeAwakeService: AwakeService {
    var isActive = false
    var systemStatus = false
    var statusError: Error?
    var activationError: Error?
    var deactivationError: Error?
    var activationApplies = true
    var deactivationApplies = true
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
        guard activationApplies else { return }
        isActive = true
        systemStatus = true
    }

    func deactivate() throws {
        deactivateCallCount += 1
        if let deactivationError {
            throw deactivationError
        }
        guard deactivationApplies else { return }
        isActive = false
        systemStatus = false
    }
}
