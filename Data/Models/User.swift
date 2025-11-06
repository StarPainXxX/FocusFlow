//
//  User.swift
//  FocusFlow
//
//  用户模型
//

import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var email: String?
    var displayName: String?
    var avatar: String?
    var level: Int
    var exp: Int
    var totalFocusTime: Int // 累计专注时长（分钟）
    var consecutiveDays: Int
    var bestStreak: Int
    var totalPomodoros: Int
    var dailyGoal: Int // 每日目标时长（分钟）
    var weeklyGoal: Int // 每周目标时长（分钟）
    var preferredFocusDuration: Int // 偏好专注时长（分钟）
    var theme: String
    var settings: String // JSON字符串存储设置
    var createdAt: Date
    var lastLoginAt: Date
    var updatedAt: Date
    var isPremium: Bool
    
    // 计算属性：当前等级名称
    var levelName: String {
        for range in AppConstants.levelRanges {
            if exp >= range.min && exp < range.max {
                return range.name
            }
        }
        return "传奇"
    }
    
    // 计算属性：距离下一级所需经验
    var expToNextLevel: Int {
        for range in AppConstants.levelRanges {
            if exp >= range.min && exp < range.max {
                return range.max - exp
            }
        }
        return 0
    }
    
    // 计算属性：当前等级进度百分比
    var levelProgress: Double {
        for range in AppConstants.levelRanges {
            if exp >= range.min && exp < range.max {
                let currentLevelExp = exp - range.min
                let levelTotalExp = range.max - range.min
                return Double(currentLevelExp) / Double(levelTotalExp)
            }
        }
        return 1.0
    }
    
    init(
        id: UUID = UUID(),
        email: String? = nil,
        displayName: String? = nil,
        avatar: String? = nil,
        level: Int = 1,
        exp: Int = 0,
        totalFocusTime: Int = 0,
        consecutiveDays: Int = 0,
        bestStreak: Int = 0,
        totalPomodoros: Int = 0,
        dailyGoal: Int = 240, // 默认4小时
        weeklyGoal: Int = 1680, // 默认28小时
        preferredFocusDuration: Int = 45,
        theme: String = "light",
        settings: String = "{}",
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        updatedAt: Date = Date(),
        isPremium: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatar = avatar
        self.level = level
        self.exp = exp
        self.totalFocusTime = totalFocusTime
        self.consecutiveDays = consecutiveDays
        self.bestStreak = bestStreak
        self.totalPomodoros = totalPomodoros
        self.dailyGoal = dailyGoal
        self.weeklyGoal = weeklyGoal
        self.preferredFocusDuration = preferredFocusDuration
        self.theme = theme
        self.settings = settings
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.updatedAt = updatedAt
        self.isPremium = isPremium
    }
    
    /// 增加经验值并更新等级
    func addExp(_ amount: Int) {
        self.exp += amount
        self.updatedAt = Date()
        
        // 检查是否需要升级
        updateLevel()
    }
    
    /// 更新等级
    private func updateLevel() {
        var newLevel = 1
        for (index, range) in AppConstants.levelRanges.enumerated() {
            if exp >= range.min && exp < range.max {
                newLevel = index + 1
                break
            }
        }
        
        if newLevel > self.level {
            self.level = newLevel
        }
    }
    
    /// 增加专注时长
    func addFocusTime(_ minutes: Int) {
        self.totalFocusTime += minutes
        self.updatedAt = Date()
    }
    
    /// 更新连续天数
    func updateConsecutiveDays(_ days: Int) {
        self.consecutiveDays = days
        if days > bestStreak {
            self.bestStreak = days
        }
        self.updatedAt = Date()
    }
}

