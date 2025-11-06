//
//  SettingsManager.swift
//  FocusFlow
//
//  设置管理器
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - 声音设置
    @Published var soundEnabled: Bool = true
    @Published var soundVolume: Double = 1.0
    @Published var selectedStartSound: String = "default"
    @Published var selectedPauseSound: String = "default"
    @Published var selectedCompleteSound: String = "default"
    @Published var selectedBreakCompleteSound: String = "default" // 休息完成声音
    
    // MARK: - 通知设置
    @Published var notificationsEnabled: Bool = true
    @Published var focusStartNotification: Bool = true
    @Published var focusPauseNotification: Bool = true
    @Published var focusCompleteNotification: Bool = true
    @Published var achievementNotification: Bool = true
    @Published var dailySummaryNotification: Bool = true
    @Published var weeklySummaryNotification: Bool = true
    @Published var smartReminderNotification: Bool = true
    
    // MARK: - 专注设置
    @Published var focusDndEnabled: Bool = false // 专注时自动启用勿扰模式（默认关闭，不可用）
    @Published var breakDuration: Int = 10 // 休息时长（分钟），默认10分钟
    @Published var autoStartAfterBreak: Bool = true // 休息结束后自动开始新一轮专注（默认开启）
    @Published var whiteNoiseEnabled: Bool = false // 专注时播放白噪音（默认关闭）
    @Published var selectedWhiteNoise: String = "none" // 选中的白噪音类型
    @Published var whiteNoiseVolume: Float = 0.5 // 白噪音音量（0.0-1.0），默认50%
    @Published var liveActivityEnabled: Bool = true // 锁屏和灵动岛专注（默认开启）
    
    // MARK: - 专注锁定模式设置
    // [已注释] 由于iOS系统限制，应用屏蔽功能暂时禁用
    @Published var focusLockEnabled: Bool = false // 是否启用专注锁定模式（已禁用）
    @Published var lockStrength: LockStrength = .hard // 锁定强度（只有硬锁定）（已禁用）
    @Published var blockedApps: [String] = [] // 屏蔽的应用列表（应用bundle ID或显示名称）（已禁用）
    @Published var blockAllAppsExceptSystem: Bool = false // 屏蔽所有应用（除了系统应用）（已禁用）
    
    // MARK: - 可用提示音
    let availableSounds: [(id: String, name: String)] = [
        ("default", "默认"),
        ("boop", "Boop"),
        ("breeze", "Breeze"),
        ("bubble", "Bubble"),
        ("crystal", "Crystal"),
        ("funky", "Funky"),
        ("heroine", "Heroine"),
        ("jump", "Jump"),
        ("mezzo", "Mezzo"),
        ("pebble", "Pebble"),
        ("pluck", "Pluck"),
        ("pong", "Pong"),
        ("sonar", "Sonar"),
        ("sonumi", "Sonumi"),
        ("submerge", "Submerge"),
        ("bell", "钟声"),
        ("chime", "铃声"),
        ("success", "成功"),
        ("complete", "完成")
    ]
    
    private init() {
        loadSettings()
    }
    
    // MARK: - 设置持久化
    private func loadSettings() {
        // 从UserDefaults加载设置
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        soundVolume = UserDefaults.standard.double(forKey: "soundVolume")
        if soundVolume == 0 {
            soundVolume = 1.0
        }
        selectedStartSound = UserDefaults.standard.string(forKey: "selectedStartSound") ?? "default"
        selectedPauseSound = UserDefaults.standard.string(forKey: "selectedPauseSound") ?? "default"
        selectedCompleteSound = UserDefaults.standard.string(forKey: "selectedCompleteSound") ?? "default"
        selectedBreakCompleteSound = UserDefaults.standard.string(forKey: "selectedBreakCompleteSound") ?? "default"
        
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        focusStartNotification = UserDefaults.standard.bool(forKey: "focusStartNotification")
        focusPauseNotification = UserDefaults.standard.bool(forKey: "focusPauseNotification")
        focusCompleteNotification = UserDefaults.standard.bool(forKey: "focusCompleteNotification")
        achievementNotification = UserDefaults.standard.bool(forKey: "achievementNotification")
        dailySummaryNotification = UserDefaults.standard.bool(forKey: "dailySummaryNotification")
        weeklySummaryNotification = UserDefaults.standard.bool(forKey: "weeklySummaryNotification")
        smartReminderNotification = UserDefaults.standard.bool(forKey: "smartReminderNotification")
        
        // 专注设置（默认值）
        focusDndEnabled = UserDefaults.standard.object(forKey: "focusDndEnabled") as? Bool ?? false // 默认为false
        breakDuration = UserDefaults.standard.integer(forKey: "breakDuration")
        if breakDuration == 0 {
            breakDuration = 10 // 默认10分钟
        }
        autoStartAfterBreak = UserDefaults.standard.object(forKey: "autoStartAfterBreak") as? Bool ?? true // 默认为true
        whiteNoiseEnabled = UserDefaults.standard.object(forKey: "whiteNoiseEnabled") as? Bool ?? false
        selectedWhiteNoise = UserDefaults.standard.string(forKey: "selectedWhiteNoise") ?? "none"
        whiteNoiseVolume = UserDefaults.standard.object(forKey: "whiteNoiseVolume") as? Float ?? 0.5
        liveActivityEnabled = UserDefaults.standard.object(forKey: "liveActivityEnabled") as? Bool ?? true // 默认为true
        
        // 专注锁定模式设置（默认值）
        focusLockEnabled = UserDefaults.standard.object(forKey: "focusLockEnabled") as? Bool ?? false
        lockStrength = .hard // 固定为硬锁定
        blockedApps = UserDefaults.standard.stringArray(forKey: "blockedApps") ?? []
        blockAllAppsExceptSystem = UserDefaults.standard.object(forKey: "blockAllAppsExceptSystem") as? Bool ?? false
    }
    
    func saveSettings() {
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(soundVolume, forKey: "soundVolume")
        UserDefaults.standard.set(selectedStartSound, forKey: "selectedStartSound")
        UserDefaults.standard.set(selectedPauseSound, forKey: "selectedPauseSound")
        UserDefaults.standard.set(selectedCompleteSound, forKey: "selectedCompleteSound")
        UserDefaults.standard.set(selectedBreakCompleteSound, forKey: "selectedBreakCompleteSound")
        
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(focusStartNotification, forKey: "focusStartNotification")
        UserDefaults.standard.set(focusPauseNotification, forKey: "focusPauseNotification")
        UserDefaults.standard.set(focusCompleteNotification, forKey: "focusCompleteNotification")
        UserDefaults.standard.set(achievementNotification, forKey: "achievementNotification")
        UserDefaults.standard.set(dailySummaryNotification, forKey: "dailySummaryNotification")
        UserDefaults.standard.set(weeklySummaryNotification, forKey: "weeklySummaryNotification")
        UserDefaults.standard.set(smartReminderNotification, forKey: "smartReminderNotification")
        
        UserDefaults.standard.set(focusDndEnabled, forKey: "focusDndEnabled")
        UserDefaults.standard.set(breakDuration, forKey: "breakDuration")
        UserDefaults.standard.set(autoStartAfterBreak, forKey: "autoStartAfterBreak")
        UserDefaults.standard.set(whiteNoiseEnabled, forKey: "whiteNoiseEnabled")
        UserDefaults.standard.set(selectedWhiteNoise, forKey: "selectedWhiteNoise")
        UserDefaults.standard.set(whiteNoiseVolume, forKey: "whiteNoiseVolume")
        UserDefaults.standard.set(liveActivityEnabled, forKey: "liveActivityEnabled")
        
        UserDefaults.standard.set(focusLockEnabled, forKey: "focusLockEnabled")
        UserDefaults.standard.set(lockStrength.rawValue, forKey: "lockStrength")
        UserDefaults.standard.set(blockedApps, forKey: "blockedApps")
        UserDefaults.standard.set(blockAllAppsExceptSystem, forKey: "blockAllAppsExceptSystem")
        
        UserDefaults.standard.synchronize()
    }
}

// MARK: - 锁定强度枚举（已简化为只有硬锁定）
enum LockStrength: String, CaseIterable {
    case hard = "hard" // 硬锁定：完全无法打开直到专注结束
    
    var displayName: String {
        return "硬锁定"
    }
}

