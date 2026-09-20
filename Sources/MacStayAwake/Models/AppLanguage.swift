import Foundation

enum AppLanguage: String, CaseIterable {
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case english = "en"

    var nativeName: String {
        switch self {
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .english: return "English"
        }
    }

    var locale: Locale {
        switch self {
        case .simplifiedChinese: return Locale(identifier: "zh_CN")
        case .traditionalChinese: return Locale(identifier: "zh_TW")
        case .english: return Locale(identifier: "en_US")
        }
    }

    func text(_ key: AppText) -> String {
        let translations: (simplified: String, traditional: String, english: String)
        switch key {
        case .normalMode:
            translations = ("正常模式", "正常模式", "Normal Mode")
        case .awakeMode:
            translations = ("合盖运行模式", "闔蓋運行模式", "Closed-Lid Mode")
        case .awakeNotApplied:
            translations = ("合盖运行未生效", "闔蓋運行未生效", "Closed-Lid Mode Not Applied")
        case .normalNotRestored:
            translations = ("未能恢复正常模式", "未能恢復正常模式", "Could Not Restore Normal Mode")
        case .statusUnknown:
            translations = ("无法确认系统状态", "無法確認系統狀態", "System Status Unknown")
        case .normalDetail:
            translations = ("Mac 会遵循系统休眠设置", "Mac 會遵循系統睡眠設定", "Mac follows system sleep settings")
        case .awakeDetail:
            translations = ("系统实际状态已确认", "系統實際狀態已確認", "System status confirmed")
        case .stillPreventingSleep:
            translations = ("系统仍在阻止休眠", "系統仍在阻止睡眠", "The system is still preventing sleep")
        case .sleepAllowed:
            translations = ("系统当前允许休眠", "系統目前允許睡眠", "The system currently allows sleep")
        case .unknownDetail:
            translations = ("请重新检测后再决定是否合盖", "請重新檢查後再決定是否闔蓋", "Check again before closing the lid")
        case .enableAwake:
            translations = ("开启合盖运行", "開啟闔蓋運行", "Enable Closed-Lid Mode")
        case .restoreNormal:
            translations = ("恢复正常模式", "恢復正常模式", "Restore Normal Mode")
        case .retryAwake:
            translations = ("重新开启合盖运行", "重新開啟闔蓋運行", "Retry Closed-Lid Mode")
        case .retryNormal:
            translations = ("重新恢复正常模式", "重新恢復正常模式", "Retry Restoring Normal Mode")
        case .refresh:
            translations = ("重新检测", "重新檢查", "Check Again")
        case .checking:
            translations = ("正在检测…", "正在檢查…", "Checking…")
        case .enabled:
            translations = ("已开启", "已開啟", "On")
        case .disabled:
            translations = ("未开启", "未開啟", "Off")
        case .unconfirmed:
            translations = ("无法确认", "無法確認", "Unknown")
        case .notChecked:
            translations = ("尚未检测", "尚未檢查", "Not Yet Checked")
        case .keepAwake:
            translations = ("保持合盖运行", "保持闔蓋運行", "Keep Closed-Lid Mode")
        case .useNormal:
            translations = ("使用正常模式", "使用正常模式", "Use Normal Mode")
        case .readStatusFailed:
            translations = ("无法读取系统休眠状态，请重新检测。", "無法讀取系統睡眠狀態，請重新檢查。", "Could not read the system sleep status. Please check again.")
        case .enableFailed:
            translations = ("无法开启合盖运行，请重试。", "無法開啟闔蓋運行，請重試。", "Could not enable closed-lid mode. Please try again.")
        case .restoreFailed:
            translations = ("无法恢复正常模式，请重试。", "無法恢復正常模式，請重試。", "Could not restore normal mode. Please try again.")
        case .confirmStatusFailed:
            translations = ("无法确认系统状态，请重新检测。", "無法確認系統狀態，請重新檢查。", "Could not confirm the system status. Please check again.")
        case .allowSleepHint:
            translations = ("允许 Mac 按系统设置休眠", "允許 Mac 按系統設定睡眠", "Allow Mac to sleep according to system settings")
        case .enableAwakeHint:
            translations = ("开启合盖运行模式", "開啟闔蓋運行模式", "Enable closed-lid mode")
        case .autoCheck:
            translations = ("每 5 秒自动检测 · 仅窗口打开时", "每 5 秒自動檢查 · 僅視窗開啟時", "Checks every 5 seconds · While this window is open")
        case .standardAppearance:
            translations = ("默认", "預設", "Default")
        case .frostedGlass:
            translations = ("极光磨砂", "極光磨砂", "Aurora Glass")
        case .midnight:
            translations = ("午夜蓝", "午夜藍", "Midnight Blue")
        case .warmSand:
            translations = ("暖砂", "暖砂", "Warm Sand")
        case .appearance:
            translations = ("外观", "外觀", "Appearance")
        case .switchLanguage:
            translations = ("切换语言/Switch Language", "切換語言/Switch Language", "Switch Language")
        case .quit:
            translations = ("退出", "結束", "Quit")
        case .appMenu:
            translations = ("应用菜单", "應用程式選單", "App Menu")
        case .currentStatus:
            translations = ("当前状态", "目前狀態", "Current Status")
        case .preventSystemSleep:
            translations = ("防止系统休眠", "防止系統睡眠", "Prevent System Sleep")
        case .lastChecked:
            translations = ("最后检测", "上次檢查", "Last Checked")
        case .actualSystemStatus:
            translations = ("系统实际状态", "系統實際狀態", "Actual System Status")
        }

        switch self {
        case .simplifiedChinese: return translations.simplified
        case .traditionalChinese: return translations.traditional
        case .english: return translations.english
        }
    }
}

enum AppText {
    case normalMode, awakeMode, awakeNotApplied, normalNotRestored, statusUnknown
    case normalDetail, awakeDetail, stillPreventingSleep, sleepAllowed, unknownDetail
    case enableAwake, restoreNormal, retryAwake, retryNormal, refresh, checking
    case enabled, disabled, unconfirmed, notChecked, keepAwake, useNormal
    case readStatusFailed, enableFailed, restoreFailed, confirmStatusFailed
    case allowSleepHint, enableAwakeHint, autoCheck
    case standardAppearance, frostedGlass, midnight, warmSand, appearance, switchLanguage, quit, appMenu
    case currentStatus, preventSystemSleep, lastChecked, actualSystemStatus
}
