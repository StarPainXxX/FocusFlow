//
//  StorageKeys.swift
//  FocusFlow
//
//  存储键名定义
//

import Foundation

enum StorageKeys {
    // MARK: - 用户设置
    static let currentTheme = "current_theme"
    static let soundEnabled = "sound_enabled"
    static let vibrationEnabled = "vibration_enabled"
    static let notificationEnabled = "notification_enabled"
    static let defaultFocusDuration = "default_focus_duration"
    
    // MARK: - 用户数据
    static let userLevel = "user_level"
    static let userExp = "user_exp"
    static let totalFocusTime = "total_focus_time"
    static let consecutiveDays = "consecutive_days"
    static let bestStreak = "best_streak"
    static let totalPomodoros = "total_pomodoros"
    
    // MARK: - 目标设置
    static let dailyGoal = "daily_goal"
    static let weeklyGoal = "weekly_goal"
    
    // MARK: - 同步状态
    static let lastSyncTime = "last_sync_time"
    static let syncStatus = "sync_status"
}

