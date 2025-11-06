//
//  AppConstants.swift
//  FocusFlow
//
//  应用常量定义
//

import Foundation

enum AppConstants {
    // MARK: - 应用信息
    static let appName = "FocusFlow"
    static let appVersion = "1.0.0"
    
    // MARK: - 专注时长预设（分钟）
    static let presetDurations: [Int] = [15, 25, 30, 45, 60, 90]
    
    // MARK: - 番茄模式默认值
    static let defaultPomodoroDuration = 25 // 分钟
    static let defaultShortBreakDuration = 5 // 分钟
    static let defaultLongBreakDuration = 15 // 分钟
    static let defaultPomodorosBeforeLongBreak = 4
    
    // MARK: - 计时器限制
    static let minDuration = 1 // 分钟
    static let maxDuration = 300 // 分钟
    
    // MARK: - 经验值系统
    static let expPerMinute = 1 // 每分钟专注获得1经验
    static let expPerPomodoro = 10 // 完成番茄额外获得10经验
    static let expPerDailyGoal = 50 // 完成每日目标额外50经验
    static let expMultiplierForStreak = 1.5 // 连续专注经验倍数
    
    // MARK: - 等级系统
    static let levelRanges: [(min: Int, max: Int, name: String)] = [
        (0, 1000, "初学者"),
        (1000, 5000, "进阶者"),
        (5000, 20000, "专注者"),
        (20000, 100000, "大师"),
        (100000, Int.max, "传奇")
    ]
    
    // MARK: - 通知ID
    enum NotificationID {
        static let focusStart = "focus_start"
        static let focusComplete = "focus_complete"
        static let focusPause = "focus_pause"
        static let dailySummary = "daily_summary"
    }
}

